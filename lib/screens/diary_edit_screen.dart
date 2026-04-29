import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/models.dart';
import '../providers/diary_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';

class DiaryEditScreen extends StatefulWidget {
  final Diary? diary;
  final bool readOnly;

  const DiaryEditScreen({super.key, this.diary, this.readOnly = false});

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _progressCtrl;
  late TextEditingController _improvementCtrl;

  late DateTime _selectedDate;
  DiaryStatus? _selectedStatus;
  List<Schedule> _daySchedules = [];
  List<String> _selectedScheduleIds = [];
  List<Map<String, dynamic>> _scheduleSnapshots = [];

  List<String> _imagePaths = [];
  List<String> _videoPaths = [];

  bool get _isEditing => widget.diary != null;
  bool get _readOnly => widget.readOnly;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.diary?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.diary?.content ?? '');
    _progressCtrl =
        TextEditingController(text: widget.diary?.progressPoints ?? '');
    _improvementCtrl =
        TextEditingController(text: widget.diary?.improvementPoints ?? '');

    _selectedDate = widget.diary?.diaryDate ?? DateTime.now();
    _selectedStatus = widget.diary?.qianqianStatus;

    _imagePaths = List.from(widget.diary?.imagePaths ?? []);
    _videoPaths = List.from(widget.diary?.videoPaths ?? []);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedulesForDate();
    });
  }

  Future<void> _loadSchedulesForDate() async {
    final provider = context.read<ScheduleProvider>();
    if (provider.schedules.isEmpty) {
      await provider.loadSchedules();
    }
    final schedules = provider.getSchedulesForDay(_selectedDate);
    setState(() {
      _daySchedules = schedules;
      if (_isEditing) {
        _selectedScheduleIds = List.from(widget.diary!.scheduleIds);
        _scheduleSnapshots = List.from(widget.diary!.scheduleSnapshots);
      } else {
        _selectedScheduleIds = schedules.map((s) => s.id).toList();
        _scheduleSnapshots =
            schedules.map((s) => _snapshotSchedule(s)).toList();
      }
    });
  }

  Map<String, dynamic> _snapshotSchedule(Schedule s) => {
        'id': s.id,
        'title': s.title,
        'scheduleType': s.scheduleType.name,
        'startTime': DateFormat.Hm().format(s.dateTime),
        if (s.location != null) 'location': s.location,
      };

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadSchedulesForDate();
    }
  }

  Future<void> _saveDiary() async {
    if (_selectedStatus == null) {
      _showSnack('请选择芊芊的心情状态');
      return;
    }
    if (_contentCtrl.text.trim().isEmpty) {
      _showSnack('请输入日记内容');
      return;
    }
    final provider = context.read<DiaryProvider>();
    final now = DateTime.now();
    HapticFeedback.mediumImpact();

    if (_isEditing) {
      await provider.updateDiary(Diary(
        id: widget.diary!.id,
        title: _titleCtrl.text.trim().isNotEmpty
            ? _titleCtrl.text.trim()
            : null,
        content: _contentCtrl.text.trim(),
        diaryDate: _selectedDate,
        qianqianStatus: _selectedStatus!,
        scheduleIds: _selectedScheduleIds,
        scheduleSnapshots: _scheduleSnapshots,
        progressPoints: _progressCtrl.text.trim().isNotEmpty
            ? _progressCtrl.text.trim()
            : null,
        improvementPoints: _improvementCtrl.text.trim().isNotEmpty
            ? _improvementCtrl.text.trim()
            : null,
        imagePaths: _imagePaths,
        videoPaths: _videoPaths,
        createdAt: widget.diary!.createdAt,
        updatedAt: now,
      ));
    } else {
      await provider.addDiary(Diary(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim().isNotEmpty
            ? _titleCtrl.text.trim()
            : null,
        content: _contentCtrl.text.trim(),
        diaryDate: _selectedDate,
        qianqianStatus: _selectedStatus!,
        scheduleIds: _selectedScheduleIds,
        scheduleSnapshots: _scheduleSnapshots,
        progressPoints: _progressCtrl.text.trim().isNotEmpty
            ? _progressCtrl.text.trim()
            : null,
        improvementPoints: _improvementCtrl.text.trim().isNotEmpty
            ? _improvementCtrl.text.trim()
            : null,
        imagePaths: _imagePaths,
        videoPaths: _videoPaths,
        createdAt: now,
        updatedAt: now,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除这篇日记？'),
        content: const Text('此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppElegant.rose),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<DiaryProvider>().deleteDiary(widget.diary!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  String _statusEmoji(DiaryStatus s) => const {
        DiaryStatus.good: '😊',
        DiaryStatus.normal: '😐',
        DiaryStatus.irritable: '😠',
      }[s]!;

  String _statusLabel(DiaryStatus s) => const {
        DiaryStatus.good: '愉悦',
        DiaryStatus.normal: '平静',
        DiaryStatus.irritable: '烦躁',
      }[s]!;

  Color _statusColor(DiaryStatus s) => {
        DiaryStatus.good: AppElegant.sage,
        DiaryStatus.normal: AppElegant.sand,
        DiaryStatus.irritable: AppElegant.rose,
      }[s]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppElegant.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildNavBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHero(),
                          const SizedBox(height: 22),
                          _buildDateCard(),
                          const SizedBox(height: 16),
                          _buildMoodCard(),
                          const SizedBox(height: 16),
                          _buildScheduleCard(),
                          const SizedBox(height: 16),
                          _buildTitleField(),
                          const SizedBox(height: 16),
                          _buildContentCard(),
                          const SizedBox(height: 16),
                          _buildReflectionCard(),
                          const SizedBox(height: 16),
                          _buildMediaCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_readOnly)
            ElegantFloatingBar(
              child: ElegantPrimaryButton(
                label: _isEditing ? '保存更改' : '发布日记',
                onPressed: _saveDiary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return ElegantNavBar(
      title: _isEditing ? (_readOnly ? '日记' : '编辑') : '写日记',
      actions: _isEditing && _readOnly
          ? [
              ElegantCircleIconButton(
                icon: Icons.edit_outlined,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryEditScreen(
                      diary: widget.diary,
                      readOnly: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElegantCircleIconButton(
                icon: Icons.delete_outline,
                onTap: _confirmDelete,
              ),
            ]
          : null,
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing
                ? (_readOnly ? '回顾此日' : '修改这一天')
                : '记录此刻的心情',
            style: AppText.heroHint,
          ),
          const SizedBox(height: 10),
          Text(
            DateFormat('M月d日 · EEEE', 'zh_CN').format(_selectedDate),
            style: AppText.heroTitle,
          ),
          const SizedBox(height: 10),
          Container(height: 1, width: 40, color: AppElegant.accent),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return _card(
      children: [
        const ElegantCardHeader(icon: Icons.event_outlined, label: '日期'),
        const SizedBox(height: 4),
        ElegantRowTile(
          label: '记录日期',
          value: DateFormat('yyyy 年 M 月 d 日', 'zh_CN').format(_selectedDate),
          onTap: _readOnly ? null : _pickDate,
        ),
      ],
    );
  }

  Widget _buildMoodCard() {
    return _card(
      children: [
        const ElegantCardHeader(icon: Icons.mood_outlined, label: '心情'),
        const SizedBox(height: 14),
        Row(
          children: DiaryStatus.values.map((s) {
            final selected = _selectedStatus == s;
            final color = _statusColor(s);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: s != DiaryStatus.values.last ? 8 : 0),
                child: GestureDetector(
                  onTap: _readOnly
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedStatus = s);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.08)
                          : AppElegant.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? color.withValues(alpha: 0.6)
                            : AppElegant.hair,
                        width: selected ? 1 : 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(_statusEmoji(s),
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text(
                          _statusLabel(s),
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? color : AppElegant.inkSoft,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleCard() {
    return _card(
      children: [
        ElegantCardHeader(
          icon: Icons.link_outlined,
          label: '关联日程',
          trailing: Text(
            '${_selectedScheduleIds.length}/${_daySchedules.length}',
            style: const TextStyle(
              fontSize: 11,
              color: AppElegant.inkSoft,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_daySchedules.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppElegant.bgAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 14, color: AppElegant.inkFaint),
                SizedBox(width: 8),
                Text(
                  '当天没有日程',
                  style: TextStyle(fontSize: 12, color: AppElegant.inkFaint),
                ),
              ],
            ),
          )
        else
          Column(
            children: _daySchedules.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final selected = _selectedScheduleIds.contains(s.id);
              return Column(
                children: [
                  if (idx > 0) const ElegantDivider(),
                  InkWell(
                    onTap: _readOnly
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (selected) {
                                _selectedScheduleIds.remove(s.id);
                                _scheduleSnapshots.removeWhere(
                                    (snap) => snap['id'] == s.id);
                              } else {
                                _selectedScheduleIds.add(s.id);
                                _scheduleSnapshots.add(_snapshotSchedule(s));
                              }
                            });
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 22,
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppElegant.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${DateFormat.Hm().format(s.dateTime)}${s.location != null && s.location!.isNotEmpty ? " · ${s.location}" : ""}',
                                  style: AppText.meta,
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppElegant.accent
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? AppElegant.accent
                                    : AppElegant.hair,
                                width: 1,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTitleField() {
    return _card(
      children: [
        const ElegantCardHeader(icon: Icons.title_rounded, label: '标题（可选）'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          readOnly: _readOnly,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppElegant.ink,
            height: 1.4,
          ),
          decoration: const InputDecoration(
            hintText: '给日记起个标题…',
            hintStyle: TextStyle(
              color: AppElegant.inkWhisper,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.symmetric(vertical: 6),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return _card(
      children: [
        const ElegantCardHeader(
            icon: Icons.edit_note_outlined, label: '日记 *'),
        const SizedBox(height: 8),
        TextField(
          controller: _contentCtrl,
          readOnly: _readOnly,
          maxLines: 8,
          minLines: 5,
          style: const TextStyle(
            fontSize: 14,
            color: AppElegant.ink,
            height: 1.8,
          ),
          decoration: const InputDecoration(
            hintText: '记录今天的精彩时刻…',
            hintStyle: TextStyle(
              color: AppElegant.inkWhisper,
              fontSize: 14,
              height: 1.8,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildReflectionCard() {
    return _card(
      children: [
        const ElegantCardHeader(
            icon: Icons.auto_graph_outlined, label: '复盘'),
        const SizedBox(height: 10),
        _reflectionField(
          icon: '+',
          color: AppElegant.sage,
          label: '进步点',
          controller: _progressCtrl,
          hint: '今天有哪些进步呢？',
        ),
        const SizedBox(height: 12),
        _reflectionField(
          icon: '△',
          color: AppElegant.sand,
          label: '可以做得更好',
          controller: _improvementCtrl,
          hint: '哪些地方可以改进？',
        ),
      ],
    );
  }

  Widget _reflectionField({
    required String icon,
    required Color color,
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppElegant.inkSoft,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: TextField(
            controller: controller,
            readOnly: _readOnly,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(
              fontSize: 13,
              color: AppElegant.ink,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppElegant.inkWhisper,
                fontSize: 13,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard() {
    return _card(
      children: [
        const ElegantCardHeader(
            icon: Icons.collections_outlined, label: '媒体'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _mediaTile(
                    icon: Icons.image_outlined,
                    label: '图片',
                    count: _imagePaths.length,
                    max: 5,
                    onTap:
                        _readOnly ? null : () => _pickMedia('image'))),
            const SizedBox(width: 10),
            Expanded(
                child: _mediaTile(
                    icon: Icons.videocam_outlined,
                    label: '视频',
                    count: _videoPaths.length,
                    max: 2,
                    onTap:
                        _readOnly ? null : () => _pickMedia('video'))),
          ],
        ),
        if (_imagePaths.isNotEmpty) ...[
          const SizedBox(height: 14),
          _mediaPreview('image'),
        ],
        if (_videoPaths.isNotEmpty) ...[
          const SizedBox(height: 14),
          _mediaPreview('video'),
        ],
      ],
    );
  }

  Widget _mediaTile({
    required IconData icon,
    required String label,
    required int count,
    required int max,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppElegant.bgAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppElegant.hair, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color: onTap != null
                    ? AppElegant.ink
                    : AppElegant.inkFaint),
            const SizedBox(height: 6),
            Text(
              '$label $count/$max',
              style: TextStyle(
                fontSize: 11,
                color: onTap != null
                    ? AppElegant.ink
                    : AppElegant.inkFaint,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(String type) async {
    if (type == 'image' && _imagePaths.length >= 5) {
      _showSnack('最多添加 5 张图片');
      return;
    }
    if (type == 'video' && _videoPaths.length >= 2) {
      _showSnack('最多添加 2 个视频');
      return;
    }
    try {
      if (type == 'image') {
        await _pickImages();
      } else if (type == 'video') {
        await _pickVideo();
      }
    } catch (e) {
      if (mounted) _showSnack('选择失败：$e');
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remaining = 5 - _imagePaths.length;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppElegant.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ElegantSheetHandle(),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppElegant.ink),
              title: const Text('从相册选择'),
              onTap: () async {
                Navigator.pop(context);
                final files = await picker.pickMultiImage(
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 85,
                );
                if (mounted) {
                  final add =
                      files.length > remaining ? remaining : files.length;
                  setState(() {
                    for (var i = 0; i < add; i++) {
                      _imagePaths.add(files[i].path);
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppElegant.ink),
              title: const Text('拍照'),
              onTap: () async {
                Navigator.pop(context);
                final file = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 85,
                );
                if (file != null && mounted) {
                  setState(() => _imagePaths.add(file.path));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppElegant.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ElegantSheetHandle(),
            ListTile(
              leading: const Icon(Icons.video_library_outlined,
                  color: AppElegant.ink),
              title: const Text('从相册选择'),
              onTap: () async {
                Navigator.pop(context);
                final file =
                    await picker.pickVideo(source: ImageSource.gallery);
                if (file != null && mounted) {
                  setState(() => _videoPaths.add(file.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined,
                  color: AppElegant.ink),
              title: const Text('录制视频'),
              onTap: () async {
                Navigator.pop(context);
                final file =
                    await picker.pickVideo(source: ImageSource.camera);
                if (file != null && mounted) {
                  setState(() => _videoPaths.add(file.path));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _removeMedia(String type, String path) {
    setState(() {
      if (type == 'image') _imagePaths.remove(path);
      if (type == 'video') _videoPaths.remove(path);
    });
  }

  Widget _mediaPreview(String type) {
    final paths = type == 'image' ? _imagePaths : _videoPaths;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: paths.map((path) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: type == 'image'
                  ? Image.file(
                      File(path),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: AppElegant.bgAlt,
                        child: const Icon(Icons.broken_image_outlined,
                            size: 24, color: AppElegant.inkFaint),
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppElegant.bgAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.play_circle_outline_rounded,
                          size: 28, color: AppElegant.inkSoft),
                    ),
            ),
            if (!_readOnly)
              Positioned(
                right: 2,
                top: 2,
                child: GestureDetector(
                  onTap: () => _removeMedia(type, path),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppElegant.ink.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _card({required List<Widget> children}) {
    return ElegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _progressCtrl.dispose();
    _improvementCtrl.dispose();
    super.dispose();
  }
}
