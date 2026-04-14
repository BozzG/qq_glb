import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/memo_provider.dart';
import '../utils/app_theme.dart';

class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});
  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<MemoProvider>().loadMemos()); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('备忘录', style: TextStyle(color: Colors.white)), actions: [
      IconButton(icon: Icon(Icons.add), onPressed: () => _showAddMemoDialog())
    ]),
    body: Consumer<MemoProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) return Center(child: CircularProgressIndicator());

        final activeMemos = provider.memos.where((m) => !m.isCompleted).toList();
        final completedMemos = provider.memos.where((m) => m.isCompleted).toList();

        return RefreshIndicator(
          onRefresh: () => provider.loadMemos(),
          child: (activeMemos.isEmpty && completedMemos.isEmpty)
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.note_outlined, size: 64, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('还没有备忘记录', style: TextStyle(color: AppColors.textHint))
            ]))
            : ListView(padding: EdgeInsets.all(16), children: [
                if (activeMemos.isNotEmpty) ...[
                  Text('待完成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  SizedBox(height: 8),
                  ...activeMemos.map((m) => _MemoCard(memo: m,
                    onToggle: () async { await context.read<MemoProvider>().updateMemo(Memo(id: m.id, title: m.title, content: m.content, reminderTime: m.reminderTime, isCompleted: true, createdAt: m.createdAt)); },
                    onDelete: () async { await context.read<MemoProvider>().deleteMemo(m.id); },
                  )),
                  SizedBox(height: 20),
                ],
                if (completedMemos.isNotEmpty) ...[
                  Text('已完成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                  SizedBox(height: 8),
                  ...completedMemos.map((m) => _MemoCard(memo: m,
                    onToggle: () async { await context.read<MemoProvider>().updateMemo(Memo(id: m.id, title: m.title, content: m.content, reminderTime: m.reminderTime, isCompleted: false, createdAt: m.createdAt)); },
                    onDelete: () async { await context.read<MemoProvider>().deleteMemo(m.id); },
                  )),
                ]
              ]),
        );
      },
    ),
  );

  Future<void> _showAddMemoDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [Icon(Icons.note_add_outlined, color: AppColors.primary), SizedBox(width: 8), Text('添加备忘')]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: InputDecoration(labelText: '标题（可选）'), autofocus: true),
          SizedBox(height: 10),
          TextField(controller: contentCtrl, maxLines: 4, decoration: InputDecoration(labelText: '备忘内容')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
        FilledButton(onPressed: () async {
          if (contentCtrl.text.trim().isEmpty) return;
          await context.read<MemoProvider>().addMemo(Memo(
            id: const Uuid().v4(),
            title: titleCtrl.text.trim(),
            content: contentCtrl.text.trim(),
          ));
          if (mounted) Navigator.pop(context);
        }, child: Text('添加'))
      ],
    ));
  }
}

class _MemoCard extends StatelessWidget {
  final Memo memo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MemoCard({required this.memo, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key(memo.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20),
      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
      child: Icon(Icons.delete_outline, color: AppColors.error),
    ),
    confirmDismiss: (direction) async {
      return await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: Text('确认删除？'),
        content: Text("确定要删除这条备忘吗？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('删除', style: TextStyle(color: AppColors.error))),
        ],
      )) ?? false;
    },
    onDismissed: (_) => onDelete(),
    child: Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 26,
              height: 26,
              margin: EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: memo.isCompleted ? AppColors.success : AppColors.primary.withValues(alpha: 0.5), width: 2),
              ),
              child: memo.isCompleted ? Center(child: Icon(Icons.check, size: 16, color: AppColors.success)) : null,
            ),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (memo.title != null && memo.title!.isNotEmpty)
                Text(memo.title!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, decoration: memo.isCompleted ? TextDecoration.lineThrough : null, color: memo.isCompleted ? AppColors.textHint : AppColors.textPrimary)),
              Text(memo.content, style: TextStyle(fontSize: 13, color: memo.isCompleted ? AppColors.textHint : AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
              if (memo.reminderTime != null)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(children: [
                    Icon(Icons.alarm, size: 13, color: AppColors.warning),
                    SizedBox(width: 3),
                    Text(_formatReminder(memo.reminderTime!), style: TextStyle(fontSize: 11, color: AppColors.warning))
                  ]),
                ),
            ],
          )),
        ]),
      ),
    ),
  );

  String _formatReminder(DateTime t) => '${t.month}月${t.day}日 ${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')} 提醒';
}
