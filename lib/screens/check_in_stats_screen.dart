import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class CheckInStatsScreen extends StatefulWidget {
  const CheckInStatsScreen({super.key});

  @override
  State<CheckInStatsScreen> createState() => _CheckInStatsScreenState();
}

class _CheckInStatsScreenState extends State<CheckInStatsScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 30)),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('打卡统计', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (ctx, provider, _) {
          final stats = provider.getCheckInStats(
            start: _dateRange.start,
            end: _dateRange.end,
          );
          final dailyCounts = stats['dailyCounts'] as Map<String, int>;
          final totalCount = stats['totalCount'] as int;
          final maxDaily = dailyCounts.values
              .fold(0, (a, b) => a > b ? a : b)
              .toDouble()
              .clamp(1.0, double.infinity);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日期选择器
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: AppColors.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${_formatDate(_dateRange.start)} ~ ${_formatDate(_dateRange.end)}",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickDateRange,
                          icon: Icon(Icons.calendar_month, size: 18),
                          label: Text('选择', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),

                // 统计概览卡片
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.check_circle_outline,
                        label: '总打卡次数',
                        value: '$totalCount',
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        icon: Icons.today,
                        label: '活跃天数',
                        value: '${stats['uniqueDays']}',
                        color: AppColors.info,
                      ),
                    ),
                    if (totalCount > 0) ...[
                      SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          icon: Icons.trending_up,
                          label: '日均打卡',
                          value:
                              (totalCount /
                                      ((stats['uniqueDays'] == 0
                                          ? 1
                                          : stats['uniqueDays'])))
                                  .toStringAsFixed(1),
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),

                // 柱状图（简化版）
                SizedBox(height: 20),
                Text(
                  '每日打卡趋势',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...dailyCounts.entries.map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  entry.key.substring(5),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (entry.value.toDouble() / maxDaily)
                                        .clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: AppColors.primaryLight
                                        .withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.cartoonPalette[dailyCounts.keys
                                              .toList()
                                              .indexOf(entry.key) %
                                          AppColors.cartoonPalette.length],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${entry.value}次',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (dailyCounts.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              '暂无数据',
                              style: TextStyle(color: AppColors.textHint),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 详细数据列表
                SizedBox(height: 22),
                Text(
                  '详细记录',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                ...provider.checkIns
                    .where(
                      (c) =>
                          c.checkInTime.isAfter(
                            _dateRange.start.subtract(Duration(days: 1)),
                          ) &&
                          c.checkInTime.isBefore(
                            _dateRange.end.add(Duration(days: 1)),
                          ),
                    )
                    .map((ci) {
                      final sched = provider.schedules.firstWhere(
                        (s) => s.id == ci.scheduleId,
                        orElse: () => Schedule(
                          id: '',
                          title: '已删除的日程',
                          dateTime: ci.checkInTime,
                        ),
                      );
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: sched.color.withValues(alpha: 0.12),
                          child: Text(
                            sched.typeIcon,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        title: Text(
                          sched.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          ci.notes ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(ci.checkInTime),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sched.color,
                              ),
                            ),
                            Text(
                              DateFormat('MM/dd').format(ci.checkInTime),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                if (!provider.checkIns.any(
                  (c) =>
                      c.checkInTime.isAfter(
                        _dateRange.start.subtract(Duration(days: 1)),
                      ) &&
                      c.checkInTime.isBefore(
                        _dateRange.end.add(Duration(days: 1)),
                      ),
                ))
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 56,
                            color: AppColors.textHint,
                          ),
                          Text(
                            '暂无打卡数据',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) => DateFormat('MM/dd').format(d);

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    if (range != null) setState(() => _dateRange = range);
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
