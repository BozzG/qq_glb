# PRD - 修改重复规则（recurring-rule-edit）

| 字段 | 值 |
| --- | --- |
| 版本号 | v1.0 |
| 责任 agent | product-agent |
| Task 编号 | #007 |
| Plan ID | 6a4fdf818f2b49b8af2be98edc86accd |
| 关联资料 | [团队章程](../team/charter.md) · [Plan 文档](../../../../Library/Application%20Support/CodeBuddy%20CN/User/globalStorage/tencent-cloud.coding-copilot/plans/6a4fdf818f2b49b8af2be98edc86accd/plan.md) · [schedule_provider.dart](../../lib/providers/schedule_provider.dart) · [schedule_detail_screen.dart](../../lib/screens/schedule_detail_screen.dart) · [add_schedule_screen.dart](../../lib/screens/add_schedule_screen.dart) · [models.dart](../../lib/models/models.dart) |
| 上游产物 | plan.md（产品/技术/UI 决策） |
| 生效日期 | 2026-06-03 |
| 状态 | 待 G1 评审 |

## 1. 一句话概述（What & Why）

为「重复日程」补齐**修改组级别规则**的能力：用户可在不丢失已打卡记录、不影响过去日程的前提下，把已生成的重复组（如每周一~五）改成新规则（如每周一~三），改动只对**未来未打卡**的实例生效。

## 2. 用户故事 + 主流程时序

**典型场景**（PRD 主用例）：今天 = 2026-06-03 周三 14:30。用户原有重复日程「篮球训练 18:00-20:00」每周一~五循环。教练通知后续课表改为每周一~三。

### 主流程
| 步骤 | 用户操作 | 系统行为 |
|---|---|---|
| 1 | 在首页或周视图点开任一篮球训练实例（如 6/4 周四 18:00 那条），进入日程详情页 | 详情页 NavBar 显示三枚圆形图标按钮：编辑 / **修改重复规则** / 删除 |
| 2 | 点击「修改重复规则」按钮 | 跳转 `EditRecurringRuleScreen`，表单字段以**当前组组长**字段预填；顶部显示"生效起始日：明天起 · 2026-06-04（含）" |
| 3 | 在重复卡片把星期勾选从「一二三四五」改为「一二三」，其它字段不动 | 表单实时更新本地 state，未触发任何 DB 写入 |
| 4 | 点击底部「保存修改」按钮 | 调用 `previewRecurringRuleUpdate`，弹出 `RecurringImpactDialog` |
| 5 | 弹窗显示三行影响摘要 + 示例日期 | 「将删除 N 条未来未打卡实例 / 保留 M 条已打卡或今天及之前实例 / 按新规则重建 K 条新实例」 |
| 6 | 点击「确认修改」 | `commitRecurringRuleUpdate` 在事务内删除/接力组长/重建/通知刷新；事务后 `loadSchedules` 触发 UI 刷新 |
| 7 | 弹窗与编辑屏关闭，回到详情页 | 详情页 pop 回上一级（首页/周视图），新规则下首条实例出现在新日期上 |

### 反向场景
- 用户在第 3 步取消所有星期勾选 → 保存按钮置灰 / 点击给 SnackBar，不进入预演（见 AC-08）。
- 用户在第 5 步点「取消」→ 关闭弹窗回到编辑屏，无任何 DB 改动。

## 3. 功能范围

### In Scope
- 详情页 NavBar 新增第 3 枚圆形图标按钮「修改重复规则」（仅重复组显示）。
- 新屏 `EditRecurringRuleScreen`：可改字段含 repeatType、repeatDays、标题、描述、地点、备注、开始/结束时间时分、分类（ScheduleType）、是否关联课程 + 课程选择。
- 影响范围确认弹窗 `RecurringImpactDialog`：三行计数 + 示例日期 + 取消/确认两键。
- Provider 层：`previewRecurringRuleUpdate`（dry-run）+ `commitRecurringRuleUpdate`（事务化提交）。
- 通知服务对齐：删除实例 → `cancelForSchedule`；新建实例 → `scheduleForSchedule`；组长 update → 先 cancel 后 reschedule。
- 组长接力：原组长被删时，把组长身份过户给新规则下"未来第一条"。

