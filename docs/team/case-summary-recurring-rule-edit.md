# Case Summary · recurring-rule-edit「修改重复规则」

| 字段 | 值 |
| --- | --- |
| Task 编号 | #007 |
| Plan ID | 6a4fdf818f2b49b8af2be98edc86accd |
| 团队 | qq-glb-team（v2 重启） |
| 周期 | 2026-06-03（G1→G4 单日闭环） |
| 结论 | ✅ 四闸门全通过 + 用户 UI 终验通过，case 正式闭环 |
| 终验 | 2026-06-03 用户确认 6 条 UI 手测全部通过 ✅ |

---

## 1. 用户原始诉求

> 已有每周一到周五的循环日程，要改成每周一到周三。需要有入口能修改"种子日程 / 组长"那一条；修改后不影响已过去的日程，只影响未来。优化重复日程实现逻辑。

## 2. 锁定的 4 个产品决策

- **Q1=B**：详情页新增独立入口「修改重复规则」，与编辑/删除并列；普通编辑保持只改单实例。
- **Q2=B**：未来边界 = 明天 00:00 起（`dateTime >= 今天次日 00:00`）。
- **Q3=A**：已打卡的未来实例保留不动，只重排"未来 + 未打卡"。
- **Q4=B**：可同时把模板字段（标题/时分/结束时分/地点/备注/描述/分类/课程关联）批量同步到未来实例。

## 3. 四闸门交付物

| 闸门 | 责任 | 产物 | 结论 |
|---|---|---|---|
| G1 PRD | product-agent | `docs/prd/recurring-rule-edit.md`（24 条 AC） | ✅ |
| G2 设计 | ux-agent | `docs/design/recurring-rule-edit.md`（token 清单 + 弹窗精确稿 + K=0~K>3 矩阵） | ✅ |
| G3 实现 | dev-agent | 4 文件 +1605 行 | ✅ |
| G3 CR | PM（code-reviewer skill） | `docs/review/recurring-rule-edit-cr.md`（8.7/10） | ✅ |
| G4 测试 | qa-agent | `test/schedule_recurring_rule_test.dart`（862 行/17 用例）+ `docs/qa/recurring-rule-edit-test-report.md` | ✅ |

## 4. 实现要点（dev 落地的关键技术决策）

1. **新增 API**：`ScheduleProvider.previewRecurringRuleUpdate(...)`（dry-run）+ `commitRecurringRuleUpdate(...)`（事务化），返回 `RecurringRuleUpdatePreview{toDelete, toKeep, toCreate}`。
2. **组长接力**：原组长若落在"未来未打卡"被删区间，则把 `toCreate` 最早一条提升为新组长（`parentId=null`），其余指向它；组长在过去则原地 update 字段。
3. **copyWith 置 null 坑规避**：用显式 `Schedule(...)` 构造函数（`_buildLeaderInstance`），不用 `copyWith(parentId:null)`（`?? this.parentId` 会失效）。
4. **事务边界**：commit 内只用 `txn.xxx`（删 check_ins → 删 schedules → 插新实例 / update 组长）；通知 cancel/schedule + loadSchedules 放事务外。
5. **续期竞态规避**：commit 内一次性生成到下月末 23:59:59，使后续 `_ensureRecurringSchedulesExpanded` 因 `latest > needUntil` 不再重复补全。
6. **冲突避让（AC-07）**：`toCreate` 中与 `toKeep` 同日的项被移除，保护已打卡实例。

## 5. 配色横向决策（重要）

ux-agent 发现 memory 记录的 CASE-B v2.0「街头潮玩 × 收藏卡牌」（深紫蓝/橙、显式 16 槽位、禁用 fromSeed）**从未落地到 lib/ 代码**。仓库实际生效的是 v1.0「Wine Rose 玫瑰粉」+ `ColorScheme.fromSeed`。

**PM 决策**：以代码现状为准，本 case 沿用 v1.0 玫瑰粉，不打扰其它线；已 `update_memory` 修正该错误记忆。

## 6. 验证结果（PM 独立复核）

- `flutter test test/schedule_recurring_rule_test.dart` → **+17 All tests passed!**
- `flutter test`（全量） → **+104 All tests passed!**，无回归。
- 4 个改动文件 `read_lints` / `flutter analyze` → 0 issue（4 个预存 issue 在 home_screen / medical_records_screen 等无关文件，按 Blast Radius 原则未顺手改）。

## 7. 手测清单（✅ 用户终验已通过 · 2026-06-03）

自动化触达 75%（18/24 AC）。剩余 6 条 UI/交互 AC 经用户手测全部通过：

1. ✅ **AC-01**：重复组详情页 NavBar「修改重复规则」按钮（圆形 + `event_repeat_outlined`）出现在编辑↔删除之间。
2. ✅ **AC-02**：单实例详情页 NavBar 仅编辑/删除两枚按钮，不占位。
3. ✅ **AC-05**：编辑屏顶部副标题「生效起始日：明天起 · 2026-06-04（含）」+ 1px×40 accent 短线。
4. ✅ **AC-08**：weekly 取消所有星期勾选后点保存 → SnackBar「请至少选择一个星期」，不进预演弹窗。
5. ✅ **AC-15**：daily 模式星期区不渲染，切回 weekly 重现。
6. ✅ **AC-23**：影响弹窗「取消」为 TextButton、「确认修改」为 FilledButton（accent 底）。

> 24/24 AC 全部达成（自动化 18 + 手测 6）。

## 8. v2 候选改进

- 引入 mockito mock NotificationService → 补 AC-18/19/20 精确调用次数断言。
- 加 widget test → 补 6 条 UI AC 的自动化。
- 加事务内异常注入测试 → 补 AC-24 中段物理回滚 E2E。

## 9. 不在本次范围（明确排除）

❌ 普通编辑按钮行为变更 · ❌ DB schema 变更 · ❌ 改过去日程 · ❌ 解绑/合并组 · ❌ iOS Home Widget。
