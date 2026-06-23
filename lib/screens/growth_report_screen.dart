import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../models/models.dart';
import '../providers/schedule_provider.dart';
import '../providers/course_provider.dart';
import '../providers/diary_provider.dart';
import '../services/growth_report_service.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';

/// P1-6 成长报告页：周/月切换 + 区间翻阅 + 打卡概况/课程进度/情绪趋势三块，
/// 支持将报告渲染为一张长图分享。严格延续 AppElegant / elegant_kit 体系。
class GrowthReportScreen extends StatefulWidget {
  const GrowthReportScreen({super.key});

  @override
  State<GrowthReportScreen> createState() => _GrowthReportScreenState();
}

class _GrowthReportScreenState extends State<GrowthReportScreen> {
  ReportPeriod _period = ReportPeriod.week;
  DateTime _anchor = DateTime.now();
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadSchedules();
      context.read<CourseProvider>().loadCourses();
      context.read<DiaryProvider>().loadDiaries();
    });
  }

  void _shift(int delta) {
    setState(() {
      _anchor = GrowthReportService.shiftAnchor(_anchor, _period, delta);
    });
  }

  void _switchPeriod(ReportPeriod p) {
    if (p == _period) return;
    setState(() => _period = p);
  }

  /// 是否已翻到「未来」区间（下一期按钮禁用判断）。
  bool get _isLatest {
    final cur = GrowthReportService.rangeOf(_anchor, _period);
    final now = GrowthReportService.rangeOf(DateTime.now(), _period);
    return !cur.$1.isBefore(now.$1);
  }

  String _rangeLabel(GrowthReportData data) {
    if (_period == ReportPeriod.week) {
      return '${DateFormat('M月d日').format(data.start)} — ${DateFormat('M月d日').format(data.end)}';
    }
    return DateFormat('yyyy年M月').format(data.start);
  }

  @override
  Widget build(BuildContext context) {
    return ElegantScaffold(
      body: Column(
        children: [
          ElegantNavBar(
            title: '成长报告',
            actions: [
              _sharing
                  ? const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(child: ElegantLoading(size: 18)),
                      ),
                    )
                  : ElegantCircleIconButton(
                      icon: Icons.ios_share_rounded,
                      onTap: _shareReport,
                    ),
            ],
          ),
          _buildControls(),
          Expanded(
            child: Consumer3<ScheduleProvider, CourseProvider, DiaryProvider>(
              builder: (ctx, sched, course, diary, _) {
                final data = GrowthReportService.build(
                  schedules: sched.schedules,
                  checkIns: sched.checkIns,
                  courses: course.courses,
                  diaries: diary.diaries,
                  anchor: _anchor,
                  period: _period,
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: _ReportCard(
                      data: data,
                      rangeLabel: _rangeLabel(data),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElegantSegment(
                  label: '周报',
                  selected: _period == ReportPeriod.week,
                  onTap: () => _switchPeriod(ReportPeriod.week),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElegantSegment(
                  label: '月报',
                  selected: _period == ReportPeriod.month,
                  onTap: () => _switchPeriod(ReportPeriod.month),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElegantCircleIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _shift(-1),
              ),
              Builder(builder: (ctx) {
                final r = GrowthReportService.rangeOf(_anchor, _period);
                final label = _period == ReportPeriod.week
                    ? '${DateFormat('M月d日').format(r.$1)} — ${DateFormat('M月d日').format(r.$2)}'
                    : DateFormat('yyyy年M月').format(r.$1);
                return Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppElegant.ink,
                    letterSpacing: 0.2,
                  ),
                );
              }),
              Opacity(
                opacity: _isLatest ? 0.35 : 1,
                child: ElegantCircleIconButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () {
                    if (_isLatest) return;
                    _shift(1);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareReport() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // 等待下一帧绘制完成，确保最新内容已落到 RepaintBoundary 图层
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _toast('生成失败，请重试');
        return;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _toast('生成失败，请重试');
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/growth_report_$ts.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '芊芊成长报告',
      );
    } catch (e) {
      _toast('生成失败：$e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// 报告内容卡（同时用于屏幕展示与长图导出）。
class _ReportCard extends StatelessWidget {
  final GrowthReportData data;
  final String rangeLabel;

  const _ReportCard({required this.data, required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppElegant.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppElegant.hair, width: 0.5),
        boxShadow: AppElegant.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 18),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: ElegantEmpty(
                icon: Icons.insights_outlined,
                label: '这一区间还没有记录',
                hint: '打卡、写日记后再来看看成长足迹吧',
              ),
            )
          else ...[
            _checkInBlock(),
            const SizedBox(height: 18),
            _courseBlock(),
            const SizedBox(height: 18),
            _moodBlock(),
          ],
          const SizedBox(height: 18),
          const ElegantDivider(),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '芊芊成长日志 · 记录每一步成长',
              style: TextStyle(
                fontSize: 10,
                color: AppElegant.inkFaint,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppElegant.accentWhisper,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppElegant.accent),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.period == ReportPeriod.week ? '本周成长报告' : '本月成长报告',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppElegant.ink,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rangeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppElegant.inkSoft,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String zh, String en) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          zh,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppElegant.ink,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            en,
            style: const TextStyle(
              fontSize: 9,
              color: AppElegant.inkFaint,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _checkInBlock() {
    final pct = (data.checkInRate * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('打卡概况', 'CHECK-IN'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppElegant.bgAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _RateRing(rate: data.checkInRate),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '完成 ${data.checkedCount} / ${data.dueCount} 项日程',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppElegant.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '打卡完成率 $pct%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppElegant.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElegantStatTile(
                icon: Icons.check_circle_outline,
                value: '${data.totalCheckIns}',
                label: '总打卡',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElegantStatTile(
                icon: Icons.today_outlined,
                value: '${data.activeDays}',
                label: '活跃天数',
                accent: AppElegant.sage,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElegantStatTile(
                icon: Icons.local_fire_department_outlined,
                value: '${data.streakDays}',
                label: '连续天数',
                accent: AppElegant.sand,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _courseBlock() {
    final courses = data.courses.where((c) => c.totalHours > 0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('课程进度', 'COURSES'),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          _placeholderBox('暂无课程数据')
        else
          ...courses.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(c.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppElegant.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${_fmt(c.usedHours)}/${_fmt(c.totalHours)} ${c.unitName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppElegant.inkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.usagePercent,
                        minHeight: 6,
                        backgroundColor: AppElegant.hairSoft,
                        valueColor:
                            const AlwaysStoppedAnimation(AppElegant.accent),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _moodBlock() {
    const order = [DiaryStatus.good, DiaryStatus.normal, DiaryStatus.irritable];
    const labels = {
      DiaryStatus.good: '愉悦',
      DiaryStatus.normal: '平静',
      DiaryStatus.irritable: '烦躁',
    };
    const emojis = {
      DiaryStatus.good: '😊',
      DiaryStatus.normal: '😐',
      DiaryStatus.irritable: '😠',
    };
    const colors = {
      DiaryStatus.good: AppElegant.sage,
      DiaryStatus.normal: AppElegant.sand,
      DiaryStatus.irritable: AppElegant.rose,
    };
    final total = data.diaryCount;
    final maxCount = order
        .map((s) => data.moodCounts[s] ?? 0)
        .fold(0, (a, b) => a > b ? a : b)
        .clamp(1, 1 << 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('情绪趋势', 'MOOD'),
        const SizedBox(height: 12),
        if (total == 0)
          _placeholderBox('暂无日记记录')
        else
          Column(
            children: order.map((s) {
              final count = data.moodCounts[s] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Row(
                        children: [
                          Text(emojis[s]!,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            labels[s]!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppElegant.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: count / maxCount,
                          minHeight: 6,
                          backgroundColor: AppElegant.hairSoft,
                          valueColor: AlwaysStoppedAnimation(colors[s]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 22,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppElegant.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _placeholderBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppElegant.bgAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppElegant.inkFaint),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

/// 打卡完成率环形进度。
class _RateRing extends StatelessWidget {
  final double rate; // 0..1
  const _RateRing({required this.rate});

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).round();
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              strokeWidth: 6,
              backgroundColor: AppElegant.hairSoft,
              valueColor: const AlwaysStoppedAnimation(AppElegant.accent),
            ),
          ),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppElegant.ink,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
