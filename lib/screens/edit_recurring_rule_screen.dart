import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/course_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';
import '../widgets/recurring_impact_dialog.dart';

/// ─────────────────────────────────────────────────────────────
///  EditRecurringRuleScreen · 修改重复规则
///  PRD: docs/prd/recurring-rule-edit.md（24 条 AC）
///  Design: docs/design/recurring-rule-edit.md §4
///
///  入参 [seed]：用户在详情页点击的"那条实例"。
///  initState 会用其 repeatTemplateId 找组长（parentId == null），
///  存在则用组长字段预填，不存在则回退到 seed。
/// ─────────────────────────────────────────────────────────────
class EditRecurringRuleScreen extends StatefulWidget {
  final Schedule seed;
  const EditRecurringRuleScreen({super.key, required this.seed});

  @override
  State<EditRecurringRuleScreen> createState() =>
      _EditRecurringRuleScreenState();
}

class _EditRecurringRuleScreenState extends State<EditRecurringRuleScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  late DateTime _dateTime; // 仅时分被使用，年月日仅用于 UI 显示初值
  DateTime? _endTime;
  late RepeatType _repeatType;
  late List<int> _repeatDays;
  late ScheduleType _scheduleType;
  late bool _isCourse;
  String? _courseId;

  /// 锚定实例（详情页传入），用于 commit 时找组。
  late Schedule _anchor;

  /// 生效起始日：明天 00:00。
  late DateTime _tomorrowStart;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _anchor = widget.seed;
    final now = DateTime.now();
    _tomorrowStart = DateTime(now.year, now.month, now.day + 1);

    // 从 provider 找组长字段预填
    final provider = context.read<ScheduleProvider>();
    final templateId = widget.seed.repeatTemplateId;
    Schedule source = widget.seed;
    if (templateId != null) {
      final group = provider.schedules
          .where((s) => s.repeatTemplateId == templateId)
          .toList();
      final leader = group.firstWhere(
        (s) => s.parentId == null,
        orElse: () => widget.seed,
      );
      source = leader;
    }

    _titleCtrl.text = source.title;
    _descCtrl.text = source.description ?? '';
    _locationCtrl.text = source.location ?? '';
    _memoCtrl.text = source.memo ?? '';
    _dateTime = source.dateTime;
    _endTime = source.endTime;
    _repeatType = source.repeatType;
    _repeatDays = List.from(source.repeatDays);
    _scheduleType = source.scheduleType;
    _isCourse = source.isCourse;
    _courseId = source.courseId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
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

  // ─── 时间选择器 ───────────────────────────────────────────
  Future<void> _pickTime() async {
    DateTime temp = _dateTime;
    await _showCupertinoSheet(
      title: '开始时间',
      height: 280,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: _dateTime,
        use24hFormat: true,
        minuteInterval: 5,
        onDateTimeChanged: (v) => temp = v,
      ),
      onConfirm: () => setState(() => _dateTime = temp),
    );
  }

  Future<void> _pickEndTime() async {
    if (_endTime == null) return;
    DateTime temp = _endTime!;
    await _showCupertinoSheet(
      title: '结束时间',
      height: 280,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: _endTime,
        use24hFormat: true,
        minuteInterval: 5,
        onDateTimeChanged: (v) => temp = v,
      ),
      onConfirm: () => setState(() => _endTime = temp),
    );
  }

  Future<void> _showCupertinoSheet({
    required String title,
    required double height,
    required Widget child,
    required VoidCallback onConfirm,
  }) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppElegant.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const ElegantSheetHandle(),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          color: AppElegant.inkSoft,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppElegant.ink,
                        letterSpacing: 1,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onConfirm();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '完成',
                        style: TextStyle(
                          color: AppElegant.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleEndTime() {
    HapticFeedback.selectionClick();
    setState(() {
      _endTime = _endTime == null
          ? _dateTime.add(const Duration(hours: 1))
          : null;
    });
  }

  // ─── 保存流程：校验 → preview → Dialog → commit ─────────
  Future<void> _onTapSave() async {
    if (_saving) return;

    // 校验 1：标题非空
    if (_titleCtrl.text.trim().isEmpty) {
      HapticFeedback.lightImpact();
      _showSnack('请输入日程标题');
      return;
    }

    // 校验 2：weekly + 空 repeatDays（PRD AC-08）
    if (_repeatType == RepeatType.weekly && _repeatDays.isEmpty) {
      HapticFeedback.lightImpact();
      _showSnack('请至少选择一个星期');
      return;
    }

    final provider = context.read<ScheduleProvider>();

    // 构造仅作"模板字段载体"的 Schedule（id/parentId 等无意义，仅取时分及业务字段）
    final templateFields = Schedule(
      id: '_template_',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      dateTime: _dateTime,
      endTime: _endTime,
      repeatType: _repeatType,
      repeatDays: List.from(_repeatDays),
      scheduleType: _scheduleType,
      isCourse: _isCourse,
      courseId: _isCourse ? _courseId : null,
    );

    final RecurringRuleUpdatePreview preview;
    try {
      preview = provider.previewRecurringRuleUpdate(
        scheduleIdInGroup: _anchor.id,
        newRepeatType: _repeatType,
        newRepeatDays: List.from(_repeatDays),
        newTemplateFields: templateFields,
      );
    } on ArgumentError {
      _showSnack('请至少选择一个星期');
      return;
    } catch (e) {
      _showSnack('预演失败：$e');
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => RecurringImpactDialog(
        deleteCount: preview.toDelete.length,
        keepCount: preview.toKeep.length,
        createCount: preview.toCreate.length,
        sampleLine: buildSampleLine(preview.toCreate),
        onCancel: () => Navigator.pop(dialogCtx, false),
        onConfirm: () => Navigator.pop(dialogCtx, true),
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _saving = true);
    try {
      await provider.commitRecurringRuleUpdate(
        scheduleIdInGroup: _anchor.id,
        newRepeatType: _repeatType,
        newRepeatDays: List.from(_repeatDays),
        newTemplateFields: templateFields,
      );
      if (!mounted) return;
      _showSnack('已保存修改');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('保存失败：$e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                  title: '修改重复规则',
                  leading: ElegantCircleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  actions: const [SizedBox(width: 40)],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroHint(),
                        const SizedBox(height: 28),
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
              ],
            ),
          ),
          ElegantFloatingBar(
            child: ElegantPrimaryButton(
              label: _saving ? '保存中…' : '保存修改',
              onPressed: _saving ? null : _onTapSave,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 副标题区（PRD AC-05） ────────────────────────────
  Widget _buildHeroHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '生效起始日：明天起 · ${DateFormat('yyyy-MM-dd').format(_tomorrowStart)}（含）',
            style: AppText.heroHint,
          ),
          const SizedBox(height: 8),
          Container(height: 1, width: 40, color: AppElegant.accent),
        ],
      ),
    );
  }

  // ─── 标题输入 ─────────────────────────────────────────
  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('修改重复规则的所有未来实例', style: AppText.heroHint),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            cursorColor: AppElegant.accent,
            cursorWidth: 1.5,
            style: AppText.heroTitle,
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

  // ─── 卡片：时间（仅时分） ────────────────────────────
  Widget _buildTimeCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
            icon: Icons.schedule_outlined,
            label: '时间',
          ),
          const SizedBox(height: 18),
          const Text(
            '日期由重复规则决定，此处仅设定时分',
            style: AppText.meta,
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _pickTime();
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '开始',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppElegant.inkSoft,
                      height: 2.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(_dateTime),
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
          ),
          const ElegantDivider(),
          if (_endTime != null)
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _pickEndTime();
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '结束',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppElegant.inkSoft,
                        height: 2.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('HH:mm').format(_endTime!),
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
            ),
          if (_endTime != null) const ElegantDivider(),
          InkWell(
            onTap: _toggleEndTime,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _endTime == null
                        ? Icons.add_rounded
                        : Icons.remove_rounded,
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

  // ─── 卡片：分类 ───────────────────────────────────────
  Widget _buildTypeCard() {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
            icon: Icons.bookmark_border_rounded,
            label: '分类',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: ScheduleType.values.map((type) {
              final selected = _scheduleType == type;
              return _TypeChip(
                icon: _typeIcon(type),
                label: _typeLabel(type),
                color: _typeColor(type),
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _scheduleType = type);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── 卡片：重复 ───────────────────────────────────────
  Widget _buildRepeatCard() {
    final showWeekdayPicker =
        _repeatType == RepeatType.weekly || _repeatType == RepeatType.custom;
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ElegantCardHeader(
            icon: Icons.repeat_rounded,
            label: '重复',
          ),
          const SizedBox(height: 14),
          Row(
            children: RepeatType.values.map((type) {
              final selected = _repeatType == type;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type != RepeatType.values.last ? 8 : 0,
                  ),
                  child: ElegantSegment(
                    label: _repeatLabel(type),
                    selected: selected,
                    onTap: () {
                      HapticFeedback.selectionClick();
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
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: showWeekdayPicker
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      const ElegantDivider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['一', '二', '三', '四', '五', '六', '日']
                            .asMap()
                            .entries
                            .map((e) {
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
                                color: active
                                    ? AppElegant.accent
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: active
                                      ? AppElegant.accent
                                      : AppElegant.hair,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: active
                                        ? Colors.white
                                        : AppElegant.inkSoft,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── 卡片：详情（地点/备注） ─────────────────────────
  Widget _buildDetailCard() {
    return ElegantCard(
      child: Column(
        children: [
          const ElegantCardHeader(
            icon: Icons.tune_rounded,
            label: '详情',
          ),
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

  // ─── 卡片：关联课程 ──────────────────────────────────
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
          const Text(
            '开启后，完成打卡将自动扣除一次课时',
            style: TextStyle(
              fontSize: 12,
              color: AppElegant.inkSoft,
              height: 1.5,
            ),
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
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppElegant.inkSoft,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '暂无课程，请先在「课程管理」中添加',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppElegant.inkSoft,
                            ),
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
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  本地辅助组件（与 add_schedule_screen 保持视觉一致）
// ═══════════════════════════════════════════════════════════════

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppElegant.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                selected ? color.withValues(alpha: 0.5) : AppElegant.hair,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? color : AppElegant.inkSoft,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? color : AppElegant.ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
