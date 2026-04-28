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

/// ─────────────────────────────────────────────────────────────
///  精致优雅版 · 新建/编辑日程
///  设计语言：
///  · 大留白、弱分隔、强层级
///  · 衬线标题 + 细线几何图标
///  · 柔和底色卡片分组
///  · 选中态采用描边 + 微填充，避免俗艳色块
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

  bool get isEditing => widget.editSchedule != null;

  // 精致调色板（仅本页使用，避免影响全局）- 与 AppElegant 保持一致
  static const _bg = Color(0xFFFBF8F7); // 带微粉暖调的米白底
  static const _ink = Color(0xFF2B1E22); // 深墨（带酒红）
  static const _inkSoft = Color(0xFF7A6268); // 次级灰
  static const _hair = Color(0xFFEDE6E7); // 发丝线（粉调）
  static const _accent = Color(0xFFC9526E); // 主行动色 · Wine Rose

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
        SnackBar(
          content: const Text('请输入日程标题'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
    );

    final provider = context.read<ScheduleProvider>();
    HapticFeedback.mediumImpact();
    if (isEditing) {
      await provider.updateSchedule(schedule);
    } else {
      await provider.addSchedule(schedule);
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '已更新' : '已添加'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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

  Color _typeColor(ScheduleType t) => {
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

  // ─── 日期/时间选择器 ───────────────────────────────────────
  Future<void> _pickDate() async {
    DateTime temp = _dateTime;
    await _showCupertinoSheet(
      title: '日期',
      height: 320,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: _dateTime,
        minimumDate: DateTime(2020),
        maximumDate: DateTime(2035),
        onDateTimeChanged: (v) => temp = v,
      ),
      onConfirm: () => setState(() {
        _dateTime = DateTime(
            temp.year, temp.month, temp.day, _dateTime.hour, _dateTime.minute);
      }),
    );
  }

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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 顶部指示条
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _hair,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _SheetHeader(
                title: title,
                onCancel: () => Navigator.pop(context),
                onConfirm: () {
                  HapticFeedback.selectionClick();
                  onConfirm();
                  Navigator.pop(context);
                },
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
      _endTime = _endTime == null ? _dateTime.add(const Duration(hours: 1)) : null;
    });
  }

  // ─── 构建 ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildNavBar(),
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
          _buildFloatingSaveBar(),
        ],
      ),
    );
  }

  // ─── 顶部导航 ────────────────────────────────────────────
  Widget _buildNavBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            isEditing ? '编辑' : '新建日程',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _ink,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
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
            isEditing ? '修改日程详情' : '记录此刻的安排',
            style: const TextStyle(
              fontSize: 12,
              color: _inkSoft,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            cursorColor: _accent,
            cursorWidth: 1.5,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: _ink,
              height: 1.25,
              letterSpacing: -0.5,
            ),
            maxLines: 2,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: '未命名日程',
              hintStyle: TextStyle(
                color: Color(0xFFD1D1D6),
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
          Container(height: 1, width: 40, color: _accent),
        ],
      ),
    );
  }

  // ─── 卡片：时间 ─────────────────────────────────────────
  Widget _buildTimeCard() {
    return _Card(
      child: Column(
        children: [
          _CardHeader(label: '时间', icon: Icons.schedule_outlined),
          const SizedBox(height: 18),
          // 日期
          _RowTile(
            label: '日期',
            value: DateFormat('yyyy 年 M 月 d 日 · EEEE', 'zh_CN').format(_dateTime),
            onTap: _pickDate,
          ),
          const _HairDivider(),
          // 开始时间 - 大号显示
          InkWell(
            onTap: _pickTime,
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
                      color: _inkSoft,
                      height: 2.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(_dateTime),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: _ink,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.chevron_right, size: 18, color: _inkSoft),
                  ),
                ],
              ),
            ),
          ),
          const _HairDivider(),
          // 结束时间
          if (_endTime != null)
            _RowTile(
              label: '结束',
              value: DateFormat('HH:mm').format(_endTime!),
              valueLarge: true,
              onTap: _pickEndTime,
            ),
          if (_endTime != null) const _HairDivider(),
          // 添加/移除结束时间
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
                    color: _ink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _endTime == null ? '添加结束时间' : '移除结束时间',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _ink,
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

  // ─── 卡片：类型 ─────────────────────────────────────────
  Widget _buildTypeCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(label: '分类', icon: Icons.bookmark_border_rounded),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: ScheduleType.values.map((type) {
              final selected = _scheduleType == type;
              final color = _typeColor(type);
              return _TypeChip(
                icon: _typeIcon(type),
                label: _typeLabel(type),
                color: color,
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

  // ─── 卡片：重复 ─────────────────────────────────────────
  Widget _buildRepeatCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(label: '重复', icon: Icons.repeat_rounded),
          const SizedBox(height: 14),
          Row(
            children: RepeatType.values.map((type) {
              final selected = _repeatType == type;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: type != RepeatType.values.last ? 8 : 0),
                  child: _SegmentChip(
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
          if (_repeatType == RepeatType.custom ||
              _repeatType == RepeatType.weekly) ...[
            const SizedBox(height: 18),
            const _HairDivider(),
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
                      color: active ? _accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? _accent : _hair,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: active ? Colors.white : _inkSoft,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 卡片：详情（地点/备注）────────────────────────────
  Widget _buildDetailCard() {
    return _Card(
      child: Column(
        children: [
          _CardHeader(label: '详情', icon: Icons.tune_rounded),
          const SizedBox(height: 6),
          _PlainInputRow(
            icon: Icons.place_outlined,
            hint: '添加地点',
            controller: _locationCtrl,
          ),
          const _HairDivider(),
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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  size: 16, color: _inkSoft),
              const SizedBox(width: 8),
              const Text(
                '关联课程',
                style: TextStyle(
                  fontSize: 13,
                  color: _inkSoft,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              CupertinoSwitch(
                value: _isCourse,
                activeTrackColor: _accent,
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
            style: TextStyle(fontSize: 12, color: _inkSoft, height: 1.5),
          ),
          if (_isCourse) ...[
            const SizedBox(height: 16),
            const _HairDivider(),
            const SizedBox(height: 14),
            Consumer<CourseProvider>(
              builder: (context, provider, _) {
                if (provider.courses.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: _inkSoft),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '暂无课程，请先在「课程管理」中添加',
                            style:
                                TextStyle(fontSize: 12, color: _inkSoft),
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
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? color.withValues(alpha: 0.6)
                                : _hair,
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
                                color: selected ? color : _ink,
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

  // ─── 底部浮动保存栏 ─────────────────────────────────────
  Widget _buildFloatingSaveBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _bg.withValues(alpha: 0),
              _bg.withValues(alpha: 0.95),
              _bg,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isEditing ? '保存更改' : '完成',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  辅助组件
// ═══════════════════════════════════════════════════════════════

/// 卡片容器
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEDEDED),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 卡片标题
class _CardHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _CardHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6E6E73)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6E6E73),
            letterSpacing: 2.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 发丝分隔线
class _HairDivider extends StatelessWidget {
  const _HairDivider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: const Color(0xFFEDEDED));
}

/// 行列表项（label 左，value 右）
class _RowTile extends StatelessWidget {
  final String label;
  final String value;
  final bool valueLarge;
  final VoidCallback onTap;
  const _RowTile({
    required this.label,
    required this.value,
    this.valueLarge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: valueLarge ? 14 : 16),
        child: Row(
          crossAxisAlignment:
              valueLarge ? CrossAxisAlignment.end : CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF6E6E73),
                height: valueLarge ? 2.2 : 1.2,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: valueLarge ? 36 : 15,
                fontWeight:
                    valueLarge ? FontWeight.w300 : FontWeight.w500,
                color: const Color(0xFF1C1C1E),
                letterSpacing: valueLarge ? -1 : 0,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.only(bottom: valueLarge ? 4 : 0),
              child: const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFFBDBDBD)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 圆形图标按钮（导航栏用）
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1C1C1E)),
      ),
    );
  }
}

/// 分类 chip
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : const Color(0xFFEDEDED),
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? color : const Color(0xFF6E6E73)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? color : const Color(0xFF1C1C1E),
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分段 chip（重复频率）
class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFEDEDED),
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : const Color(0xFF1C1C1E),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

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
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
            child: Icon(icon, size: 18, color: const Color(0xFF6E6E73)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              cursorColor: const Color(0xFF1C1C1E),
              cursorWidth: 1.5,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1C1C1E),
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFBDBDBD),
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

/// 底部弹窗头部
class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const _SheetHeader({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: onCancel,
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(0xFF6E6E73),
                fontSize: 15,
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
              letterSpacing: 1,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: onConfirm,
            child: const Text(
              '完成',
              style: TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
