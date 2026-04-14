import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/medical_provider.dart';
import '../utils/app_theme.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('健康管理', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: Icon(Icons.add_circle_outline), onPressed: () => _showAddRecordDialog())
        ],
      ),
      body: Consumer<MedicalProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading) return Center(child: CircularProgressIndicator());
          
          return RefreshIndicator(
            onRefresh: () => provider.loadRecords(),
            child: provider.records.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_hospital_outlined, size: 64, color: AppColors.textHint),
                    SizedBox(height: 12),
                    Text('暂无医疗记录', style: TextStyle(color: AppColors.textHint)),
                    SizedBox(height: 8),
                    TextButton(onPressed: _showAddRecordDialog, child: Text('添加记录'))
                  ],
                ))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: provider.records.length,
                  itemBuilder: (ctx, idx) => _MedicalCard(
                    record: provider.records[idx],
                    onDelete: () async {
                      await context.read<MedicalProvider>().deleteRecord(provider.records[idx].id);
                    },
                  ),
                ),
          );
        },
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

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 4),
          title: Row(children: [
            Icon(Icons.medical_services, color: AppColors.scheduleMedical),
            SizedBox(width: 8),
            Text('添加医疗记录')
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                  title: Text('${visitDate.year}-${visitDate.month.toString().padLeft(2,'0')}-${visitDate.day.toString().padLeft(2,'0')}'),
                  trailing: Icon(Icons.edit_calendar, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: visitDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => visitDate = date);
                    }
                  },
                ),
                Divider(),
                TextField(controller: hospitalCtrl, decoration: InputDecoration(prefixIcon: Icon(Icons.location_city), labelText: '医院名称')),
                TextField(controller: doctorCtrl, decoration: InputDecoration(prefixIcon: Icon(Icons.person), labelText: '医生姓名')),
                TextField(controller: diagnosisCtrl, maxLines: 2, decoration: InputDecoration(prefixIcon: Icon(Icons.assignment), labelText: '诊断结果')),
                TextField(controller: medicationCtrl, maxLines: 2, decoration: InputDecoration(prefixIcon: Icon(Icons.medication), labelText: '服药/治疗建议')),
                TextField(controller: notesCtrl, maxLines: 2, decoration: InputDecoration(prefixIcon: Icon(Icons.note_add), labelText: '备注')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.scheduleMedical),
              onPressed: () async {
                await context.read<MedicalProvider>().addRecord(MedicalRecord(
                  id: Uuid().v4(),
                  hospitalName: hospitalCtrl.text.trim(),
                  doctorName: doctorCtrl.text.trim(),
                  diagnosis: diagnosisCtrl.text.trim(),
                  medication: medicationCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                  visitDate: visitDate,
                ));
                if (mounted) Navigator.pop(context);
              },
              child: Text('保存记录'),
            )
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.scheduleMedical.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, color: AppColors.scheduleMedical, size: 22),
                    SizedBox(height: 2),
                    Text(
                      '${record.visitDate.month}/${record.visitDate.day}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.scheduleMedical),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record.hospitalName.isNotEmpty)
                      Text(record.hospitalName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))
                    else
                      Text('就诊记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    if (record.doctorName.isNotEmpty)
                      Row(children: [
                        Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                        SizedBox(width: 3),
                        Text(record.doctorName, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ]),
                    if (record.diagnosis.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Text(record.diagnosis, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ),
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (record.diagnosis.isNotEmpty)
                          Chip(
                            label: Text('诊断', style: TextStyle(fontSize: 11)),
                            backgroundColor: Colors.blue.shade50,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        if (record.medication.isNotEmpty)
                          Chip(
                            label: Text('用药建议', style: TextStyle(fontSize: 11)),
                            backgroundColor: Colors.orange.shade50,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                SizedBox(height: 16),

                // 头部
                Row(children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.scheduleMedical.withValues(alpha: 0.15),
                        AppColors.scheduleMedical.withValues(alpha: 0.05),
                      ]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.local_hospital, size: 28, color: AppColors.scheduleMedical),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.hospitalName.isNotEmpty ? record.hospitalName : '医疗记录',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${record.visitDate.year}年${record.visitDate.month}月${record.visitDate.day}日',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ]),

                Divider(height: 30),

                // 详情字段
                if (record.doctorName.isNotEmpty)
                  _DetailRow(icon: Icons.person, label: '医生', value: record.doctorName),
                if (record.diagnosis.isNotEmpty)
                  _DetailRow(icon: Icons.assignment, label: '诊断结果', value: record.diagnosis),
                if (record.medication.isNotEmpty)
                  _DetailRow(icon: Icons.medication_liquid_outlined, label: '治疗建议', value: record.medication),
                if (record.notes.isNotEmpty)
                  _DetailRow(icon: Icons.note, label: '备注', value: record.notes),

                // 图片展示
                if (record.reportImagePaths.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('报告图片', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: record.reportImagePaths.map((path) {
                        return Container(
                          width: 200,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: path.startsWith('/')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(path, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_outlined, size: 36, color: AppColors.textHint),
                                    Text(path.split('/').last, style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                                  ],
                                ),
                              ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline),
                  label: Text('删除此记录'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
