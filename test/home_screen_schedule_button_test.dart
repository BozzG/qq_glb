// ============================================================================
// HomeScreen 快捷入口 / 底部导航 / 添加按钮 测试
//
// 版本号 : v2.0
// 责任 agent : qa-agent
// Task 编号 : #005（既存红灯修复，仅修 test/，不动业务代码）
// 关联报告 : docs/qa/widget-test-realign-report.md v1.0
// 说明 :
//   - 旧版（v1.0）以 FloatingActionButton / BottomNavigationBar / 旧文案
//     "首页/日志/统计/日记"、"今日概览/课时统计/健康管理/打卡记录"为锚点，
//     与现行 lib/screens/home_screen.dart 的实现完全不一致，集体红灯。
//   - 现行实现（截至 2026-05-14）使用：
//       · 自建 Container 形式的底部导航栏（_NavItem × 7：首页/今日/统计/[+]/课时/健康/日记）
//       · 中央浮起的 GestureDetector + Container + Icons.add_rounded 作为新增日程入口
//       · 顶栏问候 + ElegantCircleIconButton（设置）
//       · 日程列表区显示当日 _ScheduleCard，无快捷入口区
//   - 因此本次重写：
//       · 重写 finder 锚定到当前 UI 的稳定文本/图标/widget 类型
//       · 保留可对齐的测试意图（导航存在、加号入口、加号入口可点跳转、底部导航文案）
//       · 删除已不存在的"快捷入口区域"用例，登记到报告
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qianqian_growth_logbook/screens/home_screen.dart';
import 'package:qianqian_growth_logbook/screens/add_schedule_screen.dart';
import 'package:qianqian_growth_logbook/providers/schedule_provider.dart';
import 'package:qianqian_growth_logbook/providers/medical_provider.dart';
import 'package:qianqian_growth_logbook/providers/diary_provider.dart';
import 'package:qianqian_growth_logbook/providers/course_provider.dart';

