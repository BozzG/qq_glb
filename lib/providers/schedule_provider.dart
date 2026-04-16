import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

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

  // 打卡（每个日程实例独立）
  Future<bool> checkIn(String scheduleId, {String? notes}) async {
    try {
      final today = DateTime.now();
      final alreadyChecked = _checkIns.any((c) =>
          c.scheduleId == scheduleId &&
          isSameDay(c.checkInTime, today));
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
        await _deductCourseHours(schedule.courseId!, checkIn.id, 1.0);
      }

      await loadSchedules();
      return true;
    } catch (e) {
      debugPrint('打卡失败: $e');
      return false;
    }
  }

  bool isCheckedToday(String scheduleId) {
    final today = DateTime.now();
    return _checkIns.any((c) =>
        c.scheduleId == scheduleId &&
        c.checkInTime.year == today.year &&
        c.checkInTime.month == today.month &&
        c.checkInTime.day == today.day);
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

  // 获取打卡统计
  Map<String, dynamic> getCheckInStats({required DateTime start, required DateTime end}) {
    final filtered = _checkIns.where((c) =>
        c.checkInTime.isAfter(start.subtract(Duration(days: 1))) &&
        c.checkInTime.isBefore(end.add(Duration(days: 1)))).toList();

    Map<String, int> dailyCounts = {};
    for (var ci in filtered) {
      final key = '${ci.checkInTime.year}-${ci.checkInTime.month.toString().padLeft(2, "0")}-${ci.checkInTime.day.toString().padLeft(2, "0")}';
      dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
    }

    return {
      'totalCount': filtered.length,
      'uniqueDays': dailyCounts.keys.length,
      'dailyCounts': dailyCounts,
    };
  }
}
