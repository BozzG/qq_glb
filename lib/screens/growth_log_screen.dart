import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/growth_log_provider.dart';
import '../utils/app_theme.dart';

class GrowthLogScreen extends StatefulWidget {
  const GrowthLogScreen({super.key});
  @override
  State<GrowthLogScreen> createState() => _GrowthLogScreenState();
}

class _GrowthLogScreenState extends State<GrowthLogScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GrowthLogProvider>().loadLogs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('成长日志', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [Tab(text: '日志列表'), Tab(text: '数据分析')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: Icon(Icons.edit_note, color: Colors.white),
        onPressed: () => _showAddLogDialog(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLogList(), _buildDataAnalysis()],
      ),
    );
  }

  Widget _buildLogList() {
    return Consumer<GrowthLogProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_stories, size: 64, color: AppColors.textHint),
                SizedBox(height: 12),
                Text('还没有成长日志哦~', style: TextStyle(color: AppColors.textHint)),
                SizedBox(height: 4),
                Text('点击右下角按钮记录芊芊的精彩瞬间',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadLogs(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: provider.logs.length,
            itemBuilder: (ctx, idx) {
              final log = provider.logs[idx];
              return _buildLogCard(log);
            },
          ),
        );
      },
    );
  }

  Widget _buildLogCard(GrowthLog log) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片预览占位
            if (log.imagePaths.isNotEmpty)
              SizedBox(
                height: 180,
                child: Center(
                  child: Icon(Icons.image_outlined, size: 48, color: AppColors.textHint),
                ),
              ),
            // 内容区域
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    children: [
                      Text(_moodEmoji(log.mood), style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(log.title,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  // 内容
                  if (log.content.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        log.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                      ),
                    ),
                  // 底部信息栏
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        ...log.tags.take(3).map((tag) => Container(
                              margin: EdgeInsets.only(right: 6),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('#$tag',
                                  style: TextStyle(fontSize: 11, color: AppColors.primary)),
                            )),
                        Spacer(),
                        Icon(Icons.access_time, size: 13, color: AppColors.textHint),
                        SizedBox(width: 3),
                        Text(_formatDate(log.createdAt),
                            style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataAnalysis() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.analytics, color: AppColors.info),
                    SizedBox(width: 8),
                    Text('成长数据分析', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ]),
                  SizedBox(height: 16),
                  Consumer<GrowthLogProvider>(
                    builder: (ctx, provider, _) => Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _AnaCard(icon: Icons.article, label: '总日志数',
                            value: '${provider.logs.length}', color: AppColors.primary),
                        _AnaCard(icon: Icons.image, label: '含图片',
                            value: '${provider.logs.where((l) => l.imagePaths.isNotEmpty).length}',
                            color: AppColors.secondary),
                        _AnaCard(icon: Icons.tag, label: '标签总数',
                            value: '${provider.logs.expand((l) => l.tags).toSet().length}',
                            color: AppColors.accent),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('心情分布', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Consumer<GrowthLogProvider>(
                    builder: (ctx, provider, _) => Column(
                      children: Mood.values.map((mood) {
                        final count = provider.logs.where((l) => l.mood == mood).length;
                        final total = provider.logs.length;
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text(_moodEmoji(mood), style: TextStyle(fontSize: 22)),
                              SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: total > 0 ? count / total : 0,
                                    minHeight: 10,
                                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation(
                                        AppColors.cartoonPalette[Mood.values.indexOf(mood)]),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('$count篇',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }).toList(),
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

  Future<void> _showAddLogDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    var selectedMood = Mood.happy;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Icon(Icons.edit_note, color: AppColors.primary),
            SizedBox(width: 8),
            Text('写成长日志'),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(prefixIcon: Icon(Icons.title), labelText: '标题'),
                  autofocus: true,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.description),
                    labelText: '今天发生了什么有趣的事呢？...',
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: tagsCtrl,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.tag), labelText: '标签（逗号分隔，如：运动,进步）'),
                ),
                SizedBox(height: 12),
                Text('芊芊的心情', style: TextStyle(fontSize: 13)),
                SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: Mood.values.map((m) => ChoiceChip(
                    label: Text('${_moodEmoji(m)} ${_moodLabel(m)}'),
                    selected: selectedMood == m,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (_) => setState(() => selectedMood = m),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await context.read<GrowthLogProvider>().addLog(GrowthLog(
                  id: const Uuid().v4(),
                  title: titleCtrl.text.trim(),
                  content: contentCtrl.text.trim(),
                  mood: selectedMood,
                  tags: tagsCtrl.text
                      .split(',')
                      .where((t) => t.trim().isNotEmpty)
                      .map((t) => t.trim())
                      .toList(),
                ));
                if (mounted) Navigator.pop(context);
              },
              child: Text('发布'),
            ),
          ],
        ),
      ),
    );
  }

  String _moodEmoji(Mood m) =>
      {'happy': '😊', 'sad': '😢', 'excited': '🤩', 'calm': '😌', 'proud': '😎', 'tired': '😴'}[m.name] ?? '😊';

  String _moodLabel(Mood m) =>
      {'happy': '开心', 'sad': '难过', 'excited': '兴奋', 'calm': '平静', 'proud': '自豪', 'tired': '疲惫'}[m.name] ?? '开心';

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

class _AnaCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AnaCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
