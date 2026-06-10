import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/schedule_provider.dart';
import '../providers/medical_provider.dart';
import '../providers/course_provider.dart';
import '../providers/diary_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';

class TodayOverviewScreen extends StatelessWidget {
  final DateTime? currentDate;
  const TodayOverviewScreen({super.key, this.currentDate});

  @override
  Widget build(BuildContext context) {
    final now = currentDate ?? DateTime.now();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final medicalProvider = context.watch<MedicalProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final diaryProvider = context.watch<DiaryProvider>();

    final todaySchedules = scheduleProvider.getSchedulesForDay(now);
    final todayCheckInCount = todaySchedules
        .where((s) => scheduleProvider.isCheckedIn(s.id))
        .length;
    final todayMedicals = medicalProvider.records
        .where((r) =>
            r.visitDate.year == now.year &&
            r.visitDate.month == now.month &&
            r.visitDate.day == now.day)
        .toList();
    final monthDiaries = diaryProvider.getDiariesByMonth(DateTime.now());
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
    final weekStats = scheduleProvider.getCheckInStats(
      start: weekStart,
      end: weekEnd,
    );
    double totalHours = 0;
    double usedHours = 0;
    for (final c in courseProvider.courses) {
      totalHours += c.totalHours;
      usedHours += c.usedHours;
    }

    return ElegantScaffold(
      body: Column(
        children: [
          ElegantNavBar(title: '今日概览'),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildDateHero(now),
                      const SizedBox(height: 24),
                      // 2x2 stat grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.55,
                        children: [
                          ElegantStatTile(
                            icon: Icons.event_available_outlined,
                            value: '${todaySchedules.length}',
                            label: '今日日程 · $todayCheckInCount 已打卡',
                          ),
                          ElegantStatTile(
                            icon: Icons.medical_services_outlined,
                            value: '${todayMedicals.length}',
                            label:
                                todayMedicals.isEmpty ? '今日医疗 · 无' : '今日医疗',
                            accent: AppElegant.rose,
                          ),
                          ElegantStatTile(
                            icon: Icons.auto_stories_outlined,
                            value: '${monthDiaries.length}',
                            label: '本月日记',
                            accent: AppElegant.plum,
                          ),
                          ElegantStatTile(
                            icon: Icons.menu_book_outlined,
                            value: usedHours.toStringAsFixed(1),
                            label:
                                '已用课时 / 共 ${totalHours.toStringAsFixed(1)}',
                            accent: AppElegant.sage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // 今日日程
                      _sectionHeader('今日日程', 'TODAY'),
                      const SizedBox(height: 12),
                      if (todaySchedules.isEmpty)
                        _miniEmpty('今日无安排')
                      else
                        ...todaySchedules.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ScheduleLine(
                                schedule: s,
                                isChecked:
                                    scheduleProvider.isCheckedIn(s.id),
                              ),
                            )),
                      const SizedBox(height: 28),
                      // 本周打卡
                      _sectionHeader('本周打卡', 'WEEK'),
                      const SizedBox(height: 12),
                      _buildWeekStats(weekStats, now),
                      const SizedBox(height: 28),
                      // 健康管理
                      _sectionHeader('健康管理', 'HEALTH'),
                      const SizedBox(height: 12),
                      if (medicalProvider.records.isEmpty)
                        _miniEmpty('暂无医疗记录')
                      else
                        ...medicalProvider.records.take(3).map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _MedicalLine(record: r),
                            )),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHero(DateTime date) {
    return ElegantCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE', 'zh_CN').format(date).toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: AppElegant.inkSoft,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: AppElegant.ink,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy').format(date),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppElegant.inkSoft,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMMM', 'zh_CN').format(date),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppElegant.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1, width: 40, color: AppElegant.accent),
          const SizedBox(height: 10),
          const Text(
            '记录成长的一天',
            style: TextStyle(
              fontSize: 13,
              color: AppElegant.inkSoft,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStats(Map<String, dynamic> stats, DateTime now) {
    final total = stats['totalCount'] as int;
    final unique = stats['uniqueDays'] as int;
    final progress = now.weekday == 0 ? 0.0 : unique / now.weekday;
    return ElegantCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniStat('$total', '总打卡'),
              ),
              Container(
                width: 0.5,
                height: 36,
                color: AppElegant.hair,
              ),
              Expanded(child: _miniStat('$unique', '活跃天数')),
              Container(
                width: 0.5,
                height: 36,
                color: AppElegant.hair,
              ),
              Expanded(
                child: _miniStat('${now.weekday}', '本周已过'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppElegant.hairSoft,
              valueColor: const AlwaysStoppedAnimation(AppElegant.accent),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '完成率 ${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 11,
                color: AppElegant.inkSoft,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppElegant.ink,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppText.meta),
      ],
    );
  }

  Widget _sectionHeader(String zh, String en) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          zh,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppElegant.ink,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            en,
            style: const TextStyle(
              fontSize: 10,
              color: AppElegant.inkFaint,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniEmpty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppElegant.bgAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppElegant.inkFaint,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _ScheduleLine extends StatelessWidget {
  final Schedule schedule;
  final bool isChecked;

  const _ScheduleLine({required this.schedule, required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppElegant.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppElegant.hair, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: schedule.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              DateFormat('HH:mm').format(schedule.dateTime),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppElegant.ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppElegant.ink,
                  ),
                ),
                if (schedule.location != null && schedule.location!.isNotEmpty)
                  Text(
                    schedule.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta,
                  ),
              ],
            ),
          ),
          Icon(
            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isChecked ? AppElegant.accent : AppElegant.inkWhisper,
          ),
        ],
      ),
    );
  }
}

class _MedicalLine extends StatelessWidget {
  final MedicalRecord record;
  const _MedicalLine({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppElegant.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppElegant.hair, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppElegant.rose.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_outlined,
                size: 14, color: AppElegant.rose),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.diagnosis.isNotEmpty
                      ? record.diagnosis
                      : (record.hospitalName.isNotEmpty
                          ? record.hospitalName
                          : '医疗记录'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppElegant.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.hospitalName.isNotEmpty ? '${record.hospitalName} · ' : ''}${DateFormat('M月d日', 'zh_CN').format(record.visitDate)}',
                  style: AppText.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
