// ============================================================================
// TodayOverviewScreen Widget 测试
//
// 版本号 : v2.0
// 责任 agent : qa-agent
// Task 编号 : #005（既存红灯修复，仅修 test/，不动业务代码）
// 关联报告 : docs/qa/widget-test-realign-report.md v1.0
// 说明 :
//   - 旧版（v1.0）以 "芊芊的一天 / 周五 / 5天 / 7天 / 周日 / 周一 /
//     无记录 / 课程课时" 等已不存在的文案为锚点，集体红灯。
//   - 现行实现（截至 2026-05-14）的稳定文本/结构锚点：
//       · 顶部导航：ElegantNavBar(title: '今日概览')
//       · Date Hero：上方 "EEEE".toUpperCase()（zh_CN 下为 "星期五"），
//         数字日期（如 "24"），"记录成长的一天"
//       · 4 块 ElegantStatTile：'今日日程 · N 已打卡' / '今日医疗' /
//         '本月日记' / '已用课时 / 共 X.X'
//       · 区块标题：'今日日程 / TODAY'、'本周打卡 / WEEK'、'健康管理 / HEALTH'
//       · _miniStat label：'总打卡' / '活跃天数' / '本周已过'
//       · 空态：'今日无安排' / '暂无医疗记录'
//       · 完成率：'完成率 X%'
//   - 重写策略：把测试意图（TC-001 currentDate 透传 / TC-002 区块存在 /
//     TC-003 周进度 / TC-004 主组件渲染 / TC-005 边界日期）映射到上述新锚点。
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qianqian_growth_logbook/screens/today_overview_screen.dart';
import 'package:qianqian_growth_logbook/providers/schedule_provider.dart';
import 'package:qianqian_growth_logbook/providers/medical_provider.dart';
import 'package:qianqian_growth_logbook/providers/diary_provider.dart';
import 'package:qianqian_growth_logbook/providers/course_provider.dart';

