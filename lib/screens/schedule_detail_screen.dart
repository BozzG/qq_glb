import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/schedule_provider.dart';
import 'add_schedule_screen.dart';
import '../utils/app_theme.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final Schedule schedule;
  const ScheduleDetailScreen({super.key, required this.schedule});

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  late Schedule _schedule;
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _schedule = widget.schedule;
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);
    final provider = context.read<ScheduleProvider>();
    final success = await provider.checkIn(_schedule.id);
    setState(() => _isCheckingIn = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ 打卡成功！' : '⚠️ 今天已经打卡过啦~'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.success : AppColors.warning,
        ),
      );
      if (success) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('日程详情', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _EditSchedulePage(schedule: _schedule),
                ),
              );
              if (result == true && mounted) {
                context.read<ScheduleProvider>().loadSchedules();
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirm(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日程头部卡片
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _schedule.color.withValues(alpha: 0.8),
                    _schedule.color,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        _schedule.typeIcon,
                        style: TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _schedule.title,
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_schedule.description != null &&
                      _schedule.description!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        _schedule.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // 详细信息卡片
            _InfoCard(
              icon: Icons.access_time,
              label: '时间',
              value:
                  '${DateFormat.yMMMd('zh_CN').format(_schedule.dateTime)} ${DateFormat.Hm().format(_schedule.dateTime)}',
            ),
            if (_schedule.endTime != null)
              _InfoCard(
                icon: Icons.schedule_outlined,
                label: '结束时间',
                value:
                    '${DateFormat.yMMMd('zh_CN').format(_schedule.endTime!)} ${DateFormat.Hm().format(_schedule.endTime!)}',
              ),
            if (_schedule.location != null && _schedule.location!.isNotEmpty)
              _InfoCard(
                icon: Icons.location_on_outlined,
                label: '地点',
                value: _schedule.location!,
              ),
            _InfoCard(
              icon: Icons.repeat,
              label: '重复',
              value: _schedule.repeatType == RepeatType.none
                  ? '不重复'
                  : _schedule.repeatType == RepeatType.daily
                  ? '每天重复'
                  : _schedule.repeatType == RepeatType.weekly
                  ? '每周重复'
                  : '周${_schedule.repeatDays.map((d) => ['一', '二', '三', '四', '五', '六', '日'][d - 1]).join('、')} 重复${_schedule.parentId != null ? '（此为单日实例）' : ''}',
            ),

            // 备忘内容
            if (_schedule.memo != null && _schedule.memo!.isNotEmpty) ...[
              SizedBox(height: 12),
              Card(
                elevation: 0,
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '备忘',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        _schedule.memo!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 28),

            // 打卡按钮区域
            Consumer<ScheduleProvider>(
              builder: (ctx, provider, _) {
                final checkedToday = provider.isCheckedToday(_schedule.id);
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: checkedToday
                        ? null
                        : (_isCheckingIn ? null : _handleCheckIn),
                    icon: _isCheckingIn
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : (checkedToday
                              ? Icon(Icons.check_circle, size: 22)
                              : Icon(Icons.touch_app, size: 22)),
                    label: Text(
                      checkedToday
                          ? '今日已打卡 ✅'
                          : (_isCheckingIn ? '打卡中...' : '立即打卡'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: checkedToday
                          ? AppColors.success
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 最近打卡记录
            ..._buildRecentCheckIns(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentCheckIns() {
    final checkIns = context
        .watch<ScheduleProvider>()
        .checkIns
        .where((c) => c.scheduleId == _schedule.id)
        .take(5)
        .toList();
    if (checkIns.isEmpty) return [];
    return [
      SizedBox(height: 28),
      Divider(),
      SizedBox(height: 12),
      Row(
        children: [
          Text(
            '最近打卡记录',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      SizedBox(height: 12),
      ...checkIns.map(
        (c) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.check_circle, color: AppColors.success, size: 20),
          title: Text(
            '${DateFormat.MMMd('zh_CN').format(c.checkInTime)} ${DateFormat.Hm().format(c.checkInTime)}',
            style: TextStyle(fontSize: 13),
          ),
          subtitle: c.notes != null
              ? Text(
                  c.notes!,
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                )
              : null,
        ),
      ),
    ];
  }

  void _showDeleteConfirm() {
    final isRecurring =
        _schedule.repeatTemplateId != null &&
        _schedule.repeatType != RepeatType.none;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('删除确认'),
          ],
        ),
        content: isRecurring
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text("这是重复日程的一个实例，要如何删除？"), SizedBox(height: 12)],
              )
            : Text("确定要删除「${_schedule.title}」吗？\n相关打卡记录也将被删除。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          if (isRecurring) ...[
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                context.read<ScheduleProvider>().deleteSchedule(
                  _schedule.id,
                  deleteAllRecurring: false,
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('仅删除此项'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                context.read<ScheduleProvider>().deleteSchedule(
                  _schedule.id,
                  deleteAllRecurring: true,
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('删除全部重复'),
            ),
          ] else
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                context.read<ScheduleProvider>().deleteSchedule(_schedule.id);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('确认删除'),
            ),
        ],
      ),
    );
  }
}

// 编辑页面 - 复用 AddScheduleScreen
class _EditSchedulePage extends StatelessWidget {
  final Schedule schedule;
  const _EditSchedulePage({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return AddScheduleScreen(editSchedule: schedule);
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          margin: EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: AppColors.primary),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
