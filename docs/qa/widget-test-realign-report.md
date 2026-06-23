# 测试报告 - Widget 测试与现行 UI 对齐（既存红灯修复）

| 字段 | 值 |
| --- | --- |
| 报告ID | QA-005 |
| 版本号 | v1.0 |
| 责任 agent | qa-agent |
| Task 编号 | #005 |
| 类型 | G4 follow-up · 测试维护型（按章程允许的裁剪） |
| 关联 | [docs/qa/checkin-status-fix-report.md](checkin-status-fix-report.md) v1.0 第 4.3 / F-01 / F-02 节 |
| 执行时间 | 2026-05-14 |
| 应用版本 | 1.0.0+1 |

---

## 1. 任务边界（PM 派单原文映射）

| 维度 | 内容 |
| --- | --- |
| 目标 | 把 `test/home_screen_schedule_button_test.dart`（16 例）与 `test/today_overview_screen_test.dart`（9 例）修到当前 UI 全绿 |
| ✅ 允许 | 仅改 `test/` 下两个文件；可参考 `lib/screens/home_screen.dart`、`today_overview_screen.dart`、`widgets/elegant_kit.dart` 当前实现重写 finder/文案断言 |
| ❌ 禁止 | 改 `lib/` 下任何业务代码；新增 widget test 文件 |
| 阻塞处理 | 用例对应的 UI 已不存在且无替代项 → 登记为"已废弃用例"并删除，写入"删除清单"小节 |

---

## 2. 现行 UI 与旧测试锚点差异盘点

### 2.1 home_screen.dart

| 旧测试锚点 | 现行 UI 状态 | 处理方式 |
| --- | --- | --- |
| `FloatingActionButton` | ❌ 已不使用，改为自建 `Container` + `GestureDetector` 浮起按钮 | 重写：锚定到 `Icons.add_rounded` |
| `Scaffold.floatingActionButtonLocation == centerDocked` | ❌ 已不再使用 Scaffold.fab | **删除**（已废弃用例） |
| `BottomNavigationBar` | ❌ 已不使用，改为自建 `Container` + 7 格 `_NavItem` | 重写：锚定到底部导航文本标签 |
| 文本 `日志` | ❌ 已改为 `今日` | **删除并以 TC-005-03 重写覆盖**（含新增的 `课时/健康` 标签） |
| 快捷入口区 `今日概览/课时统计/健康管理/打卡记录` | ❌ 已不存在；功能下沉到底部导航 | **删除**（已废弃用例） |
| 文本 `添加新日程`（AddScheduleScreen 标题） | 未在派单边界内验证 | 锚点改为更稳健的 `AddScheduleScreen` widget 类型 |

### 2.2 today_overview_screen.dart

| 旧测试锚点 | 现行 UI 状态 | 处理方式 |
| --- | --- | --- |
| `今日概览` | ✅ 仍在（ElegantNavBar 标题） | 保留 |
| `芊芊的一天` | ❌ 已替换为 `记录成长的一天` | 改文案 |
| `周五 / 周日 / 周一`（textContaining） | ❌ Date Hero 顶部用 `EEEE.toUpperCase()`，zh_CN 下输出 `星期五/星期日/星期一` | 改文案 |
| `5天 / 7天` | ❌ `_miniStat` 仅显示 weekday 数字（无 "天" 字后缀） | 改为对数字本身的存在性断言 |
| `本周已过` | ✅ 仍在 | 保留 |
| `无记录` | ❌ 改为 `今日医疗 · 无` | 改文案 |
| `今日医疗`（精确 text） | ❌ 实际渲染为 `今日医疗 · 无`（合并字符串） | 改为完整字符串 |
| `今日日程` | ✅ 仍在（区块标题） | 保留 |
| `课程课时` | ❌ 已改为 statTile label `已用课时 / 共 X.X` | 改文案 |
| `本周打卡`（containing） | ✅ 仍在（区块标题） | 改为精确文本 |
| `总打卡` | ✅ 仍在 | 保留 |
| `有记录天数` | ❌ 已改为 `活跃天数` | 改文案 |
| `健康管理`（containing） | ✅ 仍在（区块标题） | 改为精确文本 |
| 4 块 stat tile 数值 | 视口截断未渲染 → 需要拉大测试 viewport | 引入 `tester.view.physicalSize=800x2400` |

