import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/schedule_provider.dart';
import '../providers/medical_provider.dart';
import '../providers/memo_provider.dart';
import '../providers/course_provider.dart';
import '../utils/app_theme.dart';

class TodayOverviewScreen extends StatelessWidget {
  const TodayOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final medicalProvider = context.watch<MedicalProvider>();
    final memoProvider = context.watch<MemoProvider>();
    final courseProvider = context.watch<CourseProvider>();

    // ===== 今日数据计算 =====
    final todaySchedules = scheduleProvider.getSchedulesForDay(now);
    final todayCheckInCount = todaySchedules.where((s) => scheduleProvider.isCheckedToday(s.id)).length;
    // 今日医疗记录（按 visitDate 匹配）
    final todayMedicals = medicalProvider.records.where((r) =>
        r.visitDate.year == now.year && r.visitDate.month == now.month && r.visitDate.day == now.day
    ).toList();
    // 未完成备忘
    final pendingMemos = memoProvider.memos.where((m) => !m.isCompleted).toList();
    // 本周打卡统计
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6, hours: 23, minutes: 59));
    final weekStats = scheduleProvider.getCheckInStats(start: weekStart, end: weekEnd);
    // 课程总课时
    double totalHours = 0;
    double usedHours = 0;
    for (final c in courseProvider.courses) {
      totalHours += c.totalHours;
      usedHours += c.usedHours;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('今日概览', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 日期头部卡片 =====
            _DateHeader(date: now),

            SizedBox(height: 20),

            // ===== 统计概览行 =====
            Row(
              children: [
                Expanded(child: _StatCard(
                  icon: Icons.event_available,
                  label: '今日日程',
                  value: '${todaySchedules.length}',
                  subText: '$todayCheckInCount 已打卡',
                  color: AppColors.primary,
                  onTap: () => Navigator.pop(context),
                )),
                SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.local_hospital,
                  label: '今日医疗',
                  value: '${todayMedicals.length}',
                  subText: todayMedicals.isEmpty ? '无记录' : todayMedicals.first.hospitalName,
                  color: AppColors.scheduleMedical,
                )),
              ],
            ),

            SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _StatCard(
                  icon: Icons.fact_check,
                  label: '待办备忘',
                  value: '${pendingMemos.length}',
                  subText: pendingMemos.isEmpty ? '全部完成' : pendingMemos.first.title ?? '备忘',
                  color: AppColors.info,
                )),
                SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.school,
                  label: '课程课时',
                  value: usedHours.toStringAsFixed(1),
                  subText: '共 ${totalHours.toStringAsFixed(1)} 课时',
                  color: AppColors.scheduleSchool,
                )),
              ],
            ),

            SizedBox(height: 24),

            // ===== 今日日程详情 =====
            _SectionTitle(title: '📅 今日日程', icon: Icons.today),
            SizedBox(height: 10),
            if (todaySchedules.isEmpty)
              _EmptyHint(text: '今天没有安排日程哦~', icon: Icons.event_busy)
            else
              ...todaySchedules.map((s) {
                final checked = scheduleProvider.isCheckedToday(s.id);
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _ScheduleItem(schedule: s, isChecked: checked),
                );
              }),

            SizedBox(height: 24),

            // ===== 本周打卡统计 =====
            _SectionTitle(title: '✅ 本周打卡', icon: Icons.check_circle),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WeekStatItem(label: '总打卡', value: '${weekStats['totalCount']}', color: AppColors.success),
                      _WeekStatItem(label: '有记录天数', value: '${weekStats['uniqueDays']}', color: AppColors.primary),
                      Container(width: 1, height: 36, color: Colors.grey.shade300),
                      _WeekStatItem(label: '本周天数', value: '${now.weekday}/7', color: AppColors.textSecondary),
                    ],
                  ),
                  if (weekStats['uniqueDays'] != null && (weekStats['uniqueDays'] as int) > 0) ...[
                    SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (weekStats['uniqueDays'] as int) / now.weekday.clamp(1, 7),
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(AppColors.success),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '完成率 ${((weekStats['uniqueDays'] as int) / now.weekday.clamp(1, 7) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 24),

            // ===== 待办备忘 =====
            _SectionTitle(title: '📝 待办备忘', icon: Icons.note_outlined),
            SizedBox(height: 10),
            if (pendingMemos.isEmpty)
              _EmptyHint(text: '没有待办的备忘事项~', icon: Icons.task_alt)
            else
              ...pendingMemos.take(5).map((m) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _MemoItem(memo: m),
              )),

            SizedBox(height: 24),

            // ===== 最近医疗记录 =====
            _SectionTitle(title: '🏥 健康管理', icon: Icons.medical_services),
            SizedBox(height: 10),
            if (medicalProvider.records.isEmpty)
              _EmptyHint(text: '暂无医疗记录~', icon: Icons.favorite_border)
            else
              ...medicalProvider.records.take(3).map((r) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _MedicalItem(record: r),
              )),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ========== 子组件 ==========

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}', style: TextStyle(fontSize: 26, color: AppColors.primary, fontWeight: FontWeight.bold, height: 1.2)),
                Text(DateFormat.MMMM('zh_CN').format(date), style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMMEEEEd('zh_CN').format(date),
                  style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  weekdayNames[date.weekday - 1] + ' · 芊芊的一天',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          Icon(Icons.wb_sunny_rounded, size: 32, color: Colors.white70),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subText;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon, required this.label, required this.value,
    this.subText, required this.color, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            if (subText != null)
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(subText!, style: TextStyle(fontSize: 11, color: AppColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ],
  );
}

