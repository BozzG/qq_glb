# UI 校验清单 - 打卡状态判定修复

| 字段 | 值 |
| --- | --- |
| 版本号 | v1.0 |
| 责任 agent | ux-agent |
| Task 编号 | #002 |
| 关联 PRD | [docs/prd/checkin-status-fix.md](../prd/checkin-status-fix.md) |
| 闸门 | G2（UI 校验清单） |
| 范围 | 仅"打卡态"视觉一致性校验，不引入新视觉/新组件 |

> 本文档为 G3 review 与 G4 QA 的视觉一致性判定依据。所有条目以"现状（代码已实现）"vs"期望（PRD 验收口径）"形式列出，以可观察的 UI 表现为准。涉及"已打卡 / 未打卡"两态及若干隐含子态。

---

## 1. 涉及屏幕 / 组件清单

| 屏幕 / 组件 | 文件路径 | 在打卡态中的角色 |
| --- | --- | --- |
| 首页日程卡片 `_ScheduleCard` | `lib/screens/home_screen.dart` | 打卡入口；展示打卡按钮态 |
| 打卡按钮 `ElegantCheckInButton` | `lib/widgets/elegant_check_button.dart` | 打卡按钮的视觉/动效本体 |
| 今日概览 `_ScheduleLine` | `lib/screens/today_overview_screen.dart` | 当日日程列表项的打卡指示图标 |
| 今日概览统计 `ElegantStatTile`（"今日日程 · N 已打卡"） | `lib/screens/today_overview_screen.dart` | 已打卡数量展示 |
| 日程详情底部主按钮 | `lib/screens/schedule_detail_screen.dart` | 打卡主行动按钮 + 提示语 |
| 设计系统 | `lib/widgets/elegant_kit.dart`（`AppElegant` 调色板 / `ElegantCard` / `ElegantPrimaryButton` / `ElegantStatTile` / SnackBar 容器风格） | 复用基础 |

---

## 2. 关键状态枚举

> 本次 case 不引入新状态，仅明确 PRD 修复后两个主态及若干隐含子态。

| 编号 | 状态名 | 触发条件 | 关联 AC |
| --- | --- | --- | --- |
| S1 | 未打卡 | 该日程实例 ID 在 `check_ins` 表无任何记录 | AC-03、AC-04 |
| S2 | 已打卡 | 该日程实例 ID 在 `check_ins` 表存在 ≥1 条记录 | AC-01、AC-02、AC-06 |
| S2a | 已打卡（历史日） | S2 且日程 dateTime 早于今天（昨日及更早） | AC-01（核心修复） |
| S2b | 已打卡（课程类，已扣课时） | S2 且 schedule.isCourse=true，对应已落 `course_consumptions` 一条 | AC-05 |
| S1b | 未打卡（重复日程跨天独立实例） | S1，且同 `repeatTemplateId` 在其他日期已有 S2 实例 | AC-03 |
| E1 | 重复点击拦截（瞬时态） | 用户在 S2 状态下再次触发打卡 → checkIn() 返回 false | AC-02 |
| Empty | 空态 | 当天 `getSchedulesForDay` 返回空列表 | 边界 |
| Loading | 加载态 | `provider.isLoading == true` | 边界 |
| Error | 写库失败 | `checkIn()` catch 异常返回 false（与 E1 共用 false 出口） | 边界 |

---

## 3. 各屏幕状态 - 视觉/交互校验

### 3.1 首页 `_ScheduleCard`（核心改动屏）

数据源：`provider.isCheckedIn(schedule.id)` ✅（PRD 已落地）

