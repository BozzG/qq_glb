import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/medical_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});
  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicalProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElegantScaffold(
      body: Column(
        children: [
          ElegantNavBar(
            title: '健康管理',
            actions: [
              ElegantCircleIconButton(
                icon: Icons.add_rounded,
                onTap: () => _showRecordForm(),
              ),
            ],
          ),
          Expanded(
            child: Consumer<MedicalProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading) {
                  return ElegantLoading.center();
                }
                return RefreshIndicator(
                  color: AppElegant.accent,
                  onRefresh: () => provider.loadRecords(),
                  child: provider.records.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            ElegantEmpty(
                              icon: Icons.medical_services_outlined,
                              label: '暂无医疗记录',
                              hint: '从 + 按钮添加就诊记录',
                              action: OutlinedButton(
                                onPressed: () => _showRecordForm(),
                                child: const Text('添加记录'),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          itemCount: provider.records.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final r = provider.records[idx];
                            return _MedicalCard(
                              record: r,
                              onDelete: () => provider.deleteRecord(r.id),
                              onEdit: () => _showRecordForm(record: r),
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

  Future<void> _showRecordForm({MedicalRecord? record}) async {
    final isEditing = record != null;
    final hospitalCtrl = TextEditingController(text: record?.hospitalName ?? '');
    final doctorCtrl = TextEditingController(text: record?.doctorName ?? '');
    final diagnosisCtrl = TextEditingController(text: record?.diagnosis ?? '');
    final medicationCtrl = TextEditingController(text: record?.medication ?? '');
    final notesCtrl = TextEditingController(text: record?.notes ?? '');
    DateTime visitDate = record?.visitDate ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppElegant.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (innerCtx, setInnerState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: ElegantSheetHandle()),
                      const SizedBox(height: 16),
                      // Hero 标题
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? '编辑就诊' : '新增就诊',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppElegant.inkSoft,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isEditing ? '修改就诊记录' : '添加就诊记录',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppElegant.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                            height: 1, width: 32, color: AppElegant.accent),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 日期
                              _sheetLabel('就诊日期'),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final date = await ElegantDatePicker.show(
                                    innerCtx,
                                    initial: visitDate,
                                    minimumDate: DateTime(2020),
                                    maximumDate: DateTime(2030),
                                    title: '就诊日期',
                                  );
                                  if (date != null) {
                                    setInnerState(() => visitDate = date);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppElegant.bgAlt,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppElegant.hair, width: 0.5),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_outlined,
                                          size: 16, color: AppElegant.inkSoft),
                                      const SizedBox(width: 10),
                                      Text(
                                        DateFormat('yyyy 年 M 月 d 日')
                                            .format(visitDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppElegant.ink,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.chevron_right,
                                          size: 16,
                                          color: AppElegant.inkWhisper),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _sheetLabel('医院名称'),
                              const SizedBox(height: 8),
                              _sheetInput(
                                controller: hospitalCtrl,
                                hint: '例：某某医院儿科',
                              ),
                              const SizedBox(height: 16),
                              _sheetLabel('医生姓名'),
                              const SizedBox(height: 8),
                              _sheetInput(
                                controller: doctorCtrl,
                                hint: '主治医生',
                              ),
                              const SizedBox(height: 16),
                              _sheetLabel('诊断结果'),
                              const SizedBox(height: 8),
                              _sheetInput(
                                controller: diagnosisCtrl,
                                hint: '医生给出的诊断',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              _sheetLabel('用药 / 治疗建议'),
                              const SizedBox(height: 8),
                              _sheetInput(
                                controller: medicationCtrl,
                                hint: '用药方案、治疗建议',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              _sheetLabel('备注'),
                              const SizedBox(height: 8),
                              _sheetInput(
                                controller: notesCtrl,
                                hint: '其他需要记录的信息',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      // 底部按钮
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Row(
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
                                label: '保存',
                                height: 50,
                                onPressed: () async {
                                  if (hospitalCtrl.text.trim().isEmpty &&
                                      diagnosisCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(sheetCtx)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text('请至少填写医院或诊断')),
                                    );
                                    return;
                                  }
                                  final provider =
                                      context.read<MedicalProvider>();
                                  if (isEditing) {
                                    await provider.updateRecord(
                                      MedicalRecord(
                                        id: record.id,
                                        scheduleId: record.scheduleId,
                                        hospitalName: hospitalCtrl.text.trim(),
                                        doctorName: doctorCtrl.text.trim(),
                                        diagnosis: diagnosisCtrl.text.trim(),
                                        medication: medicationCtrl.text.trim(),
                                        reportImagePaths:
                                            record.reportImagePaths,
                                        notes: notesCtrl.text.trim(),
                                        visitDate: visitDate,
                                        createdAt: record.createdAt,
                                      ),
                                    );
                                  } else {
                                    await provider.addRecord(
                                      MedicalRecord(
                                        id: const Uuid().v4(),
                                        hospitalName: hospitalCtrl.text.trim(),
                                        doctorName: doctorCtrl.text.trim(),
                                        diagnosis: diagnosisCtrl.text.trim(),
                                        medication: medicationCtrl.text.trim(),
                                        notes: notesCtrl.text.trim(),
                                        visitDate: visitDate,
                                      ),
                                    );
                                  }
                                  if (mounted && sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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

  Widget _sheetInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        color: AppElegant.ink,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppElegant.inkWhisper, fontSize: 14),
        filled: true,
        fillColor: AppElegant.bgAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppElegant.hair, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppElegant.accent, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _MedicalCard extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MedicalCard(
      {required this.record, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _showDetail(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppElegant.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppElegant.hair, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期
              Container(
                width: 52,
                height: 60,
                decoration: BoxDecoration(
                  color: AppElegant.rose.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppElegant.rose.withValues(alpha: 0.2),
                      width: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${record.visitDate.day}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppElegant.rose,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM', 'zh_CN').format(record.visitDate),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppElegant.rose,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.hospitalName.isNotEmpty
                          ? record.hospitalName
                          : '就诊记录',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppElegant.ink,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (record.doctorName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 11, color: AppElegant.inkFaint),
                          const SizedBox(width: 4),
                          Text(record.doctorName, style: AppText.meta),
                        ],
                      ),
                    ],
                    if (record.diagnosis.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        record.diagnosis,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppElegant.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (record.diagnosis.isNotEmpty)
                          const ElegantBadge(text: '诊断'),
                        if (record.medication.isNotEmpty)
                          ElegantBadge(
                              text: '用药', color: AppElegant.sand),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppElegant.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const Center(child: ElegantSheetHandle()),
              const SizedBox(height: 12),
              // 头部
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppElegant.rose.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: AppElegant.rose,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.hospitalName.isNotEmpty
                              ? record.hospitalName
                              : '医疗记录',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppElegant.ink,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('yyyy 年 M 月 d 日 · EEEE', 'zh_CN')
                              .format(record.visitDate),
                          style: AppText.meta,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const ElegantDivider(),
              const SizedBox(height: 16),

              if (record.doctorName.isNotEmpty)
                _detail(Icons.person_outline_rounded, '医生',
                    record.doctorName),
              if (record.diagnosis.isNotEmpty)
                _detail(Icons.assignment_outlined, '诊断结果',
                    record.diagnosis),
              if (record.medication.isNotEmpty)
                _detail(Icons.medication_outlined, '治疗建议',
                    record.medication),
              if (record.notes.isNotEmpty)
                _detail(Icons.edit_note_rounded, '备注', record.notes),

              if (record.reportImagePaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('报告图片',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppElegant.inkSoft,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: record.reportImagePaths.map((p) {
                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppElegant.bgAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppElegant.hair, width: 0.5),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: AppElegant.inkFaint,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Builder(
                builder: (innerCtx) => Column(
                  children: [
                    ElegantPrimaryButton(
                      label: '编辑此记录',
                      icon: Icons.edit_outlined,
                      height: 46,
                      onPressed: () {
                        Navigator.pop(innerCtx);
                        onEdit();
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await ElegantConfirmDialog.confirmDelete(
                          innerCtx,
                          title: '删除此记录？',
                          message: '此操作不可撤销，相关就诊信息将被永久删除。',
                        );
                        if (!ok) return;
                        onDelete();
                        if (innerCtx.mounted) Navigator.pop(innerCtx);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('删除此记录'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppElegant.rose,
                        side: BorderSide(
                            color: AppElegant.rose.withValues(alpha: 0.3),
                            width: 0.5),
                        minimumSize: const Size(double.infinity, 46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppElegant.inkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppElegant.inkSoft,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppElegant.ink,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
