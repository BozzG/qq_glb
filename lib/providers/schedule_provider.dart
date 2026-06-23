import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class ScheduleProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  List<Schedule> _schedules = [];
  List<CheckIn> _checkIns = [];
  bool _isLoading = false;

  List<Schedule> get schedules => _schedules;
  List<CheckIn> get checkIns => _checkIns;
  bool get isLoading => _isLoading;

  /// 获取某天的日程（独立实例模式下直接按日期匹配即可）
  List<Schedule> getSchedulesForDay(DateTime day) {
    return _schedules.where((s) {
      return isSameDay(s.dateTime, day);
    }).toList();
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> loadSchedules() async {
    _isLoading = true;
    notifyListeners();
    try {
      final maps = await _db.query('schedules', orderBy: 'dateTime ASC');
      _schedules = maps.map((m) => Schedule.fromMap(m)).toList();
      
      // 加载后自动检查是否需要扩展重复日程
      await _ensureRecurringSchedulesExpanded();

      final checkInMaps = await _db.query('check_ins', orderBy: 'checkInTime DESC');
      _checkIns = checkInMaps.map((m) => CheckIn.fromMap(m)).toList();
    } catch (e) {
      debugPrint('加载日程失败: $e');
    }
    _isLoading = false;
    notifyListeners();
    // 同步今日日程到 iOS 桌面 Widget（统一收口，覆盖增删改/打卡/撤销/重复规则提交；
    // 非 iOS 平台内部 no-op）。fire-and-forget，失败不影响主流程。
    _syncWidget();
  }

  /// 把今日日程推送给桌面 Widget（仅 iOS 生效）。
  void _syncWidget() {
    WidgetService.syncTodaySchedules(
      todaySchedules: getSchedulesForDay(DateTime.now()),
      isChecked: isCheckedIn,
    );
  }

  /// 添加日程（非重复：直接保存；重复：批量创建当前月+下月实例）
  Future<void> addSchedule(Schedule schedule) async {
    try {
      if (schedule.repeatType == RepeatType.none) {
        // 不重复：直接插入
        await _db.insert('schedules', schedule.toMap());
        await _notificationService.scheduleForSchedule(schedule);
      } else {
        // 重复日程：批量创建独立实例
        await _createRecurringInstances(schedule);
      }
      await loadSchedules();
    } catch (e) {
      debugPrint('添加日程失败: $e');
    }
  }

  /// 批量创建重复日程的独立实例
  /// 创建规则：从起始日期开始，生成当前月和下一个月的所有匹配日期的独立 Schedule
  Future<void> _createRecurringInstances(Schedule template) async {
    final templateId = const Uuid().v4();
    final now = DateTime.now();

    // 确定结束范围：下个月的最后一天
    var endMonth = now.month + 1;
    var endYear = now.year;
    if (endMonth > 12) { endMonth -= 12; endYear += 1; }
    final endDate = DateTime(endYear, endMonth + 1, 0); // 下月末

    DateTime currentDay = DateTime(template.dateTime.year, template.dateTime.month, template.dateTime.day);
    bool isFirst = true;

    while (!currentDay.isAfter(endDate)) {
      bool shouldCreate = false;
      if (template.repeatType == RepeatType.daily) {
        shouldCreate = true;
      } else if (template.repeatType == RepeatType.weekly || template.repeatType == RepeatType.custom) {
        shouldCreate = template.repeatDays.contains(currentDay.weekday);
      }

      if (shouldCreate) {
        final instanceId = isFirst ? template.id : const Uuid().v4();
        final instanceDateTime = DateTime(
          currentDay.year, currentDay.month, currentDay.day,
          template.dateTime.hour, template.dateTime.minute,
        );

        final instance = Schedule(
          id: instanceId,
          title: template.title,
          description: template.description,
          location: template.location,
          dateTime: instanceDateTime,
          endTime: template.endTime != null ? DateTime(
            currentDay.year, currentDay.month, currentDay.day,
            template.endTime!.hour, template.endTime!.minute,
          ) : null,
          repeatType: template.repeatType,
          repeatDays: List.from(template.repeatDays),
          scheduleType: template.scheduleType,
          isCourse: template.isCourse,
          courseId: template.courseId,
          courseHours: template.courseHours,
          memo: template.memo,
          parentId: isFirst ? null : template.id,   // 第一个实例是组长(parentId=null)
          repeatTemplateId: templateId,
          createdAt: template.createdAt,
          updatedAt: template.updatedAt,
        );

        await _db.insert('schedules', instance.toMap());
        await _notificationService.scheduleForSchedule(instance);

        isFirst = false;
      }

      currentDay = currentDay.add(Duration(days: 1));
    }
  }

  /// 检查并自动扩展重复日程数据
  /// 当 APP 使用时，如果发现某个 repeatTemplateId 的最晚实例已不足覆盖下个月，
  /// 则自动创建下个月的重复实例
  Future<void> _ensureRecurringSchedulesExpanded() async {
    if (_schedules.isEmpty) return;

    // 收集所有有 repeatTemplateId 的日程，按模板分组
    final Map<String, List<Schedule>> templateGroups = {};
    for (final s in _schedules) {
      if (s.repeatTemplateId != null && s.repeatType != RepeatType.none) {
        templateGroups.putIfAbsent(s.repeatTemplateId!, () => []).add(s);
      }
    }

    final now = DateTime.now();
    // 需要覆盖到下个月末
    var targetMonth = now.month + 1;
    var targetYear = now.year;
    if (targetMonth > 12) { targetMonth -= 12; targetYear += 1; }
    // needUntil = 下月末 00:00:00。
    // 与 commitRecurringRuleUpdate 路径的 _nextMonthEnd（下月末 23:59:59）配合：
    // commit 一次性写到 23:59:59，本函数判断 !latest.isAfter(needUntil) 为 false → 不重复补齐。
    // 修改此处时请同步更新 _nextMonthEnd 注释。
    final needUntil = DateTime(targetYear, targetMonth + 1, 0);

    for (final entry in templateGroups.entries) {
      final instances = entry.value;
      // 按日期排序找最新的
      instances.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      final latest = instances.last;

      if (!latest.dateTime.isAfter(needUntil)) {
        // 最新的实例不够远了，需要扩展
        // 用组长作为模板（parentId==null 的那个）
        final leader = instances.firstWhere((s) => s.parentId == null, orElse: () => instances.first);
        
        DateTime startFrom = latest.dateTime.add(Duration(days: 1));
        while (!startFrom.isAfter(needUntil)) {
          bool shouldCreate = false;
          if (leader.repeatType == RepeatType.daily) {
            shouldCreate = true;
          } else if (leader.repeatType == RepeatType.weekly || leader.repeatType == RepeatType.custom) {
            shouldCreate = leader.repeatDays.contains(startFrom.weekday);
          }

          if (shouldCreate) {
            final instanceDateTime = DateTime(
              startFrom.year, startFrom.month, startFrom.day,
              leader.dateTime.hour, leader.dateTime.minute,
            );
            final instance = Schedule(
              id: const Uuid().v4(),
              title: leader.title,
              description: leader.description,
              location: leader.location,
              dateTime: instanceDateTime,
              endTime: leader.endTime != null ? DateTime(
                startFrom.year, startFrom.month, startFrom.day,
                leader.endTime!.hour, leader.endTime!.minute,
              ) : null,
              repeatType: leader.repeatType,
              repeatDays: List.from(leader.repeatDays),
              scheduleType: leader.scheduleType,
              isCourse: leader.isCourse,
              courseId: leader.courseId,
              courseHours: leader.courseHours,
              memo: leader.memo,
              parentId: leader.id,
              repeatTemplateId: leader.repeatTemplateId,
            );
            await _db.insert('schedules', instance.toMap());
            await _notificationService.scheduleForSchedule(instance);
          }

          startFrom = startFrom.add(Duration(days: 1));
        }
      }
    }

    // 重新加载以包含新生成的日程
    final maps = await _db.query('schedules', orderBy: 'dateTime ASC');
    _schedules = maps.map((m) => Schedule.fromMap(m)).toList();
  }

  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _db.update('schedules', schedule.toMap(), where: 'id = ?', whereArgs: [schedule.id]);
      await _notificationService.cancelForSchedule(schedule.id);
      await _notificationService.scheduleForSchedule(schedule);
      await loadSchedules();
    } catch (e) {
      debugPrint('更新日程失败: $e');
    }
  }

  /// 删除日程：
  /// - 如果是独立日程或重复组的一个实例：只删除该实例及其打卡记录
  /// - 如果需要删除整个重复组：删除所有同 repeatTemplateId 的日程
  Future<void> deleteSchedule(String id, {bool deleteAllRecurring = false}) async {
    try {
      final schedule = _schedules.firstWhere((s) => s.id == id, orElse: () => throw Exception('Not found'));

      if (deleteAllRecurring && schedule.repeatTemplateId != null) {
        // 删除整个重复组的所有实例
        final groupIds = _schedules
            .where((s) => s.repeatTemplateId == schedule.repeatTemplateId)
            .map((s) => s.id)
            .toList();
        for (final gid in groupIds) {
          await _db.delete('schedules', where: 'id = ?', whereArgs: [gid]);
          await _db.delete('check_ins', where: 'scheduleId = ?', whereArgs: [gid]);
          await _notificationService.cancelForSchedule(gid);
        }
      } else {
        // 只删除单个实例
        await _db.delete('schedules', where: 'id = ?', whereArgs: [id]);
        await _db.delete('check_ins', where: 'scheduleId = ?', whereArgs: [id]);
        await _notificationService.cancelForSchedule(id);
      }
      await loadSchedules();
    } catch (e) {
      debugPrint('删除日程失败: $e');
    }
  }

  /// 获取同一重复组的所有日程ID
  List<String> getGroupScheduleIds(String scheduleId) {
    final schedule = _schedules.firstWhere((s) => s.id == scheduleId, orElse: () => Schedule(
      id: '', title: '', dateTime: DateTime.now(), 
    ));
    if (schedule.repeatTemplateId == null) return [scheduleId];
    return _schedules
        .where((s) => s.repeatTemplateId == schedule.repeatTemplateId)
        .map((s) => s.id)
        .toList();
  }

  // 打卡（每个日程实例独立，以日程自身 dateTime 为归属日）
  Future<bool> checkIn(String scheduleId, {String? notes}) async {
    try {
      // 同一日程实例只允许打卡一次（日程本身已锁定到具体某天）
      final alreadyChecked = _checkIns.any((c) => c.scheduleId == scheduleId);
      if (alreadyChecked) return false;

      final checkIn = CheckIn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        scheduleId: scheduleId,
        checkInTime: DateTime.now(),
        notes: notes,
      );
      await _db.insert('check_ins', checkIn.toMap());

      // 如果是课程，自动扣课时
      final schedule = _schedules.firstWhere(
        (s) => s.id == scheduleId,
        orElse: () => throw Exception('Schedule not found'),
      );
      if (schedule.isCourse && schedule.courseId != null) {
        await _deductCourseHours(schedule.courseId!, checkIn.id, schedule.courseHours);
      }

      await loadSchedules();
      return true;
    } catch (e) {
      debugPrint('打卡失败: $e');
      return false;
    }
  }

  /// 判断某个日程实例是否已打卡
  /// 由于每个日程实例都绑定到具体某一天（包括重复日程的独立实例），
  /// 该实例一旦有任一条 check_in 记录，就视为已打卡。
  bool isCheckedIn(String scheduleId) {
    return _checkIns.any((c) => c.scheduleId == scheduleId);
  }

  Future<void> _deductCourseHours(String courseId, String checkInId, double amount) async {
    final consumption = CourseConsumption(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: courseId,
      consumedAmount: amount,
      consumptionType: ConsumptionType.auto,
      relatedCheckInId: checkInId,
    );
    await _db.insert('course_consumptions', consumption.toMap());
    
    final courseMaps = await _db.query('courses', where: 'id = ?', whereArgs: [courseId]);
    if (courseMaps.isNotEmpty) {
      final course = Course.fromMap(courseMaps.first);
      await _db.update('courses', {'usedHours': course.usedHours + amount}, where: 'id = ?', whereArgs: [courseId]);
    }
  }

  /// 撤销打卡（误打卡补救）。
  /// 规则：
  /// - 仅允许在打卡后 24 小时内撤销，超时返回 false；
  /// - 删除该日程的打卡记录；
  /// - 若打卡曾自动扣减课时，按消耗记录的 consumedAmount 原数回补 courses.usedHours，
  ///   并删除对应的 auto 类型 CourseConsumption。回补金额取自消耗记录自身，
  ///   因此天然兼容「一次打卡扣多课时」。
  /// 返回 true 表示撤销成功。
  Future<bool> undoCheckIn(String scheduleId) async {
    try {
      final idx = _checkIns.indexWhere((c) => c.scheduleId == scheduleId);
      if (idx < 0) return false;
      final checkIn = _checkIns[idx];

      // 24h 时限
      if (DateTime.now().difference(checkIn.checkInTime) >
          const Duration(hours: 24)) {
        return false;
      }

      // 回补课时：找该打卡关联的自动消耗记录
      final consMaps = await _db.query('course_consumptions',
          where: 'relatedCheckInId = ?', whereArgs: [checkIn.id]);
      for (final m in consMaps) {
        final cons = CourseConsumption.fromMap(m);
        final courseMaps = await _db
            .query('courses', where: 'id = ?', whereArgs: [cons.courseId]);
        if (courseMaps.isNotEmpty) {
          final course = Course.fromMap(courseMaps.first);
          final restored = course.usedHours - cons.consumedAmount;
          await _db.update('courses', {'usedHours': restored < 0 ? 0 : restored},
              where: 'id = ?', whereArgs: [cons.courseId]);
        }
        await _db.delete('course_consumptions',
            where: 'id = ?', whereArgs: [cons.id]);
      }

      // 删除打卡记录
      await _db.delete('check_ins', where: 'id = ?', whereArgs: [checkIn.id]);

      await loadSchedules();
      return true;
    } catch (e) {
      debugPrint('撤销打卡失败: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  修改重复规则（recurring-rule-edit）
  //  PRD: docs/prd/recurring-rule-edit.md（24 条 AC）
  //  Design: docs/design/recurring-rule-edit.md
  //  策略：preview（dry-run） + commit（事务化）
  // ─────────────────────────────────────────────────────────────

  /// 预演修改重复规则的影响，不写库。
  /// 返回三组：将删除的实例、将保留的实例、将新建的 dateTime 列表。
  ///
  /// 算法概要（详见 PRD AC-04 / AC-06 / AC-07 / AC-13 / AC-14 / AC-15 / AC-16）：
  /// 1. 找组：以 [scheduleIdInGroup] 找 repeatTemplateId，拉取所有同组实例。
  /// 2. 划分：tomorrowStart = (now.year, now.month, now.day + 1)；
  ///    实例 dateTime < tomorrowStart 或 isCheckedIn(s.id) → toKeep；其余 → toDelete。
  /// 3. 生成新 dateTime 列表：从 tomorrowStart 起到下月末 23:59，逐天判断 newRepeatType/newRepeatDays 命中。
  /// 4. 冲突避让（AC-07）：toCreate 中如果存在与 toKeep 中同一天（isSameDay）的项，移除该项。
  RecurringRuleUpdatePreview previewRecurringRuleUpdate({
    required String scheduleIdInGroup,
    required RepeatType newRepeatType,
    required List<int> newRepeatDays,
    required Schedule newTemplateFields,
  }) {
    // AC-13：weekly + 空 repeatDays → ArgumentError
    if (newRepeatType == RepeatType.weekly && newRepeatDays.isEmpty) {
      throw ArgumentError(
        'newRepeatDays must not be empty when newRepeatType is weekly',
      );
    }

    // 找到锚定实例并据其 repeatTemplateId 拉同组
    final anchor = _schedules.firstWhere(
      (s) => s.id == scheduleIdInGroup,
      orElse: () => throw StateError(
        'scheduleIdInGroup not found in current schedules: $scheduleIdInGroup',
      ),
    );
    final templateId = anchor.repeatTemplateId;
    if (templateId == null) {
      throw StateError(
        'anchor schedule is not part of a recurring group (repeatTemplateId == null)',
      );
    }
    final group = _schedules
        .where((s) => s.repeatTemplateId == templateId)
        .toList();

    final now = DateTime.now();
    final tomorrowStart = DateTime(now.year, now.month, now.day + 1);

    // 划分集
    final toKeep = <Schedule>[];
    final toDelete = <Schedule>[];
    for (final s in group) {
      if (_isFutureUnchecked(s, tomorrowStart)) {
        toDelete.add(s);
      } else {
        toKeep.add(s);
      }
    }

    // 生成新 dateTime 列表
    // 范围：[tomorrowStart, 下月末 23:59]
    final endRange = _nextMonthEnd(now);
    final hour = newTemplateFields.dateTime.hour;
    final minute = newTemplateFields.dateTime.minute;
    final rawDates = _generateDateTimes(
      start: tomorrowStart,
      endInclusive: endRange,
      type: newRepeatType,
      days: newRepeatDays,
      hour: hour,
      minute: minute,
    );

    // AC-07：冲突避让 —— 移除与 toKeep 中同一天冲突的新实例
    final toCreate = <DateTime>[];
    for (final d in rawDates) {
      final conflict = toKeep.any((k) => isSameDay(k.dateTime, d));
      if (!conflict) toCreate.add(d);
    }

    return RecurringRuleUpdatePreview(
      toDelete: toDelete,
      toKeep: toKeep,
      toCreate: toCreate,
    );
  }

  /// 提交修改：事务化执行 删除 / 组长接力 / 新建 / 通知刷新 / loadSchedules。
  ///
  /// 事务内顺序：
  ///   a. 删除 check_ins where scheduleId IN oldIds；删除 schedules
  ///   b. 组长接力判断：原组长是否在 toDelete？
  ///      - 在：选 toCreate 时间最早的为新组长（parentId=null, repeatTemplateId=旧值），
  ///            其余新实例 parentId = 新组长 id；txn.insert 全部新实例。
  ///      - 不在：原组长保留，update 其 repeatType/repeatDays/title/desc/location/memo/scheduleType/
  ///            isCourse/courseId/dateTime（年月日不动，时分刷新）/ endTime 时分 / updatedAt；
  ///            新实例 parentId 全部指向 leader.id；txn.insert 全部新实例。
  /// 事务后：cancelForSchedule 旧实例 + 老组长（如有 update）→ scheduleForSchedule 新实例 + 新/老组长 → loadSchedules。
  Future<void> commitRecurringRuleUpdate({
    required String scheduleIdInGroup,
    required RepeatType newRepeatType,
    required List<int> newRepeatDays,
    required Schedule newTemplateFields,
  }) async {
    final preview = previewRecurringRuleUpdate(
      scheduleIdInGroup: scheduleIdInGroup,
      newRepeatType: newRepeatType,
      newRepeatDays: newRepeatDays,
      newTemplateFields: newTemplateFields,
    );

    // 兜底：无任何变更时直接返回（不应到达，UI 已阻断）
    if (preview.toCreate.isEmpty && preview.toDelete.isEmpty) {
      return;
    }

    // 锚定 + 同组实例（preview 已校验存在）
    final anchor = _schedules.firstWhere((s) => s.id == scheduleIdInGroup);
    final templateId = anchor.repeatTemplateId!;
    final group = _schedules
        .where((s) => s.repeatTemplateId == templateId)
        .toList();
    final originalLeader = group.firstWhere(
      (s) => s.parentId == null,
      orElse: () => group.first,
    );
    final leaderInDelete = preview.toDelete.any((s) => s.id == originalLeader.id);

    // 收集事务输出，事务外做通知 / loadSchedules
    final oldIds = preview.toDelete.map((s) => s.id).toList();
    final List<Schedule> insertedInstances = [];
    Schedule? updatedLeader; // 仅在 leader 在 toKeep 时使用

    final db = await _db.database;
    await db.transaction((txn) async {
      // a. 删 check_ins / schedules
      for (final id in oldIds) {
        await txn.delete('check_ins', where: 'scheduleId = ?', whereArgs: [id]);
      }
      for (final id in oldIds) {
        await txn.delete('schedules', where: 'id = ?', whereArgs: [id]);
      }

      if (preview.toCreate.isEmpty) {
        // 防御编程：理论上不可达。
        // 上游已有两层保护：
        //   1. previewRecurringRuleUpdate 校验 weekly+空 days → ArgumentError；
        //   2. commitRecurringRuleUpdate 顶部 if (toCreate.isEmpty && toDelete.isEmpty) return。
        // 走到此处意味着"只删不建"——当前 UI/AC 不会触发，但保留分支以避免误删后空提交。
        return;
      }

      // 排序保证"未来第一条"是 toCreate.first
      final sortedDates = List<DateTime>.from(preview.toCreate)
        ..sort((a, b) => a.compareTo(b));

      if (leaderInDelete) {
        // 组长接力：未来第一条成为新组长
        final newLeader = _buildLeaderInstance(
          dateTime: sortedDates.first,
          template: newTemplateFields,
          newRepeatType: newRepeatType,
          newRepeatDays: newRepeatDays,
          repeatTemplateId: templateId,
        );
        await txn.insert('schedules', newLeader.toMap());
        insertedInstances.add(newLeader);

        for (var i = 1; i < sortedDates.length; i++) {
          final child = _buildChildInstance(
            dateTime: sortedDates[i],
            template: newTemplateFields,
            newRepeatType: newRepeatType,
            newRepeatDays: newRepeatDays,
            parentId: newLeader.id,
            repeatTemplateId: templateId,
          );
          await txn.insert('schedules', child.toMap());
          insertedInstances.add(child);
        }
      } else {
        // 组长保留：update 其字段（dateTime 年月日不动，仅刷新时分）
        updatedLeader = _buildUpdatedLeader(
          original: originalLeader,
          template: newTemplateFields,
          newRepeatType: newRepeatType,
          newRepeatDays: newRepeatDays,
        );
        await txn.update(
          'schedules',
          updatedLeader!.toMap(),
          where: 'id = ?',
          whereArgs: [originalLeader.id],
        );

        // 所有新实例指向原组长
        for (final dt in sortedDates) {
          final child = _buildChildInstance(
            dateTime: dt,
            template: newTemplateFields,
            newRepeatType: newRepeatType,
            newRepeatDays: newRepeatDays,
            parentId: originalLeader.id,
            repeatTemplateId: templateId,
          );
          await txn.insert('schedules', child.toMap());
          insertedInstances.add(child);
        }
      }
    });

    // 事务后：通知刷新（AC-18 / AC-19 / AC-20）
    for (final id in oldIds) {
      try {
        await _notificationService.cancelForSchedule(id);
      } catch (e) {
        debugPrint('cancelForSchedule failed: $id, $e');
      }
    }
    if (updatedLeader != null) {
      try {
        await _notificationService.cancelForSchedule(originalLeader.id);
      } catch (e) {
        debugPrint('cancelForSchedule(old leader) failed: $e');
      }
      try {
        await _notificationService.scheduleForSchedule(updatedLeader!);
      } catch (e) {
        debugPrint('scheduleForSchedule(new leader) failed: $e');
      }
    }
    for (final ins in insertedInstances) {
      try {
        await _notificationService.scheduleForSchedule(ins);
      } catch (e) {
        debugPrint('scheduleForSchedule failed: ${ins.id}, $e');
      }
    }

    debugPrint(
      'updateRecurringRule: del=${preview.toDelete.length} keep=${preview.toKeep.length} new=${preview.toCreate.length}',
    );

    await loadSchedules();
  }

  // ─── 私有辅助 ─────────────────────────────────────────────

  /// 判断某实例是否"未来未打卡"（删除集判定）
  bool _isFutureUnchecked(Schedule s, DateTime tomorrowStart) {
    if (s.dateTime.isBefore(tomorrowStart)) return false; // 今天及之前 → 保留
    if (isCheckedIn(s.id)) return false; // 已打卡 → 保留
    return true;
  }

  /// 计算下月末（作为 commit 生成新实例的遍历上界）。
  ///
  /// 时分秒固定为 23:59:59，与 [_ensureRecurringSchedulesExpanded] 中
  /// `needUntil = DateTime(targetYear, targetMonth + 1, 0)` 形成隐式契约：
  /// - 续期函数的 needUntil 是下月末 00:00:00；
  /// - 本函数返回下月末 23:59:59。
  /// 这样 commit 写入的最后一条实例 `dateTime > needUntil`，
  /// 续期函数判断 `!latest.dateTime.isAfter(needUntil)` 为 false，
  /// 不会重复补齐 → 避免与 _ensureRecurringSchedulesExpanded 的竞态。
  /// 修改任一端时务必同步更新另一端注释。
  DateTime _nextMonthEnd(DateTime now) {
    var endMonth = now.month + 1;
    var endYear = now.year;
    if (endMonth > 12) {
      endMonth -= 12;
      endYear += 1;
    }
    // 下月末 = (endYear, endMonth + 1, 0) → DateTime 月份为 0 时自动回滚到上月最后一天
    return DateTime(endYear, endMonth + 1, 0, 23, 59, 59);
  }

  /// 通用日期遍历：在 [start, endInclusive] 区间内，按 type / days 命中规则生成 dateTime（hour:minute）。
  /// AC-14：daily 视为每天命中；AC-15/AC-16：weekly/custom 按 days 命中。
  List<DateTime> _generateDateTimes({
    required DateTime start,
    required DateTime endInclusive,
    required RepeatType type,
    required List<int> days,
    required int hour,
    required int minute,
  }) {
    final result = <DateTime>[];
    DateTime cursor = DateTime(start.year, start.month, start.day);
    final lastDay = DateTime(
      endInclusive.year,
      endInclusive.month,
      endInclusive.day,
    );
    while (!cursor.isAfter(lastDay)) {
      bool hit = false;
      switch (type) {
        case RepeatType.daily:
          hit = true;
          break;
        case RepeatType.weekly:
        case RepeatType.custom:
          hit = days.contains(cursor.weekday);
          break;
        case RepeatType.none:
          hit = false; // 不应到达，UI 不会传 none
          break;
      }
      if (hit) {
        result.add(
          DateTime(cursor.year, cursor.month, cursor.day, hour, minute),
        );
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  /// 构造新组长实例（parentId = null）。
  /// 注意：必须使用 Schedule 构造函数，不能用 copyWith（copyWith parentId 不能设为 null）。
  Schedule _buildLeaderInstance({
    required DateTime dateTime,
    required Schedule template,
    required RepeatType newRepeatType,
    required List<int> newRepeatDays,
    required String repeatTemplateId,
  }) {
    return Schedule(
      id: const Uuid().v4(),
      title: template.title,
      description: template.description,
      location: template.location,
      memo: template.memo,
      dateTime: dateTime,
      endTime: _shiftEndTimeToDate(template.endTime, dateTime),
      repeatType: newRepeatType,
      repeatDays: List.from(newRepeatDays),
      scheduleType: template.scheduleType,
      isCourse: template.isCourse,
      courseId: template.courseId,
      courseHours: template.courseHours,
      parentId: null,
      repeatTemplateId: repeatTemplateId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 构造从属实例（parentId = leaderId）。
  Schedule _buildChildInstance({
    required DateTime dateTime,
    required Schedule template,
    required RepeatType newRepeatType,
    required List<int> newRepeatDays,
    required String parentId,
    required String repeatTemplateId,
  }) {
    return Schedule(
      id: const Uuid().v4(),
      title: template.title,
      description: template.description,
      location: template.location,
      memo: template.memo,
      dateTime: dateTime,
      endTime: _shiftEndTimeToDate(template.endTime, dateTime),
      repeatType: newRepeatType,
      repeatDays: List.from(newRepeatDays),
      scheduleType: template.scheduleType,
      isCourse: template.isCourse,
      courseId: template.courseId,
      courseHours: template.courseHours,
      parentId: parentId,
      repeatTemplateId: repeatTemplateId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 组长保留场景的 update：dateTime 年月日不动，仅刷新时分；
  /// repeatType / repeatDays / 模板字段全部刷新；updatedAt = now。
  Schedule _buildUpdatedLeader({
    required Schedule original,
    required Schedule template,
    required RepeatType newRepeatType,
    required List<int> newRepeatDays,
  }) {
    final newDateTime = DateTime(
      original.dateTime.year,
      original.dateTime.month,
      original.dateTime.day,
      template.dateTime.hour,
      template.dateTime.minute,
    );
    return Schedule(
      id: original.id,
      title: template.title,
      description: template.description,
      location: template.location,
      memo: template.memo,
      dateTime: newDateTime,
      endTime: _shiftEndTimeToDate(template.endTime, newDateTime),
      repeatType: newRepeatType,
      repeatDays: List.from(newRepeatDays),
      scheduleType: template.scheduleType,
      isCourse: template.isCourse,
      courseId: template.courseId,
      courseHours: template.courseHours,
      parentId: null, // 保持组长身份
      repeatTemplateId: original.repeatTemplateId,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// 把 template.endTime 的时分对齐到目标日期上；endTime == null 时返回 null。
  DateTime? _shiftEndTimeToDate(DateTime? endTime, DateTime targetDate) {
    if (endTime == null) return null;
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      endTime.hour,
      endTime.minute,
    );
  }

  // 获取打卡统计（按日程本身的日期归档，而非打卡操作时间）
  // 对于已删除的日程，fallback 使用 checkInTime
  Map<String, dynamic> getCheckInStats({required DateTime start, required DateTime end}) {
    final startOfDay = DateTime(start.year, start.month, start.day);
    // 次日 00:00，用半开区间 [startOfDay, endExclusive) 过滤
    final endExclusive = DateTime(end.year, end.month, end.day).add(const Duration(days: 1));

    // 为每条打卡解析其"归属日期"：优先日程自身的 dateTime，找不到则用 checkInTime
    final scheduleById = {for (final s in _schedules) s.id: s};
    DateTime ownDateOf(CheckIn c) {
      final s = scheduleById[c.scheduleId];
      return s?.dateTime ?? c.checkInTime;
    }

    final filtered = _checkIns.where((c) {
      final d = ownDateOf(c);
      return !d.isBefore(startOfDay) && d.isBefore(endExclusive);
    }).toList();

    Map<String, int> dailyCounts = {};
    for (var ci in filtered) {
      final d = ownDateOf(ci);
      final key =
          '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';
      dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
    }

    return {
      'totalCount': filtered.length,
      'uniqueDays': dailyCounts.keys.length,
      'dailyCounts': dailyCounts,
    };
  }
}

/// 修改重复规则的预演结果（dry-run）。
///
/// - [toDelete]：未来未打卡的实例（commit 时会被删除）。
/// - [toKeep]：今天及之前 / 已打卡的实例（commit 不动）。
/// - [toCreate]：新规则下将新建的 dateTime 列表（按时间升序，已剔除与 toKeep 同日冲突）。
class RecurringRuleUpdatePreview {
  final List<Schedule> toDelete;
  final List<Schedule> toKeep;
  final List<DateTime> toCreate;

  const RecurringRuleUpdatePreview({
    required this.toDelete,
    required this.toKeep,
    required this.toCreate,
  });
}
