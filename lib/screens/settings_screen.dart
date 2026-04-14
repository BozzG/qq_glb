import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../services/notification_service.dart';
import '../services/database_helper.dart';
import '../providers/schedule_provider.dart';
import '../providers/course_provider.dart';
import '../providers/memo_provider.dart';
import '../providers/medical_provider.dart';
import '../providers/growth_log_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _reminderMinutes;
  late bool _notificationsEnabled;
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = _notificationService.enabled;
    _reminderMinutes = _notificationService.reminderMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 芊芊头像区域
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 3,
                      ),
                      image: DecorationImage(
                        image: AssetImage('assets/images/avatar.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '芊芊',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 8),

            // 提醒时间
            ListTile(
              leading: Icon(Icons.alarm, color: AppColors.primary),
              title: Text('日程提前提醒'),
              subtitle: Text('$_reminderMinutes 分钟前'),
              trailing: DropdownButton<int>(
                value: _reminderMinutes,
                items: [5, 10, 15, 30, 60]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m分钟')))
                    .toList(),
                onChanged: (v) async {
                  final minutes = v ?? 15;
                  setState(() => _reminderMinutes = minutes);
                  await _notificationService.setReminderMinutes(minutes);
                  if (!mounted) return;
                  final provider = context.read<ScheduleProvider>();
                  if (provider.schedules.isEmpty) await provider.loadSchedules();
                  await _notificationService.rescheduleAll(provider.schedules);
                },
              ),
            ),

            // 通知开关
            SwitchListTile(
              secondary: Icon(
                Icons.notifications_active,
                color: AppColors.primary,
              ),
              title: Text('开启通知提醒'),
              value: _notificationsEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: (v) async {
                if (v) {
                  final granted = await _notificationService.requestPermission();
                  if (!granted) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('请在系统设置中允许通知权限')),
                      );
                    }
                    return;
                  }
                }
                setState(() => _notificationsEnabled = v);
                await _notificationService.setEnabled(v);
                if (v && mounted) {
                  final provider = context.read<ScheduleProvider>();
                  if (provider.schedules.isEmpty) await provider.loadSchedules();
                  await _notificationService.rescheduleAll(provider.schedules);
                }
              },
            ),

            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 8),

            // 关于
            Text(
              '关于应用',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Card(
              elevation: 0,
              margin: EdgeInsets.only(top: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('📔', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Qianqian's Growth Logbook",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '芊芊成长日志 v1.0.0',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      '专为记录孩子成长而设计的APP，帮助家长全面、系统地跟踪孩子的成长历程，为孩子打造一份独特的成长日志。',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      '如有建议或问题，请联系：bozzguo@qq.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // 数据管理按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showResetConfirm(),
                    icon: Icon(Icons.refresh),
                    label: Text('重置数据'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirm() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error),
          SizedBox(width: 8),
          Text('确认重置'),
        ],
      ),
      content: Text("确定要重置所有数据吗？\n此操作不可恢复！"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await DatabaseHelper().resetAll();
              await _notificationService.cancelAll();
              if (!mounted) return;
              await context.read<ScheduleProvider>().loadSchedules();
              await context.read<CourseProvider>().loadCourses();
              await context.read<MemoProvider>().loadMemos();
              await context.read<MedicalProvider>().loadRecords();
              await context.read<GrowthLogProvider>().loadLogs();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('所有数据已重置')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('重置失败：$e')),
                );
              }
            }
          },
          child: Text('确认重置'),
        ),
      ],
    ),
  );
}
