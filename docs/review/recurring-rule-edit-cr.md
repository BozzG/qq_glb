# Code Review - 修改重复规则（recurring-rule-edit）

| 字段 | 值 |
| --- | --- |
| 版本号 | v1.0 |
| 责任 reviewer | team-lead（PM） + skill:code-reviewer |
| Task 编号 | #007 |
| Plan ID | 6a4fdf818f2b49b8af2be98edc86accd |
| 上游产物 | [PRD](../prd/recurring-rule-edit.md)（24 AC）· [Design](../design/recurring-rule-edit.md) |
| 审查范围 | 4 个文件，1605 新增行 |
| 生效日期 | 2026-06-03 |

## 1. 审查范围

| # | 路径 | 性质 | 行数 |
|---|---|---|---|
| 1 | `lib/providers/schedule_provider.dart` | MODIFY | 351 → 777（+426） |
| 2 | `lib/screens/schedule_detail_screen.dart` | MODIFY | 446 → 471（+25） |
| 3 | `lib/screens/edit_recurring_rule_screen.dart` | NEW | 1024 |
| 4 | `lib/widgets/recurring_impact_dialog.dart` | NEW | 130 |

## 2. 总体评分：8.7 / 10（良好偏优秀）

| 维度 | 分 | 备注 |
|---|---|---|
| 代码质量（命名 / 复杂度 / 重复） | 9 | 私有 helper 拆分得当，命名清晰；少量构造重复（_buildLeaderInstance / _buildChildInstance）但符合"明确 > DRY"原则 |
| 安全性（注入 / 越权） | 9 | 全部 SQL 走 sqflite 参数化（`?` 占位 + `whereArgs`），无字符串拼接 |
| 性能 | 8 | 算法 O(N + 90)，组规模 < 100 时常数级；通知刷新放事务外，不阻塞 DB |
| 可维护性（注释 / 模块化 / 可测） | 9 | 关键算法在 commit 顶部注释中给出 6 步清单；preview 与 commit 拆分便于单测 |

## 3. 优点（do 得好的地方）

✅ **事务边界严格**：`db.transaction((txn) async {...})` 内只用 `txn.xxx`，通知 API 放事务外，符合探查报告 §6 第 2 条要求；事务后 `for ... cancelForSchedule` 与 `for ... scheduleForSchedule` 都包了 try/catch + debugPrint，平台通道异常不阻塞主流程。

✅ **copyWith 坑完美规避**：`_buildLeaderInstance / _buildUpdatedLeader` 显式用 `Schedule(...)` 构造函数 + `parentId: null`，规避了 `copyWith(parentId: null)` 不能置空的语言陷阱（探查报告 §4.4）。

✅ **续期竞态预防**：commit 一次性生成到 `_nextMonthEnd(now)` = 下月末 23:59:59，`loadSchedules` 触发的 `_ensureRecurringSchedulesExpanded` 因 `latest.dateTime > needUntil`（needUntil 无时分）不会重复补全。

✅ **24 AC 全覆盖**：dev 自评映射表逐条对应到具体行号；本 review 抽查 AC-04（tomorrowStart 公式）、AC-12（leader update 年月日不动）、AC-22（buildSampleLine K 矩阵）、AC-24（事务原子性）均无偏差。

✅ **Blast Radius 控制**：4 文件改动严格匹配 plan.md 清单；`updateSchedule / deleteSchedule / addSchedule / isCheckedIn / getGroupScheduleIds` 全部公共方法语义未动，PRD AC-03（普通编辑路径不变）天然满足。

✅ **零裸十六进制**：grep `Color(0xFF` 在两个新文件中无命中；颜色全走 `AppElegant.*` token，符合 Design §7 view token 清单要求。

✅ **错误处理双保险**：UI 层（edit_recurring_rule_screen `_onTapSave` SnackBar）+ Provider 层（preview 入口 `ArgumentError`）共同兜底空 `repeatDays`；preview / commit 找不到 anchor 时抛 `StateError`，调用方可观测。

## 4. 问题清单

### 🔴 严重

无。

### 🟡 中等

无（详见 §5 已澄清观察点）。

### 🟢 轻微

**M-01**（轻微，可选修复）：`commitRecurringRuleUpdate` 第 461 行事务内 `if (preview.toCreate.isEmpty) return;` 在已删除 check_ins / schedules 后才 return。
- **影响**：该路径需要同时满足 `toDelete.nonEmpty + toCreate.isEmpty`，但上层 (AC-08/AC-13) 已阻断 weekly+empty，路径不可达。
- **建议**：增加注释说明"该兜底为防御编程，正常路径不可达"或在 preview 阶段提前 throw（不破坏现有行为）。
- **决策**：本次不强制修复，加注释即可。