| 项 | 状态 S1（未打卡） | 状态 S2 / S2a / S2b（已打卡） |
| --- | --- | --- |
| 卡片整体 | `AppElegant.card` 背景 + `AppElegant.hair` 0.5 描边，与 elegant_kit 卡片风格一致 | 同左（卡片本身不区分态） |
| 左侧色条 | `schedule.color`，3×44，圆角 2 | 同左 |
| 时间 / 标题 / 地点 | 正常显示，颜色 `ink`/`inkSoft`/`inkFaint` | 同左（**不变灰、不加删除线**） |
| 打卡按钮（`ElegantCheckInButton`） | 圆形 36×36；底色 `card`；描边 `hair` 0.8；图标 `Icons.circle_outlined`，色 `inkWhisper` | 圆形 36×36；底色 `accent`；描边 `accent` 1.0；图标 `Icons.check_rounded`，色白 |
| 按钮可点击性 | 可点击，触发 `provider.checkIn(id)` → 成功后即时切换 S2 | **仍可点击**（按钮本身不 disable），但 `checkIn` 在 provider 层返回 false，由 UI 走拦截分支 |
| 失败提示 SnackBar | — | 文案统一为：「**这条日程已经打过卡啦**」（与 PRD AC-02、代码现状一致） |
| 切换动效 | 点击触发 `_controller` 0.9→1.0 缩放 + 220ms 缓动；图标用 `AnimatedSwitcher` 200ms 淡换 | 同左动效；`AnimatedContainer` 250ms 颜色/描边过渡 |
| 触觉反馈 | 点击 `HapticFeedback.selectionClick` | 同左 |

校验要点：
- ✅ S2a（昨日已打卡卡片）必须显示 S2 视觉，**不能因为不是今天而退化为 S1**（这正是本次 PRD 修复目标）。
- ✅ S2 状态下用户极端情况下再次点击，必须出 SnackBar 文案 `这条日程已经打过卡啦`（不是"今天已经打卡过啦"）。
- ✅ 按钮颜色态切换在 250ms 内完成；连续 1~2s 内的连点不应产生第二条 check_in（由 provider 兜底 + UI 提示）。

### 3.2 今日概览 `today_overview_screen.dart`

数据源：`provider.isCheckedToday(schedule.id)` → 别名指向 `isCheckedIn` ✅（AC-06）

| 区块 | 项 | 状态 S1（未打卡） | 状态 S2（已打卡） |
| --- | --- | --- | --- |
| `_ScheduleLine` 末尾图标 | 图标 | `Icons.radio_button_unchecked`，色 `AppElegant.inkWhisper`，size 18 | `Icons.check_circle`，色 `AppElegant.accent`，size 18 |
| 卡片本体 | 背景 / 描边 | `card` + `hair` 0.5 | 同左（不变） |
| 时间 / 标题 / 地点 | — | 正常态 | 正常态（不变灰、无横划线） |
| 顶部统计 `ElegantStatTile` | 副标签 | `今日日程 · 0 已打卡`（按 today 计数） | `今日日程 · N 已打卡`，N 应等于今日 schedules 中 isCheckedIn 为真的条数 |
| 触摸交互 | — | 此屏 `_ScheduleLine` 仅展示，无打卡操作（与现状一致） | 同左 |

校验要点：
- ✅ 今日概览中"今日日程 · N 已打卡"的 N 必须与同屏 `_ScheduleLine` 中显示 `check_circle` 的条数 **完全一致**（防 AC-06 的"显示与统计不一致"）。
- ✅ 历史日打卡不应反映在该屏的"N 已打卡"中（该屏仅看今天）。

### 3.3 日程详情 `schedule_detail_screen.dart`

数据源：`provider.isCheckedToday(schedule.id)` → 别名指向 `isCheckedIn` ✅（AC-06）

底部 `ElegantFloatingBar` 内 `ElegantPrimaryButton`：

| 项 | 状态 S1（未打卡，可打） | 状态 S2 / S2a（已打卡，含历史日） | 瞬时态（_isCheckingIn=true） |
| --- | --- | --- | --- |
| 按钮文案 | `立即打卡` | `今日已打卡` ⚠️ | `打卡中…` |
| 按钮图标 | 无 | `Icons.check_rounded` | 无 |
| 按钮 onPressed | `_handleCheckIn` 可触发 | `null`（disabled） | `null`（disabled） |
| 按钮视觉 | `ElegantPrimaryButton` 默认主色态 | 主色按钮的 disabled 态（按 elegant_kit 既有规则呈现） | 同 disabled 态 |
| SnackBar 提示 | 成功：`打卡成功`；失败：`今天已经打卡过啦`（详情页现有文案，与首页 SnackBar 不同） | — | — |
| Haptic | 成功：`HapticFeedback.mediumImpact` + 自动返回上一屏 | — | — |

