import 'package:flutter_test/flutter_test.dart';
import 'package:qianqian_growth_logbook/models/models.dart';
import 'package:qianqian_growth_logbook/services/growth_report_service.dart';

/// GrowthReportService 纯函数聚合层单测（P1-6 成长报告）。
/// 覆盖：打卡率 / 连续天数 / 课程进度 / 情绪分布 / 周月边界 / 空区间。
void main() {
  // 固定一个工作日锚点：2026-06-17 是周三。
  // 当周（周一起）：2026-06-15(一) ~ 2026-06-21(日)。
  final anchor = DateTime(2026, 6, 17, 9, 0);

  Schedule sched(String id, DateTime dt, {bool isCourse = false, String? courseId}) =>
      Schedule(
        id: id,
        title: id,
        dateTime: dt,
        isCourse: isCourse,
        courseId: courseId,
      );

  CheckIn ci(String id, String scheduleId, DateTime t) =>
      CheckIn(id: id, scheduleId: scheduleId, checkInTime: t);

  group('rangeOf 区间边界', () {
    test('周报：周一为起点、周日为终点', () {
      final (start, end) = GrowthReportService.rangeOf(anchor, ReportPeriod.week);
      expect(start, DateTime(2026, 6, 15));
      expect(end, DateTime(2026, 6, 21));
    });

    test('周报：锚点为周日时仍归当周', () {
      final sunday = DateTime(2026, 6, 21, 23, 0);
      final (start, end) =
          GrowthReportService.rangeOf(sunday, ReportPeriod.week);
      expect(start, DateTime(2026, 6, 15));
      expect(end, DateTime(2026, 6, 21));
    });

    test('月报：1 号到月末（6 月 30 天）', () {
      final (start, end) =
          GrowthReportService.rangeOf(anchor, ReportPeriod.month);
      expect(start, DateTime(2026, 6, 1));
      expect(end, DateTime(2026, 6, 30));
    });

    test('月报：2 月闰年边界（2024-02 → 29 天）', () {
      final feb = DateTime(2024, 2, 10);
      final (start, end) =
          GrowthReportService.rangeOf(feb, ReportPeriod.month);
      expect(start, DateTime(2024, 2, 1));
      expect(end, DateTime(2024, 2, 29));
    });
  });

  group('shiftAnchor 区间翻阅', () {
    test('周报：-1 回退 7 天', () {
      final prev = GrowthReportService.shiftAnchor(anchor, ReportPeriod.week, -1);
      expect(prev, DateTime(2026, 6, 10));
    });

    test('月报：+1 进入下月 1 号', () {
      final next =
          GrowthReportService.shiftAnchor(anchor, ReportPeriod.month, 1);
      expect(next, DateTime(2026, 7, 1));
    });

    test('月报：跨年回退（1 月 -1 → 上年 12 月）', () {
      final jan = DateTime(2026, 1, 15);
      final prev = GrowthReportService.shiftAnchor(jan, ReportPeriod.month, -1);
      expect(prev, DateTime(2025, 12, 1));
    });
  });

  group('打卡率 / 活跃天数 / 连续天数', () {
    test('打卡率 = 已打卡日程 / 区间内日程', () {
      final schedules = [
        sched('s1', DateTime(2026, 6, 15, 8)),
        sched('s2', DateTime(2026, 6, 16, 8)),
        sched('s3', DateTime(2026, 6, 17, 8)),
        sched('s4', DateTime(2026, 6, 18, 8)),
      ];
      final checkIns = [
        ci('c1', 's1', DateTime(2026, 6, 15, 8, 30)),
        ci('c2', 's2', DateTime(2026, 6, 16, 8, 30)),
      ];
      final data = GrowthReportService.build(
        schedules: schedules,
        checkIns: checkIns,
        courses: const [],
        diaries: const [],
        anchor: anchor,
        period: ReportPeriod.week,
      );
      expect(data.dueCount, 4);
      expect(data.checkedCount, 2);
      expect(data.checkInRate, closeTo(0.5, 1e-9));
      expect(data.totalCheckIns, 2);
    });

    test('连续天数：取最长连续段（15/16/17 连续 + 19 单独 → 3）', () {
      final schedules = [
        sched('s1', DateTime(2026, 6, 15, 8)),
        sched('s2', DateTime(2026, 6, 16, 8)),
        sched('s3', DateTime(2026, 6, 17, 8)),
        sched('s4', DateTime(2026, 6, 19, 8)),
      ];
      final checkIns = [
        ci('c1', 's1', DateTime(2026, 6, 15, 8, 30)),
        ci('c2', 's2', DateTime(2026, 6, 16, 8, 30)),
        ci('c3', 's3', DateTime(2026, 6, 17, 8, 30)),
        ci('c4', 's4', DateTime(2026, 6, 19, 8, 30)),
      ];
      final data = GrowthReportService.build(
        schedules: schedules,
        checkIns: checkIns,
        courses: const [],
        diaries: const [],
        anchor: anchor,
        period: ReportPeriod.week,
      );
      expect(data.activeDays, 4);
      expect(data.streakDays, 3);
    });

    test('区间外打卡不计入', () {
      final schedules = [
        sched('in', DateTime(2026, 6, 16, 8)),
        sched('out', DateTime(2026, 6, 30, 8)), // 不在当周
      ];
      final checkIns = [
        ci('c1', 'in', DateTime(2026, 6, 16, 8, 30)),
        ci('c2', 'out', DateTime(2026, 6, 30, 8, 30)),
      ];
      final data = GrowthReportService.build(
        schedules: schedules,
        checkIns: checkIns,
        courses: const [],
        diaries: const [],
        anchor: anchor,
        period: ReportPeriod.week,
      );
      expect(data.dueCount, 1);
      expect(data.checkedCount, 1);
      expect(data.totalCheckIns, 1);
    });
  });

  group('课程进度', () {
    test('快照映射 used/total/percent/remaining', () {
      final courses = [
        Course(id: 'k1', name: '钢琴', totalHours: 10, usedHours: 4),
        Course(id: 'k2', name: '游泳', totalHours: 0, usedHours: 0),
      ];
      final data = GrowthReportService.build(
        schedules: const [],
        checkIns: const [],
        courses: courses,
        diaries: const [],
        anchor: anchor,
        period: ReportPeriod.month,
      );
      expect(data.courses.length, 2);
      final piano = data.courses.firstWhere((c) => c.courseId == 'k1');
      expect(piano.usagePercent, closeTo(0.4, 1e-9));
      expect(piano.remainingHours, closeTo(6.0, 1e-9));
      // total=0 时百分比为 0，不应除零
      final swim = data.courses.firstWhere((c) => c.courseId == 'k2');
      expect(swim.usagePercent, 0);
    });
  });

  group('情绪分布', () {
    test('按 qianqianStatus 计数，仅统计区间内日记', () {
      final diaries = [
        Diary(
          id: 'd1',
          content: '',
          diaryDate: DateTime(2026, 6, 15),
          qianqianStatus: DiaryStatus.good,
        ),
        Diary(
          id: 'd2',
          content: '',
          diaryDate: DateTime(2026, 6, 16),
          qianqianStatus: DiaryStatus.good,
        ),
        Diary(
          id: 'd3',
          content: '',
          diaryDate: DateTime(2026, 6, 17),
          qianqianStatus: DiaryStatus.irritable,
        ),
        Diary(
          id: 'd4',
          content: '',
          diaryDate: DateTime(2026, 7, 1), // 区间外
          qianqianStatus: DiaryStatus.normal,
        ),
      ];
      final data = GrowthReportService.build(
        schedules: const [],
        checkIns: const [],
        courses: const [],
        diaries: diaries,
        anchor: anchor,
        period: ReportPeriod.week,
      );
      expect(data.diaryCount, 3);
      expect(data.moodCounts[DiaryStatus.good], 2);
      expect(data.moodCounts[DiaryStatus.irritable], 1);
      expect(data.moodCounts[DiaryStatus.normal], isNull);
    });
  });

  group('空区间', () {
    test('无任何数据 → isEmpty 且各项为 0', () {
      final data = GrowthReportService.build(
        schedules: const [],
        checkIns: const [],
        courses: const [],
        diaries: const [],
        anchor: anchor,
        period: ReportPeriod.week,
      );
      expect(data.isEmpty, true);
      expect(data.dueCount, 0);
      expect(data.checkedCount, 0);
      expect(data.checkInRate, 0);
      expect(data.activeDays, 0);
      expect(data.streakDays, 0);
      expect(data.diaryCount, 0);
    });
  });
}
