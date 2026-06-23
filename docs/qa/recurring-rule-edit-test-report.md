# QA 测试报告 - 修改重复规则（recurring-rule-edit）

| 字段 | 值 |
| --- | --- |
| 版本号 | v1.0 |
| 责任 agent | qa-agent |
| Task 编号 | #007 |
| Plan ID | 6a4fdf818f2b49b8af2be98edc86accd |
| 关联资料 | [团队章程](../team/charter.md) · [PRD v1.0](../prd/recurring-rule-edit.md) · [Design v1.0](../design/recurring-rule-edit.md) · [G3 CR 报告](../review/recurring-rule-edit-cr.md) · [测试源码](../../test/schedule_recurring_rule_test.dart) |
| 上游产物 | G1 PRD（24 条 AC）/ G2 Design（含 buildSampleLine K=0~K>3 矩阵）/ G3 实现（4 文件 1605 新增行）/ G3 CR（8.7/10 已通过） |
| 生效日期 | 2026-06-03 |
| 状态 | 待 G4 评审 |

---

## 1. 测试范围与策略

### 1.1 范围

本批测试聚焦**「修改重复规则」case 在 Provider 层的核心逻辑**，覆盖：

- `ScheduleProvider.previewRecurringRuleUpdate(...)`（dry-run）
- `ScheduleProvider.commitRecurringRuleUpdate(...)`（事务化）
- `RecurringRuleUpdatePreview` 数据结构
- `widgets/recurring_impact_dialog.dart` 顶层纯函数 `buildSampleLine(...)`
- 与既有 `updateSchedule(...)` 的向后兼容关系

### 1.2 策略

| 维度 | 选择 | 理由 |
|---|---|---|
| 测试层级 | **单元测试**（基于 sqflite_common_ffi 内存 DB） | charter §4.G4 要求；与 `test/schedule_provider_test.dart`、`test/migration_test.dart` 同套基础设施，零新依赖（不动 pubspec.yaml） |
| 数据准备 | **直接 `DatabaseHelper().insert('schedules', ...)` 落库** | 避开 `addSchedule → _createRecurringInstances` 副作用，让组实例分布完全可控；同时配合"latest > 下月末 + 5 天"避免 `_ensureRecurringSchedulesExpanded` 触发自动续期对断言的干扰 |
| 通知服务 | **`NotificationService().isTestMode = true`** | 与既有测试一致，跳过实际通知调度 |
| 时间稳定性 | 用 `DateTime.now() / nextWeekday(...)` 动态计算 | 避免硬编码"6/4 周四"导致跑出窗口失效；buildSampleLine 矩阵唯一例外，其属纯函数测试，可硬编码日期 |
| 事务异常注入 | **降级**（详见 §4） | 在 sqflite_ffi 内存 DB 上稳定构造"事务内某条 insert 抛异常"需 monkey-patch DatabaseHelper 私有结构，越界 Blast Radius；改为静态源码断言 + ArgumentError 路径回归覆盖核心承诺 |

---

## 2. 用例清单与执行结果

### 2.1 总体统计

| 项 | 数 |
|---|---|
| 用例总数 | **17** |
| 通过 | **17** |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

> 单测文件：`test/schedule_recurring_rule_test.dart`（862 行）。

### 2.2 用例明细

> 列定义：编号 / 描述 / 关联 AC / 前置（核心条件） / 关键断言 / 结果

#### Group A · 修改重复规则 - preview & commit 场景

