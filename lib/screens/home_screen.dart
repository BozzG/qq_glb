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
import 'add_schedule_screen.dart';
import 'check_in_stats_screen.dart';
import 'course_list_screen.dart';
import 'medical_records_screen.dart';
import 'diary_screen.dart';
import 'settings_screen.dart';
import 'today_overview_screen.dart';

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
          // 顶栏问候区始终展示"今天"的日程数，不随日历选中变化
          final todayCount =
              provider.getSchedulesForDay(DateTime.now()).length;
          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─ 顶栏（问候 + 设置按钮）─
                SliverToBoxAdapter(
                  child: _buildTopBar(todayCount),
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
      bottomNavigationBar: _buildBottomNav(),
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

  // ─── 日历 ───────────────────────────────────────────
  Widget _buildCalendar(ScheduleProvider provider) {
    return ElegantCard(
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
        eventLoader: (d) => provider.getSchedulesForDay(d),
      ),
    );
  }

  // ─── 底部导航（7 格：首页/今日/统计/[+]/课时/健康/日记）──
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppElegant.card,
        border: Border(top: BorderSide(color: AppElegant.hair, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: '首页',
                isSelected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.today_outlined,
                selectedIcon: Icons.today_rounded,
                label: '今日',
                isSelected: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TodayOverviewScreen(),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.insights_outlined,
                selectedIcon: Icons.insights_rounded,
                label: '统计',
                isSelected: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckInStatsScreen()),
                ),
              ),
              // 中间浮起的添加按钮
              SizedBox(
                width: 60,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddScheduleScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppElegant.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppElegant.accent.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                label: '课时',
                isSelected: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourseListScreen()),
                ),
              ),
              _NavItem(
                icon: Icons.medical_services_outlined,
                selectedIcon: Icons.medical_services_rounded,
                label: '健康',
                isSelected: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MedicalRecordsScreen(),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.edit_outlined,
                selectedIcon: Icons.edit_rounded,
                label: '日记',
                isSelected: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiaryScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 22,
              color: isSelected ? AppElegant.accent : AppElegant.inkFaint,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppElegant.accent : AppElegant.inkFaint,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
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
