import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/course_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_theme.dart';

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

  DateTime _dateTime = DateTime.now().add(Duration(hours: 1));
  DateTime? _endTime;
  RepeatType _repeatType = RepeatType.none;
  List<int> _repeatDays = [];
  ScheduleType _scheduleType = ScheduleType.general;
  bool _isCourse = false;
  String? _courseId;

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
    if (!_formKey.currentState!.validate()) return;

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
    if (isEditing) {
      await provider.updateSchedule(schedule);
    } else {
      await provider.addSchedule(schedule);
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '日程已更新' : '日程已添加'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        isEditing ? '编辑日程' : '添加新日程',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: _saveSchedule,
          child: Text(
            '保存',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 基本信息卡片 =====
            _buildCard(
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    icon: Icon(Icons.event_note, color: AppColors.primary),
                    labelText: '日程名称',
                    hintText: '如：托班、运动课、上学',
                    border: InputBorder.none,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请输入日程名称' : null,
                ),
                Divider(height: 1),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 1,
                  decoration: InputDecoration(
                    icon: Icon(Icons.description_outlined, color: Colors.grey),
                    labelText: '描述（可选）',
                    border: InputBorder.none,
                  ),
                ),
                Divider(height: 1),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: InputDecoration(
                    icon: Icon(Icons.location_on_outlined, color: Colors.grey),
                    labelText: '地点（可选）',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // ===== 日程类型 =====
            _buildSectionTitle('日程类型'),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ScheduleType.values.map((type) {
                final selected = _scheduleType == type;
                return GestureDetector(
                  onTap: () => setState(() => _scheduleType = type),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? _typeColor(type).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? _typeColor(type)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_typeIcon(type), style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
                        Text(
                          _typeLabel(type),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? _typeColor(type) : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 16),

            // ===== 时间设置 =====
            _buildSectionTitle('时间'),
            SizedBox(height: 8),
            _buildCard(
              children: [
                // 开始 - 日期
                ListTile(
                  dense: true,
                  leading: Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                  title: Text('开始日期', style: TextStyle(fontSize: 14)),
                  trailing: Text(
                    DateFormat.yMMMd('zh_CN').format(_dateTime),
                    style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                  onTap: () => _pickDate(isStart: true),
                ),
                Divider(height: 1, indent: 48),
                // 开始 - 时间
                ListTile(
                  dense: true,
                  leading: Icon(Icons.access_time, color: AppColors.primary, size: 20),
                  title: Text('开始时间', style: TextStyle(fontSize: 14)),
                  trailing: Text(
                    DateFormat.Hm().format(_dateTime),
                    style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                  onTap: () => _pickTime(isStart: true),
                ),
                Divider(height: 1, indent: 48),
                // 结束 - 日期
                ListTile(
                  dense: true,
                  leading: Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                  title: Text('结束日期', style: TextStyle(fontSize: 14)),
                  trailing: Text(
                    _endTime != null
                        ? DateFormat.yMMMd('zh_CN').format(_endTime!)
                        : '可选',
                    style: TextStyle(
                      fontSize: 14,
                      color: _endTime != null ? AppColors.primary : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _pickDate(isStart: false),
                ),
                Divider(height: 1, indent: 48),
                // 结束 - 时间
                ListTile(
                  dense: true,
                  leading: Icon(Icons.schedule_outlined, color: Colors.grey, size: 20),
                  title: Text('结束时间', style: TextStyle(fontSize: 14)),
                  trailing: _endTime != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat.Hm().format(_endTime!),
                              style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() => _endTime = null),
                              child: Icon(Icons.close, size: 16, color: Colors.grey),
                            ),
                          ],
                        )
                      : Text('可选', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  onTap: () => _pickTime(isStart: false),
                ),
              ],
            ),

            SizedBox(height: 16),

            // ===== 重复设置 =====
            _buildSectionTitle('重复'),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: RepeatType.values.map((type) {
                  final selected = _repeatType == type;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_repeatLabel(type)),
                      selected: selected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : Colors.black87,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
                      ),
                      onSelected: (_) => setState(() {
                        _repeatType = type;
                        if (type == RepeatType.weekly && _repeatDays.isEmpty) {
                          _repeatDays = [_dateTime.weekday];
                        }
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),

            if (_repeatType == RepeatType.custom || _repeatType == RepeatType.weekly)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['一', '二', '三', '四', '五', '六', '日']
                      .asMap()
                      .entries
                      .map((e) {
                        final day = e.key + 1;
                        final active = _repeatDays.contains(day);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (active) {
                              _repeatDays.remove(day);
                            } else {
                              _repeatDays.add(day);
                            }
                          }),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : Colors.grey.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: active ? Colors.white : Colors.black54,
                                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),

            SizedBox(height: 16),

            // ===== 课程关联 =====
            _buildCard(
              children: [
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  title: Text('关联课程', style: TextStyle(fontSize: 14)),
                  subtitle: Text('打卡自动扣课时', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _isCourse,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() {
                    _isCourse = v;
                    if (!v) _courseId = null;
                  }),
                ),
                if (_isCourse) ...[
                  Divider(height: 1),
                  Builder(
                    builder: (context) {
                      final courses = context.watch<CourseProvider>().courses;
                      if (courses.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            '暂无课程，请先在「课程管理」中添加',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        );
                      }
                      return Column(
                        children: courses.map((course) {
                          final selected = _courseId == course.id;
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(course.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(course.name, style: TextStyle(fontSize: 13)),
                            trailing: selected
                                ? Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                                : Icon(Icons.circle_outlined, color: Colors.grey.withValues(alpha: 0.3), size: 20),
                            onTap: () => setState(() => _courseId = course.id),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ],
            ),

            SizedBox(height: 16),

            // ===== 备忘 =====
            _buildCard(
              children: [
                TextFormField(
                  controller: _memoCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    icon: Icon(Icons.note_alt_outlined, color: Colors.grey),
                    labelText: '备忘（可选）',
                    hintText: '记录特殊事项...',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );

  // ===== 辅助组件 =====

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
  );

  Widget _buildCard({required List<Widget> children}) => Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(children: children),
    ),
  );

  String _repeatLabel(RepeatType t) => {
    RepeatType.none: '不重复',
    RepeatType.daily: '每天',
    RepeatType.weekly: '每周',
    RepeatType.custom: '自定义',
  }[t] ?? '';

  Color _typeColor(ScheduleType t) => {
    'nursery': AppColors.scheduleNursery,
    'sports': AppColors.scheduleSports,
    'language': AppColors.scheduleLanguage,
    'medical': AppColors.scheduleMedical,
    'school': AppColors.scheduleSchool,
    'general': AppColors.scheduleGeneral,
  }[t.name] ?? AppColors.scheduleGeneral;

  String _typeLabel(ScheduleType t) =>
      {
        'school': '上学',
        'nursery': '托班',
        'sports': '运动课',
        'language': '语言训练',
        'medical': '医疗',
        'general': '通用',
      }[t.name] ??
      '通用';

  String _typeIcon(ScheduleType t) =>
      {
        'school': '🏫',
        'nursery': '🏭',
        'sports': '⚽',
        'language': '💬',
        'medical': '🏥',
        'general': '📋',
      }[t.name] ??
      '📋';

  /// 将分钟对齐到 minuteInterval 的倍数
  DateTime _roundToInterval(DateTime dt, int interval) {
    final rounded = (dt.minute / interval).round() * interval;
    return DateTime(dt.year, dt.month, dt.day, dt.hour, rounded % 60);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _dateTime : (_endTime ?? _dateTime);
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _dateTime = DateTime(date.year, date.month, date.day, _dateTime.hour, _dateTime.minute);
      } else {
        final t = _endTime ?? _dateTime.add(Duration(hours: 1));
        _endTime = DateTime(date.year, date.month, date.day, t.hour, t.minute);
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _dateTime : (_endTime ?? _dateTime.add(Duration(hours: 1)));
    final initial = _roundToInterval(current, 5);
    DateTime temp = initial;
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text('取消', style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: Text('确定', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () {
                    setState(() {
                      if (isStart) {
                        _dateTime = DateTime(_dateTime.year, _dateTime.month, _dateTime.day, temp.hour, temp.minute);
                      } else {
                        final d = _endTime ?? _dateTime;
                        _endTime = DateTime(d.year, d.month, d.day, temp.hour, temp.minute);
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initial,
                use24hFormat: true,
                minuteInterval: 5,
                onDateTimeChanged: (v) => temp = v,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
