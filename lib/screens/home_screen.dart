import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/elegant_kit.dart';
import '../widgets/elegant_check_button.dart';
import 'schedule_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppElegant.bg,
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          final day = _selectedDay ?? DateTime.now();
          final daySchedules = provider.getSchedulesForDay(day);
          // 顶栏问候区与今日焦点卡始终基于"今天"，不随日历选中变化
          final todayList = provider.getSchedulesForDay(DateTime.now());
          final todayCount = todayList.length;
          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─ 顶栏（问候 + 设置按钮）─
                SliverToBoxAdapter(child: _buildTopBar(todayCount)),
                // ─ 今日焦点卡 (P1-2) ─
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    child: _TodayFocusCard(
                      todaySchedules: todayList,
                      isCheckedIn: provider.isCheckedIn,
                      onTapSchedule: (s) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScheduleDetailScreen(schedule: s),
                        ),
                      ),
                    ),
                  ),
                ),
                // ─ 日历卡片 ─
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: _buildCalendar(provider),
                  ),
                ),
                // ─ 日程列表标题 ─
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('M月d日', 'zh_CN').format(day),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppElegant.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '共 ${daySchedules.length} 项',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppElegant.inkSoft,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                // ─ 日程列表 ─
                if (provider.isLoading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ElegantLoading.center(),
                  )
                else if (daySchedules.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: ElegantEmpty(
                      icon: Icons.event_note_outlined,
                      label: '这一天还没有日程',
                      hint: '点击下方 + 新增',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ScheduleCard(
                            schedule: daySchedules[index],
                            isCheckedIn: provider.isCheckedIn(
                              daySchedules[index].id,
                            ),
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => ScheduleDetailScreen(
                                  schedule: daySchedules[index],
                                ),
                              ),
                            ),
                            onCheckIn: () async {
                              final messenger = ScaffoldMessenger.of(ctx);
                              final success = await provider.checkIn(
                                daySchedules[index].id,
                              );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success ? '已打卡 · 记录成功' : '这条日程已经打过卡啦',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        childCount: daySchedules.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── 顶栏（问候 + 设置按钮）────────────────────────
  Widget _buildTopBar(int scheduleCount) {
    final hour = DateTime.now().hour;
    final greet = hour < 6
        ? '夜深了'
        : hour < 12
        ? '早安'
        : hour < 18
        ? '午后好'
        : '晚上好';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$greet.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: AppElegant.ink,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  scheduleCount > 0 ? '今日共 $scheduleCount 个日程安排' : '今日无特别安排',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppElegant.inkSoft,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElegantCircleIconButton(
            icon: Icons.settings_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 日历（含周/月切换 + 打卡热力 P1-3）──────────────
  Widget _buildCalendar(ScheduleProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 2),
          child: Row(
            children: [
              const Spacer(),
              _FormatToggle(
                format: _calendarFormat,
                onChanged: (f) => setState(() => _calendarFormat = f),
              ),
            ],
          ),
        ),
        ElegantCard(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          child: TableCalendar(
            locale: 'zh_CN',
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            onDaySelected: (selected, focused) {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onFormatChanged: (fmt) => setState(() => _calendarFormat = fmt),
            onPageChanged: (focused) => _focusedDay = focused,
            rowHeight: 38,
            daysOfWeekHeight: 26,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: AppElegant.bgAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppElegant.hair, width: 0.5),
              ),
              todayTextStyle: const TextStyle(
                color: AppElegant.ink,
                fontWeight: FontWeight.w600,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppElegant.accent,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              defaultTextStyle: const TextStyle(
                color: AppElegant.ink,
                fontSize: 13,
              ),
              weekendTextStyle: const TextStyle(
                color: AppElegant.inkSoft,
                fontSize: 13,
              ),
              markerDecoration: const BoxDecoration(
                color: AppElegant.accent,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 4,
              markerMargin: const EdgeInsets.symmetric(horizontal: 1.2),
              markersAlignment: Alignment.bottomCenter,
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 11,
                color: AppElegant.inkSoft,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
              weekendStyle: TextStyle(
                fontSize: 11,
                color: AppElegant.inkFaint,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                size: 20,
                color: AppElegant.ink,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                size: 20,
                color: AppElegant.ink,
              ),
              titleTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppElegant.ink,
                letterSpacing: 1.5,
              ),
              headerPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                final list = events.cast<Schedule>();
                final done = list
                    .where((s) => provider.isCheckedIn(s.id))
                    .length;
                final ratio = list.isEmpty ? 0.0 : done / list.length;
                // 颜色按打卡完成度：浅粉(未打卡) → 深玫瑰粉(全打卡)
                final color = Color.lerp(
                  AppElegant.accentLight,
                  AppElegant.accent,
                  ratio,
                )!;
                // 宽度按日程密度：8 ~ 18
                final w = 8.0 + list.length.clamp(1, 5) * 2.0;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    width: w,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
            eventLoader: (d) => provider.getSchedulesForDay(d),
          ),
        ),
      ],
    );
  }
}

