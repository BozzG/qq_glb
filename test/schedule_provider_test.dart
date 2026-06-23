import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:qianqian_growth_logbook/models/models.dart';
import 'package:qianqian_growth_logbook/providers/schedule_provider.dart';
import 'package:qianqian_growth_logbook/services/database_helper.dart';
import 'package:qianqian_growth_logbook/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  // 初始化内存数据库用于测试
  setUpAll(() async {
    // 初始化 Flutter 绑定（需要用于 NotificationService）
    TestWidgetsFlutterBinding.ensureInitialized();
    
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    // 启用测试模式，使用内存数据库
    DatabaseHelper.isTestMode = true;
    // 启用通知服务测试模式（跳过实际通知调度）
    NotificationService().isTestMode = true;
    // 初始化时区（NotificationService 需要）
    tzdata.initializeTimeZones();
    
    // 初始化 NotificationService（测试模式下不会实际初始化插件）
    await NotificationService().init();
  });

  group('ScheduleProvider Tests', () {
    late ScheduleProvider provider;

    setUp(() async {
      // 重置数据库实例，确保使用内存数据库
      DatabaseHelper().resetDatabase();
      provider = ScheduleProvider();
      await provider.loadSchedules();
    });

    tearDown(() async {
      // 清理并重新创建表
      await DatabaseHelper().recreateTables();
    });

    test('TC-010: 初始状态', () {
      expect(provider.schedules, isEmpty);
      expect(provider.checkIns, isEmpty);
      expect(provider.isLoading, false);
    });

    test('TC-011: 添加单次日程', () async {
      final schedule = Schedule(
        id: 'test-schedule-1',
        title: '测试日程',
        dateTime: DateTime(2026, 4, 24, 10, 0),
        repeatType: RepeatType.none,
      );

      await provider.addSchedule(schedule);
      
      // 重新加载以从数据库获取
      await provider.loadSchedules();
      
      expect(provider.schedules.length, 1);
      expect(provider.schedules.first.id, 'test-schedule-1');
      expect(provider.schedules.first.title, '测试日程');
    });

    test('TC-012: 添加每日重复日程', () async {
      final schedule = Schedule(
        id: 'test-recurring-1',
        title: '每日课程',
        dateTime: DateTime(2026, 4, 24, 10, 0),
        repeatType: RepeatType.daily,
      );

      await provider.addSchedule(schedule);
      await provider.loadSchedules();

      // 应该创建多个实例（从今天到下个月末）
      expect(provider.schedules.length, greaterThan(1));
      
      // 检查是否包含原始日程
      final hasOriginal = provider.schedules.any((s) => s.id == 'test-recurring-1');
      expect(hasOriginal, true);
    });

    test('TC-013: 删除单个日程', () async {
      final schedule = Schedule(
        id: 'test-delete-1',
        title: '待删除日程',
        dateTime: DateTime(2026, 4, 24, 10, 0),
      );

      await provider.addSchedule(schedule);
      await provider.loadSchedules();
      expect(provider.schedules.length, 1);

      await provider.deleteSchedule('test-delete-1');
      await provider.loadSchedules();
      expect(provider.schedules.length, 0);
    });

    test('TC-015: 打卡功能', () async {
      final schedule = Schedule(
        id: 'test-checkin-1',
        title: '打卡测试',
        dateTime: DateTime.now(), // 使用当前时间，确保可以打卡
        isCourse: false,
      );

      await provider.addSchedule(schedule);
      await provider.loadSchedules();

      final result = await provider.checkIn('test-checkin-1');
      
      expect(result, true);
      expect(provider.isCheckedIn('test-checkin-1'), true);
    });

    test('TC-016: 重复打卡检测', () async {
      final schedule = Schedule(
        id: 'test-double-checkin',
        title: '重复打卡测试',
        dateTime: DateTime.now(),
        isCourse: false,
      );

      await provider.addSchedule(schedule);
      await provider.loadSchedules();

      // 第一次打卡
      final result1 = await provider.checkIn('test-double-checkin');
      expect(result1, true);

      // 第二次打卡应该失败
      final result2 = await provider.checkIn('test-double-checkin');
      expect(result2, false);
    });

    test('TC-017: 获取某天日程', () async {
      final day1 = DateTime(2026, 4, 25);
      final day2 = DateTime(2026, 4, 26);

      final schedule1 = Schedule(
        id: 's1',
        title: '日程1',
        dateTime: DateTime(2026, 4, 25, 10, 0),
      );

      final schedule2 = Schedule(
        id: 's2',
        title: '日程2',
        dateTime: DateTime(2026, 4, 26, 10, 0),
      );

      await provider.addSchedule(schedule1);
      await provider.addSchedule(schedule2);
      await provider.loadSchedules();

      final day1Schedules = provider.getSchedulesForDay(day1);
      final day2Schedules = provider.getSchedulesForDay(day2);

      expect(day1Schedules.length, 1);
      expect(day1Schedules.first.id, 's1');
      expect(day2Schedules.length, 1);
      expect(day2Schedules.first.id, 's2');
    });
  });

  // ===========================================================================
  // 打卡状态判定修复 (Task #004)
  // 关联：
  //   PRD  docs/prd/checkin-status-fix.md           (AC-01 ~ AC-06)
  //   UI   docs/design/checkin-status-fix-ui-checklist.md (VC-06 / IC-04)
  //   G3   docs/review/checkin-status-fix-review.md (G3 → G4 接力清单 1~6)
  // 作者：qa-agent
  // 说明：本组用例覆盖 isCheckedIn 语义重定为"按日程实例"后的核心断言，
  //       不引入新 test 文件，沿用 schedule_provider_test.dart 已有基础设施。
  // ===========================================================================
  group('打卡状态判定修复 (Task #004)', () {
    late ScheduleProvider provider;

    setUp(() async {
      DatabaseHelper().resetDatabase();
      provider = ScheduleProvider();
      await provider.loadSchedules();
    });

    tearDown(() async {
      await DatabaseHelper().recreateTables();
    });

    test('TC-004-01: isCheckedIn 直测 - 历史日已打卡 / 未打卡两态返回正确 (AC-01)',
        () async {
      // 构造一条"昨日"日程（早于今天），写入并直接落一条 check_in，
      // 模拟"用户昨天打过卡，今天回看"的核心修复场景。
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final checked = Schedule(
        id: 'tc-004-01-checked',
        title: '昨日已打卡',
        dateTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 7, 0),
        repeatType: RepeatType.none,
      );
      final unchecked = Schedule(
        id: 'tc-004-01-unchecked',
        title: '昨日未打卡',
        dateTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 0),
        repeatType: RepeatType.none,
      );

      await provider.addSchedule(checked);
      await provider.addSchedule(unchecked);
      // 直接通过 provider 接口写打卡记录，保证走 checkIn() 主路径
      final ok = await provider.checkIn('tc-004-01-checked');
      expect(ok, true, reason: '首次打卡应成功（AC-04 正向路径）');

      // 核心断言：判定不依赖"今天"
      expect(provider.isCheckedIn('tc-004-01-checked'), true,
          reason: 'AC-01：历史日已打卡实例必须返回 true');
      expect(provider.isCheckedIn('tc-004-01-unchecked'), false,
          reason: 'AC-01：历史日未打卡实例必须返回 false');
    });

    test('TC-004-02: isCheckedIn 跨日独立 - 历史日已打卡返回 true、未打卡返回 false (AC-06)',
        () async {
      // 构造"今日"与"昨日"两条独立日程，仅对昨日打卡，
      // isCheckedIn 必须按实例判定（与自然日无关）。
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final scheduleToday = Schedule(
        id: 'tc-004-02-today',
        title: '今日',
        dateTime: today,
      );
      final scheduleYesterday = Schedule(
        id: 'tc-004-02-yesterday',
        title: '昨日',
        dateTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 8, 0),
      );

      await provider.addSchedule(scheduleToday);
      await provider.addSchedule(scheduleYesterday);
      await provider.checkIn('tc-004-02-yesterday'); // 只对昨日打卡

      // 关键断言：isCheckedIn 在历史日已打卡场景必须返回 true
      expect(provider.isCheckedIn('tc-004-02-yesterday'), true,
          reason: 'AC-06：历史日已打卡实例必须返回 true');
      expect(provider.isCheckedIn('tc-004-02-today'), false,
          reason: 'AC-06：未打卡实例必须返回 false');
    });

    test('TC-004-03: 重复打卡幂等 - 第二次 checkIn 返回 false 且仅落 1 条记录 (AC-02)',
        () async {
      final schedule = Schedule(
        id: 'tc-004-03-dup',
        title: '幂等校验',
        dateTime: DateTime.now(),
      );
      await provider.addSchedule(schedule);

      final first = await provider.checkIn('tc-004-03-dup');
      final second = await provider.checkIn('tc-004-03-dup');

      expect(first, true, reason: '首次打卡应成功');
      expect(second, false, reason: 'AC-02：同实例第二次必须返回 false');

      // 直查 check_ins 表，确保物理只有一条记录
      final rows = await DatabaseHelper().query(
        'check_ins',
        where: 'scheduleId = ?',
        whereArgs: ['tc-004-03-dup'],
      );
      expect(rows.length, 1,
          reason: 'AC-02：check_ins 表只允许保留 1 条记录');
      expect(provider.isCheckedIn('tc-004-03-dup'), true);
    });

    test(
        'TC-004-04: 课程类日程扣课时幂等 - 重复打卡 course_consumptions 仅 1 条 / usedHours 仅 +1 (AC-05)',
        () async {
      // 先在 courses 表落一条课程
      final course = Course(
        id: 'tc-004-04-course',
        name: 'QA 课程',
        courseType: CourseType.sports,
        totalHours: 10.0,
        usedHours: 0.0,
      );
      await DatabaseHelper().insert('courses', course.toMap());

      final schedule = Schedule(
        id: 'tc-004-04-course-schedule',
        title: '课程打卡',
        dateTime: DateTime.now(),
        isCourse: true,
        courseId: 'tc-004-04-course',
      );
      await provider.addSchedule(schedule);

      // 连续两次打卡同一实例
      final r1 = await provider.checkIn('tc-004-04-course-schedule');
      final r2 = await provider.checkIn('tc-004-04-course-schedule');
      expect(r1, true);
      expect(r2, false, reason: '第二次打卡必须被 alreadyChecked 拦截');

      // 课时消耗记录幂等
      final consumptions = await DatabaseHelper().query(
        'course_consumptions',
        where: 'courseId = ?',
        whereArgs: ['tc-004-04-course'],
      );
      expect(consumptions.length, 1,
          reason: 'AC-05：course_consumptions 表只能新增 1 条');
      expect(consumptions.first['relatedCheckInId'], isNotNull);

      // courses.usedHours 仅 +1.0
      final courseRows = await DatabaseHelper().query(
        'courses',
        where: 'id = ?',
        whereArgs: ['tc-004-04-course'],
      );
      final updated = Course.fromMap(courseRows.first);
      expect(updated.usedHours, closeTo(1.0, 0.0001),
          reason: 'AC-05：usedHours 仅 +1.0，不允许重复扣减');
      expect(updated.remainingHours, closeTo(9.0, 0.0001));
    });

    test(
        'TC-004-05: 重复日程跨天独立 - 对 D1 打卡不影响 D2 的 isCheckedIn (AC-03 / VC-06)',
        () async {
      // 直接构造两个同 repeatTemplateId、不同日期的实例落库，
      // 避免依赖 _createRecurringInstances 当月扩展窗口（更稳定可控）。
      const templateId = 'tc-004-05-template';
      final today = DateTime.now();
      final d1 = DateTime(today.year, today.month, today.day, 8, 0)
          .subtract(const Duration(days: 2));
      final d2 = d1.add(const Duration(days: 1));

      final instanceD1 = Schedule(
        id: 'tc-004-05-d1',
        title: '每日英语',
        dateTime: d1,
        repeatType: RepeatType.daily,
        repeatTemplateId: templateId,
      );
      final instanceD2 = Schedule(
        id: 'tc-004-05-d2',
        title: '每日英语',
        dateTime: d2,
        repeatType: RepeatType.daily,
        repeatTemplateId: templateId,
        parentId: 'tc-004-05-d1',
      );

      await DatabaseHelper().insert('schedules', instanceD1.toMap());
      await DatabaseHelper().insert('schedules', instanceD2.toMap());
      await provider.loadSchedules();

      // 仅对 D1 打卡
      final ok = await provider.checkIn('tc-004-05-d1');
      expect(ok, true);

      // 跨天独立断言
      expect(provider.isCheckedIn('tc-004-05-d1'), true,
          reason: 'AC-03：D1 实例已打卡');
      expect(provider.isCheckedIn('tc-004-05-d2'), false,
          reason: 'AC-03 / VC-06：同 repeatTemplateId 的 D2 实例必须仍为未打卡');

      // D2 应当能独立完成自己的打卡，且不影响 D1
      final okD2 = await provider.checkIn('tc-004-05-d2');
      expect(okD2, true, reason: 'D2 应可独立打卡');
      expect(provider.isCheckedIn('tc-004-05-d1'), true);
      expect(provider.isCheckedIn('tc-004-05-d2'), true);

      // 物理校验：两条 check_ins，各归属一个实例
      final allRows = await DatabaseHelper().query(
        'check_ins',
        orderBy: 'checkInTime ASC',
      );
      final scheduleIds = allRows.map((r) => r['scheduleId']).toSet();
      expect(scheduleIds, containsAll(['tc-004-05-d1', 'tc-004-05-d2']));
      expect(allRows.length, 2);
    });

    test(
        'TC-004-06: IC-04 课程类首次打卡 UI 数据态变化 - usedHours 通过 provider 数据态可观察',
        () async {
      // 注：IC-04 为 UI 清单动态项；按 Task #004 派单：
      //   "至少为 IC-04 写一条 widget test 或在 schedule_provider_test 内
      //    通过 provider 数据态验证"。
      // 这里选择 provider 数据态验证 —— 课程类日程首次打卡后，
      // 直查 courses 表的 usedHours 必须从 0 -> 1，
      // 等价于课时屏 UI 上"已用课时"+1 的视觉变化。
      final course = Course(
        id: 'tc-004-06-course',
        name: 'IC-04 课程',
        courseType: CourseType.language,
        totalHours: 5.0,
        usedHours: 0.0,
      );
      await DatabaseHelper().insert('courses', course.toMap());

      final schedule = Schedule(
        id: 'tc-004-06-schedule',
        title: '英语 1v1',
        dateTime: DateTime.now(),
        isCourse: true,
        courseId: 'tc-004-06-course',
      );
      await provider.addSchedule(schedule);

      // 打卡前
      var rows = await DatabaseHelper().query('courses',
          where: 'id = ?', whereArgs: ['tc-004-06-course']);
      expect(Course.fromMap(rows.first).usedHours, 0.0);

      // 打卡后
      final ok = await provider.checkIn('tc-004-06-schedule');
      expect(ok, true);
      rows = await DatabaseHelper().query('courses',
          where: 'id = ?', whereArgs: ['tc-004-06-course']);
      final after = Course.fromMap(rows.first);
      expect(after.usedHours, closeTo(1.0, 0.0001),
          reason: 'IC-04：首次打卡后 usedHours 数据态变化等价于 UI 上 +1');

      // 二次点击不再扣减（与 TC-004-04 互补：聚焦"UI 课时数不变"）
      final dup = await provider.checkIn('tc-004-06-schedule');
      expect(dup, false);
      rows = await DatabaseHelper().query('courses',
          where: 'id = ?', whereArgs: ['tc-004-06-course']);
      expect(Course.fromMap(rows.first).usedHours, closeTo(1.0, 0.0001),
          reason: 'IC-04：二次点击 UI 课时数应保持不变');
    });
  });

  // ===========================================================================
  // v2.4 新功能：默认消耗课时数（P1-10）+ 打卡撤销（P1-1）
  // ===========================================================================
  group('v2.4 课时与打卡撤销', () {
    late ScheduleProvider provider;

    setUp(() async {
      DatabaseHelper().resetDatabase();
      provider = ScheduleProvider();
      await provider.loadSchedules();
    });

    tearDown(() async {
      await DatabaseHelper().recreateTables();
    });

    test('TC-V24-01: courseHours=3 时单次打卡按 3 扣减', () async {
      final course = Course(
        id: 'v24-course-1',
        name: '钢琴',
        totalHours: 10.0,
        usedHours: 0.0,
      );
      await DatabaseHelper().insert('courses', course.toMap());

      final schedule = Schedule(
        id: 'v24-sch-1',
        title: '钢琴课',
        dateTime: DateTime.now(),
        isCourse: true,
        courseId: 'v24-course-1',
        courseHours: 3.0,
      );
      await provider.addSchedule(schedule);

      final ok = await provider.checkIn('v24-sch-1');
      expect(ok, true);

      final rows = await DatabaseHelper()
          .query('courses', where: 'id = ?', whereArgs: ['v24-course-1']);
      expect(Course.fromMap(rows.first).usedHours, closeTo(3.0, 0.0001),
          reason: '一次打卡应扣减 courseHours=3');

      // 消耗记录金额也应为 3
      final cons = await DatabaseHelper().query('course_consumptions',
          where: 'courseId = ?', whereArgs: ['v24-course-1']);
      expect(cons.length, 1);
      expect((cons.first['consumedAmount'] as num).toDouble(),
          closeTo(3.0, 0.0001));
    });

    test('TC-V24-02: courseHours 默认 1（未设置时行为不变）', () async {
      final course = Course(
        id: 'v24-course-2',
        name: '游泳',
        totalHours: 8.0,
        usedHours: 0.0,
      );
      await DatabaseHelper().insert('courses', course.toMap());

      final schedule = Schedule(
        id: 'v24-sch-2',
        title: '游泳课',
        dateTime: DateTime.now(),
        isCourse: true,
        courseId: 'v24-course-2',
        // 不传 courseHours
      );
      expect(schedule.courseHours, 1.0, reason: '默认应为 1.0');

      await provider.addSchedule(schedule);
      await provider.checkIn('v24-sch-2');

      final rows = await DatabaseHelper()
          .query('courses', where: 'id = ?', whereArgs: ['v24-course-2']);
      expect(Course.fromMap(rows.first).usedHours, closeTo(1.0, 0.0001));
    });

    test('TC-V24-03: 撤销打卡删除记录并按实际消耗回补课时', () async {
      final course = Course(
        id: 'v24-course-3',
        name: '美术',
        totalHours: 12.0,
        usedHours: 0.0,
      );
      await DatabaseHelper().insert('courses', course.toMap());

      final schedule = Schedule(
        id: 'v24-sch-3',
        title: '美术课',
        dateTime: DateTime.now(),
        isCourse: true,
        courseId: 'v24-course-3',
        courseHours: 2.0,
      );
      await provider.addSchedule(schedule);

      await provider.checkIn('v24-sch-3');
      var rows = await DatabaseHelper()
          .query('courses', where: 'id = ?', whereArgs: ['v24-course-3']);
      expect(Course.fromMap(rows.first).usedHours, closeTo(2.0, 0.0001));

      // 撤销
      final undone = await provider.undoCheckIn('v24-sch-3');
      expect(undone, true);
      expect(provider.isCheckedIn('v24-sch-3'), false,
          reason: '撤销后应回到未打卡态');

      // 课时回补到 0
      rows = await DatabaseHelper()
          .query('courses', where: 'id = ?', whereArgs: ['v24-course-3']);
      expect(Course.fromMap(rows.first).usedHours, closeTo(0.0, 0.0001),
          reason: '应按消耗记录回补 2 课时');

      // 消耗记录被删除
      final cons = await DatabaseHelper().query('course_consumptions',
          where: 'courseId = ?', whereArgs: ['v24-course-3']);
      expect(cons, isEmpty);

      // check_ins 记录被删除
      final ci = await DatabaseHelper().query('check_ins',
          where: 'scheduleId = ?', whereArgs: ['v24-sch-3']);
      expect(ci, isEmpty);
    });

    test('TC-V24-04: 超过 24 小时不可撤销', () async {
      final schedule = Schedule(
        id: 'v24-sch-4',
        title: '普通日程',
        dateTime: DateTime.now(),
        isCourse: false,
      );
      await provider.addSchedule(schedule);

      // 手动写一条 25 小时前的打卡记录
      final old = CheckIn(
        id: 'v24-ci-old',
        scheduleId: 'v24-sch-4',
        checkInTime: DateTime.now().subtract(const Duration(hours: 25)),
      );
      await DatabaseHelper().insert('check_ins', old.toMap());
      await provider.loadSchedules();
      expect(provider.isCheckedIn('v24-sch-4'), true);

      final undone = await provider.undoCheckIn('v24-sch-4');
      expect(undone, false, reason: '超过 24h 应拒绝撤销');
      expect(provider.isCheckedIn('v24-sch-4'), true,
          reason: '记录应保留');
    });

    test('TC-V24-05: 撤销未打卡日程返回 false', () async {
      final schedule = Schedule(
        id: 'v24-sch-5',
        title: '未打卡',
        dateTime: DateTime.now(),
      );
      await provider.addSchedule(schedule);

      final undone = await provider.undoCheckIn('v24-sch-5');
      expect(undone, false);
    });
  });
}
