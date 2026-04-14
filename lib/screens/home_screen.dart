import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/schedule_provider.dart';
import 'schedule_detail_screen.dart';
import 'add_schedule_screen.dart';
import 'check_in_stats_screen.dart';
import 'course_list_screen.dart';
import 'medical_records_screen.dart';
import 'memo_screen.dart';
import 'growth_log_screen.dart';
import 'settings_screen.dart';
import '../utils/app_theme.dart';

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
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          final daySchedules = provider.getSchedulesForDay(
            _selectedDay ?? DateTime.now(),
          );
          return CustomScrollView(
            slivers: [
              // 顶部渐变区域：标题 + 日期卡片 + 日历
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 标题栏
                        Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 4,
                            top: 4,
                            bottom: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "🎉 芊芊成长日志",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.settings_outlined,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SettingsScreen(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 日期显示卡片
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_selectedDay?.day ?? DateTime.now().day}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    Text(
                                      DateFormat.MMMM(
                                        'zh_CN',
                                      ).format(_selectedDay ?? DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'EEEE',
                                        'zh_CN',
                                      ).format(_selectedDay ?? DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      DateFormat.yMd(
                                        'zh_CN',
                                      ).format(_selectedDay ?? DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Builder(
                                      builder: (_) {
                                        final count = provider
                                            .getSchedulesForDay(
                                              _selectedDay ?? DateTime.now(),
                                            )
                                            .length;
                                        return Text(
                                          '今日 $count 个日程',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 日历
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: TableCalendar(
                            locale: 'zh_CN',
                            firstDay: DateTime(2024, 1, 1),
                            lastDay: DateTime(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) =>
                                isSameDay(day, _selectedDay),
                            onDaySelected: (selected, focused) {
                              setState(() {
                                _selectedDay = selected;
                                _focusedDay = focused;
                              });
                            },
                            onFormatChanged: (format) =>
                                setState(() => _calendarFormat = format),
                            onPageChanged: (focused) => _focusedDay = focused,
                            calendarStyle: CalendarStyle(
                              outsideDaysVisible: false,
                              todayDecoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.5,
                                ),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              markersMaxCount: 3,
                              markerSize: 6,
                              markerMargin: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            rowHeight: 36,
                            daysOfWeekHeight: 28,
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              weekendStyle: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              formatButtonShowsNext: false,
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                              titleTextStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            eventLoader: (day) =>
                                provider.getSchedulesForDay(day),
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),

              // 快捷入口
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QuickEntry(
                        icon: Icons.add_circle_outline,
                        label: '添加日程',
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddScheduleScreen(),
                          ),
                        ),
                      ),
                      _QuickEntry(
                        icon: Icons.book_outlined,
                        label: '课时统计',
                        color: AppColors.info,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CourseListScreen()),
                        ),
                      ),
                      _QuickEntry(
                        icon: Icons.local_hospital_outlined,
                        label: '健康管理',
                        color: AppColors.scheduleMedical,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicalRecordsScreen(),
                          ),
                        ),
                      ),
                      _QuickEntry(
                        icon: Icons.check_circle_outline,
                        label: '打卡记录',
                        color: AppColors.success,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckInStatsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 日程列表标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${DateFormat.Md('zh_CN').format(_selectedDay ?? DateTime.now())} 的日程",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "共 ${daySchedules.length} 项",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 日程列表
              if (provider.isLoading)
                SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (daySchedules.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "今天还没有日程哦~",
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, index) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _ScheduleCard(
                          schedule: daySchedules[index],
                          isCheckedIn: provider.isCheckedToday(
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
                            final success = await provider.checkIn(
                              daySchedules[index].id,
                            );
                            if (!success && mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('今天已经打卡过啦！'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      childCount: daySchedules.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      // 底部导航
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: '首页',
            activeIcon: Icon(Icons.home_filled, size: 28),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '日志',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: '统计',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '备忘'),
        ],
        onTap: (idx) {
          if (idx == 0) return;
          switch (idx) {
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GrowthLogScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddScheduleScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CheckInStatsScreen()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MemoScreen()),
              );
              break;
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_fab',
        elevation: 6,
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddScheduleScreen()),
        ),
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}

class _QuickEntry extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickEntry({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: schedule.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 日程类型图标和时间
            Container(
              width: 48,
              height: 54,
              decoration: BoxDecoration(
                color: schedule.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(schedule.typeIcon, style: TextStyle(fontSize: 18)),
                  SizedBox(height: 2),
                  Text(
                    DateFormat.Hm().format(schedule.dateTime),
                    style: TextStyle(
                      fontSize: 10,
                      color: schedule.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            // 日程详情
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (schedule.location != null &&
                      schedule.location!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textHint,
                        ),
                        SizedBox(width: 3),
                        Text(
                          schedule.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  if (schedule.memo != null && schedule.memo!.isNotEmpty)
                    Text(
                      schedule.memo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                ],
              ),
            ),
            // 打卡按钮
            GestureDetector(
              onTap: onCheckIn,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCheckedIn
                      ? AppColors.success
                      : schedule.color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: isCheckedIn
                        ? AppColors.success
                        : schedule.color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isCheckedIn ? Icons.check : Icons.radio_button_unchecked,
                  color: isCheckedIn ? Colors.white : schedule.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
