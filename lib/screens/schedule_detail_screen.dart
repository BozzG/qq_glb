import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';
import 'add_schedule_screen.dart';
import 'edit_recurring_rule_screen.dart';

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
    if (!mounted) return;
    setState(() => _isCheckingIn = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '打卡成功' : '今天已经打卡过啦'),
      ),
    );
    if (success) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    }
  }

  String _typeLabel(ScheduleType t) => const {
        'school': '上学',
        'nursery': '托班',
        'sports': '运动',
        'language': '语言',
        'medical': '医疗',
        'general': '通用',
      }[t.name]!;

  String _repeatLabel() {
    switch (_schedule.repeatType) {
      case RepeatType.none:
        return '不重复';
      case RepeatType.daily:
        return '每天重复';
      case RepeatType.weekly:
        return '每周重复';
      case RepeatType.custom:
        return '周${_schedule.repeatDays.map((d) => ['一', '二', '三', '四', '五', '六', '日'][d - 1]).join('、')} 重复';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _schedule.color;
    // 仅当属于重复组时渲染"修改重复规则"按钮（PRD AC-01 / AC-02）
    final isRecurring = _schedule.repeatTemplateId != null &&
        _schedule.repeatType != RepeatType.none;
    return Scaffold(
      backgroundColor: AppElegant.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                ElegantNavBar(
                  title: '日程详情',
                  actions: [
                    ElegantCircleIconButton(
                      icon: Icons.edit_outlined,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final provider = context.read<ScheduleProvider>();
                        final result = await navigator.push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AddScheduleScreen(editSchedule: _schedule),
                          ),
                        );
                        if (result != true) return;
                        if (!mounted) return;
                        provider.loadSchedules();
                        navigator.pop();
                      },
                    ),
                    const SizedBox(width: 10),
                    if (isRecurring) ...[
                      ElegantCircleIconButton(
                        icon: Icons.event_repeat_outlined,
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          final provider = context.read<ScheduleProvider>();
                          final result = await navigator.push(
                            MaterialPageRoute(
                              builder: (_) => EditRecurringRuleScreen(
                                seed: _schedule,
                              ),
                            ),
                          );
                          if (result != true) return;
                          if (!mounted) return;
                          provider.loadSchedules();
                          navigator.pop();
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                    ElegantCircleIconButton(
                      icon: Icons.delete_outline,
                      onTap: _showDeleteConfirm,
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(color),
                        const SizedBox(height: 24),
                        _buildTimeCard(),
                        const SizedBox(height: 16),
                        if (_schedule.location != null &&
                            _schedule.location!.isNotEmpty)
                          _buildLocationCard(),
                        if (_schedule.location != null &&
                            _schedule.location!.isNotEmpty)
                          const SizedBox(height: 16),
                        _buildMetaCard(),
                        if (_schedule.memo != null &&
                            _schedule.memo!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildMemoCard(),
                        ],
                        const SizedBox(height: 16),
                        _buildRecentCheckIns(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElegantFloatingBar(
            child: Consumer<ScheduleProvider>(
              builder: (ctx, provider, _) {
                final checkedToday =
                    provider.isCheckedToday(_schedule.id);
                return ElegantPrimaryButton(
                  label: checkedToday
                      ? '今日已打卡'
                      : (_isCheckingIn ? '打卡中…' : '立即打卡'),
                  icon: checkedToday ? Icons.check_rounded : null,
                  onPressed: (checkedToday || _isCheckingIn)
                      ? null
                      : _handleCheckIn,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _typeLabel(_schedule.scheduleType).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: AppElegant.inkSoft,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _schedule.title,
            style: AppText.heroTitle,
          ),
          if (_schedule.description != null &&
              _schedule.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _schedule.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppElegant.inkSoft,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(height: 1, width: 40, color: AppElegant.accent),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
              icon: Icons.schedule_outlined, label: '时间'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(_schedule.dateTime),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w300,
                  color: AppElegant.ink,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              if (_schedule.endTime != null) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '— ${DateFormat('HH:mm').format(_schedule.endTime!)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppElegant.inkSoft,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('yyyy 年 M 月 d 日 · EEEE', 'zh_CN')
                .format(_schedule.dateTime),
            style: AppText.meta,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return ElegantCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.place_outlined,
              size: 16, color: AppElegant.inkSoft),
          const SizedBox(width: 10),
          const Text(
            '地点',
            style: TextStyle(
              fontSize: 12,
              color: AppElegant.inkSoft,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              _schedule.location!,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: AppElegant.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard() {
    return ElegantCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ElegantRowTile(
            leading: Icons.repeat_rounded,
            label: '重复',
            value: _repeatLabel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
              icon: Icons.edit_note_outlined, label: '备忘'),
          const SizedBox(height: 12),
          Text(
            _schedule.memo!,
            style: const TextStyle(
              fontSize: 14,
              color: AppElegant.ink,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCheckIns() {
    final checkIns = context
        .watch<ScheduleProvider>()
        .checkIns
        .where((c) => c.scheduleId == _schedule.id)
        .take(5)
        .toList();
    if (checkIns.isEmpty) return const SizedBox.shrink();
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
              icon: Icons.history_rounded, label: '最近打卡'),
          const SizedBox(height: 12),
          ...checkIns.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppElegant.sage.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 12, color: AppElegant.sage),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${DateFormat('M月d日', 'zh_CN').format(c.checkInTime)} · ${DateFormat('HH:mm').format(c.checkInTime)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppElegant.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (c.notes != null && c.notes!.isNotEmpty)
                      Flexible(
                        child: Text(
                          c.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.meta,
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _showDeleteConfirm() {
    final isRecurring = _schedule.repeatTemplateId != null &&
        _schedule.repeatType != RepeatType.none;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: isRecurring
            ? const Text('这是重复日程的一个实例，要如何删除？')
            : Text('确定要删除「${_schedule.title}」吗？\n相关打卡记录也将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          if (isRecurring) ...[
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppElegant.sand),
              onPressed: () {
                context.read<ScheduleProvider>().deleteSchedule(
                      _schedule.id,
                      deleteAllRecurring: false,
                    );
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('仅此项'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppElegant.rose),
              onPressed: () {
                context.read<ScheduleProvider>().deleteSchedule(
                      _schedule.id,
                      deleteAllRecurring: true,
                    );
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('全部'),
            ),
          ] else
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppElegant.rose),
              onPressed: () {
                context
                    .read<ScheduleProvider>()
                    .deleteSchedule(_schedule.id);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('删除'),
            ),
        ],
      ),
    );
  }
}