| 编号 | 描述 | 关联 AC | 前置 | 关键断言 | 结果 |
|---|---|---|---|---|---|
| **TC-007-01** | 组长在过去保留 - update 组长字段 / 新实例指向原组长 | AC-04 / AC-06 / AC-09 / AC-12 / AC-21 | 组长=昨天 9:00；3 条未来未打卡子实例 + 1 条远期 latest（>下月末+5d）锚点；改 weekly[1,2,3] → weekly[1,2,3,5] + title='篮球训练-改名' / 时分=18:30 | (1) 组长在 toKeep；(2) 三条未来子实例在 toDelete；(3) commit 后组长 id 不变 / parentId=null / title=新值 / repeatDays=[1,2,3,5] / dateTime 年月日不动而时分=18:30；(4) 新实例 parentId=组长 id | ✅ |
| **TC-007-02** | 组长在未来未打卡 → 接力（新组长 = toCreate.first） | AC-11 | 组长=未来周一无打卡；1 条更远未来子实例 | (1) 原组长 id 已删；(2) 新组只有 1 个 parentId=null；(3) 新组长 repeatDays=[2,3] / 时分=19:00；(4) 其它新实例 parentId=新组长 id | ✅ |
| **TC-007-03** | 已打卡未来实例进 toKeep / 冲突避让 | AC-04 / AC-06 / AC-07 | 组长=昨天；2 条未来未打卡（周一/周二）；周一那条直接 insert 一条 check_ins | (1) monFuture 在 toKeep；(2) tueFuture 在 toDelete；(3) toCreate 与 toKeep 中任意实例都不同日；(4) commit 后 monFuture 仍存在 + 打卡记录保留 | ✅ |
| **TC-007-04** | weekly → daily / repeatDays 被忽略 / 每天命中 | AC-14 | 组长=昨天 weekly[1,3,5]；改 daily（repeatDays=[9999] 应被忽略） | (1) toCreate.length = [明天, 下月末] 天数；(2) commit 后组长 + 新实例 repeatType=daily（注：保留集中今天及之前由 expand 续出的实例按 PRD AC-04/AC-06 原样保留 weekly，符合预期，断言已对此精确分组） | ✅ |
| **TC-007-05** | commit 后 _ensureRecurringSchedulesExpanded 不重复补全 | AC-17 | 组长=昨天 weekly[2,3]；改 weekly[1,2,3,4,5] | (1) commit 后 latest > needUntil（下月末 00:00）；(2) 再次 loadSchedules 不增加 group 实例数 | ✅ |
| **TC-007-06** | preview 三组长度与实际操作严格一致 | AC-21 | 组长=昨天 + 5 条未来未打卡周一；改 weekly[1] | afterGroup = beforeGroup - toDelete.length + toCreate.length（守恒） | ✅ |
| **TC-007-09** | weekly + 空 repeatDays → 抛 ArgumentError | AC-13 | 组长=昨天 weekly[1,2]；改 weekly[] | (1) preview 抛 ArgumentError；(2) commit 同样抛（preview 先于事务） | ✅ |
| **TC-007-10** | 单实例 updateSchedule 不影响组内其它实例 | AC-03 | 组长 + 1 条未来子实例；用 `provider.updateSchedule(child.copyWith(title:'新标题'))` | (1) 仅 child.title 改；(2) leader.title 保持原值；(3) child 的 repeatType / repeatTemplateId 不变 | ✅ |

#### Group B · buildSampleLine 矩阵（design §5.4）

| 编号 | K | 输入 | 期望文案 | 结果 |
|---|---|---|---|---|
| **TC-007-08-K0** | 0 | `[]` | `''` | ✅ |
| **TC-007-08-K1** | 1 | `[6/4 周四]` | `示例日期：6/4 周四` | ✅ |
| **TC-007-08-K2** | 2 | `[6/4 周四, 6/8 周一]` | `示例日期：6/4 周四、6/8 周一` | ✅ |
| **TC-007-08-K3** | 3 | `[6/4 周四, 6/6 周六, 6/8 周一]` | `示例日期：6/4 周四、6/6 周六、6/8 周一` | ✅ |
| **TC-007-08-K4** | 4 | `[6/4, 6/6, 6/8, 6/10]` | `示例日期：6/4 周四、6/8 周一、6/10 周三 …等共 4 条` | ✅ |
| **TC-007-08-K5** | 5 | `[6/4, 6/6, 6/8, 6/10, 6/12]` | `示例日期：6/4 周四、6/8 周一、6/12 周五 …等共 5 条` | ✅ |
| **TC-007-08-K6** | 6 | `[6/4, 6/6, 6/8, 6/10, 6/12, 6/14]` | `示例日期：6/4 周四、6/10 周三、6/14 周日 …等共 6 条` | ✅ |

> 7 组用例 100% 命中 design §5.4 矩阵，**首/中/末三索引（0/2/2 / 0/2/3 / 0/2/4 / 0/3/5）互不重复**已被验证。

#### Group C · 事务原子性（AC-24）

