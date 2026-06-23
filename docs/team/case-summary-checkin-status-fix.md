# 团队磨合首个 Case 闭环简报 - 打卡状态判定修复

| 字段 | 值 |
| --- | --- |
| 简报 ID | SUM-001 |
| 责任角色 | PM（main） |
| 团队 | qq-glb-team |
| Case | 打卡状态判定修复（Task #001~#004） |
| 闭环日期 | 2026-05-13 ~ 2026-05-14 |
| 版本 | v1.0 |

---

## 1. Case 摘要

**问题**：`schedule_provider.dart` 中 `isCheckedToday` 使用"今日"窗口判定，导致历史日已打卡日程在 UI 上仍显示为未打卡；课程类日程在重复点击场景下存在课时多扣风险。

**修复落点**：
- `lib/providers/schedule_provider.dart`：`isCheckedIn(scheduleId)` 改为按 `scheduleId` 直查 `check_ins`；`isCheckedToday` 降级为兼容旧入口的别名；`checkIn` 幂等化（重复打卡返回 false、不重复扣课时）。
- `lib/screens/home_screen.dart`：`_ScheduleCard` 调用面从 `isCheckedToday` 切到 `isCheckedIn`；SnackBar 文案细化。

---

## 2. 流水线与质量闸门执行情况

```
需求接入 → G1 PRD → G2 UI 清单 → G3 Code Review → G4 QA 验收 → 归档
   ✅        ✅        ✅            ✅              ✅          ✅
```

| 阶段 | 任务 | 责任 agent | 产物 | 闸门结论 |
| --- | --- | --- | --- | --- |
| 接入 | Task #001 PM 接入拆分 | main | plan.md + 任务派发 | — |
| G1 | Task #002 PRD 撰写 | product-agent | `docs/prd/checkin-status-fix.md` | ✅ 通过 |
| G2 | Task #002 UI 校验清单 | ux-agent | `docs/design/checkin-status-fix-ui-checklist.md` | ✅ 通过 |
| G3 | Task #003 Code Review | dev-agent + main（code-reviewer skill） | `docs/review/checkin-status-fix-review.md` | ✅ 通过 |
| G4 | Task #004 QA 回归 | qa-agent（code-explorer subagent） | `docs/qa/checkin-status-fix-report.md` | ✅ 通过 |

---

## 3. 关键数据

| 指标 | 数值 |
| --- | --- |
| PRD AC 数量 | 6 条（AC-01~06） |
| UI 清单校验项 | VC 8 项 + IC 4 项 + BC 4 项 |
| Code Review 发现技术债 | 4 项（T-01~T-04，全部黄灯，移交后续迭代） |
| 新增自动化用例 | 6 条（TC-004-01~06，全部位于 `test/schedule_provider_test.dart`） |
| 新增用例通过率 | 6/6 = 100% |
| 回归测试集 | +68 全绿（provider/model/migration/diary） |
| 新增缺陷 | 0 |
| AC → 用例覆盖率 | 6/6 = 100% |

---

## 4. Follow-up 登记

| 编号 | 类型 | 描述 | 来源 | 处理建议 |
| --- | --- | --- | --- | --- |
| T-01 | 命名/别名清理 | `isCheckedToday` 别名待逐步迁移 | G3 Review | 下一迭代 PRD |
| T-02 | 测试覆盖 | 详情页与首页集成测试缺失（MV-01/MV-02 未自动化） | G3 Review / G4 4.3 | 下一迭代 PRD |
| T-03 | 文案语义 | D-01/D-02 详情页/首页打卡文案语义不严格、不统一 | UI 清单第 6 节 / G3 | 下一迭代 PRD |
| T-04 | 数据完整性 | `schedules(templateId, dateTime)` 缺 unique 索引 | G3 Review | 下一迭代 PRD |
| F-01 | 既存红灯 | `home_screen_schedule_button_test.dart` 16 用例失败（与现行 UI 不匹配） | G4 4.3 | 独立 Task：widget 测试与现行 UI 对齐 |
| F-02 | 既存红灯 | `today_overview_screen_test.dart` 9 用例失败 | G4 4.3 | 同 F-01 |

---

## 5. 团队磨合 DoD 验证

| DoD 项 | 状态 |
| --- | --- |
| team 创建成功（qq-glb-team） | ✅ |
| 4 个 agent 响应（product / ux / dev / qa） | ✅ |
| `docs/team/charter.md` 落地 | ✅ |
| 首个 case 全流程闭环（G1~G4） | ✅ |
| PM 简报（本文档） | ✅ |
| 过程产物全部归档至 `docs/` | ✅ |

---

## 6. 复盘观察

**做得好的**：
- 流水线 + 闸门机制清晰，每阶段产出物有明确锚点，AC ↔ 清单 ↔ 用例三向追踪闭环完整。
- code-explorer subagent 在 G4 阶段帮助 qa-agent 快速摸清既有测试基础设施，避免重建轮子。
- code-reviewer skill 在 G3 阶段输出结构化结论，T-01~T-04 技术债显式登记而非淹没。

**可改进的**：
- qa-agent 在 G4 完成后未主动按"四要素"通信协议（任务编号 / 阶段 / 产物路径 / 阻塞点）回报，PM 需主动追问。后续应在 charter 中加强通信协议执行。
- 黄灯债（T-01/T-03、D-01~D-03）的统一收口方案缺失，建议下一迭代集中处理一次"文案/命名/别名"专项清理。
- widget 测试既存红灯（F-01/F-02）属于历史欠账，需独立 Task 跟进。

**章程未来增量**：
- 增加"通信协议执行清单"作为 agent 交付前自检项。
- 增加"既存红灯"在闸门评审中的判定模板，避免每次重复论证。

---

## 7. 变更记录

| 版本 | 日期 | 变更 | 责任 |
| --- | --- | --- | --- |
| v1.0 | 2026-05-14 | 首版团队磨合 case 闭环简报 | PM（main） |