---

## 3. 修复明细

### 3.1 `test/home_screen_schedule_button_test.dart`

**重写**（v1.0 → v2.0），新组织为 1 个 group + 4 个子 group：

| 用例编号 | 描述 | 关键锚点 |
| --- | --- | --- |
| TC-005-01a | 首页应显示中央加号新增按钮 | `find.byIcon(Icons.add_rounded)` findsOneWidget |
| TC-005-01b | 中央加号入口图标颜色为白色 | `Icon.color == Colors.white && size == 24` |
| TC-005-02a | 点击中央加号应跳转到 AddScheduleScreen | `find.byType(AddScheduleScreen)` findsOneWidget |
| TC-005-02b | 从 AddScheduleScreen 返回后应回到 HomeScreen | 弹栈后 `AddScheduleScreen` 消失、`HomeScreen` 与 add 图标仍在 |
| TC-005-03a | 底部导航 6 个标签 `首页/今日/统计/课时/健康/日记` 各 1 处 | `find.text(label) findsOneWidget` |
| TC-005-03b | 初始时仅"首页"为选中态（fontWeight w600） | Text 样式断言 |
| TC-005-04 | 顶栏问候语命中 1/4 + 设置按钮存在 | `find.byIcon(Icons.settings_outlined)` |

合计：**7 条用例，全部通过**。

### 3.2 `test/today_overview_screen_test.dart`

**重写**（v1.0 → v2.0），1 个 group + 5 个子 group：

| 用例编号 | 描述 | 关键锚点 |
| --- | --- | --- |
| TC-005-T1a | 默认 currentDate 渲染主标题与副标题 | `今日概览` / `记录成长的一天` |
| TC-005-T1b | currentDate=2026-04-24 时显示 `24 / 2026` | Date Hero 数字与年份 |
| TC-005-T2a | statTile `今日医疗 · 无` | 精确文本 |
| TC-005-T2b | "今日日程" 区块空态 `今日无安排` | 区块 + 空态文案 |
| TC-005-T2c | "健康管理" 区块空态 `暂无医疗记录` | 区块 + 空态文案 |
| TC-005-T3a | 周五 (weekday=5) 时 `本周已过` 数值为 5 | `本周已过` + 数字 5 |
| TC-005-T3b | 完成率 `完成率 0%` 文案存在 | 完整文案 |
| TC-005-T4a | 主标题 / 各区块 / 4 块 stat tile 全部存在 | 综合断言 |
| TC-005-T4b | 数据空时多个 stat tile 数值显示为 `0` | findsAtLeastNWidgets(3) |
| TC-005-T5a | 周日 (2026-04-26) 显示 `星期日`、本周已过=7 | EEEE.zh_CN |
| TC-005-T5b | 周一 (2026-04-20) 显示 `星期一` + weekday=1 | EEEE.zh_CN |

合计：**11 条用例，全部通过**。

#### 关键修复点：测试 viewport

`TodayOverviewScreen` 内容较长（顶部 4 stat tile + 3 区块），默认 800×600 viewport 下 `SliverList` 会 lazy 截断"本周打卡 / 健康管理"等下半部分子树，导致旧版测试中部分 finder 即使文案正确也命中不到。本期通过：

```dart
tester.view.physicalSize = const Size(800, 2400);
tester.view.devicePixelRatio = 1.0;
addTearDown(() {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
});
```

将测试视口拉高到 2400px，确保所有区块都被构建。这是测试基础设施层面的修复，不涉及业务代码。

---

## 4. 已删除用例清单（按派单的"阻塞处理"约定登记）