### Out of Scope（不在本次范围）
1. 普通「编辑」按钮行为变更（保持当前"只改单实例"语义）。
2. DB schema 变更（不改 schedules / check_ins 表结构）。
3. 改过去日程（今天及之前的实例一律保留不动）。
4. 解绑组（把某条实例从重复组中拆出）/ 合并组（把两组合并）。
5. iOS Home Widget 同步刷新（widget 数据源未来另立项处理）。

## 4. 决策矩阵（Q1~Q4 已锁定的产品决策）

| 决策点 | 选项 | 锁定值 | 体现于 AC |
|---|---|---|---|
| Q1 入口形式 | A=复用编辑按钮 / **B=新增独立入口** | **B** | AC-01、AC-02、AC-03 |
| Q2 未来边界 | A=今天 00:00 / **B=明天 00:00** | **B** | AC-04、AC-05 |
| Q3 已打卡未来实例 | **A=保留** / B=级联删除 | **A** | AC-06、AC-07 |
| Q4 字段同步 | A=仅改规则 / **B=可同步模板字段** | **B** | AC-09、AC-10 |

## 5. 验收标准（≥ 18 条 AC）

> 列定义：编号 / 描述 / 验收方式（**UI** = 手测 UI 观察，**单测** = `test/` 自动化单测，**手测** = 手动操作回归）