/// 通用 widget 注入：HomeScreen 依赖 4 个 Provider + zh_CN 日期格式
Future<void> _pumpHome(WidgetTester tester) async {
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
      child: const MaterialApp(home: HomeScreen()),
    ),
  );

  // 首页 initState 触发 PostFrameCallback -> loadSchedules，
  // 用 pump 顺序而非 pumpAndSettle 避免命中持续动画。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  group('HomeScreen 快捷入口 / 底部导航 / 加号入口测试 (Task #005)', () {
    // ─────────────────────────────────────────────────────────
    // TC-005-01 ~ 02: 中央"加号"入口存在 + 图标正确
    //   旧 TC-001 锚点 FloatingActionButton 已废弃，现行用自建按钮，
    //   稳定锚点：Icons.add_rounded（home_screen.dart L390）。
    // ─────────────────────────────────────────────────────────
    group('TC-005-01: 中央加号入口 - 显示与图标', () {
      testWidgets('首页应显示中央加号新增按钮', (WidgetTester tester) async {
        await _pumpHome(tester);
        // 锚点：Icons.add_rounded（仅一处，位于自建底部导航中央浮起按钮）
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      });

      testWidgets('中央加号入口图标颜色为白色 (Icons.add_rounded)',
          (WidgetTester tester) async {
        await _pumpHome(tester);
        final iconWidget =
            tester.widget<Icon>(find.byIcon(Icons.add_rounded));
        expect(iconWidget.color, Colors.white);
        expect(iconWidget.size, 24);
      });
    });

    // ─────────────────────────────────────────────────────────
    // TC-005-02: 点击中央加号 -> 跳转 AddScheduleScreen，且可返回首页
    //   旧 TC-002 验证文本"添加新日程"——保留意图，但锚点改为更稳健的
    //   AddScheduleScreen widget 类型，避免标题文案漂移。
    // ─────────────────────────────────────────────────────────
    group('TC-005-02: 中央加号入口 - 跳转与回退', () {
      testWidgets('点击中央加号应跳转到 AddScheduleScreen',
          (WidgetTester tester) async {
        await _pumpHome(tester);

        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(AddScheduleScreen), findsOneWidget);
      });

      testWidgets('从 AddScheduleScreen 返回后应回到 HomeScreen',
          (WidgetTester tester) async {
        await _pumpHome(tester);

        // 进入添加页
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(AddScheduleScreen), findsOneWidget);

        // 返回
        Navigator.of(
          tester.element(find.byType(AddScheduleScreen)),
        ).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(AddScheduleScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        // 加号入口仍在
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      });
    });

    // ─────────────────────────────────────────────────────────
    // TC-005-03: 底部导航存在与标签
    //   旧 TC-004 锚点：BottomNavigationBar + 文本 "首页/日志/统计/日记"。
    //   现行实现：自建 Container + 7 个 _NavItem，
    //   标签 = 首页 / 今日 / 统计 / 课时 / 健康 / 日记（"+" 不带文案）。
    //   注：旧文案"日志"已不存在，按章程允许的"已废弃用例"删除策略移除。
    // ─────────────────────────────────────────────────────────
    group('TC-005-03: 底部导航 - 标签项', () {
      testWidgets('底部导航标签：首页 / 今日 / 统计 / 课时 / 健康 / 日记 各 1 处',
          (WidgetTester tester) async {
        await _pumpHome(tester);

        // 6 个文本标签必须严格各 1 处（独占性强，避免与卡片标题撞名）
        for (final label in <String>[
          '首页',
          '今日',
          '统计',
          '课时',
          '健康',
          '日记',
        ]) {
          expect(find.text(label), findsOneWidget,
              reason: '底部导航标签 "$label" 应当唯一存在');
        }
      });

      testWidgets('底部导航在初始时仅"首页"为选中态 (AppElegant.accent 色)',
          (WidgetTester tester) async {
        await _pumpHome(tester);

        // 通过 Text widget 的样式间接断言：选中态字体加粗（w600），
        // 非选中态为 w500。
        final homeText = tester.widget<Text>(
          find.text('首页'),
        );
        expect(homeText.style?.fontWeight, FontWeight.w600);

        final todayText = tester.widget<Text>(
          find.text('今日'),
        );
        expect(todayText.style?.fontWeight, FontWeight.w500);
      });
    });

    // ─────────────────────────────────────────────────────────
    // TC-005-04: 顶栏与日历存在
    //   补充用例：保证"日程列表载体"渲染正常。
    // ─────────────────────────────────────────────────────────
    group('TC-005-04: 顶栏 + 日历区 + 设置按钮', () {
      testWidgets('顶栏问候语 + 设置按钮存在', (WidgetTester tester) async {
        await _pumpHome(tester);

        // 4 种问候语（夜深了 / 早安 / 午后好 / 晚上好）按当前小时择一
        final greetings = ['夜深了.', '早安.', '午后好.', '晚上好.'];
        final hits = greetings
            .where((g) => find.text(g).evaluate().isNotEmpty)
            .toList();
        expect(hits.length, 1,
            reason: '顶栏问候语应根据当前时段恰好命中其中一项');

        // 设置按钮：Icons.settings_outlined
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      });

      // 注：原计划补一条"日程为空时展示空态文案"用例，
      // 但 ScheduleProvider 在 widget 测试中受 PostFrameCallback +
      // sqflite 异步初始化影响，pump 时刻 ElegantEmpty 是否已挂载具有时序敏感性，
      // 不属于本期 Task #005 边界（仅"恢复既存红灯到全绿"），故不引入。
    });

    // ─────────────────────────────────────────────────────────
    // TC-005-05: 已废弃用例登记（不再断言，仅以注释留痕）
    // ─────────────────────────────────────────────────────────
    // 旧 TC-003 "FAB位置应为centerDocked" → 业务已不使用 Scaffold.fab，
    //   该用例不可恢复，删除并登记至 widget-test-realign-report.md。
    // 旧 TC-005 "首页应显示快捷入口区域 (今日概览/课时统计/健康管理/打卡记录)"
    //   → 现行 home_screen 已无该区域（功能下沉到底部导航），
    //   该用例不可恢复，删除并登记至 widget-test-realign-report.md。
    // 旧 TC-004 第二条 "底部导航栏应包含首页、日志、统计、日记"
    //   → 文案已变（"日志"→"今日"，新增"课时/健康"），
    //   原断言不可机械保留；语义已被 TC-005-03 重写覆盖。
  });
}
