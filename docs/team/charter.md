# qq-glb-team 团队章程

> 文档版本：v1.1  
> 生效日期：2026-05-13（v1.1 更新：2026-06-03）
> 维护者：PM（main）  
> 适用范围：qq_glb 项目所有需求/缺陷的工程化交付

---

## 1. 章程目的

按照 **Harness Engineering** 工程化交付理念组建 qq-glb-team，明确角色分工、流水线协作流程、各环节的质量闸门与产出物要求，确保每一次代码变更都经过"产品 → 设计 → 开发 → 评审 → 测试"的完整闭环，杜绝"想到就改、改了就上"的随意提交。

---

## 2. 团队角色

| 角色 | 实体 | 启动参数 | 核心职责 | 不做的事 |
|---|---|---|---|---|
| **PM（项目管理）** | `main`（即本对话主体） | — | 需求接入与拆分、流程编排、闸门评审、跨角色协调、风险与节奏把控、最终验收 | 不直接修改 `lib/`、`test/` 下的代码 |
| **product-agent（产品功能设计）** | team member | `mode=default` | 需求澄清、用户场景、PRD（验收标准）、产品侧问答 | 不做技术方案、不做视觉设计 |
| **ux-agent（UI 设计）** | team member | `mode=default` | 交互流程、界面布局/状态变化、视觉规范、与 `lib/widgets/elegant_kit.dart` 风格对齐 | 不做产品决策、不写实现代码 |
| **dev-agent（开发）** | team member | `mode=default` | 编码实现、单元自测、修复 review 反馈 | 不自行决定需求/UI，所有代码改动须经 PM 评审与用户审批 |
| **qa-agent（测试）** | team member | `mode=default` | 用例设计、回归执行、缺陷验证、测试报告 | 不修改业务代码（仅可补 `test/` 用例） |

**权限模式说明**：所有 agent 启动时使用 `default` 模式，每次文件编辑都需要用户二次审批，PM 负责把好"派发-验收"两端。

---

## 3. 工程化协作流水线

```
[需求 / Bug]
    ↓
[PM]  接入 + 任务拆分（明确目标、范围、Blast Radius）
    ↓
[product-agent]  PRD（用户场景 + 验收标准）
    ↓ ── 闸门 G1：PM 评审 PRD ──
    ↓
[ux-agent]  设计稿 / UI 校验清单
    ↓ ── 闸门 G2：PM 评审 UI ──
    ↓
[dev-agent]  编码实现 + 单元自测
    ↓ ── 闸门 G3：Code Review（PM + skill:code-reviewer） ──
    ↓
[qa-agent]  补充用例 + 回归测试 + 测试报告
    ↓ ── 闸门 G4：PM 验收 ──
    ↓
[归档发布]
```

**驳回机制**：任一闸门未通过，回退至上一阶段责任 agent 修订；PM 在评审反馈中明确写出"必须修改项 / 建议项"。

---

## 4. 质量闸门标准

### G1 · PRD 评审（产物：`docs/prd/<feature>.md`）
**必须包含**：
- [ ] 一句话概述（What & Why）
- [ ] 用户场景（至少 1 个正向 + 1 个反向）
- [ ] 功能范围（In Scope / Out of Scope）
- [ ] 验收标准（可枚举、可测试，每条以"用户可以…"或"系统应当…"开头）
- [ ] 风险/依赖说明

### G2 · UI 评审（产物：`docs/design/<feature>.md` 或 `<feature>-ui-checklist.md`）
**必须包含**：
- [ ] 涉及屏幕/组件清单（带文件路径）
- [ ] 关键状态枚举（如：未打卡 / 已打卡 / 已过期）
- [ ] 每个状态的视觉/交互定义（图标、颜色、文案、可点击性）
- [ ] 与 `elegant_kit` 现有组件的复用关系
- [ ] 边界场景（空态、加载态、错误态）

### G3 · Code Review（产物：`docs/review/<feature>-review.md`）
**必须包含**：
- [ ] 改动文件与改动摘要
- [ ] 与 PRD 验收标准的对应关系
- [ ] 潜在问题（语义、性能、并发、向后兼容、错误处理）
- [ ] 最佳实践建议
- [ ] 通过 / 驳回结论 + 必要的 follow-up

### G4 · QA 验收（产物：`docs/qa/<feature>-report.md`）
**必须包含**：
- [ ] 测试范围与策略
- [ ] 用例清单（编号、前置、步骤、预期、实际、结果）
- [ ] 自动化用例落地路径（指向 `test/` 下的具体文件）
- [ ] 缺陷登记（如有）
- [ ] 通过 / 驳回结论

---

## 5. 通信协议

### 5.1 PM → agent 派发任务（消息样板）

```
[Task #<编号>] <阶段名>
目标：<一句话目标>
输入：<上游产物路径 / 关键代码路径>
产出：<本阶段必须输出的文件路径>
闸门标准：<引用本章程对应小节>
截止：<期望返回时间>
```

### 5.2 agent → PM 回报（消息样板）

```
[Task #<编号>] <阶段名> 完成
产出：<文件路径>
要点：<3 条以内的关键决策/发现>
阻塞：<如有，列出阻塞点>
请求：<请 PM 评审 / 请用户审批>
```

### 5.3 跨 agent 协作

agent 之间不直接通信，所有跨角色信息流转经 PM 中转，确保 PM 对全局状态可观测。例外：当 PM 显式授权某条横向沟通通道时（如 dev-agent 询问 ux-agent 边界细节），需将结论同步抄送 PM。

