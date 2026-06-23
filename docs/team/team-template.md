# qq-glb 团队组队模板（Team Template）

> 文档版本：v1.1
> 生效日期：2026-05-14（v1.1 更新：2026-06-03）
> 维护者：PM（main）
> 用途：作为下次组建团队的"配方手册"，供 PM 复用以快速重建符合本项目工程化标准的协作团队
> 关联：[charter.md](./charter.md)（团队章程，定义 What & Why）；本文件定义 How（如何组队、如何启动、如何收尾）

---

## 1. 模板适用场景

本模板适用于：
- 全新需求 / Bug 修复，需要按 `charter.md` 流水线（G1 → G2 → G3 → G4）正式交付
- 同一工作空间（`/Users/bozzguo/project/qq_glb`）下的任何 case
- 由 PM（main）作为团队 lead 编排的多 agent 协作

不适用于：
- 单文件、单步的轻量修改（直接由 PM 处理）
- 跨工作空间协作（需要新起 workspace）

---

## 2. 团队组成（标准配方）

### 2.1 角色清单

| 角色 name | 职责定位（取自 charter §2） | spawn 时机 | 初次上线必读 |
|---|---|---|---|
| `team-lead` | PM、流程编排、闸门评审（即 main 自身，无需 spawn） | 团队创建时已存在 | 全部 docs/team/ |
| `product-agent` | PRD 撰写、用户场景、验收标准 | 接到新 case 时第一个 spawn | charter.md §4.G1、§5、§6 |
| `ux-agent` | UI 状态枚举、交互定义、与 elegant_kit 对齐 | G1 通过后 spawn（或同时上线待命） | charter.md §4.G2、`lib/widgets/elegant_kit.dart` |
| `dev-agent` | 编码实现、自测、修复 review 反馈 | G2 通过后 spawn（回溯型 case 上线即待命） | charter.md §4.G3、`lib/` 关键模块结构 |
| `qa-agent` | 用例设计、回归执行、测试报告 | G3 通过后 spawn（或同时上线待命） | charter.md §4.G4、`test/` 现有结构 |

### 2.2 团队命名规范

- 长期通用团队：`qq-glb-team`（适合多个 case 串联交付）
- 单 case 专属团队：`<feature>-team`，如 `course-stats-team`、`habit-tracker-team`
- 临时探索团队：`spike-<topic>`，如 `spike-perf-tuning`

**推荐策略**：默认用 `qq-glb-team` 长期复用；当某个 case 体量大、需要长期占用上下文时，再起专属团队。

---

## 3. 启动剧本（PM 操作 SOP）

### 3.1 创建团队

```
team_create(team_name="qq-glb-team", description="...一句话目的...")
```

### 3.2 派发"上线 Ping"任务（首次组队必做）

依次 spawn 4 个 agent，每个的初始 prompt 包含三件事：
1. 必读 `docs/team/charter.md`，特别是其角色对应的闸门标准小节
2. 简要扫读自己负责领域的关键文件（清单见下表）
3. 回报"上线 Ping"，包含：已读章程版本、关键文件认知 3 条、闸门理解、状态=待命

| 角色 | 关键文件扫读清单 |
|---|---|
| product-agent | `docs/diary_feature_design.md`、`docs/requirement_schedule_button.md`、`docs/prd/`（如有历史 PRD） |
| ux-agent | `lib/widgets/elegant_kit.dart`、`lib/screens/home_screen.dart`、`docs/design/`（如有） |
| dev-agent | `lib/` 整体结构（screens/providers/widgets/models/services）、`pubspec.yaml`、`git status` |
| qa-agent | `test/` 全部文件、`test/TEST_PLAN.md`、`test/TEST_CASES.md`、`test/TEST_REPORT.md` |

**目的**：让每个 agent 在动手前对项目有"地基性认知"，避免后续 case 中反复重读基础文件。

### 3.3 派发首个 case

按 charter §5.1 派发样板下达 Task #00X，遵循"PRD → UI → Dev → Review → QA"顺序，逐闸门通过逐阶段派发。

---

## 4. 运行期纪律（PM 必守）