| 编号 | 描述 | 验收方式 |
|---|---|---|
| AC-01 | 当 `schedule.repeatTemplateId != null && schedule.repeatType != RepeatType.none` 时，详情页 NavBar 在「编辑」与「删除」之间渲染第 3 枚 `ElegantCircleIconButton`（icon=`Icons.event_repeat_outlined`，36×36），点击跳转 `EditRecurringRuleScreen`。 | UI |
| AC-02 | 当日程不属于重复组（`repeatTemplateId == null` 或 `repeatType == none`）时，「修改重复规则」按钮不渲染（不占位、children 中条件 if 排除），NavBar 仍是两枚按钮。 | UI / 单测 |
| AC-03 | 普通「编辑」按钮的行为保持不变：进入 add_schedule_screen 编辑模式，保存后只更新当前单条实例，不影响同组其它实例、不触发组长接力。 | 单测 + 手测 |
| AC-04 | 「未来边界」严格定义为 `dateTime >= 明天 00:00`（即 `tomorrowStart = DateTime(now.year, now.month, now.day + 1)`）；今天 23:59 的实例视为"今天及之前"被保留。 | 单测 |
| AC-05 | 编辑屏顶部副标题区显示"生效起始日：明天起 · YYYY-MM-DD（含）"，日期为 `tomorrowStart` 的年月日，文字使用 12px letterSpacing 2，下方有 1px×40 accent 短分隔线，且该字段在 v1 不可改。 | UI |
| AC-06 | 已打卡的未来实例（`_checkIns.any((c) => c.scheduleId == s.id)` 命中）一律落入「保留集」，不删除、不重建、不修改其 `dateTime` / `repeatType` / `repeatDays`，其打卡记录原样保留。 | 单测 |
| AC-07 | 当新规则下某新实例的日期与「保留集」中已存在的同日实例（`isSameDay`）冲突时，**优先保留旧实例**，新实例不写入，避免同一天出现两条同组日程。 | 单测 |
| AC-08 | 当用户把星期勾选全部取消（`newRepeatDays.isEmpty`）且 `newRepeatType == weekly` 时，「保存修改」按钮触发后必须**阻止进入预演**，UI 给出 SnackBar 文案"请至少选择一个星期"，不调用 preview，也不写库。 | UI / 单测 |
| AC-09 | 用户在编辑屏修改了模板字段（标题 / 描述 / 地点 / 备注 / 开始时间时分 / 结束时间时分 / 分类 / 是否关联课程 / 课程 ID），保存后这些字段会被批量同步到所有**新建的未来实例**和**保留的组长实例（仅时分，不动其年月日）**。 | 单测 |
| AC-10 | 已打卡的未来实例（保留集中含打卡的）的模板字段**不会被同步**，原值保持，避免覆盖用户在该实例上已有的修改。 | 单测 |
| AC-11 | **边界 1（组长接力）**：当原组长（`parentId == null` 且属于该组）落入"未来未打卡"被删区间时，删除原组长后，新规则下生成的"未来第一条"被设为新组长（`parentId = null`），其它新实例 `parentId` 指向新组长 id；`repeatTemplateId` 继续复用旧组的值，保证 `getGroupScheduleIds` 仍能拉到完整组。 | 单测 |
| AC-12 | **边界 1（组长保留）**：当原组长在保留集（dateTime < 明天 00:00 或已打卡）时，不删除组长，仅 `update` 其 repeatType / repeatDays / 模板字段时分及 updatedAt（**dateTime 的年月日保持原值**，仅刷新时分），新建实例的 `parentId` 指向该原组长 id。 | 单测 |
| AC-13 | **边界 2（空 repeatDays）**：除 AC-08 阻断 UI 入口外，`previewRecurringRuleUpdate` / `commitRecurringRuleUpdate` 接收到 `newRepeatType == weekly && newRepeatDays.isEmpty` 时，必须抛出 `ArgumentError` 或返回空预演（toCreate 为空、toDelete 为空），不得静默删除原组所有未来实例。 | 单测 |
| AC-14 | **边界 3（weekly → daily）**：当 `newRepeatType` 从 weekly 切到 daily 时，`newRepeatDays` 自动忽略（视为每天命中），新实例按日生成；UI 上 daily 模式不渲染星期勾选区。 | UI / 单测 |
| AC-15 | **边界 3（daily → weekly）**：当 `newRepeatType` 从 daily 切到 weekly 时，UI 显示星期勾选区；若用户未勾选任何星期则触发 AC-08；勾选后新实例只在勾选 weekday 上生成。 | UI / 单测 |
| AC-16 | **边界 3（weekly → custom）**：当 `newRepeatType == custom` 时，沿用 `newRepeatDays`（含 1~7 任意子集）作为命中星期，与 weekly 行为等价；不引入新的"间隔周数 / 月份"语义（v1 范围内 custom 与 weekly 等价，前端文案差异不在本次）。 | 单测 |
| AC-17 | **边界 4（跨月续期）**：commit 后 `_ensureRecurringSchedulesExpanded` 在下次首页/周视图刷新时，使用**新规则下的组长**（其 repeatType/repeatDays/时分）继续把实例续期到下月末（`下月最后一天 23:59`），不会用旧规则重新生成已被删除的星期。 | 单测 |
| AC-18 | **边界 5（通知刷新-删除）**：每条进入"删除集"的实例，commit 内对其 id 调用 `NotificationService.cancelForSchedule(id)`，事务后该 id 在系统通知队列中不存在；cancel 失败仅 `debugPrint`，不阻塞主流程。 | 单测 |
| AC-19 | **边界 5（通知刷新-新建）**：每条新建的实例，commit 内对其 id 调用 `NotificationService.scheduleForSchedule(schedule)`，按 dateTime 注册本地通知；新建数 = 通知注册数。 | 单测 |
| AC-20 | **边界 5（通知刷新-组长 update）**：当组长落入保留集需 update 时，commit 内先 `cancelForSchedule(oldId)` 再 `scheduleForSchedule(newSchedule)`，避免老通知与新时分错位。 | 单测 |
| AC-21 | **边界 6（弹窗计数精确性）**：`RecurringImpactDialog` 显示的 N（toDelete.length） / M（toKeep.length） / K（toCreate.length）必须分别等于 `previewRecurringRuleUpdate` 返回值的三组实际长度，三者之和不要求恒定（保留集与重建集可在不同日期上共存）。 | 单测 |
| AC-22 | **边界 6（弹窗文案）**：弹窗标题"确认修改重复规则"；三行图标 + 文字依次为 `delete_sweep_outlined` + "将删除 {N} 条未来未打卡实例" / `lock_outline` + "保留 {M} 条已打卡或今天及之前实例" / `add_circle_outline` + "按新规则重建 {K} 条实例"；底部小字 "示例日期：{date1}、{date2}、{date3} …等共 {K} 条"，示例日期取自 `toCreate` 列表的首/中/尾三条，格式 "M/d 周X"（如 "6/4 周四"），K ≤ 3 时不出现"等共"后缀。 | UI |
| AC-23 | **边界 6（弹窗按钮）**：操作区两枚按钮——左侧「取消」（TextButton，点击关闭弹窗、不写库、保留编辑屏 state）；右侧「确认修改」（FilledButton，背景 `AppElegant.accent`，点击触发 commit 并在成功后关闭编辑屏 + pop 详情页）。 | UI |
| AC-24 | **事务原子性**：commit 内所有 delete/insert/update 操作包在 `_db.transaction` 内；事务内任意一步抛异常，整体回滚，commit 调用方收到 Future error，调用前后 schedules 表与 check_ins 表保持一致。 | 单测 |

