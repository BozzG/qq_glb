# Code Review 记录 - 打卡状态判定修复

| 字段 | 值 |
| --- | --- |
| 版本号 | v1.0 |
| 责任 agent | main (PM) |
| Task 编号 | #003 |
| 关联 PRD | [docs/prd/checkin-status-fix.md](../prd/checkin-status-fix.md) |
| 关联 UI 清单 | [docs/design/checkin-status-fix-ui-checklist.md](../design/checkin-status-fix-ui-checklist.md) |
| 闸门 | G3（Code Review） |
| Review 时间 | 2026-05-13 |
| Reviewer | main (PM) |
| 配合 agent | dev-agent（待命答疑，本次无需求） |

---

## 1. 评审范围（diff 对照）

| 文件 | 改动性质 | 行数（关键段） |
| --- | --- | --- |
| `lib/providers/schedule_provider.dart` | 核心逻辑修复 | L259-L298（checkIn / isCheckedIn / isCheckedToday） |
| `lib/screens/home_screen.dart` | 调用面 + 文案更新 | L125-L144（_ScheduleCard 调用 isCheckedIn + SnackBar 文案） |

未改文件（保持原状，本期不动）：
- `lib/screens/today_overview_screen.dart`：仍调用 `isCheckedToday`，依赖别名兼容（AC-06、PRD R1）
- `lib/screens/schedule_detail_screen.dart`：同上，文案"今日已打卡"为黄灯文案债（D-01/D-02）
- `lib/widgets/elegant_check_button.dart`：UI 组件无改动，依据 UI 清单第 3.1 节判定视觉一致

---

## 2. 逐项核对（PRD AC × 代码实现）

### AC-01 历史日已打卡显示
**PRD 要求**：用户打开"昨日及更早"已打卡日程，对应卡片打卡按钮显示"已打卡"状态。

**代码核对**：
- `schedule_provider.dart` L293-L295：`isCheckedIn(scheduleId)` 仅判断 `_checkIns.any((c) => c.scheduleId == scheduleId)`，**不再涉及"今天"日期匹配**。
- `home_screen.dart` L125-L127：`_ScheduleCard.isCheckedIn` 直接来自 `provider.isCheckedIn(实例id)`。
- 卡片渲染 L619-L623：`ElegantCheckInButton` 的 `isChecked` 透传 `isCheckedIn` 参数。

**判定**：✅ 通过。historical 实例打开后，按钮态由 check_ins 表是否有该实例 id 决定，与"今天"无耦合。直接对应 UI 清单 **VC-01**。

### AC-02 不可重复打卡
**PRD 要求**：对已存在 check_in 的日程实例再次触发 `checkIn()` 必须返回 false 且不写入新记录；UI 给出明确反馈。

**代码核对**：
- `schedule_provider.dart` L262-L263：`alreadyChecked = _checkIns.any((c) => c.scheduleId == scheduleId); if (alreadyChecked) return false;` 校验在写库**前**，幂等性正确。
- 没有 race condition 风险：`checkIn()` 是 async 但单线程，事件循环内 `_checkIns` 状态稳定。
- `home_screen.dart` L137-L144：`success == false` 时弹 SnackBar 文案 `这条日程已经打过卡啦`，与 UI 清单 IC-01 文案完全一致。

**判定**：✅ 通过。直接对应 IC-01。

### AC-03 重复日程跨天独立
**PRD 要求**：同一 `repeatTemplateId` 下不同日期的实例打卡状态彼此独立。

**代码核对**：
- `_createRecurringInstances`（L66-L124）为每个匹配日期生成**独立 Schedule**（L88：`isFirst ? template.id : Uuid().v4()`），实例 id 全局唯一。
- `isCheckedIn` 完全按 `scheduleId` 匹配，自然天生支持跨天独立。
- `_ensureRecurringSchedulesExpanded`（L129-L203）扩展时同样使用 `Uuid().v4()`（L173），不复用已有 id。

**判定**：✅ 通过。架构上在 schedule 层做了实例化（不是按 templateId + 日期推导），打卡判定可天然独立。直接对应 VC-06。

### AC-04 当天打卡不受影响
**PRD 要求**：当天日程首次点击打卡仍正常切换为"已打卡"。