class _EmptyHint extends StatelessWidget {
  final String text;
  final IconData icon;
  const _EmptyHint({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(icon, size: 36, color: AppColors.textHint),
        SizedBox(height: 8),
        Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    ),
  );
}

class _ScheduleItem extends StatelessWidget {
  final Schedule schedule;
  final bool isChecked;
  const _ScheduleItem({required this.schedule, required this.isChecked});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border(left: BorderSide(color: isChecked ? AppColors.success : schedule.color, width: 4)),
      boxShadow: [BoxShadow(color: schedule.color.withValues(alpha: 0.05), blurRadius: 6)],
    ),
    child: Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: schedule.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(schedule.typeIcon, style: TextStyle(fontSize: 18))),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(schedule.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                '${DateFormat.Hm().format(schedule.dateTime)}${schedule.location != null ? " · ${schedule.location!}" : ""}',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Icon(
          isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isChecked ? AppColors.success : Colors.grey.shade300,
          size: 22,
        ),
      ],
    ),
  );
}

class _WeekStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _WeekStatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ],
  );
}

class _MemoItem extends StatelessWidget {
  final Memo memo;
  const _MemoItem({required this.memo});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: AppColors.info.withValues(alpha: 0.5), width: 3)),
    ),
    child: Row(
      children: [
        Icon(Icons.note_outlined, size: 18, color: AppColors.info),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            memo.title ?? memo.content,
            style: TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (memo.reminderTime != null)
          Text(
            DateFormat.Hm().format(memo.reminderTime!),
            style: TextStyle(fontSize: 10, color: AppColors.textHint),
          ),
      ],
    ),
  );
}

class _MedicalItem extends StatelessWidget {
  final MedicalRecord record;
  const _MedicalItem({required this.record});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: AppColors.scheduleMedical.withValues(alpha: 0.5), width: 3)),
    ),
    child: Row(
      children: [
        Icon(Icons.local_hospital, size: 18, color: AppColors.scheduleMedical),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.diagnosis.isNotEmpty ? record.diagnosis : record.hospitalName,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${record.hospitalName} · ${DateFormat.yMMMd('zh_CN').format(record.visitDate)}',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    ),
  );
}