/// 日程卡片 - 精致版
class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final bool isCheckedIn;
  final VoidCallback onTap;
  final VoidCallback onCheckIn;

  const _ScheduleCard({
    required this.schedule,
    required this.isCheckedIn,
    required this.onTap,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: AppElegant.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppElegant.hair, width: 0.5),
          ),
          child: Row(
            children: [
              // 左侧色条
              Container(
                width: 3,
                height: 44,
                decoration: BoxDecoration(
                  color: schedule.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              // 时间 · 竖排
              SizedBox(
                width: 46,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(schedule.dateTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppElegant.ink,
                        letterSpacing: -0.3,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      schedule.endTime != null
                          ? '至 ${DateFormat('HH:mm').format(schedule.endTime!)}'
                          : '· · ·',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppElegant.inkFaint,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // 标题 + 地点
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      schedule.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppElegant.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (schedule.location != null &&
                            schedule.location!.isNotEmpty) ...[
                          const Icon(
                            Icons.place_outlined,
                            size: 11,
                            color: AppElegant.inkFaint,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              schedule.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppElegant.inkFaint,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ] else
                          Text(
                            _typeLabel(schedule.scheduleType),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppElegant.inkFaint,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 打卡
              ElegantCheckInButton(
                isChecked: isCheckedIn,
                scheduleColor: schedule.color,
                onTap: onCheckIn,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(ScheduleType t) =>
      const {
        'school': '上学',
        'nursery': '托班',
        'sports': '运动',
        'language': '语言',
        'medical': '医疗',
        'general': '通用',
      }[t.name] ??
      '通用';
}

// ═══════════════════════════════════════════════════════════════
//  今日焦点卡 (P1-2)：完成进度环 + 下一件待办
//  数据基于"今天"，不随日历选中日变化。
// ═══════════════════════════════════════════════════════════════
class _TodayFocusCard extends StatelessWidget {
  final List<Schedule> todaySchedules;
  final bool Function(String id) isCheckedIn;
  final void Function(Schedule schedule) onTapSchedule;

  const _TodayFocusCard({
    required this.todaySchedules,
    required this.isCheckedIn,
    required this.onTapSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final total = todaySchedules.length;
    final done = todaySchedules.where((s) => isCheckedIn(s.id)).length;

    // 今日无安排
    if (total == 0) {
      return ElegantCard(
        child: Row(
          children: [
            _Ring(done: 0, total: 0),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('今日焦点', style: AppText.meta),
                  SizedBox(height: 6),
                  Text(
                    '今天没有安排，好好休息～',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppElegant.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final allDone = done == total;

    // 下一件待办：未打卡中 dateTime >= now 的最早；否则最早的未打卡
    final now = DateTime.now();
    final pending = todaySchedules.where((s) => !isCheckedIn(s.id)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    Schedule? next;
    for (final s in pending) {
      if (!s.dateTime.isBefore(now)) {
        next = s;
        break;
      }
    }
    next ??= pending.isNotEmpty ? pending.first : null;

    return ElegantCard(
      onTap: (allDone || next == null) ? null : () => onTapSchedule(next!),
      child: Row(
        children: [
          _Ring(done: done, total: total),
          const SizedBox(width: 16),
          Expanded(
            child: (allDone || next == null)
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('今日焦点', style: AppText.meta),
                      SizedBox(height: 6),
                      Text(
                        '今天全部打卡完成 🎉',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppElegant.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text('坚持得很棒', style: AppText.meta),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text('下一件', style: AppText.meta),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('HH:mm').format(next.dateTime),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppElegant.accent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: next.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              next.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppElegant.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          if (!allDone && next != null)
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppElegant.inkWhisper,
            ),
        ],
      ),
    );
  }
}

/// 完成进度环：灰底环 + 玫瑰粉进度弧 + 中心 "done/total"
class _Ring extends StatelessWidget {
  final int done;
  final int total;
  const _Ring({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    return SizedBox(
      width: 54,
      height: 54,
      child: CustomPaint(
        painter: _RingPainter(progress: pct),
        child: Center(
          child: Text(
            total == 0 ? '—' : '$done/$total',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppElegant.ink,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  static const double _twoPi = 6.283185307179586;
  static const double _halfPi = 1.5707963267948966;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 5) / 2;
    final bg = Paint()
      ..color = AppElegant.hair
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    if (progress > 0) {
      final fg = Paint()
        ..color = AppElegant.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -_halfPi,
        _twoPi * progress.clamp(0.0, 1.0),
        false,
        fg,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 周/月视图切换（P1-3）：胶囊分段，选中态白底微阴影
class _FormatToggle extends StatelessWidget {
  final CalendarFormat format;
  final ValueChanged<CalendarFormat> onChanged;
  const _FormatToggle({required this.format, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppElegant.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppElegant.hair, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('月', CalendarFormat.month),
          _seg('周', CalendarFormat.week),
        ],
      ),
    );
  }

  Widget _seg(String label, CalendarFormat f) {
    final selected = format == f;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(f);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppElegant.card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? AppElegant.softShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppElegant.accent : AppElegant.inkSoft,
          ),
        ),
      ),
    );
  }
}