---

## 6. 文档目录约定

```
docs/
├── team/
│   └── charter.md                  # 团队章程（本文件）
├── prd/
│   └── <feature>.md                # 产品需求文档
├── design/
│   └── <feature>.md                # UI 设计稿 / 校验清单
├── review/
│   └── <feature>-review.md         # 代码审查记录
└── qa/
    └── <feature>-report.md         # 测试报告
```

**命名规范**：
- `<feature>` 使用 kebab-case，如 `checkin-status-fix`、`add-schedule-button`
- 每份文档头部统一包含：版本号、责任 agent、关联 Task 编号、关联 PRD/前序产物链接
- 测试报告参考 `test/TEST_REPORT.md` 现有格式

---

## 7. 工作流约束

### 7.1 PM 边界
- ✅ 评审产物、撰写章程类/简报类文档（`docs/team/`）
- ✅ 调用 `skill:code-reviewer` 主导 Code Review 闸门
- ❌ 直接编辑 `lib/`、`test/`、配置文件
- ❌ 越过 product-agent 自行决定需求范围

### 7.2 agent 边界
- 各 agent 仅在其职责文档目录下创建文件，不跨目录写入
- dev-agent 的代码改动必须先有 PRD（G1）和 UI 评审（G2）通过
- qa-agent 不得在未拿到 PRD 验收标准前编写用例

### 7.3 Blast Radius 控制
- 单次 case 的代码改动尽量限制在最少必要文件
- 任何涉及 schema、Provider 公共接口、跨页面共享组件的改动必须在 PRD 中显式标注，并在 G2/G3 阶段做兼容性确认

### 7.4 技术坑预防必读（源自 Task #007 recurring-rule-edit 实战）

以下 3 条源自 Task #007 的实战踩坑，后续所有涉及同类模式的 case **必须参考**：

#### 坑 1：`copyWith` 无法将字段置为 null

- **现象**：Dart 的 `copyWith` 惯用 `parentId ?? this.parentId` 模式，当需要将 `parentId` 从非 null 置为 `null` 时（如组长接力：新组长 `parentId=null`），`copyWith(parentId: null)` 实际传入 `null`，`?? this.parentId` 仍回退旧值，**赋 null 失败**。
- **预防**：凡需将字段置 null 的场景，一律用显式构造函数（`Schedule(...)`）而非 `copyWith`；或在 `copyWith` 中为可 null 字段引入 `Object? parentId = _sentinel` 哨兵模式。dev-agent 在 G3 编码前须确认本次 case 是否涉及"置 null"语义，如有则**禁用 copyWith 路径**。

#### 坑 2：事务边界——`txn` vs 非事务 DAO 混用

- **现象**：sqflite 的 `_db.transaction((txn) async { ... })` 内必须且只能用 `txn.xxx`（txn 的 query/insert/update/delete），若误用 `ScheduleDatabase.instance.xxx`（走外层 `_db`），该操作**脱离事务**，崩溃时不会回滚。
- **预防**：事务内所有 DB 操作一律走 `txn` 参数；通知操作（`NotificationService.cancelForSchedule` / `scheduleForSchedule`）和 UI 通知（`notifyListeners` / `loadSchedules`）放事务外执行。dev-agent 在 G3 提交 CR 前须自查：事务块内是否出现非 `txn.` 前缀的 DB 调用。

#### 坑 3：续期竞态——事务内生成范围须覆盖 `_ensureRecurringSchedulesExpanded` 判断

- **现象**：`_ensureRecurringSchedulesExpanded` 依据"已有最新实例日期 > needUntil"决定是否补全。若事务内生成范围不足（如只到当月末），commit 后 `_ensureRecurringSchedulesExpanded` 会再次补全，导致重复实例。
- **预防**：事务内生成新实例的范围须**≥** `_ensureRecurringSchedulesExpanded` 的 `needUntil` 计算范围（当前为"下月末 23:59:59"）。dev-agent 在 G3 编码时须对照 `_ensureRecurringSchedulesExpanded` 的 `needUntil` 计算逻辑，确保生成范围一致或更大。

---

## 8. 首个 case 流程裁剪规则（适用于已落地代码的回溯型 case）

针对"代码先行、流程后补"的特殊场景（如本次打卡 bug 修复），允许如下裁剪：

| 阶段 | 裁剪方式 |
|---|---|
| G1 PRD | 出"简版 PRD"，重点补足验收标准 |
| G2 UI | 若无 UI 变化，仅出"状态校验清单"代替设计稿 |
| Dev | 已落地改动作为"已交付物"直接进入 G3 |
| G3 Review | 必须正式走，不裁剪 |
| G4 QA | 必须正式走，不裁剪 |

**原则**：可以前置缺失的产物，但**不可省略 Review 与 QA 两道闸门**。

---

## 9. 章程版本管理

- 任何对本章程的修订须由 PM 起草并在对话中向用户确认后入库
- 章程变更应在文件头部更新版本号与生效日期
- 历史变更摘要追加至本章末尾的"变更记录"

---

## 10. 变更记录

| 版本 | 日期 | 变更摘要 | 作者 |
|---|---|---|---|
| v1.0 | 2026-05-13 | 初版发布：定义五角色、流水线、四闸门、通信协议、目录约定、首个 case 裁剪规则 | PM |
| v1.1 | 2026-06-03 | §7.4 新增「技术坑预防必读」3 条（copyWith 置 null / 事务边界 txn vs DAO 混用 / 续期竞态），源自 Task #007 实战 | PM |
