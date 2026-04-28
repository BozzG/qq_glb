import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/diary_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';
import 'diary_edit_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadDiaries();
    });
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() =>
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() =>
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
  }

  List<Diary> _getDiariesForMonth() =>
      context.read<DiaryProvider>().getDiariesByMonth(_selectedMonth);

  Map<String, List<Diary>> _groupByDate(List<Diary> list) {
    final g = <String, List<Diary>>{};
    for (final d in list) {
      final key = DateFormat('yyyy-MM-dd').format(d.diaryDate);
      g.putIfAbsent(key, () => []).add(d);
    }
    return g;
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
    return ElegantScaffold(
      body: Column(
        children: [
          ElegantNavBar(
            title: '成长日记',
            actions: [
              ElegantCircleIconButton(
                icon: Icons.add_rounded,
                onTap: () => _navigateToEdit(null),
              ),
            ],
          ),
          _buildMonthSwitcher(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildMonthSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppElegant.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppElegant.hair, width: 0.5),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 22),
              color: AppElegant.ink,
              onPressed: _prevMonth,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      DateFormat('yyyy').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppElegant.inkSoft,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMMM', 'zh_CN').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppElegant.ink,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              color: AppElegant.ink,
              onPressed: _nextMonth,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<DiaryProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final monthDiaries = _getDiariesForMonth();
        if (monthDiaries.isEmpty) {
          return ElegantEmpty(
            icon: Icons.auto_stories_outlined,
            label: '本月还没有日记',
            hint: '记录成长的每一天',
            action: OutlinedButton(
              onPressed: () => _navigateToEdit(null),
              child: const Text('写第一篇'),
            ),
          );
        }
        final groups = _groupByDate(monthDiaries);
        final sortedDates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          itemCount: sortedDates.length,
          itemBuilder: (ctx, i) {
            final key = sortedDates[i];
            final day = DateTime.parse(key);
            final diaries = groups[key]!;
            return _DayGroup(
              date: day,
              diaries: diaries,
              statusEmoji: _statusEmoji,
              statusLabel: _statusLabel,
              statusColor: _statusColor,
              onTapDiary: _navigateToDetail,
              onLongPressDiary: _showMenu,
            );
          },
        );
      },
    );
  }

  void _showMenu(Diary diary) {
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
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppElegant.ink),
              title: const Text('编辑', style: AppText.itemBody),
              onTap: () {
                Navigator.pop(context);
                _navigateToEdit(diary);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppElegant.rose),
              title: const Text('删除',
                  style: TextStyle(color: AppElegant.rose, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(diary);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Diary diary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除这篇日记？'),
        content: const Text('此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppElegant.rose),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<DiaryProvider>().deleteDiary(diary.id);
    }
  }

  void _navigateToEdit(Diary? diary) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiaryEditScreen(diary: diary)),
      );

  void _navigateToDetail(Diary diary) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                DiaryEditScreen(diary: diary, readOnly: true)),
      );
}

class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<Diary> diaries;
  final String Function(DiaryStatus) statusEmoji;
  final String Function(DiaryStatus) statusLabel;
  final Color Function(DiaryStatus) statusColor;
  final void Function(Diary) onTapDiary;
  final void Function(Diary) onLongPressDiary;

  const _DayGroup({
    required this.date,
    required this.diaries,
    required this.statusEmoji,
    required this.statusLabel,
    required this.statusColor,
    required this.onTapDiary,
    required this.onLongPressDiary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppElegant.ink,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  DateFormat('M月 · EEEE', 'zh_CN').format(date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppElegant.inkSoft,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(height: 0.5, color: AppElegant.hair),
              ),
            ],
          ),
        ),
        ...diaries.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onTapDiary(d),
                onLongPress: () => onLongPressDiary(d),
                child: _DiaryCard(
                  diary: d,
                  statusEmoji: statusEmoji(d.qianqianStatus),
                  statusLabel: statusLabel(d.qianqianStatus),
                  statusColor: statusColor(d.qianqianStatus),
                ),
              ),
            )),
      ],
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final Diary diary;
  final String statusEmoji;
  final String statusLabel;
  final Color statusColor;

  const _DiaryCard({
    required this.diary,
    required this.statusEmoji,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppElegant.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppElegant.hair, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：心情徽章 + 标题（如有）
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(statusEmoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (diary.scheduleIds.isNotEmpty)
                ElegantBadge(
                  text: '${diary.scheduleIds.length} 日程',
                  icon: Icons.link_rounded,
                ),
            ],
          ),
          if (diary.title != null && diary.title!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              diary.title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppElegant.ink,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          // 内容
          Text(
            diary.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppElegant.inkSoft,
              height: 1.6,
            ),
          ),
          // 进步/改进
          if ((diary.progressPoints?.isNotEmpty ?? false) ||
              (diary.improvementPoints?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppElegant.bgAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (diary.progressPoints?.isNotEmpty ?? false)
                    _miniRow(
                      '+',
                      AppElegant.sage,
                      diary.progressPoints!,
                    ),
                  if ((diary.progressPoints?.isNotEmpty ?? false) &&
                      (diary.improvementPoints?.isNotEmpty ?? false))
                    const SizedBox(height: 6),
                  if (diary.improvementPoints?.isNotEmpty ?? false)
                    _miniRow(
                      '△',
                      AppElegant.sand,
                      diary.improvementPoints!,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniRow(String mark, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            mark,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppElegant.ink,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