**代码核对**：
- 整个 checkIn 流程（L259-L288）未对"是否今天"做任何条件判断，所有日期一视同仁。
- `home_screen.dart` L137-L139 调用路径在所有日期下一致。

**判定**：✅ 通过。对应 IC-02。

### AC-05 课程类扣课时
**PRD 要求**：课程类日程打卡成功后扣 1 课时。

**代码核对**：
- `schedule_provider.dart` L274-L280：`if (schedule.isCourse && schedule.courseId != null) { await _deductCourseHours(schedule.courseId!, checkIn.id, 1.0); }`，仅在首次写入成功路径执行。
- AC-02 的 `if (alreadyChecked) return false` 在前，重复点击不会触发扣课时。

**判定**：✅ 通过。课时扣减幂等，不会重复扣。需 QA 用例覆盖（QA 阶段告知）。

### AC-06 旧入口兼容
**PRD 要求**：原 `isCheckedToday` 的两个调用点（today_overview / schedule_detail）行为正确。

**代码核对**：
- `schedule_provider.dart` L297-L298：`bool isCheckedToday(String scheduleId) => isCheckedIn(scheduleId);` 仅是 thin wrapper，语义统一。
- `today_overview_screen.dart` L26、L110：调用 `isCheckedToday`，经别名指向 `isCheckedIn`，**含义已变更**为"该实例是否已打卡"。
  - 旁路风险：今日概览页"N 已打卡"统计是 `today.where((s) => isCheckedToday(s.id))`（L26），其中 `today` 已是当天日程列表，所以"今日 N 已打卡"语义仍正确（只是底层判定方式从"今天有打卡记录"变成"该实例有打卡记录"，结果在当日范围内等价）。
- `schedule_detail_screen.dart` L140：`provider.isCheckedToday(_schedule.id)` 用于判定按钮 disabled 态，含义已变为"该实例是否已打卡"，符合 PRD 期望（历史日打卡也应 disable）。但文案"今日已打卡"在 historical 场景语义不严格 —— **黄灯，按 D-01 登记**。

**判定**：✅ 通过（含黄灯登记）。

---

## 3. 与 UI 清单 checklist 对照（静态评审项）

> 静态可审项（VC-01/02/04/06/07/08、IC-01/02、BC-01）由 PM 对照代码确认；动态项（VC-03 切换 ≤250ms、IC-03 SnackBar 触发、IC-04 课时扣减）移交 QA G4 阶段。

| 编号 | 类型 | 评审结论 | 依据 |
| --- | --- | --- | --- |
| VC-01 | 静态 | ✅ 通过 | `home_screen.dart` L125 `provider.isCheckedIn(...)` 不依赖今天 |
| VC-02 | 静态 | ✅ 通过 | `_ScheduleCard` L619-L623 `isChecked: isCheckedIn` 透传 |
| VC-03 | 动态 | ↪ 移交 QA | 依赖 `ElegantCheckInButton` 内部 AnimatedContainer 250ms（UI 清单 3.1） |
| VC-04 | 静态 | ✅ 通过（无改动） | `today_overview_screen.dart` 图标使用代码未改 |
| VC-05 | 静态 | ✅ 通过（语义一致） | "today.where(isCheckedToday)" → "today.where(isCheckedIn)"，当日范围内等价 |
| VC-06 | 静态 | ✅ 通过 | 实例 id 全局唯一（Uuid.v4），跨天独立天然成立 |
| VC-07 | 静态 | ✅ 通过（无改动） | `schedule_detail_screen.dart` 按钮逻辑沿用 |
| VC-08 | 静态 | ✅ 通过 | 本次改动未引入硬编码 RGB；颜色全部经 AppElegant |
| IC-01 | 静态 | ✅ 通过 | `home_screen.dart` L142 SnackBar 文案 = `这条日程已经打过卡啦` |
| IC-02 | 静态 | ✅ 通过 | success==true 路径无 SnackBar、无报错 |
| IC-03 | 动态 | ↪ 移交 QA | 详情页 `_handleCheckIn` 未改动，但需回归验证 |
| IC-04 | 动态 | ↪ 移交 QA | AC-05 静态通过，但课时数变化需 QA 验证 |
| BC-01~04 | 边界 | ↪ 移交 QA | 边界态需运行时校验 |

