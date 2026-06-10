import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/course_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';

/// ─────────────────────────────────────────────────────────────
///  精致优雅版 · 新建/编辑日程
///  设计语言：
///  · 大留白、弱分隔、强层级
///  · 衬线标题 + 细线几何图标
///  · 柔和底色卡片分组
///  · 选中态采用描边 + 微填充，避免俗艳色块
///  · 全量复用 elegant_kit 组件 + AppElegant 调色板（不引入本地视觉 token）
/// ─────────────────────────────────────────────────────────────
class AddScheduleScreen extends StatefulWidget {
  final Schedule? editSchedule;
  const AddScheduleScreen({super.key, this.editSchedule});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));
  DateTime? _endTime;
  RepeatType _repeatType = RepeatType.none;
  List<int> _repeatDays = [];
  ScheduleType _scheduleType = ScheduleType.general;
  bool _isCourse = false;
  String? _courseId;
  int _courseHours = 1; // 每次打卡消耗课时数，最小 1

  bool get isEditing => widget.editSchedule != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final s = widget.editSchedule!;
      _titleCtrl.text = s.title;
      _descCtrl.text = s.description ?? '';
      _locationCtrl.text = s.location ?? '';
      _memoCtrl.text = s.memo ?? '';
      _dateTime = s.dateTime;
      _endTime = s.endTime;
      _repeatType = s.repeatType;
      _repeatDays = List.from(s.repeatDays);
      _scheduleType = s.scheduleType;
      _isCourse = s.isCourse;
      _courseId = s.courseId;
      _courseHours = s.courseHours < 1 ? 1 : s.courseHours.round();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (_titleCtrl.text.trim().isEmpty) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入日程标题')),
      );
      return;
    }

    final scheduleData = isEditing
        ? widget.editSchedule!
        : Schedule(
            id: const Uuid().v4(),
            title: _titleCtrl.text.trim(),
            dateTime: _dateTime,
            createdAt: DateTime.now(),
          );

    final schedule = scheduleData.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      memo: _memoCtrl.text.isEmpty ? null : _memoCtrl.text.trim(),
      dateTime: _dateTime,
      endTime: _endTime,
      repeatType: _repeatType,
      repeatDays: List.from(_repeatDays),
      scheduleType: _scheduleType,
      isCourse: _isCourse,
      courseId: _courseId,
      courseHours: _courseHours.toDouble(),
    );

    final provider = context.read<ScheduleProvider>();
    if (isEditing) {
      await provider.updateSchedule(schedule);
    } else {
      await provider.addSchedule(schedule);
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? '已更新' : '已添加')),
      );
    }
  }

  // ─── 数据映射 ───────────────────────────────────────────────
  String _repeatLabel(RepeatType t) => const {
    RepeatType.none: '不重复',
    RepeatType.daily: '每天',
    RepeatType.weekly: '每周',
    RepeatType.custom: '自定义',
  }[t]!;

  Color _typeColor(ScheduleType t) =>
      {
        'nursery': AppColors.scheduleNursery,
        'sports': AppColors.scheduleSports,
        'language': AppColors.scheduleLanguage,
        'medical': AppColors.scheduleMedical,
        'school': AppColors.scheduleSchool,
        'general': AppColors.scheduleGeneral,
      }[t.name] ??
      AppColors.scheduleGeneral;

  String _typeLabel(ScheduleType t) => const {
    'school': '上学',
    'nursery': '托班',
    'sports': '运动',
    'language': '语言',
    'medical': '医疗',
    'general': '通用',
  }[t.name]!;

  IconData _typeIcon(ScheduleType t) => const {
    'school': Icons.school_outlined,
    'nursery': Icons.child_care_outlined,
    'sports': Icons.sports_basketball_outlined,
    'language': Icons.translate_outlined,
    'medical': Icons.local_hospital_outlined,
    'general': Icons.label_outline,
  }[t.name]!;

  // ─── 日期/时间选择器（复用 elegant_kit 统一选择器）──────────
  Future<void> _pickDate() async {
    final picked = await ElegantDatePicker.show(
      context,
      initial: _dateTime,
      minimumDate: DateTime(2020),
      maximumDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await ElegantTimePicker.show(
      context,
      initial: _dateTime,
      title: '开始时间',
    );
    if (picked == null) return;
    setState(() => _dateTime = picked);
  }

  Future<void> _pickEndTime() async {
    if (_endTime == null) return;
    final picked = await ElegantTimePicker.show(
      context,
      initial: _endTime!,
      title: '结束时间',
    );
    if (picked == null) return;
    setState(() => _endTime = picked);
  }

  void _toggleEndTime() {
    HapticFeedback.selectionClick();
    setState(() {
      _endTime = _endTime == null
          ? _dateTime.add(const Duration(hours: 1))
          : null;
    });
  }

  // ─── 构建 ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppElegant.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                ElegantNavBar(
                  title: isEditing ? '编辑' : '新建日程',
                  leading: ElegantCircleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleField(),
                          const SizedBox(height: 28),
                          _buildTimeCard(),
                          const SizedBox(height: 20),
                          _buildTypeCard(),
                          const SizedBox(height: 20),
                          _buildRepeatCard(),
                          const SizedBox(height: 20),
                          _buildDetailCard(),
                          const SizedBox(height: 20),
                          _buildCourseCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElegantFloatingBar(
            child: ElegantPrimaryButton(
              label: isEditing ? '保存更改' : '完成',
              onPressed: _saveSchedule,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 标题输入（大号、衬托高级感）────────────────────────
  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? '修改日程详情' : '记录成长的安排',
            style: const TextStyle(
              fontSize: 12,
              color: AppElegant.inkSoft,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            cursorColor: AppElegant.accent,
            cursorWidth: 1.5,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppElegant.ink,
              height: 1.25,
              letterSpacing: -0.5,
            ),
            maxLines: 2,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: '未命名日程',
              hintStyle: TextStyle(
                color: AppElegant.inkWhisper,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, width: 40, color: AppElegant.accent),
        ],
      ),
    );
  }

  // ─── 卡片：时间 ─────────────────────────────────────────
  Widget _buildTimeCard() {
    return ElegantCard(
      child: Column(
        children: [
          const ElegantCardHeader(label: '时间', icon: Icons.schedule_outlined),
          const SizedBox(height: 18),
          // 日期
          ElegantRowTile(
            label: '日期',
            value: DateFormat('yyyy 年 M 月 d 日 · EEEE', 'zh_CN').format(_dateTime),
            onTap: _pickDate,
          ),
          const ElegantDivider(),
          // 开始时间 - 大号显示
          _bigTimeRow(
            label: '开始',
            value: DateFormat('HH:mm').format(_dateTime),
            onTap: _pickTime,
          ),
          const ElegantDivider(),
          // 结束时间
          if (_endTime != null) ...[
            _bigTimeRow(
              label: '结束',
              value: DateFormat('HH:mm').format(_endTime!),
              onTap: _pickEndTime,
            ),
            const ElegantDivider(),
          ],
          // 添加/移除结束时间
          InkWell(
            onTap: _toggleEndTime,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _endTime == null ? Icons.add_rounded : Icons.remove_rounded,
                    size: 16,
                    color: AppElegant.ink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _endTime == null ? '添加结束时间' : '移除结束时间',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppElegant.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 大号时间行（开始/结束）— 36px 细体时间 + 右侧箭头
  Widget _bigTimeRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppElegant.inkSoft,
                height: 2.2,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: AppElegant.ink,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(width: 10),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: AppElegant.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 卡片：类型 ─────────────────────────────────────────
  Widget _buildTypeCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
            label: '分类',
            icon: Icons.bookmark_border_rounded,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: ScheduleType.values.map((type) {
              return ElegantChip(
                icon: _typeIcon(type),
                label: _typeLabel(type),
                accentColor: _typeColor(type),
                selected: _scheduleType == type,
                onTap: () => setState(() => _scheduleType = type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── 卡片：重复 ─────────────────────────────────────────
  Widget _buildRepeatCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(label: '重复', icon: Icons.repeat_rounded),
          const SizedBox(height: 14),
          Row(
            children: RepeatType.values.map((type) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type != RepeatType.values.last ? 8 : 0,
                  ),
                  child: ElegantSegment(
                    label: _repeatLabel(type),
                    selected: _repeatType == type,
                    onTap: () {
                      setState(() {
                        _repeatType = type;
                        if (type == RepeatType.weekly && _repeatDays.isEmpty) {
                          _repeatDays = [_dateTime.weekday];
                        }
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          if (_repeatType == RepeatType.custom ||
              _repeatType == RepeatType.weekly) ...[
            const SizedBox(height: 18),
            const ElegantDivider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['一', '二', '三', '四', '五', '六', '日'].asMap().entries.map(
                (e) {
                  final day = e.key + 1;
                  final active = _repeatDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (active) {
                          _repeatDays.remove(day);
                        } else {
                          _repeatDays.add(day);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: active ? AppElegant.accent : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active ? AppElegant.accent : AppElegant.hair,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: active ? Colors.white : AppElegant.inkSoft,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 卡片：详情（地点/备注）────────────────────────────
  Widget _buildDetailCard() {
    return ElegantCard(
      child: Column(
        children: [
          const ElegantCardHeader(label: '详情', icon: Icons.tune_rounded),
          const SizedBox(height: 6),
          _PlainInputRow(
            icon: Icons.place_outlined,
            hint: '添加地点',
            controller: _locationCtrl,
          ),
          const ElegantDivider(),
          _PlainInputRow(
            icon: Icons.edit_note_rounded,
            hint: '添加备注…',
            controller: _memoCtrl,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ─── 卡片：关联课程 ─────────────────────────────────────
  Widget _buildCourseCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: AppElegant.inkSoft,
              ),
              const SizedBox(width: 8),
              const Text(
                '关联课程',
                style: TextStyle(
                  fontSize: 13,
                  color: AppElegant.inkSoft,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              CupertinoSwitch(
                value: _isCourse,
                activeTrackColor: AppElegant.accent,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isCourse = v;
                    if (!v) _courseId = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isCourse
                ? '完成打卡将自动扣除 $_courseHours 课时'
                : '开启后，完成打卡将自动扣除课时',
            style: const TextStyle(
                fontSize: 12, color: AppElegant.inkSoft, height: 1.5),
          ),
          if (_isCourse) ...[
            const SizedBox(height: 16),
            const ElegantDivider(),
            const SizedBox(height: 14),
            Consumer<CourseProvider>(
              builder: (context, provider, _) {
                if (provider.courses.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppElegant.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: AppElegant.inkSoft),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '暂无课程，请先在「课程管理」中添加',
                            style: TextStyle(
                                fontSize: 12, color: AppElegant.inkSoft),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.courses.map((course) {
                    final selected = _courseId == course.id;
                    final color = Color(course.color);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _courseId = course.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.08)
                              : AppElegant.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? color.withValues(alpha: 0.6)
                                : AppElegant.hair,
                            width: selected ? 1 : 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                              course.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected ? color : AppElegant.ink,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            if (_courseId != null) ...[
              const SizedBox(height: 16),
              const ElegantDivider(),
              const SizedBox(height: 14),
              _buildCourseHoursStepper(),
            ],
          ],
        ],
      ),
    );
  }

  /// 每次消耗课时步进器（整数，最小 1）
  Widget _buildCourseHoursStepper() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '每次消耗课时',
                style: TextStyle(
                  fontSize: 14,
                  color: AppElegant.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '一次打卡扣除的课时数',
                style: TextStyle(fontSize: 12, color: AppElegant.inkSoft),
              ),
            ],
          ),
        ),
        _stepperButton(
          icon: Icons.remove_rounded,
          enabled: _courseHours > 1,
          onTap: () {
            if (_courseHours <= 1) return;
            HapticFeedback.selectionClick();
            setState(() => _courseHours--);
          },
        ),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Text(
            '$_courseHours',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppElegant.ink,
            ),
          ),
        ),
        _stepperButton(
          icon: Icons.add_rounded,
          enabled: true,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _courseHours++);
          },
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppElegant.bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppElegant.accent : AppElegant.hair,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppElegant.accent : AppElegant.inkWhisper,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  辅助组件（仅本页特有、elegant_kit 暂无等价物）
// ═══════════════════════════════════════════════════════════════

/// 无边框输入行
class _PlainInputRow extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  const _PlainInputRow({
    required this.icon,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
            child: Icon(icon, size: 18, color: AppElegant.inkSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              cursorColor: AppElegant.ink,
              cursorWidth: 1.5,
              style: const TextStyle(
                fontSize: 14,
                color: AppElegant.ink,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppElegant.inkWhisper,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

