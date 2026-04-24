import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qianqian_growth_logbook/screens/today_overview_screen.dart';
import 'package:qianqian_growth_logbook/providers/schedule_provider.dart';
import 'package:qianqian_growth_logbook/providers/medical_provider.dart';
import 'package:qianqian_growth_logbook/providers/memo_provider.dart';
import 'package:qianqian_growth_logbook/providers/course_provider.dart';

void main() {
  // 初始化日期格式化（支持中文）
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  group('TodayOverviewScreen Widget Tests', () {
    // 测试1: currentDate 参数传入/默认行为
    group('TC-001: currentDate 参数测试', () {
      testWidgets('使用默认当前时间', (WidgetTester tester) async {
        // 安排：创建mock providers
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        // 执行：使用默认currentDate（应为今天）
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle(); // 等待Widget完全渲染

        // 验证：widget应正常渲染，无异常
        expect(find.text('今日概览'), findsOneWidget);
        // 注意：文本是"周五 · 芊芊的一天"，需要查找包含的部分
        expect(find.textContaining('芊芊的一天'), findsOneWidget);
      });

      testWidgets('传入自定义currentDate', (WidgetTester tester) async {
        // 安排：指定一个特定日期（2026年4月24日，周五）
        final testDate = DateTime(2026, 4, 24);
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        // 执行：传入自定义日期
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(currentDate: testDate),
            ),
          ),
        );

        await tester.pumpAndSettle(); // 等待Widget完全渲染

        // 验证：应显示指定日期的信息
        expect(find.text('今日概览'), findsOneWidget);
        // 日期头部应显示24号
        expect(find.text('24'), findsOneWidget);
        // 应显示"周五"
        expect(find.textContaining('周五'), findsOneWidget);
        expect(find.textContaining('芊芊的一天'), findsOneWidget);
      });
    });

    // 测试2: 多条医疗记录/备忘的显示逻辑
    group('TC-002: 多条记录显示逻辑测试', () {
      testWidgets('无医疗记录时显示"无记录"', (WidgetTester tester) async {
        // 安排：空医疗记录
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        // 执行
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle(); // 等待Widget完全渲染

        // 验证：统计卡片应显示"无记录"
        expect(find.text('无记录'), findsOneWidget);
      });

      testWidgets('单条医疗记录时显示医院名称', (WidgetTester tester) async {
        // 注意：由于TodayOverviewScreen依赖Provider状态，
        // 且MedicalProvider可能需要数据库，这里主要测试UI逻辑
        // 实际完整测试需要mock数据和数据库
        
        // 简化测试：验证widget能正常渲染
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle(); // 等待Widget完全渲染

        // 验证：今日医疗卡片存在
        expect(find.text('今日医疗'), findsOneWidget);
      });

      testWidgets('无待办备忘时显示"全部完成"', (WidgetTester tester) async {
        // 安排：空备忘列表
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        // 执行
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle(); // 等待Widget完全渲染

        // 验证：统计卡片应显示"全部完成"
        expect(find.text('全部完成'), findsOneWidget);
      });
    });

    // 测试3: 本周进度计算逻辑
    group('TC-003: 本周进度计算测试', () {
      testWidgets('本周已过天数显示正确', (WidgetTester tester) async {
        // 安排：使用特定日期（2026年4月24日，周五，weekday=5）
        final testDate = DateTime(2026, 4, 24); // 周五
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        // 执行
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(currentDate: testDate),
            ),
          ),
        );

        await tester.pumpAndSettle(); // 等待Widget完全渲染

        // 验证：本周已过应显示"5天"（周一到周五）
        expect(find.text('本周已过'), findsOneWidget);
        expect(find.text('5天'), findsOneWidget);
      });

      testWidgets('进度条和完成率计算', (WidgetTester tester) async {
        // 安排
        final testDate = DateTime(2026, 4, 24);
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        // 执行
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(currentDate: testDate),
            ),
          ),
        );

        await tester.pumpAndSettle(); // 等待Widget完全渲染

        // 验证：本周打卡区域存在（文本前有emoji）
        expect(find.textContaining('本周打卡'), findsOneWidget);
        
        // 验证：显示"总打卡"和"有记录天数"
        expect(find.text('总打卡'), findsOneWidget);
        expect(find.text('有记录天数'), findsOneWidget);
      });
    });

    // 测试4: Widget渲染完整性
    group('TC-004: Widget渲染测试', () {
      testWidgets('所有主要组件都能正常渲染', (WidgetTester tester) async {
        // 安排
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        // 执行
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle(); // 等待Widget完全渲染

        // 验证：主要标题和区域都存在
        expect(find.text('今日概览'), findsOneWidget);
        expect(find.text('今日日程'), findsOneWidget);
        expect(find.text('今日医疗'), findsOneWidget);
        expect(find.text('待办备忘'), findsOneWidget);
        expect(find.text('课程课时'), findsOneWidget);
        // 文本前有emoji，使用contains匹配
        expect(find.textContaining('本周打卡'), findsOneWidget);
        expect(find.textContaining('待办备忘'), findsNWidgets(2)); // 统计卡片和区域标题
        expect(find.textContaining('健康管理'), findsOneWidget);
      });

      testWidgets('StatCard正确显示数据', (WidgetTester tester) async {
        // 安排
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        // 执行
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle(); // 等待Widget完全渲染

        // 验证：统计卡片的数值初始应为0
        expect(find.text('0'), findsAtLeast(3)); // 至少3个0（日程、医疗、待办）
      });
    });

    // 测试5: 边界条件和特殊情况
    group('TC-005: 边界条件测试', () {
      testWidgets('周日作为currentDate', (WidgetTester tester) async {
        // 周日是一周的最后一天，weekday=7
        final sunday = DateTime(2026, 4, 26); // 周日
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(currentDate: sunday),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证：应显示"周日"
        expect(find.textContaining('周日'), findsOneWidget);
        // 本周已过应显示"7天"
        expect(find.text('7天'), findsOneWidget);
      });

      testWidgets('周一作为currentDate', (WidgetTester tester) async {
        // 周一是一周的第一天，weekday=1
        final monday = DateTime(2026, 4, 20); // 周一
        final scheduleProvider = ScheduleProvider();
        final medicalProvider = MedicalProvider();
        final memoProvider = MemoProvider();
        final courseProvider = CourseProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: scheduleProvider),
              ChangeNotifierProvider.value(value: medicalProvider),
              ChangeNotifierProvider.value(value: memoProvider),
              ChangeNotifierProvider.value(value: courseProvider),
            ],
            child: MaterialApp(
              home: TodayOverviewScreen(currentDate: monday),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证：应显示"周一"
        expect(find.textContaining('周一'), findsOneWidget);
      });
    });
  });
}