校验要点：
- ⚠️ **文案口径不一致风险（已知）**：详情页文案仍为"**今日已打卡**"/"今天已经打卡过啦"，但 PRD 已将判定口径改为"按实例"。当用户从首页进入历史日已打卡日程时，按钮文案显示"今日已打卡"在语义上不严格准确（实际是该实例已打卡，未必是今天打的）。
  - 处理建议：本次 case 不改文案（章程要求"不出新设计"），但在 G3 review 时记录为 **已知文案语义债**，下一迭代统一为"已打卡"。本清单据此判定**视觉一致性通过**，**文案语义为黄灯（非阻塞）**。
- ✅ S2a 场景（昨日已打卡，今天进入详情）：按钮必须为 disabled 状态、显示 `Icons.check_rounded`，不可再触发新写入。
- ✅ "最近打卡"卡片（`_buildRecentCheckIns`）应至少展示该实例对应的 1 条 check_in，与 S2 态对应。

### 3.4 设计系统复用关系（`elegant_kit.dart` / `app_theme.dart` AppElegant）

本次 case **不新增**色板或组件。打卡态复用：

| 用途 | 复用项 |
| --- | --- |
| 已打卡按钮主色 / 选中态指示 | `AppElegant.accent` |
| 未打卡按钮描边 | `AppElegant.hair`（0.8 px） |
| 未打卡按钮图标色 | `AppElegant.inkWhisper` |
| 卡片背景 | `AppElegant.card` |
| 卡片描边 | `AppElegant.hair`（0.5 px） |
| 主文本 / 副文本 / 弱化文本 | `AppElegant.ink` / `inkSoft` / `inkFaint` |
| 打卡按钮主体组件 | `ElegantCheckInButton`（首页卡片用） |
| 打卡主行动按钮 | `ElegantPrimaryButton`（详情页底栏用） |
| 卡片容器 | `ElegantCard`（用于详情页时间卡、最近打卡卡等） |
| 历史 check-in 列表的对勾色 | `AppElegant.sage`（详情页"最近打卡"项，已打卡不冲突） |
| SnackBar | 沿用 Flutter 默认 `ScaffoldMessenger`，无定制；文案是唯一变量 |

校验要点：
- ✅ 不允许引入新色值或新组件类。如发现 PR 中新增 RGB / 新 Widget，回退或要求 dev-agent 改用 AppElegant 现有字段。

---

## 4. 边界场景

| 场景 | 触发 | 期望 UI |
| --- | --- | --- |
| Empty（当天无日程） | `getSchedulesForDay(day).isEmpty` | 首页：`ElegantEmpty`（icon=`event_note_outlined`，label=`这一天还没有日程`，hint=`点击下方 + 新增`）；今日概览：`_miniEmpty('今日无安排')` |
| Loading（schedules 加载中） | `provider.isLoading == true` | 首页：`SliverFillRemaining` 内置 `CircularProgressIndicator` 居中；今日概览：在 ScheduleProvider loading 期间 statTile 数值与列表沿用上一帧（不闪烁），加载完成后 `notifyListeners` 自动刷新（**不要求**额外 skeleton） |
| Error（checkIn 写库失败） | `checkIn()` catch 异常 → 返回 false（与 E1 共用 false 通道） | 首页：SnackBar 文案 `这条日程已经打过卡啦`（注意：当前实现下，写库失败与重复打卡共用同一文案，**视觉一致性通过**，但**文案语义债**记录为黄灯）。详情页：SnackBar `今天已经打卡过啦`（同口径黄灯） |
| 重复点击防抖（E1） | 1~2s 内连点同一实例 | 仅首次写入；后续点击触发 SnackBar；按钮态在首次写入返回后立即切到 S2，避免视觉残留"未打卡" |
| 重复日程跨天（S1b vs S2） | 同 `repeatTemplateId` 多实例 | 每个日期实例独立显示，D1 显示 S2、D2 显示 S1，互不干扰；首页切换不同日期时按 `provider.isCheckedIn(实例id)` 各自判定 |