/// 通用 widget 注入：4 个 Provider + zh_CN
///
/// 注：TodayOverviewScreen 内容较长（顶部 4 stat tile + 3 个区块），
/// 默认 800×600 viewport 下 SliverList 会 lazy 截断下半部分，
/// 导致 "本周打卡 / 健康管理 / 完成率" 等下半部分文本无法被 finder 命中。
/// 这里把测试视口拉高到 1600，确保所有区块都被渲染。
Future<void> _pumpOverview(
  WidgetTester tester, {
  DateTime? currentDate,
}) async {
  // 拉大 viewport，避免 lazy SliverList 截断下半部分子树
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final scheduleProvider = ScheduleProvider();
  final medicalProvider = MedicalProvider();
  final diaryProvider = DiaryProvider();
  final courseProvider = CourseProvider();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: scheduleProvider),
        ChangeNotifierProvider.value(value: medicalProvider),
        ChangeNotifierProvider.value(value: diaryProvider),
        ChangeNotifierProvider.value(value: courseProvider),
      ],
      child: MaterialApp(
        home: TodayOverviewScreen(currentDate: currentDate),
      ),
    ),
  );

  // TodayOverviewScreen 是 StatelessWidget，无持续动画，可使用 pumpAndSettle
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  group('TodayOverviewScreen Widget Tests (Task #005)', () {
    // ─────────────────────────────────────────────────────────
    // TC-005-T1: currentDate 参数 - 默认 / 自定义
    //   旧锚点 "芊芊的一天 / 周五" 已废弃；现锚点：
    //     · 标题 "今日概览"
    //     · Date Hero 数字（date.day）
    //     · subtitle "记录成长的一天"
    // ─────────────────────────────────────────────────────────
    group('TC-005-T1: currentDate 参数', () {
      testWidgets('默认 currentDate 渲染主标题与副标题',
          (WidgetTester tester) async {
        await _pumpOverview(tester);
        expect(find.text('今日概览'), findsOneWidget);
        expect(find.text('记录成长的一天'), findsOneWidget);
      });

      testWidgets('自定义 currentDate=2026-04-24 时显示数字 24',
          (WidgetTester tester) async {
        final testDate = DateTime(2026, 4, 24); // 周五
        await _pumpOverview(tester, currentDate: testDate);
        expect(find.text('今日概览'), findsOneWidget);
        // Date Hero 大数字
        expect(find.text('24'), findsOneWidget);
        // 年份与子标题
        expect(find.text('2026'), findsOneWidget);
        expect(find.text('记录成长的一天'), findsOneWidget);
      });
    });

    // ─────────────────────────────────────────────────────────
    // TC-005-T2: 区块文案与空态
    //   旧锚点 "无记录 / 今日医疗" → 现锚点：
    //     · 顶部 4 stat tiles 的 label：'今日日程 · 0 已打卡'、
    //       '今日医疗 · 无'（医疗为空时）、'本月日记'、
    //       '已用课时 / 共 0.0'
    //     · 区块空态："今日无安排"（todaySchedules 空）
    //                 "暂无医疗记录"（medical records 空）
    // ─────────────────────────────────────────────────────────
    group('TC-005-T2: 区块文案与空态', () {
      testWidgets('无医疗记录时 statTile 显示 "今日医疗 · 无"',
          (WidgetTester tester) async {
        await _pumpOverview(tester);
        expect(find.text('今日医疗 · 无'), findsOneWidget);
      });

      testWidgets('无日程时 "今日日程" 区块显示空态 "今日无安排"',
          (WidgetTester tester) async {
        await _pumpOverview(tester);
        // 区块标题（左中文 + 右英文小字）
        expect(find.text('今日日程'), findsOneWidget);
        expect(find.text('TODAY'), findsOneWidget);
        // 空态
        expect(find.text('今日无安排'), findsOneWidget);
      });

      testWidgets('无医疗记录时 "健康管理" 区块显示空态 "暂无医疗记录"',
          (WidgetTester tester) async {
        await _pumpOverview(tester);
        expect(find.text('健康管理'), findsOneWidget);
        expect(find.text('HEALTH'), findsOneWidget);
        expect(find.text('暂无医疗记录'), findsOneWidget);
      });
    });

    // ─────────────────────────────────────────────────────────
    // TC-005-T3: 本周打卡 - 数据初始态
    //   旧锚点 "本周已过 / 5天 / 进度条 / 总打卡 / 有记录天数" → 现锚点：
    //     · _miniStat 三个 label：'总打卡' / '活跃天数' / '本周已过'
    //     · 完成率文案 '完成率 X%'
    //   注：旧版 "5天/7天" 是带 "天" 字后缀的格式化值，现行实现仅显示 weekday 数字
    //   （'${now.weekday}'），无 "天" 字。这是有意的视觉简化，按章程处理为
    //   "测试用例对齐到当前 UI 形态"。
    // ─────────────────────────────────────────────────────────
    group('TC-005-T3: 本周打卡区块', () {
      testWidgets('周五 (weekday=5) 时 "本周已过" 数值为 "5"',
          (WidgetTester tester) async {
        final friday = DateTime(2026, 4, 24); // 周五
        await _pumpOverview(tester, currentDate: friday);

        // 三个 _miniStat label 必须均存在
        expect(find.text('总打卡'), findsOneWidget);
        expect(find.text('活跃天数'), findsOneWidget);
        expect(find.text('本周已过'), findsOneWidget);
        // 周五 -> weekday=5；初始数据空，'总打卡' 数值为 '0'
        expect(find.text('5'), findsAtLeastNWidgets(1));
      });

      testWidgets('完成率文案存在', (WidgetTester tester) async {
        final friday = DateTime(2026, 4, 24);
        await _pumpOverview(tester, currentDate: friday);
        // 区块标题
        expect(find.text('本周打卡'), findsOneWidget);
        expect(find.text('WEEK'), findsOneWidget);
        // 数据空时完成率应为 "完成率 0%"
        expect(find.text('完成率 0%'), findsOneWidget);
      });
    });

    // ─────────────────────────────────────────────────────────
    // TC-005-T4: 主组件渲染完整性
    //   旧锚点 "课程课时" → 现 statTile label 为 '已用课时 / 共 X.X'
    // ─────────────────────────────────────────────────────────
    group('TC-005-T4: 主组件渲染', () {
      testWidgets('主标题 / 各区块 / 4 块 stat tile 全部存在',
          (WidgetTester tester) async {
        await _pumpOverview(tester);

        // 顶部导航
        expect(find.text('今日概览'), findsOneWidget);

        // 4 块 stat tile 的 label（数据空时的形态）
        expect(find.text('今日日程 · 0 已打卡'), findsOneWidget);
        expect(find.text('今日医疗 · 无'), findsOneWidget);
        expect(find.text('本月日记'), findsOneWidget);
        expect(find.text('已用课时 / 共 0.0'), findsOneWidget);

        // 三个区块 zh + en 标题
        expect(find.text('今日日程'), findsOneWidget);
        expect(find.text('TODAY'), findsOneWidget);
        expect(find.text('本周打卡'), findsOneWidget);
        expect(find.text('WEEK'), findsOneWidget);
        expect(find.text('健康管理'), findsOneWidget);
        expect(find.text('HEALTH'), findsOneWidget);
      });

      testWidgets('数据空时多个 stat tile 数值显示为 "0"',
          (WidgetTester tester) async {
        await _pumpOverview(tester);
        // 顶部 4 块 stat tile 数值：日程 0 / 医疗 0 / 日记 0 / 课时 0.0
        // "0" 至少出现 3 次（前 3 块），课时块是 "0.0" 不计入 "0" 严格匹配
        expect(find.text('0'), findsAtLeastNWidgets(3));
      });
    });

    // ─────────────────────────────────────────────────────────
    // TC-005-T5: 边界 - 周一 / 周日
    //   旧锚点 "周日 / 周一 / 7天" 已废弃。
    //   现行实现 Date Hero 顶部用 EEEE.toUpperCase() 输出（zh_CN 下为 "星期日"
    //   "星期一"，对中文 toUpperCase 无影响），这是稳定锚点。
    // ─────────────────────────────────────────────────────────
    group('TC-005-T5: 边界日期', () {
      testWidgets('周日 (2026-04-26) - Date Hero 顶部显示 "星期日"，本周已过=7',
          (WidgetTester tester) async {
        final sunday = DateTime(2026, 4, 26);
        await _pumpOverview(tester, currentDate: sunday);
        expect(find.text('星期日'), findsOneWidget);
        // weekday=7
        expect(find.text('7'), findsAtLeastNWidgets(1));
        expect(find.text('本周已过'), findsOneWidget);
      });

      testWidgets('周一 (2026-04-20) - Date Hero 顶部显示 "星期一"',
          (WidgetTester tester) async {
        final monday = DateTime(2026, 4, 20);
        await _pumpOverview(tester, currentDate: monday);
        expect(find.text('星期一'), findsOneWidget);
        // weekday=1
        expect(find.text('1'), findsAtLeastNWidgets(1));
      });
    });
  });
}