**AC 总数：24 条**（≥ 18 满足）

## 6. 影响范围确认弹窗 · 文案精确稿

```
┌──────────────────────────────────────────┐
│        确认修改重复规则                    │
├──────────────────────────────────────────┤
│  🗑  将删除 5 条未来未打卡实例              │
│  🔒  保留 3 条已打卡或今天及之前实例        │
│  ➕  按新规则重建 8 条实例                  │
│                                          │
│  示例日期：6/4 周四、6/8 周一 …等共 8 条    │
├──────────────────────────────────────────┤
│              [取消]    [确认修改]          │
└──────────────────────────────────────────┘
```

**字段映射**：
- N=`toDelete.length`，M=`toKeep.length`，K=`toCreate.length`。
- 示例日期格式：月份与日不补 0（`6/4` 而非 `06/04`）；"周X" 取中文星期一字。
- 当 K ≤ 3，示例日期列出全部，不加"…等共 N 条"。
- 当 K > 3，示例日期取首条 / 中位条（`toCreate[(K/2).floor()]`） / 末条，加"…等共 K 条"。

## 7. 风险 / 依赖

| 类型 | 项 | 缓解 |
|---|---|---|
| 风险 | 通知 cancel/schedule 与 DB 事务非原子 | cancel 失败仅 `debugPrint`；schedule 失败也不阻塞 UI；保留人工"重启应用刷新通知"兜底（既有行为） |
| 风险 | 跨月续期时新组长时分被错误覆盖 | AC-12 约束组长 update 仅刷新时分，年月日保持原值 |
| 风险 | 弹窗示例日期对国际化/本地化不友好 | v1 写死中文 "周X"，i18n 留作 v2 |
| 依赖 | `NotificationService.cancelForSchedule` / `scheduleForSchedule` 已存在且接口稳定 | dev-agent 在 G3 前用 code-explorer subagent 校验 |
| 依赖 | `Schedule.copyWith` 已覆盖本次所有字段 | 无需扩展 model（plan.md 已确认） |

## 8. 自评 G1 闸门标准

参照 charter §4.G1：

- [x] 一句话概述（§1）
- [x] 用户场景：正向主流程（§2 表）+ 反向（§2 反向场景）
- [x] 功能范围 In Scope / Out of Scope（§3）
- [x] 验收标准 ≥ 18 条，每条以"用户/系统"主语 + 可观测/可测试（§5，共 24 条）
- [x] 风险/依赖说明（§7）

**自评结论**：满足 G1 通过条件，等待 PM 评审。