---

## 5. G3/G4 校验 Checklist（可勾选项）

> QA / Reviewer 按此勾选；任一未通过即阻塞闸门。

### 视觉一致性（必过 / 红灯阻塞）
- [ ] **VC-01** 首页历史日已打卡日程卡片，打卡按钮显示 S2 视觉（accent 圆 + 白色 check_rounded）
- [ ] **VC-02** 首页未打卡日程卡片，打卡按钮显示 S1 视觉（card 底 + hair 描边 + inkWhisper circle_outlined）
- [ ] **VC-03** 同一卡片上 S1→S2 切换在 ≤250ms 内完成颜色/图标过渡（无闪烁、无残留）
- [ ] **VC-04** 今日概览中 `_ScheduleLine` 末尾图标在 S1/S2 下分别为 `radio_button_unchecked(inkWhisper)` / `check_circle(accent)`
- [ ] **VC-05** 今日概览顶部"今日日程 · N 已打卡"中的 N 与列表中 `check_circle` 数量一致
- [ ] **VC-06** 重复日程在 D1 已打卡、D2 未打卡时，两天分别显示 S2 / S1，按钮独立可操作（AC-03）
- [ ] **VC-07** 详情页底部按钮在 S2 / S2a 下显示 `今日已打卡` + `check_rounded` 图标，且 disabled
- [ ] **VC-08** 所有打卡相关颜色仅来自 `AppElegant`（accent / card / hair / ink* / sage），无硬编码 RGB

### 交互/文案（必过 / 红灯阻塞）
- [ ] **IC-01** 首页对 S2 实例再次点击 → SnackBar 文案为 `这条日程已经打过卡啦`（AC-02）
- [ ] **IC-02** 首页 S1 实例点击 → 立即切 S2、无 SnackBar、无报错（AC-04）
- [ ] **IC-03** 详情页 S1 状态点击 → SnackBar `打卡成功`、自动返回上一屏（沿用现状）
- [ ] **IC-04** 课程类日程首次打卡时课时 -1（仅首次，二次点击不再扣减）—— UI 上"已用课时"应增加一次；二次点击时不变（AC-05，需配合课时屏校验）

### 边界（黄灯允许，但需登记）
- [ ] **BC-01** 当天无日程 → `ElegantEmpty` 文案与 hint 完整可见，无错位
- [ ] **BC-02** schedules 加载期间 → 首页 `CircularProgressIndicator` 居中显示
- [ ] **BC-03** checkIn 写库失败 → 与重复打卡共用 SnackBar 文案；记录为已知文案语义债，不阻塞本期
- [ ] **BC-04** 详情页"今日已打卡"文案在历史日 S2a 场景仍出现，记录为已知文案语义债，不阻塞本期

---

## 6. 已知文案语义债（移交 product-agent / 下次迭代）

| 编号 | 现象 | 位置 | 建议 |
| --- | --- | --- | --- |
| D-01 | "今日已打卡"出现在历史日实例的详情页底部按钮 | `schedule_detail_screen.dart` `_buildRecentCheckIns` 上方 `ElegantFloatingBar` | 改为 `已打卡` |
| D-02 | "今天已经打卡过啦"作为详情页 SnackBar 文案 | `schedule_detail_screen.dart` `_handleCheckIn` | 改为 `这条日程已经打过卡啦`，与首页统一 |
| D-03 | `isCheckedToday` 命名与实际语义不一致 | `schedule_provider.dart` | 下次迭代统一替换调用方为 `isCheckedIn` 后删除别名（PRD R1 已登记） |

> 以上 3 项为命名/文案语义层面，本期 G2 不做视觉调整，仅作为黄灯登记，作为后续 PRD 切入点。

---

## 7. 闸门结论

- **G2 视觉一致性**：通过（无新视觉）
- **依赖现有 elegant_kit**：通过
- **状态枚举完整性**：通过（覆盖 S1 / S2 / S2a / S2b / S1b / E1 / Empty / Loading / Error）
- **黄灯项**：D-01 / D-02 / D-03，不阻塞 G3/G4，移交后续迭代