**M-02**（轻微）：`_nextMonthEnd` 中 23:59:59 的硬编码与 `_ensureRecurringSchedulesExpanded` 的 needUntil（00:00:00）匹配是隐式契约。
- **影响**：未来若有人改 `_ensureRecurringSchedulesExpanded` 的 needUntil 时分，可能导致触发重复补全。
- **建议**：在两处加交叉注释（"//  与 _ensureRecurringSchedulesExpanded.needUntil 配合"）。
- **决策**：建议加注释，不阻塞 G3 通过。

**M-03**（轻微）：`schedule_provider.dart` 文件已达 777 行，已超出"600 行可维护阈值"。
- **建议**：未来有新需求时考虑把 `RecurringRuleUpdatePreview` 类与 `_buildLeaderInstance / _buildChildInstance / _generateDateTimes` 抽到 `lib/providers/recurring_rule_engine.dart`。
- **决策**：列入技术债 T-02，本次不动。

## 5. 已澄清观察点

| ID | 观察 | 澄清结论 |
|---|---|---|
| O-01 | 事务后调 loadSchedules 是否会触发 _ensureRecurringSchedulesExpanded 重复补全？ | **不会**。commit 生成到下月末 23:59:59，扩展逻辑 needUntil = 下月末 00:00:00，`latest > needUntil` 跳过补全。✅ |
| O-02 | ScheduleType 切换后保留旧 courseId 是否合理？ | 沿用 `add_schedule_screen` 既有产品逻辑，未在本 case 引入，不阻塞。 |
| O-03 | flutter analyze 4 个 issue 是否本次引入？ | **否**，全部为 home_screen / medical_records_screen / diary 等预存 issue，与本 case 4 个改动文件无关。本次新增/修改文件 0 issue。 |

## 6. 改进建议（落地优先级）

| 优先级 | 建议 | 落地建议 |
|---|---|---|
| P2 | M-01 / M-02 注释加固（5 行注释级改动） | 可在本次 G3 顺手修复 |
| P3 | M-03 文件拆分 | 列入技术债 T-02，下个 case 再做 |
| P3 | 把 `_buildSampleLine` 单测独立到 widget test | 由 qa-agent 在 G4 落地（PRD AC-22 已覆盖） |

## 7. 安全性专项检查

| 检查项 | 结果 |
|---|---|
| SQL 注入（字符串拼接） | ✅ 全部参数化（`where: 'id = ?', whereArgs: [id]`） |
| 跨 schedule 越权（外键） | ✅ 操作严格限定 `repeatTemplateId == templateId` 范围 |
| 时区 / 跨设备数据漂移 | ⚠️ 沿用既有"本地 DateTime + ISO 8601"策略，跨时区设备迁移会偏移；非本 case 引入，已在 PRD §7 风险栏列出 |
| PII 日志泄漏 | ✅ debugPrint 仅打 id 前缀与计数（`del=$d keep=$k new=$n`），未打 title / location / memo |

## 8. 通过 / 驳回结论

**结论：✅ G3 通过**

理由：
1. 24 条 AC 全部映射到具体实现，抽查关键 4 条均无偏差；
2. 4 个改动文件 IDE 端 0 lint，flutter analyze 4 个 issue 全部为预存（不在本次 Blast Radius）；
3. 严重问题 0 项、中等问题 0 项；轻微问题 3 项（M-01/M-02 建议加注释，M-03 列入技术债）；
4. 探查报告标记的 3 个关键技术坑（copyWith null / 事务边界 / 续期竞态）均已规避。

**预存 issue 处理决策**：
- home_screen / medical_records_screen 等 4 个预存 issue **不在本次 Blast Radius**，不在本 G3 修复；
- 列入技术债 T-03 "通用 lint 清理"，由后续 case 收口或独立闸门处理。

**G3 状态**：进入 G4 测试。

## 9. 后续行动

- ✅ 本 review 文档归档至 `docs/review/recurring-rule-edit-cr.md`
- ⏭ 触发 qa-agent 进入 G4：编写 `test/schedule_recurring_rule_test.dart` 覆盖 5 大场景 + preview 计数 + 事务回滚
- ⏭ M-01 / M-02 注释加固（可选）