| 旧用例 | 旧锚点 | 删除原因 | 替代覆盖 |
| --- | --- | --- | --- |
| home_screen TC-001 第 1 条 `首页应显示日程快捷按钮FAB` | `find.byType(FloatingActionButton)` | 现行实现已不使用 Scaffold.fab；锚点已不存在 | TC-005-01a 改用 `Icons.add_rounded` 锚点 |
| home_screen TC-001 第 2 条 `FAB按钮应有正确的图标` | `find.byIcon(Icons.add)` | 图标改为 `Icons.add_rounded` | TC-005-01a / 01b |
| home_screen TC-002 第 1 条 `点击FAB应跳转到添加日程页面` | `find.text('添加新日程')` | 锚点是 AddScheduleScreen 内部标题，不稳定；本期改用 widget type 锚点 | TC-005-02a |
| home_screen TC-002 第 2 条 `从添加日程页面返回后应回到首页` | 同上 | 同上 | TC-005-02b |
| **home_screen TC-003** `FAB位置应为centerDocked` | `Scaffold.floatingActionButtonLocation == centerDocked` | 现行实现已彻底不用 Scaffold.fab，无任何替代锚点 | **无替代，已废弃** |
| home_screen TC-004 第 1 条 `首页应显示底部导航栏` | `find.byType(BottomNavigationBar)` | 现行使用自建 Container；锚点不存在 | TC-005-03a 用文本标签覆盖 |
| home_screen TC-004 第 2 条 `底部导航栏应包含首页、日志、统计、日记` | 4 个旧文案 | 文案已变（"日志"→"今日"，新增"课时/健康"） | TC-005-03a 重写为 6 标签全集 |
| **home_screen TC-005** `首页应显示快捷入口区域 (今日概览/课时统计/健康管理/打卡记录)` | 4 个文案 | 现行 home_screen 已不存在该区域，功能下沉到底部导航 | **无替代，已废弃** |
| today_overview TC-001~005 共 9 条 | 多处旧文案（芊芊的一天 / 周五 / 5天 / 7天 / 周日 / 周一 / 无记录 / 课程课时） | 文案已变 | TC-005-T1~T5 共 11 条全部重写覆盖原意图 |

**显式废弃（无替代）**：
- `home_screen TC-003 FAB位置应为centerDocked`
- `home_screen TC-005 首页应显示快捷入口区域`

理由：业务实现已彻底重构，原断言对当前 UI 已无意义。按派单约定登记。

---

## 5. 执行结果

### 5.1 单文件验证

```bash
flutter test test/home_screen_schedule_button_test.dart
# 输出：+7: All tests passed!

flutter test test/today_overview_screen_test.dart
# 输出：+11: All tests passed!
```

### 5.2 全量回归

```bash
flutter test
# 输出：+87: All tests passed!
```

包含：
- Task #004 已落地的 6 条新增用例（TC-004-01 ~ 06）
- 本期重写的 7 + 11 = 18 条 widget 用例
- 其余 provider/model/migration/diary 共 63 条历史用例

**共计 87 条，0 失败，0 阻塞，0 lint warning。**

---

## 6. 边界声明

- 本期未修改 `lib/` 下任何业务代码（git diff 仅触及 `test/home_screen_schedule_button_test.dart`、`test/today_overview_screen_test.dart`、`docs/qa/widget-test-realign-report.md`）
- 在用例对齐过程中未发现任何 UI 缺陷或歧义；如后续发现，按章程 5.2 阻塞样板回报 PM 升级
- 课程列表 / 课程详情 / 日记 / 设置 等屏幕未纳入本期范围

---

## 7. 闸门结论

| 项 | 结论 |
| --- | --- |
| 两文件全部用例转绿 | ✅（7 + 11 = 18，0 失败） |
| flutter test 全量 0 失败 | ✅（87/87） |
| 仅改 `test/` 下两个文件 | ✅ |
| 未触及 `lib/` | ✅ |
| 未新增 widget test 文件 | ✅ |
| 已废弃用例显式登记 | ✅（4 节） |

**Task #005 follow-up 闸门：✅ 通过，建议归档。**

---

## 8. 变更记录

| 版本 | 日期 | 变更 | 责任 |
| --- | --- | --- | --- |
| v1.0 | 2026-05-14 | 首版 follow-up 报告，Task #005 完成 | qa-agent |