| 项 | 规则 |
|---|---|
| 评审节奏 | 每收到 agent 回报后**当轮内**给出评审结论或继续派单，不要积压（本团队曾因主控积压一天导致流程卡死） |
| 通信收敛 | agent 间不直接通信，所有信息经 PM 中转；PM 在每次中转时显式抄送依据 |
| 阻塞处理 | agent 阻塞回报必须**当轮**响应，要么解锁、要么升级、要么明确"暂缓 + 截止时间" |
| 边界守卫 | 派单时显式列出 ✅ 允许 / ❌ 禁止 清单，避免 agent 越界 |
| 产物溯源 | 每个产物头部必须含版本号、责任 agent、Task 编号、上游产物链接（charter §6） |

---

## 5. 收尾剧本（PM 操作 SOP）

### 5.1 单 case 归档（不解散团队）

PM 在 G4 通过后：
1. 给责任 agent（通常是 qa-agent）发"收闸通报"
2. 给其他 agent 同步"归档通报"，明确黄灯/技术债的后续处理路径
3. 团队继续待命，等待下一 case

### 5.2 团队解散（彻底清理实例）

PM 在判断"短期不会再用此团队"时：
1. 向**所有活跃成员**发 `shutdown_request`（一个不能少，否则成员会留在僵尸态）
2. 等待 4 个 `shutdown_response`（approve=true）
3. 调用 `team_delete` 清理团队目录
4. 向用户口头确认归档完成

### 5.3 解散前的资产保全清单

`team_delete` 会清掉 `.codebuddy/teams/<team_name>/`，所以解散前确认以下资产**已落到 docs/ 或 test/**：

- [ ] 所有 PRD（`docs/prd/`）
- [ ] 所有 UI 校验清单（`docs/design/`）
- [ ] 所有 Code Review 记录（`docs/review/`）
- [ ] 所有 QA 报告（`docs/qa/`）
- [ ] case 摘要（`docs/team/case-summary-<feature>.md`，可选但推荐）
- [ ] 黄灯/技术债登记（建议在 case-summary 或后续 PRD 头部承接）

`.codebuddy/teams/<team_name>/inboxes/*.json`（通信历史）**不会自动归档**，如需保留，请在解散前手动 copy 到 `docs/team/archive/<team_name>-inboxes/` 下。

---

## 6. 重启口令模板（用户视角）

下次想重新启用本模板组建团队，给 PM 发以下任一句即可：

| 场景 | 推荐口令 |
|---|---|
| 全新需求 | "按 docs/team/team-template.md 组建团队做 `<需求一句话描述>`" |
| 复用旧团队名做新需求 | "重启 qq-glb-team 做 `<需求>`，沿用 charter.md" |
| 收口黄灯/技术债 | "重启 qq-glb-team 做 `<R1/D-01/T-01...>` 收口" |
| 单纯探索/spike | "组个 spike-`<topic>` 团队评估 `<问题>`，不必走完整闸门" |

PM 收到口令后会按本文件 §3 启动剧本执行。

---

## 7. 历史团队登记表

| 团队名 | 创建日期 | 主要 case | 状态 | 解散日期 |
|---|---|---|---|---|
| qq-glb-team（一期） | 2026-05-13 | Task #001~005（打卡状态修复 + widget test 对齐） | 已解散 | — |
| qq-glb-team（v2 重启） | 2026-06-03 | Task #007 recurring-rule-edit（修改重复规则） | 已解散 | 2026-06-03 |

> 解散后，请把对应行的"状态"改为"已解散"并填写解散日期。
> Task #007 四闸门全通过 + 用户 UI 终验通过（24/24 AC），归档见 [case-summary-recurring-rule-edit.md](./case-summary-recurring-rule-edit.md)。

---

## 8. 变更记录

| 版本 | 日期 | 变更摘要 | 作者 |
|---|---|---|---|
| v1.0 | 2026-05-14 | 初版发布：从 qq-glb-team 首次实战中提炼组队/运行/收尾 SOP，作为路线 A（解散重建）的资产保全方案 | PM |
| v1.1 | 2026-06-03 | G4 收闸 recurring-rule-edit：历史登记表补登 qq-glb-team（v2 重启）周期及 Task #007 交付结论（24/24 AC，已解散） | PM |
