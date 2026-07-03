import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'today_overview_screen.dart';
import 'check_in_stats_screen.dart';
import 'course_list_screen.dart';
import 'medical_records_screen.dart';
import 'diary_screen.dart';
import 'add_schedule_screen.dart';

/// 应用主壳 (P2-8)：用 IndexedStack 承载 6 个 Tab，切换时保留各页状态与滚动位置，
/// 取代此前 Navigator.push 的页面栈堆积方案。中间 [+] 仍以模态 push 打开新增日程。
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  // IndexedStack 子页与索引一一对应
  static const List<Widget> _pages = [
    HomeScreen(), // 0 首页
    TodayOverviewScreen(), // 1 今日
    CheckInStatsScreen(), // 2 统计
    CourseListScreen(), // 3 课时
    MedicalRecordsScreen(), // 4 健康
    DiaryScreen(), // 5 日记
  ];

  void _select(int i) {
    if (_index == i) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  void _openAddSchedule() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddScheduleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppElegant.bg,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
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
                isSelected: _index == 0,
                onTap: () => _select(0),
              ),
              _NavItem(
                icon: Icons.today_outlined,
                selectedIcon: Icons.today_rounded,
                label: '今日',
                isSelected: _index == 1,
                onTap: () => _select(1),
              ),
              _NavItem(
                icon: Icons.insights_outlined,
                selectedIcon: Icons.insights_rounded,
                label: '统计',
                isSelected: _index == 2,
                onTap: () => _select(2),
              ),
              // 中间浮起的添加按钮
              SizedBox(
                width: 60,
                child: Center(
                  child: GestureDetector(
                    onTap: _openAddSchedule,
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
                isSelected: _index == 3,
                onTap: () => _select(3),
              ),
              _NavItem(
                icon: Icons.medical_services_outlined,
                selectedIcon: Icons.medical_services_rounded,
                label: '健康',
                isSelected: _index == 4,
                onTap: () => _select(4),
              ),
              _NavItem(
                icon: Icons.edit_outlined,
                selectedIcon: Icons.edit_rounded,
                label: '日记',
                isSelected: _index == 5,
                onTap: () => _select(5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
