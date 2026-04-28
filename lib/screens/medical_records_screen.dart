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
                onTap: _showAddRecordDialog,
              ),
            ],
          ),
          Expanded(
            child: Consumer<MedicalProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
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
                                onPressed: _showAddRecordDialog,
                                child: const Text('添加记录'),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          itemCount: provider.records.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final r = provider.records[idx];
                            return _MedicalCard(
                              record: r,
                              onDelete: () => provider.deleteRecord(r.id),
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

  Future<void> _showAddRecordDialog() async {
    final hospitalCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    final diagnosisCtrl = TextEditingController();
    final medicationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime visitDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('添加就诊记录'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: visitDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => visitDate = date);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppElegant.bgAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppElegant.hair, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            size: 16, color: AppElegant.inkSoft),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('yyyy 年 M 月 d 日').format(visitDate),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppElegant.ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppElegant.inkWhisper),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalCtrl,
                  decoration: const InputDecoration(labelText: '医院名称'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: doctorCtrl,
                  decoration: const InputDecoration(labelText: '医生姓名'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: diagnosisCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '诊断结果'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: medicationCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '用药 / 治疗建议'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await context.read<MedicalProvider>().addRecord(
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
                if (mounted) Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalCard extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onDelete;

  const _MedicalCard({required this.record, required this.onDelete});

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
                builder: (innerCtx) => OutlinedButton.icon(
                  onPressed: () {
                    onDelete();
                    Navigator.pop(innerCtx);
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
