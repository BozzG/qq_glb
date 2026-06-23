import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';
import 'growth_report_screen.dart';

class CheckInStatsScreen extends StatefulWidget {
  const CheckInStatsScreen({super.key});

  @override
  State<CheckInStatsScreen> createState() => _CheckInStatsScreenState();
}

class _CheckInStatsScreenState extends State<CheckInStatsScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElegantScaffold(
      body: Column(
        children: [
          ElegantNavBar(
            title: '打卡统计',
            actions: [
              ElegantCircleIconButton(
                icon: Icons.insights_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GrowthReportScreen(),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Consumer<ScheduleProvider>(
              builder: (ctx, provider, _) {
                final stats = provider.getCheckInStats(
                  start: _dateRange.start,
                  end: _dateRange.end,
                );
                final dailyCounts = stats['dailyCounts'] as Map<String, int>;
                final totalCount = stats['totalCount'] as int;
                final uniqueDays = stats['uniqueDays'] as int;
                final maxDaily = dailyCounts.values
                    .fold(0, (a, b) => a > b ? a : b)
                    .toDouble()
                    .clamp(1.0, double.infinity);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRangeCard(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElegantStatTile(
                              icon: Icons.check_circle_outline,
                              value: '$totalCount',
                              label: '总打卡',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElegantStatTile(
                              icon: Icons.today_outlined,
                              value: '$uniqueDays',
                              label: '活跃天数',
                              accent: AppElegant.sage,
                            ),
                          ),
                          if (totalCount > 0) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElegantStatTile(
                                icon: Icons.trending_up_rounded,
                                value: (totalCount /
                                        (uniqueDays == 0 ? 1 : uniqueDays))
                                    .toStringAsFixed(1),
                                label: '日均',
                                accent: AppElegant.sand,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionHeader('每日趋势', 'DAILY'),
                      const SizedBox(height: 12),
                      _buildDailyChart(dailyCounts, maxDaily),
                      const SizedBox(height: 20),
                      _sectionHeader('详细记录', 'RECORDS'),
                      const SizedBox(height: 12),
                      ..._buildRecordList(provider),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String zh, String en) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          zh,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppElegant.ink,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            en,
            style: const TextStyle(
              fontSize: 9,
              color: AppElegant.inkFaint,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeCard() {
    return ElegantCard(
      onTap: _pickDateRange,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.date_range_outlined,
              size: 18, color: AppElegant.inkSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '统计区间',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppElegant.inkSoft,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('M月d日').format(_dateRange.start)} — ${DateFormat('M月d日').format(_dateRange.end)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppElegant.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 16, color: AppElegant.inkWhisper),
        ],
      ),
    );
  }

  Widget _buildDailyChart(Map<String, int> dailyCounts, double maxDaily) {
    if (dailyCounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppElegant.bgAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text('暂无数据',
              style: TextStyle(
                  fontSize: 12, color: AppElegant.inkFaint)),
        ),
      );
    }
    return ElegantCard(
      child: Column(
        children: dailyCounts.entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        child: Text(
                          entry.key.substring(5),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppElegant.inkSoft,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (entry.value / maxDaily).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppElegant.hairSoft,
                            valueColor: const AlwaysStoppedAnimation(
                                AppElegant.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${entry.value}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppElegant.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  List<Widget> _buildRecordList(ScheduleProvider provider) {
    // 半开区间 [startOfDay, endExclusive)，按"日程本身的日期"精确过滤
    final startOfDay =
        DateTime(_dateRange.start.year, _dateRange.start.month, _dateRange.start.day);
    final endExclusive =
        DateTime(_dateRange.end.year, _dateRange.end.month, _dateRange.end.day)
            .add(const Duration(days: 1));
    final scheduleById = {for (final s in provider.schedules) s.id: s};

    // 取打卡归属日期：优先日程 dateTime，fallback 到 checkInTime
    DateTime ownDateOf(CheckIn c) =>
        scheduleById[c.scheduleId]?.dateTime ?? c.checkInTime;

    final filtered = provider.checkIns.where((c) {
      final d = ownDateOf(c);
      return !d.isBefore(startOfDay) && d.isBefore(endExclusive);
    }).toList()
      // 按归属日期倒序，同一天内按打卡时间倒序
      ..sort((a, b) {
        final da = ownDateOf(a);
        final db = ownDateOf(b);
        final cmp = db.compareTo(da);
        if (cmp != 0) return cmp;
        return b.checkInTime.compareTo(a.checkInTime);
      });

    if (filtered.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: AppElegant.bgAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text('暂无打卡记录',
                style: TextStyle(
                    fontSize: 12, color: AppElegant.inkFaint)),
          ),
        ),
      ];
    }

    return filtered.map((ci) {
      final sched = scheduleById[ci.scheduleId] ??
          Schedule(
            id: '',
            title: '已删除的日程',
            dateTime: ci.checkInTime,
          );
      final ownDate = ownDateOf(ci);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppElegant.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppElegant.hair, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 26,
                decoration: BoxDecoration(
                  color: sched.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sched.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppElegant.ink,
                      ),
                    ),
                    if (ci.notes != null && ci.notes!.isNotEmpty)
                      Text(
                        ci.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.meta,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('M月d日').format(ownDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppElegant.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '打卡于 ${DateFormat('M/d HH:mm').format(ci.checkInTime)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppElegant.inkFaint,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.selectionClick();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    if (range != null) setState(() => _dateRange = range);
  }
}