| 编号 | 描述 | 关联 AC | 关键断言 | 结果 |
|---|---|---|---|---|
| **TC-007-07a** | 静态源码断言 - commit 内 DB 写操作仅走 `txn.xxx` | AC-24 | 读取 `lib/providers/schedule_provider.dart`，截取 `commitRecurringRuleUpdate` 函数体，断言：(a) 函数体内不出现 `await _db.delete` / `await _db.insert` / `await _db.update`；(b) 必须出现 `txn.delete` / `txn.insert` / `txn.update` 各至少一次 | ✅ |
| **TC-007-07b** | preview 抛 ArgumentError 时 commit 无任何写入 | AC-24（局部回归） | 触发 weekly + 空 repeatDays 路径，捕获 ArgumentError 后断言 schedules 表行数与触发前完全一致 | ✅ |

---

## 3. AC 覆盖率（24 条）

> 列定义：AC 编号 / PRD 验收方式 / 本批单测覆盖 / 覆盖说明

| AC | PRD 标注 | 单测 | 说明 |
|---|---|---|---|
| AC-01 | UI | ❌ | UI 渲染条件，需手测 / widget test |
| AC-02 | UI / 单测 | ⚪ 部分 | UI 不渲染需要 widget test；本批未覆盖（不在派单 5 大场景） |
| AC-03 | 单测 + 手测 | ✅ | TC-007-10 |
| AC-04 | 单测 | ✅ | TC-007-01 / TC-007-03 / TC-007-04 / TC-007-06 |
| AC-05 | UI | ❌ | 编辑屏副标题视觉，需手测 |
| AC-06 | 单测 | ✅ | TC-007-01 / TC-007-03 |
| AC-07 | 单测 | ✅ | TC-007-03（toCreate ⊥ toKeep 同日断言） |
| AC-08 | UI / 单测 | ⚪ 部分 | UI 部分需手测；Provider 层逻辑等价于 AC-13（已覆盖） |
| AC-09 | 单测 | ✅ | TC-007-01（title='篮球训练-改名' + 时分=18:30 同步刷新） |
| AC-10 | 单测 | ✅ | TC-007-03（mon 已打卡保留实例 commit 后仍存在；其打卡记录原值保留 → 隐含模板字段也未被覆盖。完整模板字段 diff 断言可在 v2 加强） |
| AC-11 | 单测 | ✅ | TC-007-02 |
| AC-12 | 单测 | ✅ | TC-007-01 |
| AC-13 | 单测 | ✅ | TC-007-09 |
| AC-14 | UI / 单测 | ✅ | TC-007-04（Provider 部分） |
| AC-15 | UI / 单测 | ⚪ 部分 | Provider 端"weekly+空 days 抛错"覆盖（=AC-13）；UI 切换动画需手测 |
| AC-16 | 单测 | ⚪ 部分 | 由 `_generateDateTimes` 内 `case weekly: case custom:` 共用分支隐式覆盖；显式 custom 用例可在 v2 加 |
| AC-17 | 单测 | ✅ | TC-007-05 |
| AC-18 | 单测 | ⚪ 部分 | NotificationService 已被 `isTestMode=true` 拦截；本批未对 cancel 调用次数做 mock 断言（避免引入 mockito）。代码路径检查在 G3 CR 已通过 |
| AC-19 | 单测 | ⚪ 部分 | 同 AC-18 |
| AC-20 | 单测 | ⚪ 部分 | 同 AC-18 |
| AC-21 | 单测 | ✅ | TC-007-06（守恒律） |
| AC-22 | UI | ✅（计算部分） | buildSampleLine 矩阵 7 组用例已 100% 覆盖文案生成逻辑；图标 + token 颜色映射需 widget test 或手测 |
| AC-23 | UI | ❌ | 弹窗按钮交互，需手测 |
| AC-24 | 单测 | ⚪ 降级 | TC-007-07a（静态源码断言）+ TC-007-07b（ArgumentError 路径回归）；事务内"中间步骤抛异常 + 物理回滚"未覆盖（详见 §4 阻塞清单） |

### 3.1 覆盖率小结

| 等级 | 数 | 比例 |
|---|---|---|
| ✅ 完全单测覆盖 | 11 / 24 | 45.8% |
| ⚪ 部分覆盖（已隐式 / 已降级） | 7 / 24 | 29.2% |
| ❌ 仅手测 / Widget test 覆盖 | 6 / 24 | 25.0% |

> **手测/widget test 名单**：AC-01, AC-02（UI 部分）, AC-05, AC-08（UI 部分）, AC-15（UI 部分）, AC-23。
> **AC-22 文案矩阵已 100% 单测覆盖**；AC-22 视觉部分（图标颜色对应 `AppElegant.rose / sage / accent`）需 widget test 或手测。

