import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/course_provider.dart';
import '../utils/app_theme.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});
  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('课时管理', style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(icon: Icon(Icons.add_circle_outline), onPressed: () => _showAddCourseDialog())
      ],
    ),
    body: Consumer<CourseProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) return Center(child: CircularProgressIndicator());

        return RefreshIndicator(
          onRefresh: () => provider.loadCourses(),
          child: provider.courses.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.school_outlined, size: 64, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('还没有添加课程', style: TextStyle(color: AppColors.textHint)),
              TextButton(onPressed: _showAddCourseDialog, child: Text('添加课程'))
            ]))
            : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: provider.courses.length,
              separatorBuilder: (_, __) => SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final course = provider.courses[idx];
                return _CourseCard(
                  course: course,
                  consumptions: provider.getConsumptionsForCourse(course.id),
                );
              },
            ),
        );
      },
    ),
  );

  Future<void> _showAddCourseDialog() async {
    final nameCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '0');
    final typeCtrl = ValueNotifier<CourseType>(CourseType.other);

    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [Icon(Icons.add_circle, color: AppColors.primary), SizedBox(width: 8), Text('添加课程')]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(prefixIcon: Icon(Icons.book), labelText: '课程名称'), autofocus: true),
          SizedBox(height: 12),
          TextField(controller: hoursCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(prefixIcon: Icon(Icons.timer), labelText: '总课时数')),
          SizedBox(height: 12),
          ValueListenableBuilder(valueListenable: typeCtrl,
            builder: (ctx, val, _) => SegmentedButton<CourseType>(
              segments: [
                ButtonSegment(value: CourseType.sports, label: Text('运动课'), icon: Icon(Icons.sports_soccer, size: 16)),
                ButtonSegment(value: CourseType.language, label: Text('语言训练'), icon: Icon(Icons.record_voice_over, size: 16)),
                ButtonSegment(value: CourseType.other, label: Text('其他'), icon: Icon(Icons.more_horiz, size: 16)),
              ],
              selected: {val},
              onSelectionChanged: (v) => typeCtrl.value = v.first,
            )
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
        FilledButton(onPressed: () async {
          if (nameCtrl.text.trim().isEmpty) return;
          await context.read<CourseProvider>().addCourse(Course(
            id: const Uuid().v4(),
            name: nameCtrl.text.trim(),
            courseType: typeCtrl.value,
            totalHours: double.tryParse(hoursCtrl.text) ?? 0,
          ));
          if (mounted) Navigator.pop(context);
        }, child: Text('添加'))
      ],
    ));
  }
}

class _CourseCard extends StatefulWidget {
  final Course course;
  final List<CourseConsumption> consumptions;

  const _CourseCard({required this.course, required this.consumptions});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _expanded = !_expanded),
    child: AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Color(widget.course.color).withValues(alpha: 0.08), blurRadius: 14, offset: Offset(0,4))],
      ),
      child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        // 课程信息行
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(
            color: Color(widget.course.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ), child: Icon(_courseIcon(widget.course.courseType), size: 24, color: Color(widget.course.color))),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.course.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('${_typeName(widget.course.courseType)} · ${widget.course.unitName}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),

          // 进度圆环
          SizedBox(width: 52, height: 52,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: widget.course.usagePercent, strokeWidth: 5, backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(Color(widget.course.color))),
              Text('${widget.course.remainingHours.toInt()}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ])),
        ]),

        // 进度条
        Padding(padding: EdgeInsets.only(top: 10), child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: widget.course.usagePercent, minHeight: 6,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(Color(widget.course.color))),
        )),

        // 数值显示
        Padding(padding: EdgeInsets.only(top: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatItem(label: '总课时', value: '${widget.course.totalHours.toInt()}'),
          _StatItem(label: '已用', value: '${widget.course.usedHours.toInt()}'),
          _StatItem(label: '剩余', value: '${widget.course.remainingHours.toInt()}', highlight: true),
        ])),

        // 展开区域 - 消耗记录
        if (_expanded) ...[
          Divider(), SizedBox(height: 8),
          ...widget.consumptions.take(20).map((c) => ListTile(dense: true, contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 14, backgroundColor: c.consumptionType == ConsumptionType.auto ? AppColors.info.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
              child: Icon(c.consumptionType == ConsumptionType.auto ? Icons.auto_mode : Icons.edit, size: 14, color: c.consumptionType == ConsumptionType.auto ? AppColors.info : AppColors.warning)),
            title: Text(c.note ?? (c.consumptionType == ConsumptionType.auto ? '自动扣减' : '手动调整'), style: TextStyle(fontSize: 13)),
            subtitle: Text('${c.consumedAmount > 0 ? '-' : '+'}${c.consumedAmount.abs().toStringAsFixed(1)} ${widget.course.unitName}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c.consumedAmount > 0 ? AppColors.error : AppColors.success)),
          )),
          if (widget.consumptions.isEmpty)
            Padding(padding: EdgeInsets.all(12), child: Text('暂无消耗记录', style: TextStyle(color: AppColors.textHint, fontSize: 13))),

          // 手动调整按钮
          SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => _showAdjustDialog(context), icon: Icon(Icons.tune), label: Text('手动调整课时'))
        ],

        // 展开/收起箭头
        Align(alignment: Alignment.centerRight, child: IconButton(
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => setState(() => _expanded = !_expanded),
        )),
      ])),
    ),
  );

  IconData _courseIcon(CourseType t) => t == CourseType.sports ? Icons.sports_soccer : t == CourseType.language ? Icons.record_voice_over : Icons.menu_book;
  String _typeName(CourseType t) => {'sports': '运动课', 'language': '语言训练', 'other': '其他'}[t.name] ?? '其他';

  Future<void> _showAdjustDialog(BuildContext ctx) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    await showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('调整课时'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: amountCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '调整数量（正数增加，负数减少）')),
        TextField(controller: noteCtrl, decoration: InputDecoration(labelText: '备注（可选）')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
        FilledButton(onPressed: () async {
          await context.read<CourseProvider>().adjustHours(widget.course.id, double.tryParse(amountCtrl.text) ?? 0, note: noteCtrl.text.trim());
          if (mounted) Navigator.pop(context);
        }, child: Text('确认')),
      ],
    ));
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatItem({required this.label, required this.value, this.highlight = false});

  @override Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: highlight ? AppColors.primary : AppColors.textPrimary)),
    Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}
