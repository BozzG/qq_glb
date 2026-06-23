import '../models/models.dart';

/// 成长报告周期：周报 / 月报
enum ReportPeriod { week, month }

/// 单门课程在报告中的进度快照（已用 / 总课时 / 百分比）。
class CourseProgress {
  final String courseId;
  final String name;
  final double usedHours;
  final double totalHours;
  final String unitName;
  final int color;

  const CourseProgress({
    required this.courseId,
    required this.name,
    required this.usedHours,
    required this.totalHours,
    required this.unitName,
    required this.color,
  });

  /// 剩余课时（不为负）。
  double get remainingHours {
    final r = totalHours - usedHours;
    return r < 0 ? 0 : r;
  }

  /// 使用百分比，钳制到 [0,1]。
  double get usagePercent {
    if (totalHours <= 0) return 0;
    final p = usedHours / totalHours;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }
}

/// 不可变的成长报告聚合结果。
///
/// 口径说明（与 check_in_stats_screen / getCheckInStats 对齐）：
/// - 打卡归属日 = "日程自身 dateTime" 的自然日；
/// - 区间为半开 [startOfDay, endExclusive)，[start]/[end] 对外暴露为含端点的自然日。
class GrowthReportData {
  /// 区间起始日（含，00:00）。
  final DateTime start;

  /// 区间结束日（含，该日 00:00；用于展示「— 6月22日」）。
  final DateTime end;

  final ReportPeriod period;

  /// 应打卡日程数（区间内日程实例总数）。
  final int dueCount;

  /// 已打卡日程数（区间内有 check-in 的日程实例数）。
  final int checkedCount;

  /// 打卡率 = checkedCount / dueCount，dueCount==0 时为 0。
  final double checkInRate;

  /// 区间内打卡总次数（按归属日落在区间内的 check-in 计）。
  final int totalCheckIns;

  /// 活跃天数（区间内至少有一次打卡的不同自然日数）。
  final int activeDays;

  /// 连续打卡天数（区间内打卡自然日的最长连续段长度）。
  final int streakDays;

  /// 课程进度快照列表。
  final List<CourseProgress> courses;

  /// 日记情绪分布（按 diaryDate 落在区间内的日记，按 qianqianStatus 计数）。
  final Map<DiaryStatus, int> moodCounts;

  /// 区间内日记总数。
  final int diaryCount;

  const GrowthReportData({
    required this.start,
    required this.end,
    required this.period,
    required this.dueCount,
    required this.checkedCount,
    required this.checkInRate,
    required this.totalCheckIns,
    required this.activeDays,
    required this.streakDays,
    required this.courses,
    required this.moodCounts,
    required this.diaryCount,
  });

  bool get isEmpty =>
      dueCount == 0 && totalCheckIns == 0 && diaryCount == 0 && courses.isEmpty;
}

/// 成长报告聚合层 —— 纯函数，无 BuildContext / I/O 依赖，便于单测。
class GrowthReportService {
  GrowthReportService._();

  /// 计算 [anchor] 所在 [period] 区间的报告数据。
  ///
  /// - week：以周一为起点，周日为终点；
  /// - month：自然月，1 号到月末。
  static GrowthReportData build({
    required List<Schedule> schedules,
    required List<CheckIn> checkIns,
    required List<Course> courses,
    required List<Diary> diaries,
    required DateTime anchor,
    required ReportPeriod period,
  }) {
    final range = rangeOf(anchor, period);
    final startOfDay = range.$1;
    final endInclusiveDay = range.$2; // 含端点日 00:00
    final endExclusive = endInclusiveDay.add(const Duration(days: 1));

    // 日程归属日索引
    final scheduleById = {for (final s in schedules) s.id: s};
    DateTime ownDateOf(CheckIn c) =>
        scheduleById[c.scheduleId]?.dateTime ?? c.checkInTime;

    bool inRange(DateTime d) =>
        !d.isBefore(startOfDay) && d.isBefore(endExclusive);

    // 区间内日程实例
    final dueSchedules =
        schedules.where((s) => inRange(s.dateTime)).toList();
    final dueCount = dueSchedules.length;

    // 哪些日程有打卡
    final checkedScheduleIds = <String>{};
    for (final c in checkIns) {
      checkedScheduleIds.add(c.scheduleId);
    }
    final checkedCount =
        dueSchedules.where((s) => checkedScheduleIds.contains(s.id)).length;
    final checkInRate = dueCount == 0 ? 0.0 : checkedCount / dueCount;

    // 区间内打卡次数 + 活跃日集合
    final checkedDayKeys = <String>{};
    var totalCheckIns = 0;
    for (final c in checkIns) {
      final d = ownDateOf(c);
      if (inRange(d)) {
        totalCheckIns += 1;
        checkedDayKeys.add(_dayKey(d));
      }
    }
    final activeDays = checkedDayKeys.length;
    final streakDays = _longestStreak(checkedDayKeys);

    // 课程进度快照
    final courseProgress = courses
        .map((c) => CourseProgress(
              courseId: c.id,
              name: c.name,
              usedHours: c.usedHours,
              totalHours: c.totalHours,
              unitName: c.unitName,
              color: c.color,
            ))
        .toList();

    // 日记情绪分布
    final moodCounts = <DiaryStatus, int>{};
    var diaryCount = 0;
    for (final d in diaries) {
      if (inRange(d.diaryDate)) {
        diaryCount += 1;
        moodCounts[d.qianqianStatus] =
            (moodCounts[d.qianqianStatus] ?? 0) + 1;
      }
    }

    return GrowthReportData(
      start: startOfDay,
      end: endInclusiveDay,
      period: period,
      dueCount: dueCount,
      checkedCount: checkedCount,
      checkInRate: checkInRate,
      totalCheckIns: totalCheckIns,
      activeDays: activeDays,
      streakDays: streakDays,
      courses: courseProgress,
      moodCounts: moodCounts,
      diaryCount: diaryCount,
    );
  }

  /// 计算 [anchor] 所在 [period] 的区间端点（均为自然日 00:00，含端点）。
  /// 返回 (startOfDay, endInclusiveDay)。
  static (DateTime, DateTime) rangeOf(DateTime anchor, ReportPeriod period) {
    final a = DateTime(anchor.year, anchor.month, anchor.day);
    if (period == ReportPeriod.week) {
      // weekday: 周一=1 … 周日=7
      final start = a.subtract(Duration(days: a.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return (start, end);
    } else {
      final start = DateTime(a.year, a.month, 1);
      final end = DateTime(a.year, a.month + 1, 0); // 下月第 0 天 = 本月末
      return (start, end);
    }
  }

  /// 向前 / 向后翻一个周期，返回新的锚点（用于区间翻阅）。
  /// [delta] 为 -1（上一期）或 +1（下一期）等整数倍。
  static DateTime shiftAnchor(
      DateTime anchor, ReportPeriod period, int delta) {
    final a = DateTime(anchor.year, anchor.month, anchor.day);
    if (period == ReportPeriod.week) {
      return a.add(Duration(days: 7 * delta));
    } else {
      return DateTime(a.year, a.month + delta, 1);
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

  /// 计算自然日集合中的最长连续段长度（按日历相邻日）。
  static int _longestStreak(Set<String> dayKeys) {
    if (dayKeys.isEmpty) return 0;
    final days = dayKeys.map((k) {
      final parts = k.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList()
      ..sort();

    var longest = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        current += 1;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return longest;
  }
}
