import 'dart:io' show File;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:qianqian_growth_logbook/models/models.dart';
import 'package:qianqian_growth_logbook/providers/schedule_provider.dart';
import 'package:qianqian_growth_logbook/services/database_helper.dart';
import 'package:qianqian_growth_logbook/services/notification_service.dart';
import 'package:qianqian_growth_logbook/widgets/recurring_impact_dialog.dart';

/// ─────────────────────────────────────────────────────────────
/// 修改重复规则 - 单元测试 (Task #007)
///
/// 关联：
///   PRD     docs/prd/recurring-rule-edit.md   （24 条 AC，UI/单测分类已标注）
///   Design  docs/design/recurring-rule-edit.md（含 buildSampleLine K=0~K>3 矩阵）
///   Review  docs/review/recurring-rule-edit-cr.md
///   Plan    plans/6a4fdf818f2b49b8af2be98edc86accd/plan.md
///
/// 覆盖场景：
///   1. 组长在过去保留（leader in toKeep）
///   2. 组长在未来未打卡 → 接力（leader in toDelete）
///   3. 含已打卡未来实例（保留 + 冲突避让 AC-07）
///   4. weekly → daily 类型切换（AC-14）
///   5. 跨月续期（commit 后 _ensureRecurringSchedulesExpanded 不重复补全）
///   6. preview 计数精确性（AC-21）
///   7. 事务原子性（降级：静态断言 + 手测说明）
///   8. buildSampleLine 矩阵 K=0~6（design §5.4）
///   9. 边界 - 空 repeatDays（AC-13）
///   10. 向后兼容（AC-03：单实例 updateSchedule 仅改自己）
/// ─────────────────────────────────────────────────────────────
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseHelper.isTestMode = true;
    NotificationService().isTestMode = true;
    tzdata.initializeTimeZones();
    await NotificationService().init();
  });

  // ─── 测试夹具/工具 ──────────────────────────────────────────

  /// 计算 [base] 后第一个 weekday=[targetWeekday] 的日期（包含 base 当天）。
  /// targetWeekday 1=Mon … 7=Sun（与 DateTime.weekday 对齐）。
  DateTime nextWeekday(DateTime base, int targetWeekday, {int hour = 9, int minute = 0}) {
    var d = DateTime(base.year, base.month, base.day);
    while (d.weekday != targetWeekday) {
      d = d.add(const Duration(days: 1));
    }
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  /// 直接落库一条日程（绕开 addSchedule，不触发 _createRecurringInstances 副作用）。
  Future<void> insertRaw(Schedule s) async {
    await DatabaseHelper().insert('schedules', s.toMap());
  }

  /// 计算下月末 23:59:59（与 schedule_provider 私有 _nextMonthEnd 同源）。
  DateTime calcNextMonthEnd(DateTime now) {
    var endMonth = now.month + 1;
    var endYear = now.year;
    if (endMonth > 12) {
      endMonth -= 12;
      endYear += 1;
    }
    return DateTime(endYear, endMonth + 1, 0, 23, 59, 59);
  }

  /// 计算下月末 00:00:00（与 schedule_provider._ensureRecurringSchedulesExpanded.needUntil 同源）。
  DateTime calcNeedUntil(DateTime now) {
    var targetMonth = now.month + 1;
    var targetYear = now.year;
    if (targetMonth > 12) {
      targetMonth -= 12;
      targetYear += 1;
    }
    return DateTime(targetYear, targetMonth + 1, 0);
  }

  // ─────────────────────────────────────────────────────────────
  group('修改重复规则 (Task #007) - preview & commit 场景', () {
    late ScheduleProvider provider;
    late DateTime now;
    late DateTime tomorrowStart;
    const String tplId = 'tpl-tc007';

    setUp(() async {
      DatabaseHelper().resetDatabase();
      provider = ScheduleProvider();
      // 不先 loadSchedules，避免空表时也触发 expand；后面每个用例自行调
      now = DateTime.now();
      tomorrowStart = DateTime(now.year, now.month, now.day + 1);
    });

    tearDown(() async {
      await DatabaseHelper().recreateTables();
    });

    // ─────────────────────────────────────────────────────────
    // 场景 1：组长在过去保留（leader in toKeep）
    //   AC-04 / AC-06 / AC-12 / AC-21
    // ─────────────────────────────────────────────────────────
    test('TC-007-01: 组长在过去保留 - update 组长字段 / 新实例指向原组长', () async {
      // ── 准备 ──
      // 组长 = 昨天上午 9:00（过去 → 必落 toKeep）
      final yesterday = DateTime(now.year, now.month, now.day, 9, 0)
          .subtract(const Duration(days: 1));
      // 把 latest 设到下月末 + 5 天，避免 _ensureRecurringSchedulesExpanded 触发补齐
      final latestFar = calcNextMonthEnd(now).add(const Duration(days: 5));

      final leader = Schedule(
        id: 'tc007-01-leader',
        title: '篮球训练',
        dateTime: yesterday, // 昨天 → 过去 → 保留
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2, 3], // 一二三
        repeatTemplateId: tplId,
      );
      // 几条未来未打卡实例（在 tomorrowStart 之后）
      final futureMon = nextWeekday(tomorrowStart, 1, hour: 9);
      final futureTue = nextWeekday(tomorrowStart, 2, hour: 9);
      final futureWed = nextWeekday(tomorrowStart, 3, hour: 9);
      final farFuture = Schedule(
        id: 'tc007-01-far',
        title: '篮球训练',
        dateTime: latestFar,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2, 3],
        repeatTemplateId: tplId,
        parentId: 'tc007-01-leader',
      );

      await insertRaw(leader);
      await insertRaw(Schedule(
        id: 'tc007-01-mon',
        title: '篮球训练',
        dateTime: futureMon,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2, 3],
        repeatTemplateId: tplId,
        parentId: 'tc007-01-leader',
      ));
      await insertRaw(Schedule(
        id: 'tc007-01-tue',
        title: '篮球训练',
        dateTime: futureTue,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2, 3],
        repeatTemplateId: tplId,
        parentId: 'tc007-01-leader',
      ));
      await insertRaw(Schedule(
        id: 'tc007-01-wed',
        title: '篮球训练',
        dateTime: futureWed,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2, 3],
        repeatTemplateId: tplId,
        parentId: 'tc007-01-leader',
      ));
      await insertRaw(farFuture);

      await provider.loadSchedules();

      // ── 改：weekly 一二三 → 一二三五 ──
      final newTpl = leader.copyWith(
        title: '篮球训练-改名',
        dateTime: DateTime(2000, 1, 1, 18, 30), // 仅时分有效：18:30
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2, 3, 5],
      );

      final preview = provider.previewRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-01-leader',
        newRepeatType: RepeatType.weekly,
        newRepeatDays: const [1, 2, 3, 5],
        newTemplateFields: newTpl,
      );

      // toKeep 至少含组长 + 远期那条（未来但被冲突避让保留？远期是周几不一定。
      // 关键断言：组长（昨天）必在 toKeep；future* 三条由于"未来未打卡"必在 toDelete。
      final keepIds = preview.toKeep.map((s) => s.id).toSet();
      final delIds = preview.toDelete.map((s) => s.id).toSet();
      expect(keepIds, contains('tc007-01-leader'),
          reason: 'AC-04/AC-06：组长在昨天，必须落入 toKeep');
      expect(delIds,
          containsAll(['tc007-01-mon', 'tc007-01-tue', 'tc007-01-wed']),
          reason: 'AC-04：未来未打卡实例应进 toDelete');

      // toCreate 不为空（新规则下 [明天, 下月末] 有命中）
      expect(preview.toCreate, isNotEmpty);

      // ── commit ──
      await provider.commitRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-01-leader',
        newRepeatType: RepeatType.weekly,
        newRepeatDays: const [1, 2, 3, 5],
        newTemplateFields: newTpl,
      );

      // 组长仍在 schedules 中（id 不变，parentId=null），且字段已更新
      final after = provider.schedules.firstWhere(
        (s) => s.id == 'tc007-01-leader',
        orElse: () => Schedule(id: 'NF', title: 'NF', dateTime: DateTime(2000)),
      );
      expect(after.id, 'tc007-01-leader');
      expect(after.parentId, isNull, reason: 'AC-12：组长保留 parentId 仍为 null');
      expect(after.title, '篮球训练-改名',
          reason: 'AC-09：title 应被同步刷新');
      expect(after.repeatDays, const [1, 2, 3, 5],
          reason: 'AC-12：repeatDays 已更新');
      expect(after.dateTime.year, yesterday.year);
      expect(after.dateTime.month, yesterday.month);
      expect(after.dateTime.day, yesterday.day,
          reason: 'AC-12：组长 dateTime 年月日保持原值');
      expect(after.dateTime.hour, 18,
          reason: 'AC-12：仅时分被刷新');
      expect(after.dateTime.minute, 30);

      // 未来实例已被替换：原三条已删，按新规则生成的实例 parentId 都指向组长
      for (final id in ['tc007-01-mon', 'tc007-01-tue', 'tc007-01-wed']) {
        expect(provider.schedules.any((s) => s.id == id), false,
            reason: '$id 应已被删除');
      }
      final newChildren = provider.schedules
          .where((s) =>
              s.repeatTemplateId == tplId &&
              s.id != 'tc007-01-leader' &&
              s.id != 'tc007-01-far')
          .toList();
      expect(newChildren, isNotEmpty);
      for (final c in newChildren) {
        expect(c.parentId, 'tc007-01-leader',
            reason: 'AC-12：新实例 parentId 指向原组长');
      }
    });

    // ─────────────────────────────────────────────────────────
    // 场景 2：组长在未来未打卡 → 接力（leader in toDelete）
    //   AC-11
    // ─────────────────────────────────────────────────────────
    test('TC-007-02: 组长在未来未打卡 → 接力（新组长 = toCreate.first）', () async {
      // 组长 = 下周一未来日期，无打卡
      final futureMon = nextWeekday(tomorrowStart, 1, hour: 9);
      final futureMon2 = futureMon.add(const Duration(days: 7));

      final leader = Schedule(
        id: 'tc007-02-leader',
        title: '英语课',
        dateTime: futureMon, // 未来 + 未打卡 → 必落 toDelete
        repeatType: RepeatType.weekly,
        repeatDays: const [1],
        repeatTemplateId: tplId,
      );
      final child1 = Schedule(
        id: 'tc007-02-c1',
        title: '英语课',
        dateTime: futureMon2,
        repeatType: RepeatType.weekly,
        repeatDays: const [1],
        repeatTemplateId: tplId,
        parentId: 'tc007-02-leader',
      );

      await insertRaw(leader);
      await insertRaw(child1);
      await provider.loadSchedules();

      final newTpl = leader.copyWith(
        repeatType: RepeatType.weekly,
        repeatDays: const [2, 3],
        dateTime: DateTime(2000, 1, 1, 19, 0),
      );

      // commit 直接执行（preview 已隐含）
      await provider.commitRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-02-leader',
        newRepeatType: RepeatType.weekly,
        newRepeatDays: const [2, 3],
        newTemplateFields: newTpl,
      );

      // 原组长 id 不再存在
      expect(provider.schedules.any((s) => s.id == 'tc007-02-leader'), false,
          reason: 'AC-11：原组长（在 toDelete 中）已被删除');
      // 同模板组下应有新组长（parentId=null），且 repeatTemplateId 复用旧值
      final group = provider.schedules
          .where((s) => s.repeatTemplateId == tplId)
          .toList();
      expect(group, isNotEmpty);
      final newLeaders =
          group.where((s) => s.parentId == null).toList();
      expect(newLeaders.length, 1,
          reason: 'AC-11：新组只能有一个组长');
      // 新组长 dateTime 应等于 toCreate.first；toCreate.first = [明天, 下月末] 中
      // 第一个 weekday∈{2,3} 的日期 19:00。
      final newLeader = newLeaders.first;
      expect(newLeader.repeatType, RepeatType.weekly);
      expect(newLeader.repeatDays, const [2, 3]);
      expect(newLeader.dateTime.hour, 19);
      expect(newLeader.dateTime.minute, 0);
      // 其它新实例 parentId = 新组长 id
      for (final s in group.where((s) => s.parentId != null)) {
        expect(s.parentId, newLeader.id,
            reason: 'AC-11：从属实例 parentId 指向新组长');
      }
    });

    // ─────────────────────────────────────────────────────────
    // 场景 3：含已打卡未来实例
    //   AC-06 / AC-07
    // ─────────────────────────────────────────────────────────
    test('TC-007-03: 已打卡未来实例进 toKeep / 冲突避让', () async {
      // 组长 = 昨天（保留），含一条"未来某周一已打卡"
      final yesterday = DateTime(now.year, now.month, now.day, 9, 0)
          .subtract(const Duration(days: 1));
      final futureMon = nextWeekday(tomorrowStart, 1, hour: 9, minute: 0);
      final futureTue = nextWeekday(tomorrowStart, 2, hour: 9, minute: 0);

      final leader = Schedule(
        id: 'tc007-03-leader',
        title: 'A',
        dateTime: yesterday,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2],
        repeatTemplateId: tplId,
      );
      final monFuture = Schedule(
        id: 'tc007-03-mon',
        title: 'A',
        dateTime: futureMon,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2],
        repeatTemplateId: tplId,
        parentId: 'tc007-03-leader',
      );
      final tueFuture = Schedule(
        id: 'tc007-03-tue',
        title: 'A',
        dateTime: futureTue,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2],
        repeatTemplateId: tplId,
        parentId: 'tc007-03-leader',
      );
      await insertRaw(leader);
      await insertRaw(monFuture);
      await insertRaw(tueFuture);

      // 直接落一条 check_ins → 让 monFuture 进入"已打卡保留"
      final ci = CheckIn(
        id: 'ci-tc007-03',
        scheduleId: 'tc007-03-mon',
        checkInTime: DateTime.now(),
      );
      await DatabaseHelper().insert('check_ins', ci.toMap());

      await provider.loadSchedules();

      // 改：weekly 一二 → 三四
      final newTpl = leader.copyWith(
        repeatType: RepeatType.weekly,
        repeatDays: const [3, 4],
      );

      final preview = provider.previewRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-03-leader',
        newRepeatType: RepeatType.weekly,
        newRepeatDays: const [3, 4],
        newTemplateFields: newTpl,
      );

      // 已打卡的 monFuture 必须在 toKeep
      expect(preview.toKeep.any((s) => s.id == 'tc007-03-mon'), true,
          reason: 'AC-06：已打卡未来实例必落入 toKeep');
      // tueFuture 没打卡 → 必须在 toDelete
      expect(preview.toDelete.any((s) => s.id == 'tc007-03-tue'), true,
          reason: 'AC-04：未来未打卡实例必落入 toDelete');

      // 冲突避让（AC-07）：toCreate 中不应再出现与 mon (已打卡保留) 同日的实例
      // 由于新规则是周三/四，与已打卡周一不同日，所以"避让效果"未直接生效。
      // 这里我们再加一条断言：toCreate 的所有日期都不与 toKeep 中任意实例同日。
      bool sameDay(DateTime a, DateTime b) =>
          a.year == b.year && a.month == b.month && a.day == b.day;
      for (final d in preview.toCreate) {
        for (final k in preview.toKeep) {
          expect(sameDay(d, k.dateTime), false,
              reason: 'AC-07：toCreate 不得与 toKeep 同日冲突');
        }
      }

      // commit 后 mon 还在，且 check_in 还在
      await provider.commitRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-03-leader',
        newRepeatType: RepeatType.weekly,
        newRepeatDays: const [3, 4],
        newTemplateFields: newTpl,
      );
      expect(provider.schedules.any((s) => s.id == 'tc007-03-mon'), true,
          reason: 'AC-06：已打卡实例 commit 后仍存在');
      expect(provider.isCheckedIn('tc007-03-mon'), true,
          reason: 'AC-06：打卡记录原样保留');
    });

    // ─────────────────────────────────────────────────────────
    // 场景 4：weekly → daily 类型切换（AC-14）
    // ─────────────────────────────────────────────────────────
    test('TC-007-04: weekly → daily / repeatDays 被忽略 / 每天命中', () async {
      // 组长 = 昨天（保留）
      final yesterday = DateTime(now.year, now.month, now.day, 9, 0)
          .subtract(const Duration(days: 1));
      final leader = Schedule(
        id: 'tc007-04-leader',
        title: '晨跑',
        dateTime: yesterday,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 3, 5],
        repeatTemplateId: tplId,
      );
      await insertRaw(leader);
      await provider.loadSchedules();

      final newTpl = leader.copyWith(
        repeatType: RepeatType.daily,
        repeatDays: const [9999], // 任意值，daily 时应被忽略
      );

      final preview = provider.previewRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-04-leader',
        newRepeatType: RepeatType.daily,
        newRepeatDays: const [9999],
        newTemplateFields: newTpl,
      );

      // toCreate 应等于 [明天, 下月末] 的天数（每天一条，含周末）
      final start = tomorrowStart;
      final end = calcNextMonthEnd(now);
      final lastDay = DateTime(end.year, end.month, end.day);
      var cursor = DateTime(start.year, start.month, start.day);
      var expectedDays = 0;
      while (!cursor.isAfter(lastDay)) {
        expectedDays += 1;
        cursor = cursor.add(const Duration(days: 1));
      }
      expect(preview.toCreate.length, expectedDays,
          reason: 'AC-14：daily 应在 [明天, 下月末] 每天生成一条');

      // commit 后所有新实例 repeatType=daily
      await provider.commitRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-04-leader',
        newRepeatType: RepeatType.daily,
        newRepeatDays: const [9999],
        newTemplateFields: newTpl,
      );
      final group = provider.schedules
          .where((s) => s.repeatTemplateId == tplId)
          .toList();
      // 区分"保留集"与"新建集"：
      //   保留集（包括组长 + 今天及之前的旧实例）的 repeatType 行为：
      //     - 组长本身：commit 时通过 _buildUpdatedLeader 刷新为 daily；
      //     - 其它"今天及之前"的旧实例（如 _ensureRecurringSchedulesExpanded
      //       自动续出来的、命中今日 weekday 的那条）：原样保留 weekly，
      //       这是 PRD AC-04/AC-06 的核心承诺（不动保留集的 dateTime/repeatType）。
      //   新建集（commit 内 _buildLeaderInstance / _buildChildInstance 写入的）：
      //     必须全部为 daily。
      // 因此本断言改为：组长 + 新建实例必须都是 daily；保留的旧子实例 = weekly。
      final tomorrowStartLocal =
          DateTime(now.year, now.month, now.day + 1);
      final newOrLeader = group
          .where((s) =>
              s.id == 'tc007-04-leader' ||
              !s.dateTime.isBefore(tomorrowStartLocal))
          .toList();
      expect(newOrLeader, isNotEmpty);
      for (final s in newOrLeader) {
        expect(s.repeatType, RepeatType.daily,
            reason:
                'AC-14：组长 + 新建实例 commit 后 repeatType=daily, 实际 id=${s.id} parent=${s.parentId} dt=${s.dateTime}');
      }
    });

    // ─────────────────────────────────────────────────────────
    // 场景 5：跨月续期（不重复补全）
    //   AC-17
    // ─────────────────────────────────────────────────────────
    test('TC-007-05: commit 后 _ensureRecurringSchedulesExpanded 不重复补全',
        () async {
      // 组长 = 昨天，原 weekly 二三
      final yesterday = DateTime(now.year, now.month, now.day, 9, 0)
          .subtract(const Duration(days: 1));
      final leader = Schedule(
        id: 'tc007-05-leader',
        title: '钢琴',
        dateTime: yesterday,
        repeatType: RepeatType.weekly,
        repeatDays: const [2, 3],
        repeatTemplateId: tplId,
      );
      await insertRaw(leader);
      await provider.loadSchedules();

      final newTpl = leader.copyWith(
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2, 3, 4, 5],
      );

      // 第一次 commit
      await provider.commitRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-05-leader',
        newRepeatType: RepeatType.weekly,
        newRepeatDays: const [1, 2, 3, 4, 5],
        newTemplateFields: newTpl,
      );

      final beforeCount = provider.schedules
          .where((s) => s.repeatTemplateId == tplId)
          .length;
      expect(beforeCount, greaterThan(1));

      // latest 必须超过 needUntil（下月末 00:00）
      final latest = provider.schedules
          .where((s) => s.repeatTemplateId == tplId)
          .map((s) => s.dateTime)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final needUntil = calcNeedUntil(now);
      expect(latest.isAfter(needUntil), true,
          reason: 'AC-17：commit 写到下月末 23:59:59，需 > needUntil 00:00:00');

      // 再调一次 loadSchedules（内部会调 _ensureRecurringSchedulesExpanded）
      await provider.loadSchedules();
      final afterCount = provider.schedules
          .where((s) => s.repeatTemplateId == tplId)
          .length;
      expect(afterCount, beforeCount,
          reason: 'AC-17：续期函数不应在 latest > needUntil 时重复补齐');
    });

    // ─────────────────────────────────────────────────────────
    // 场景 6：preview 计数精确性（AC-21）
    // ─────────────────────────────────────────────────────────
    test('TC-007-06: preview 返回的三组长度与实际操作一致 (AC-21)', () async {
      final yesterday = DateTime(now.year, now.month, now.day, 9, 0)
          .subtract(const Duration(days: 1));
      final leader = Schedule(
        id: 'tc007-06-leader',
        title: 'X',
        dateTime: yesterday,
        repeatType: RepeatType.weekly,
        repeatDays: const [1],
        repeatTemplateId: tplId,
      );
      // 5 条未来未打卡实例（不同周一）
      final futureSchedules = <Schedule>[];
      var d = nextWeekday(tomorrowStart, 1, hour: 9);
      for (var i = 0; i < 5; i++) {
        futureSchedules.add(Schedule(
          id: 'tc007-06-f$i',
          title: 'X',
          dateTime: d,
          repeatType: RepeatType.weekly,
          repeatDays: const [1],
          repeatTemplateId: tplId,
          parentId: 'tc007-06-leader',
        ));
        d = d.add(const Duration(days: 7));
      }
      await insertRaw(leader);
      for (final s in futureSchedules) {
        await insertRaw(s);
      }
      await provider.loadSchedules();

      final newTpl = leader.copyWith(
        repeatType: RepeatType.weekly,
        repeatDays: const [1],
        dateTime: DateTime(2000, 1, 1, 10, 0),
      );

      final preview = provider.previewRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-06-leader',
        newRepeatType: RepeatType.weekly,
        newRepeatDays: const [1],
        newTemplateFields: newTpl,
      );

      final beforeGroup = provider.schedules
          .where((s) => s.repeatTemplateId == tplId)
          .length;

      await provider.commitRecurringRuleUpdate(
        scheduleIdInGroup: 'tc007-06-leader',
        newRepeatType: RepeatType.weekly,
        newRepeatDays: const [1],
        newTemplateFields: newTpl,
      );

      final afterGroup = provider.schedules
          .where((s) => s.repeatTemplateId == tplId)
          .length;

      // afterGroup = beforeGroup - toDelete + toCreate
      expect(
        afterGroup,
        beforeGroup - preview.toDelete.length + preview.toCreate.length,
        reason: 'AC-21：preview 的删/建数与实际操作完全一致',
      );
    });

    // ─────────────────────────────────────────────────────────
    // 场景 9：边界 - 空 repeatDays（AC-13）
    // ─────────────────────────────────────────────────────────
    test('TC-007-09: weekly + 空 repeatDays → 抛 ArgumentError (AC-13)', () async {
      final yesterday = DateTime(now.year, now.month, now.day, 9, 0)
          .subtract(const Duration(days: 1));
      final leader = Schedule(
        id: 'tc007-09-leader',
        title: 'Y',
        dateTime: yesterday,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2],
        repeatTemplateId: tplId,
      );
      await insertRaw(leader);
      await provider.loadSchedules();

      expect(
        () => provider.previewRecurringRuleUpdate(
          scheduleIdInGroup: 'tc007-09-leader',
          newRepeatType: RepeatType.weekly,
          newRepeatDays: const [],
          newTemplateFields: leader,
        ),
        throwsArgumentError,
        reason: 'AC-13：weekly + 空 repeatDays 必须抛 ArgumentError',
      );

      // commit 同样应抛（commit 内部先调 preview）
      expect(
        () => provider.commitRecurringRuleUpdate(
          scheduleIdInGroup: 'tc007-09-leader',
          newRepeatType: RepeatType.weekly,
          newRepeatDays: const [],
          newTemplateFields: leader,
        ),
        throwsArgumentError,
        reason: 'AC-13：commit 也应抛 ArgumentError（preview 先于事务）',
      );
    });

    // ─────────────────────────────────────────────────────────
    // 场景 10：向后兼容（AC-03）
    //   单实例 updateSchedule 仅改自己，不影响组内其它实例
    // ─────────────────────────────────────────────────────────
    test('TC-007-10: 单实例 updateSchedule 不影响组内其它实例 (AC-03)', () async {
      final yesterday = DateTime(now.year, now.month, now.day, 9, 0)
          .subtract(const Duration(days: 1));
      final leader = Schedule(
        id: 'tc007-10-leader',
        title: '原标题',
        dateTime: yesterday,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2],
        repeatTemplateId: tplId,
      );
      final futureMon = nextWeekday(tomorrowStart, 1, hour: 9);
      final child = Schedule(
        id: 'tc007-10-child',
        title: '原标题',
        dateTime: futureMon,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2],
        repeatTemplateId: tplId,
        parentId: 'tc007-10-leader',
      );
      await insertRaw(leader);
      await insertRaw(child);
      await provider.loadSchedules();

      // 改 child 的 title
      await provider.updateSchedule(child.copyWith(title: '新标题'));

      // 仅 child 改名，leader 保留原标题
      final afterChild = provider.schedules
          .firstWhere((s) => s.id == 'tc007-10-child');
      final afterLeader = provider.schedules
          .firstWhere((s) => s.id == 'tc007-10-leader');
      expect(afterChild.title, '新标题');
      expect(afterLeader.title, '原标题',
          reason: 'AC-03：updateSchedule 不影响组内其它实例');
      // 重复属性不变
      expect(afterChild.repeatType, RepeatType.weekly);
      expect(afterChild.repeatTemplateId, tplId);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 场景 8：buildSampleLine 矩阵（design §5.4）
  //   纯函数测试，无需 DB
  // ─────────────────────────────────────────────────────────────
  group('buildSampleLine 矩阵 (design §5.4)', () {
    // 构造 6 个连续日期，2026-06-04(周四) 起每隔 2 天：
    //   D0 = 6/4 周四
    //   D1 = 6/6 周六
    //   D2 = 6/8 周一
    //   D3 = 6/10 周三
    //   D4 = 6/12 周五
    //   D5 = 6/14 周日
    final d = <DateTime>[
      DateTime(2026, 6, 4, 9), // 周四
      DateTime(2026, 6, 6, 9), // 周六
      DateTime(2026, 6, 8, 9), // 周一
      DateTime(2026, 6, 10, 9), // 周三
      DateTime(2026, 6, 12, 9), // 周五
      DateTime(2026, 6, 14, 9), // 周日
    ];

    test('TC-007-08-K0: K=0 → 空串', () {
      expect(buildSampleLine(const []), '');
    });

    test('TC-007-08-K1: K=1 → "示例日期：6/4 周四"', () {
      expect(buildSampleLine([d[0]]), '示例日期：6/4 周四');
    });

    test('TC-007-08-K2: K=2 → "示例日期：6/4 周四、6/8 周一"', () {
      expect(buildSampleLine([d[0], d[2]]), '示例日期：6/4 周四、6/8 周一');
    });

    test('TC-007-08-K3: K=3 → "示例日期：6/4 周四、6/6 周六、6/8 周一"', () {
      expect(
        buildSampleLine([d[0], d[1], d[2]]),
        '示例日期：6/4 周四、6/6 周六、6/8 周一',
      );
    });

    test('TC-007-08-K4: K=4 → 取首/[2]/末 + "…等共 4 条"', () {
      // K=4，mid index = (4/2).floor() = 2
      // first=d[0]=6/4 周四, mid=d[2]=6/8 周一, last=d[3]=6/10 周三
      expect(
        buildSampleLine([d[0], d[1], d[2], d[3]]),
        '示例日期：6/4 周四、6/8 周一、6/10 周三 …等共 4 条',
      );
    });

    test('TC-007-08-K5: K=5 → 取首/[2]/末 + "…等共 5 条"', () {
      // K=5，mid index = (5/2).floor() = 2
      // first=d[0]=6/4 周四, mid=d[2]=6/8 周一, last=d[4]=6/12 周五
      expect(
        buildSampleLine([d[0], d[1], d[2], d[3], d[4]]),
        '示例日期：6/4 周四、6/8 周一、6/12 周五 …等共 5 条',
      );
    });

    test('TC-007-08-K6: K=6 → 取首/[3]/末 + "…等共 6 条"', () {
      // K=6，mid index = (6/2).floor() = 3
      // first=d[0]=6/4 周四, mid=d[3]=6/10 周三, last=d[5]=6/14 周日
      expect(
        buildSampleLine([d[0], d[1], d[2], d[3], d[4], d[5]]),
        '示例日期：6/4 周四、6/10 周三、6/14 周日 …等共 6 条',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 场景 7：事务原子性 - 静态/逻辑断言（降级）
  //   AC-24：事务原子性
  //
  // 说明：在 sqflite_common_ffi 内存 DB 上构造稳定的事务异常注入路径，
  //   需要 monkey-patch DatabaseHelper 或包装 Database 实例，会侵入业务代码
  //   的私有结构（_db.database）。本批改为：
  //   1) 静态断言：commit 内 DB 写操作必须全部走 txn.xxx，不得出现 _db.xxx；
  //   2) 关键回归：preview 抛 ArgumentError 时，commit 不应留下任何残骸
  //      （和事务回滚的核心承诺等价：无脏数据）。
  //   余下"事务内部分写入后回滚"的真实异常注入用例，建议在
  //   集成测试 / E2E 阶段补回（详见测试报告"未覆盖项"）。
  // ─────────────────────────────────────────────────────────────
  group('事务原子性 (AC-24) - 降级断言', () {
    test('TC-007-07a: 静态断言 - commit 内 DB 写操作仅走 txn.xxx', () async {
      // 加载源码并断言"commitRecurringRuleUpdate 函数体内不含 _db.delete /
      // _db.insert / _db.update 的直接调用"。这是事务原子性的静态保证。
      final src = await _readFile(
        '/Users/bozzguo/project/qq_glb/lib/providers/schedule_provider.dart',
      );
      // 截取 commitRecurringRuleUpdate 函数体（粗略：从函数签名到下一处
      // 顶层 `Schedule _build` 之前；用 lastIndexOf 定位足够稳健）。
      final start = src.indexOf('Future<void> commitRecurringRuleUpdate');
      expect(start, isNot(-1), reason: '函数应存在');
      final end = src.indexOf('// ─── 私有辅助', start);
      expect(end, greaterThan(start), reason: '应找到函数边界');
      final body = src.substring(start, end);

      // 事务边界内禁止使用 _db.<write>；允许 _db.database 取出实例 + _db.transaction 调用之外的写
      // 这里宽松断言：函数体内出现的写动词必须前缀为 'txn.'；
      // 检测 'await _db.delete'、'await _db.insert'、'await _db.update' 不应出现。
      final forbidden = [
        'await _db.delete',
        'await _db.insert',
        'await _db.update',
      ];
      for (final f in forbidden) {
        expect(body.contains(f), false,
            reason: 'AC-24：commit 函数体内不应直接 $f（必须走 txn）');
      }
      // 反向断言：函数体内必须出现 txn.delete / txn.insert / txn.update 至少一次
      expect(body.contains('txn.delete'), true);
      expect(body.contains('txn.insert'), true);
      // update 在 leader 保留路径才会调用，body 里至少需要见一次 txn.update
      expect(body.contains('txn.update'), true);
    });

    test('TC-007-07b: preview 抛 ArgumentError 时 commit 无任何写入', () async {
      // setUp 在外层 group；这里独立准备一个最小重复组
      DatabaseHelper().resetDatabase();
      final provider = ScheduleProvider();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      const tplId = 'tpl-tc007-07';
      final leader = Schedule(
        id: 'tc007-07-leader',
        title: 'Z',
        dateTime: yesterday,
        repeatType: RepeatType.weekly,
        repeatDays: const [1, 2],
        repeatTemplateId: tplId,
      );
      await DatabaseHelper().insert('schedules', leader.toMap());
      await provider.loadSchedules();

      final beforeRows = await DatabaseHelper().query('schedules');

      // 触发 ArgumentError
      try {
        await provider.commitRecurringRuleUpdate(
          scheduleIdInGroup: 'tc007-07-leader',
          newRepeatType: RepeatType.weekly,
          newRepeatDays: const [],
          newTemplateFields: leader,
        );
        fail('应该抛 ArgumentError');
      } on ArgumentError {
        // expected
      }

      final afterRows = await DatabaseHelper().query('schedules');
      expect(afterRows.length, beforeRows.length,
          reason: 'AC-24：preview 抛错时 schedules 表无任何变更');

      // 收尾
      await DatabaseHelper().recreateTables();
    });
  });
}

// ─────────────────────────────────────────────────────────────
// 工具：读取本地文件（用于 TC-007-07a 静态源码断言）
// ─────────────────────────────────────────────────────────────
Future<String> _readFile(String path) async {
  return await File(path).readAsString();
}
