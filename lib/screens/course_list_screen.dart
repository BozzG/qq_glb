import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/course_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';

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
  Widget build(BuildContext context) {
    return ElegantScaffold(
      body: Column(
        children: [
          ElegantNavBar(
            title: '课时管理',
            actions: [
              ElegantCircleIconButton(
                icon: Icons.add_rounded,
                onTap: _showAddCourseDialog,
              ),
            ],
          ),
          Expanded(
            child: Consumer<CourseProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  color: AppElegant.accent,
                  onRefresh: () => provider.loadCourses(),
                  child: provider.courses.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            ElegantEmpty(
                              icon: Icons.menu_book_outlined,
                              label: '还没有添加课程',
                              hint: '从 + 按钮添加第一门课程',
                              action: OutlinedButton(
                                onPressed: _showAddCourseDialog,
                                child: const Text('添加课程'),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          itemCount: provider.courses.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, idx) {
                            final course = provider.courses[idx];
                            return _CourseCard(
                              course: course,
                              consumptions: provider
                                  .getConsumptionsForCourse(course.id),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCourseDialog() async {
    final nameCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '0');
    final typeNotifier = ValueNotifier<CourseType>(CourseType.other);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppElegant.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: ElegantSheetHandle()),
                  const SizedBox(height: 16),
                  // Hero 标题
                  const Text(
                    '新增课程',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppElegant.inkSoft,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '添加课程',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppElegant.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, width: 32, color: AppElegant.accent),
                  const SizedBox(height: 20),
                  // 名称
                  _sheetLabel('课程名称'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppElegant.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: '例：钢琴一对一',
                      hintStyle: const TextStyle(
                          color: AppElegant.inkWhisper, fontSize: 14),
                      filled: true,
                      fillColor: AppElegant.bgAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppElegant.hair, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppElegant.accent, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 课时
                  _sheetLabel('总课时'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: hoursCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppElegant.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: const TextStyle(
                          color: AppElegant.inkWhisper, fontSize: 14),
                      filled: true,
                      fillColor: AppElegant.bgAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppElegant.hair, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppElegant.accent, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 类型
                  _sheetLabel('类型'),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<CourseType>(
                    valueListenable: typeNotifier,
                    builder: (ctx, val, _) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CourseType.values.map((t) {
                        return ElegantChip(
                          label: _typeName(t),
                          icon: _courseIcon(t),
                          selected: val == t,
                          onTap: () => typeNotifier.value = t,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 行动按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            side: const BorderSide(
                                color: AppElegant.hair, width: 0.5),
                            foregroundColor: AppElegant.ink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElegantPrimaryButton(
                          label: '添加',
                          height: 50,
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                const SnackBar(content: Text('请输入课程名称')),
                              );
                              return;
                            }
                            await context.read<CourseProvider>().addCourse(
                                  Course(
                                    id: const Uuid().v4(),
                                    name: nameCtrl.text.trim(),
                                    courseType: typeNotifier.value,
                                    totalHours:
                                        double.tryParse(hoursCtrl.text) ?? 0,
                                  ),
                                );
                            if (mounted && sheetCtx.mounted) {
                              Navigator.pop(sheetCtx);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppElegant.inkSoft,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      );
}

IconData _courseIcon(CourseType t) => const {
      CourseType.sports: Icons.sports_basketball_outlined,
      CourseType.interest: Icons.palette_outlined,
      CourseType.language: Icons.translate_outlined,
      CourseType.olympiad: Icons.emoji_events_outlined,
      CourseType.other: Icons.menu_book_outlined,
    }[t] ??
    Icons.menu_book_outlined;

String _typeName(CourseType t) => const {
      'sports': '运动',
      'interest': '兴趣',
      'language': '语言',
      'olympiad': '奥赛',
      'other': '其他',
    }[t.name] ??
    '其他';

class _CourseCard extends StatefulWidget {
  final Course course;
  final List<CourseConsumption> consumptions;

  const _CourseCard({required this.course, required this.consumptions});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final color = Color(course.color);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expanded = !_expanded);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppElegant.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppElegant.hair, width: 0.5),
          boxShadow: AppElegant.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_courseIcon(course.courseType),
                      size: 20, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppElegant.ink,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_typeName(course.courseType)} · ${course.unitName}',
                        style: AppText.meta,
                      ),
                    ],
                  ),
                ),
                Text(
                  course.remainingHours.toStringAsFixed(
                      course.remainingHours % 1 == 0 ? 0 : 1),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: AppElegant.ink,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    '剩余',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppElegant.inkSoft,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: course.usagePercent,
                minHeight: 4,
                backgroundColor: AppElegant.hairSoft,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniKV('总', course.totalHours),
                _miniKV('已用', course.usedHours),
                _miniKV('剩余', course.remainingHours, highlight: true),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppElegant.inkFaint,
                  size: 20,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 16),
              const ElegantDivider(),
              const SizedBox(height: 12),
              if (widget.consumptions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '暂无消耗记录',
                    style: AppText.meta,
                  ),
                )
              else
                ...widget.consumptions.take(20).map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: (c.consumptionType ==
                                          ConsumptionType.auto
                                      ? AppElegant.slate
                                      : AppElegant.sand)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              c.consumptionType == ConsumptionType.auto
                                  ? Icons.auto_awesome_rounded
                                  : Icons.edit_rounded,
                              size: 12,
                              color: c.consumptionType ==
                                      ConsumptionType.auto
                                  ? AppElegant.slate
                                  : AppElegant.sand,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c.note ??
                                  (c.consumptionType ==
                                          ConsumptionType.auto
                                      ? '自动扣减'
                                      : '手动调整'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppElegant.ink,
                              ),
                            ),
                          ),
                          Text(
                            '${c.consumedAmount > 0 ? '-' : '+'}${c.consumedAmount.abs().toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.consumedAmount > 0
                                  ? AppElegant.rose
                                  : AppElegant.sage,
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showAdjustDialog(context),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('手动调整课时'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppElegant.ink,
                  minimumSize: const Size(double.infinity, 44),
                  side:
                      const BorderSide(color: AppElegant.hair, width: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniKV(String label, double value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.meta),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: highlight ? AppElegant.ink : AppElegant.inkSoft,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Future<void> _showAdjustDialog(BuildContext ctx) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('调整课时'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '数量（+增加 / -减少）',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await context.read<CourseProvider>().adjustHours(
                    widget.course.id,
                    double.tryParse(amountCtrl.text) ?? 0,
                    note: noteCtrl.text.trim(),
                  );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