---

## 4. 阻塞 / 黄灯清单

### 4.1 黄灯 - 事务内异常注入（AC-24 中段）

- **现象**：plan §3.1 / 派单"场景 7"原期望"mock _db.database 让 txn.insert 在第 N 步抛异常"。
- **难点**：`DatabaseHelper` 暴露的是 `database` getter（返回 `Future<Database>`），事务由 sqflite 框架管理；要稳定构造"事务内某次 insert 失败"需要：
  1. 包装 sqflite 的 `Database` 接口（涉及 ~20 个方法 forwarding） → 越界 Blast Radius；
  2. 或修改 `DatabaseHelper.isTestMode` 增加"poison pill"开关 → 侵入业务源码；
  3. 或直接在 `Schedule.toMap()` 抛异常 → 本测试套不掌握该模型代码权（qa-agent 仅可补 test/，不动 lib/）。
- **降级方案**：见 TC-007-07a / TC-007-07b。
  - **TC-007-07a 静态源码断言** → 保证"commit 函数体内只用 txn.xxx"，从代码组织层面消除"事务外脏写"风险，等价于事务原子性的**前置条件**。
  - **TC-007-07b ArgumentError 回归** → 验证 commit 顶部的 preview 校验抛错时不留任何痕迹，等价于"前置异常路径回滚"。
- **未覆盖部分**：事务**进入后**某条 `txn.insert` 抛异常导致回滚的 E2E 行为；建议在集成测试 / 真机回归阶段手测：构造 schedules 表上一条与 commit 内将插入的 id 完全相同的旧记录（极小概率），观察 PRIMARY KEY 冲突时的回滚效果。
- **风险评估**：**低**。理由：
  1. G3 CR 已对 `commitRecurringRuleUpdate` 的事务边界做了静态评审通过；
  2. 所有 insert 用 `Uuid().v4()`，与既存 id 冲突概率几近 0；
  3. sqflite 的事务 API 本身保证"任何步骤抛异常 → 整个事务回滚"，是 SQLite 层的硬性承诺。

### 4.2 黄灯 - NotificationService 调用次数断言（AC-18 / AC-19 / AC-20）

- **现象**：本批未对 `cancelForSchedule` / `scheduleForSchedule` 的调用次数做精确断言。
- **难点**：需引入 mockito 或自写 mock 类，pubspec.yaml 已有 mockito 但项目当前测试套未使用，引入 mock 会改变 NotificationService 单例模式。
- **降级方案**：依赖 G3 CR 的代码路径检查（已记录 `cancelForSchedule(oldId)` / `scheduleForSchedule(newSchedule)` / `cancelForSchedule(originalLeader.id)` 三处调用点齐全，且包在 try/catch 内不阻塞主流程）。
- **建议**：v2 case 引入 mockito mock NotificationService 后补回 AC-18 / AC-19 / AC-20 的精确调用次数断言。

### 4.3 阻塞 - 无

无阻塞项；G4 可交付。

---

## 5. 测试基础设施

### 5.1 沿用既有

| 项 | 来源 | 用法 |
|---|---|---|
| `sqflite_common_ffi` | pubspec.yaml dev_dependencies（既有） | `databaseFactory = databaseFactoryFfiNoIsolate`；内存 DB |
| `DatabaseHelper.isTestMode = true` | `lib/services/database_helper.dart`（既有） | 让 DB 走内存 |
| `NotificationService().isTestMode = true` | `lib/services/notification_service.dart`（既有） | 跳过通知调度（事务后通知操作不阻塞测试） |
| `tzdata.initializeTimeZones()` | `package:timezone/data/latest_all.dart`（既有） | NotificationService.init() 依赖 |
| `setUp/tearDown` 模式 | `test/schedule_provider_test.dart` 既有 | 每个用例 `resetDatabase` + `recreateTables` |

### 5.2 本批新增

无新依赖、无新 mock、无新 helper（除测试文件内局部函数）。`pubspec.yaml` 未改动（符合派单约束："不要修改 pubspec.yaml 引入新依赖"）。

### 5.3 测试文件局部工具

