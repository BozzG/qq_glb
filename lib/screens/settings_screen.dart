import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';
import '../services/notification_service.dart';
import '../services/database_helper.dart';
import '../services/backup_service.dart';
import '../providers/schedule_provider.dart';
import '../providers/course_provider.dart';
import '../providers/diary_provider.dart';
import '../providers/medical_provider.dart';

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
    return ElegantScaffold(
      body: Column(
        children: [
          const ElegantNavBar(title: '设置'),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfile(),
                  const SizedBox(height: 24),
                  _buildNotificationCard(),
                  const SizedBox(height: 16),
                  _buildAboutCard(),
                  const SizedBox(height: 16),
                  _buildBackupCard(),
                  const SizedBox(height: 16),
                  _buildDangerCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 头像区 ──────────────────────────────
  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppElegant.hair, width: 0.5),
                image: const DecorationImage(
                  image: AssetImage('assets/images/avatar.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: AppElegant.softShadow,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '芊芊',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppElegant.ink,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'GROWTH JOURNAL',
              style: TextStyle(
                fontSize: 10,
                color: AppElegant.inkSoft,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 通知卡 ──────────────────────────────
  Widget _buildNotificationCard() {
    return ElegantCard(
      child: Column(
        children: [
          const ElegantCardHeader(
            icon: Icons.notifications_none_rounded,
            label: '通知',
          ),
          const SizedBox(height: 6),
          ElegantRowTile(
            label: '开启通知提醒',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (v) async {
                HapticFeedback.selectionClick();
                if (v) {
                  final granted = await _notificationService
                      .requestPermission();
                  if (!granted) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请在系统设置中允许通知权限')),
                    );
                    return;
                  }
                }
                setState(() => _notificationsEnabled = v);
                await _notificationService.setEnabled(v);
                if (!mounted) return;
                if (v) {
                  final provider = context.read<ScheduleProvider>();
                  if (provider.schedules.isEmpty) {
                    await provider.loadSchedules();
                  }
                  await _notificationService.rescheduleAll(provider.schedules);
                }
              },
            ),
          ),
          const ElegantDivider(),
          ElegantRowTile(
            label: '提前提醒时间',
            value: '$_reminderMinutes 分钟前',
            onTap: () => _showReminderPicker(),
          ),
        ],
      ),
    );
  }

  Future<void> _showReminderPicker() async {
    final options = [5, 10, 15, 30, 60];
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppElegant.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ElegantSheetHandle(),
              const SizedBox(height: 8),
              const Text(
                '提前提醒时间',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppElegant.ink,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((m) {
                final selected = m == _reminderMinutes;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);
                      setState(() => _reminderMinutes = m);
                      await _notificationService.setReminderMinutes(m);
                      if (!mounted) return;
                      final provider = context.read<ScheduleProvider>();
                      if (provider.schedules.isEmpty) {
                        await provider.loadSchedules();
                      }
                      await _notificationService.rescheduleAll(
                        provider.schedules,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppElegant.accent : AppElegant.bgAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$m 分钟前',
                            style: TextStyle(
                              fontSize: 14,
                              color: selected ? Colors.white : AppElegant.ink,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (selected)
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 关于 ────────────────────────────────
  Widget _buildAboutCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
            icon: Icons.info_outline_rounded,
            label: '关于应用',
          ),
          const SizedBox(height: 16),
          const Text(
            "Qianqian's Growth Logbook",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppElegant.ink,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text('芊芊成长日志 · v2.3.0', style: AppText.meta),
          const SizedBox(height: 14),
          const Text(
            '专为记录孩子成长而设计的 APP，帮助家长全面、系统地跟踪孩子的成长历程，为孩子打造一份独特的成长日志。',
            style: AppText.itemBody,
          ),
          const SizedBox(height: 16),
          const ElegantDivider(),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                size: 14,
                color: AppElegant.inkSoft,
              ),
              const SizedBox(width: 8),
              const Text('bozzguo@qq.com', style: AppText.meta),
              const Spacer(),
              Text(
                'CONTACT',
                style: TextStyle(
                  fontSize: 10,
                  color: AppElegant.inkFaint,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 数据备份 ─────────────────────────────
  Widget _buildBackupCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
            icon: Icons.cloud_sync_outlined,
            label: '数据备份',
          ),
          const SizedBox(height: 6),
          ElegantRowTile(
            leading: Icons.ios_share_rounded,
            label: '导出备份',
            onTap: _handleExport,
          ),
          const ElegantDivider(),
          ElegantRowTile(
            leading: Icons.settings_backup_restore_rounded,
            label: '从备份恢复',
            onTap: _handleImport,
          ),
          const SizedBox(height: 8),
          const Text(
            '导出后请妥善保存备份文件；恢复将以备份内容覆盖当前全部数据。',
            style: AppText.meta,
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    try {
      await BackupService().exportAndShare();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  Future<void> _handleImport() async {
    final confirmed = await ElegantConfirmDialog.confirmDelete(
      context,
      title: '从备份恢复',
      message: '恢复将以所选备份覆盖当前全部数据，且不可撤销。确定继续吗？',
      confirmLabel: '选择备份文件',
      icon: Icons.settings_backup_restore_rounded,
    );
    if (!confirmed || !mounted) return;
    try {
      final result = await BackupService().importFromPickedFile();
      if (!mounted || result.cancelled) return;
      await _notificationService.cancelAll();
      if (!mounted) return;
      final scheduleProvider = context.read<ScheduleProvider>();
      await scheduleProvider.loadSchedules();
      if (!mounted) return;
      await context.read<CourseProvider>().loadCourses();
      if (!mounted) return;
      await context.read<DiaryProvider>().loadDiaries();
      if (!mounted) return;
      await context.read<MedicalProvider>().loadRecords();
      if (!mounted) return;
      if (_notificationService.enabled) {
        await _notificationService.rescheduleAll(scheduleProvider.schedules);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已恢复 ${result.total} 条数据')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败：$e')),
      );
    }
  }

  // ─── 危险操作 ─────────────────────────────
  Widget _buildDangerCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
            icon: Icons.warning_amber_rounded,
            label: '数据',
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _showResetConfirm,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.restart_alt_rounded,
                    size: 18,
                    color: AppElegant.rose,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '重置全部数据',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppElegant.rose,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppElegant.inkWhisper,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text('清空日程、日记、医疗、课程与打卡数据。此操作不可撤销。', style: AppText.meta),
        ],
      ),
    );
  }

  void _showResetConfirm() async {
    final confirmed = await ElegantConfirmDialog.confirmDelete(
      context,
      title: '确认重置',
      message: '确定要清空所有数据吗？此操作不可恢复。',
      confirmLabel: '确认重置',
      icon: Icons.warning_amber_rounded,
    );
    if (!confirmed || !mounted) return;
    try {
      await DatabaseHelper().resetAll();
      await _notificationService.cancelAll();
      if (!mounted) return;
      await context.read<ScheduleProvider>().loadSchedules();
      if (!mounted) return;
      await context.read<CourseProvider>().loadCourses();
      if (!mounted) return;
      await context.read<DiaryProvider>().loadDiaries();
      if (!mounted) return;
      await context.read<MedicalProvider>().loadRecords();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('所有数据已重置')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('重置失败：$e')));
    }
  }
}