---

## 4. 代码质量观察

### 4.1 优点
1. **修复路径最小**：仅改了 1 个公共方法的实现 + 1 个调用点，影响面小、回滚成本低。
2. **向后兼容设计**：`isCheckedToday` 保留为 alias，避免一次性大改面而引入新问题。
3. **注释清晰**：L290-L292 文档注释直接点明"日程实例独立于日期"的核心模型。
4. **重复校验提前**：`checkIn` 中先判 `alreadyChecked` 再写库，幂等性由代码层而非数据库唯一约束保证（适合 SQLite 项目）。

### 4.2 改进建议（非阻塞，记录为技术债）

| 编号 | 类别 | 建议 | 处理 |
| --- | --- | --- | --- |
| T-01 | 命名 | `isCheckedToday` 别名应在调用方迁移完成后移除（PRD R1） | 记录到 D-03，下一迭代由 product-agent 起 PRD |
| T-02 | 测试 | `schedule_provider_test.dart` L116 仍调用 `isCheckedToday`，应增加 `isCheckedIn` 的直测用例（含 historical 场景） | 移交 QA G4 阶段补齐 |
| T-03 | 文案 | 详情页"今日已打卡" / "今天已经打卡过啦"在 historical 场景语义偏差 | D-01/D-02 黄灯登记，下一迭代 |
| T-04 | 数据 | 当前无 schedules 表的 unique 索引在 (templateId, dateTime)；理论上 `_ensureRecurringSchedulesExpanded` 在并发或异常重试时可能产生重复实例。本次不阻塞，但值得排进未来质量项 | 记录，不在本次 case 内处理 |

### 4.3 安全性 / 性能 / 边界
- 无 SQL 注入风险（用 prepared 接口）。
- `_checkIns.any` 在打卡量级（千级以下）下性能无忧。
- 无空指针风险：`firstWhere` 含 `orElse: () => throw Exception(...)` 路径，`schedule_provider.dart` L274-L277。

### 4.4 lint 状态
- 已确认无 lint 错误（前置已检查）。

---

## 5. 闸门结论

| 闸门项 | 状态 |
| --- | --- |
| PRD 6 条 AC 全部对照通过 | ✅ |
| UI 清单静态项全部通过 | ✅ |
| 改动最小、回滚可控 | ✅ |
| lint / 文档注释 / 命名 | ✅ |
| 黄灯登记完整（D-01/D-02/D-03/T-04） | ✅ |
| 动态项已明确移交 QA | ✅ |

**G3 评审结论：✅ 通过，可进入 G4（QA）阶段。**

---

## 6. 移交 QA 的关键事项（G3 → G4 接力清单）

QA 阶段（qa-agent）需要重点覆盖：

1. **新增直测用例**：`isCheckedIn(scheduleId)` 在历史日已打卡 / 未打卡 / 重复日程跨天三场景下的返回值断言。
2. **回归 `isCheckedToday` 别名**：保证既有调用方语义未坏。
3. **重复打卡幂等**：连续两次 `checkIn(同 id)` 第二次必返回 false 且 check_ins 表只有一条。
4. **课程扣课时幂等**：连续两次 checkIn 课程类日程，仅扣一次课时。
5. **重复日程跨天独立**：构造 `repeatTemplateId` 相同的两个不同日期实例，对 D1 打卡不影响 D2 状态。
6. **VC-03 / IC-03 / IC-04 动态项**：通过 widget test 或集成测试覆盖。
7. **测试报告**输出至 `docs/qa/checkin-status-fix-report.md`，遵循章程 6 节格式。

---

## 7. dev-agent 答疑记录

本次 G3 review 过程未触发对 dev-agent 的提问，dev-agent 保持待命状态。修复点清晰、注释充分，无需额外说明。

---

## 8. 变更记录

| 版本 | 日期 | 变更 | 责任 |
| --- | --- | --- | --- |
| v1.0 | 2026-05-13 | 首版 review 完成，G3 闸门通过 | main (PM) |