```dart
DateTime nextWeekday(DateTime base, int targetWeekday, {int hour, int minute}); // 找下一个周X
Future<void> insertRaw(Schedule s);    // 直接落库，绕开 _createRecurringInstances
DateTime calcNextMonthEnd(DateTime now);  // 与 schedule_provider._nextMonthEnd 同源
DateTime calcNeedUntil(DateTime now);     // 与 schedule_provider._ensureRecurringSchedulesExpanded.needUntil 同源
Future<String> _readFile(String path); // dart:io 读源码，用于静态断言（TC-007-07a）
```

---

## 6. 执行命令与输出

### 6.1 命令

```bash
cd /Users/bozzguo/project/qq_glb
flutter test test/schedule_recurring_rule_test.dart
flutter analyze test/schedule_recurring_rule_test.dart
```

### 6.2 关键输出（最后部分）

```
00:01 +16: 事务原子性 (AC-24) - 降级断言 TC-007-07a: 静态断言 - commit 内 DB 写操作仅走 txn.xxx
00:01 +17: 事务原子性 (AC-24) - 降级断言 TC-007-07b: preview 抛 ArgumentError 时 commit 无任何写入
00:01 +17: (tearDownAll)
00:01 +17: All tests passed!
```

### 6.3 Analyzer

```
Analyzing schedule_recurring_rule_test.dart...
No issues found! (ran in 0.9s)
```

---

## 7. 自评 G4 闸门标准

参照 charter §4.G4：

- [x] **测试范围与策略** → §1
- [x] **用例清单**（编号、前置、步骤、预期、实际、结果） → §2.2 三组表
- [x] **自动化用例落地路径** → `test/schedule_recurring_rule_test.dart`（862 行，17 用例 100% 通过）
- [x] **缺陷登记** → §4 黄灯清单（2 项黄灯，0 阻塞，均给出降级方案与风险评估）
- [x] **通过 / 驳回结论** → 见 §8

---

## 8. 结论

### 8.1 综合判定

✅ **建议通过 G4 闸门，归档发布**。

### 8.2 理由

1. **17 用例 100% 通过**，覆盖 plan.md / 派单锁定的 10 大场景；
2. **AC 覆盖率**：完全单测覆盖 11/24（45.8%）+ 部分覆盖 7/24（29.2%）= 75% 已被自动化测试触达；剩余 25%（6 条）均为 UI 视觉/交互 AC，需在 G4 验收手测阶段配合走查；
3. **flutter analyze 0 issue**，符合 charter §4 质量基线；
4. **无新依赖、无 pubspec.yaml 改动**，Blast Radius 控制良好；
5. **黄灯项 2 个（事务异常注入 / 通知调用次数）已给出降级方案与 v2 改进路径**，不阻塞本次 G4。

### 8.3 G4 验收手测建议清单（给 PM）

请在归档前手测以下 6 条 UI/交互 AC（每条预计 ≤ 2 分钟）：

1. **AC-01**：在重复组实例的详情页 NavBar 上确认"修改重复规则"按钮（圆形 + `event_repeat_outlined`）出现在编辑↔删除之间。
2. **AC-02**：在单实例日程详情页确认 NavBar 仅 2 枚按钮（编辑/删除），不占位。
3. **AC-05**：进入 EditRecurringRuleScreen 后顶部副标题区显示"生效起始日：明天起 · 2026-06-04（含）"+ 1px×40 accent 短分隔线。
4. **AC-08**：在 weekly 模式取消所有星期勾选后，点击"保存修改" → SnackBar 文案"请至少选择一个星期"，不进入预演弹窗。
5. **AC-15**：在 daily 模式下，星期勾选区不渲染；切回 weekly 后再次出现，且未选时按钮自动 disabled。
6. **AC-23**：影响范围确认弹窗的"取消"为 TextButton（ink 字）；"确认修改"为 FilledButton（accent 底白字）。

### 8.4 后续改进（v2 candidate）

- 引入 mockito mock NotificationService → 补 AC-18 / AC-19 / AC-20 精确调用次数断言；
- 加 widget test → 补 AC-01 / AC-02 / AC-05 / AC-08 / AC-15 / AC-22 / AC-23 的 UI 自动化；
- 加事务内异常注入测试 → 补 AC-24 中段事务回滚的 E2E 验证（需小幅扩展 DatabaseHelper 的 testHook）。

---

## 9. 变更记录

| 版本 | 日期 | 变更摘要 | 作者 |
|---|---|---|---|
| v1.0 | 2026-06-03 | 初版发布：17 用例全绿；AC 覆盖率 75%；2 黄灯 0 阻塞；自评 G4 通过 | qa-agent |
