# iOS 屏幕小组件开发 Plan · v1.0

> 创建日期：2026-05-26
> 创建者：PM（main，基于用户决策与代码现状勘察）
> 关联：[docs/team/team-template.md](../team/team-template.md) §6 重启口令模板
> 状态：📌 **待用户审阅 → 通过后启动团队执行**

---

## 0. 文档定位

本文件是**正式启动团队前的 plan 草案**，目标：
1. 把"做什么 / 不做什么"用一页纸固化，避免开工后边界蔓延
2. 把已知技术风险、决策点、Blast Radius 列清楚，让团队在 G1~G4 各闸门有判依据
3. 作为团队启动后 product-agent 撰写 PRD 的**输入而非替代**——PRD 仍要按 charter §4.G1 全套要素产出

---

## 1. 用户决策快照（2026-05-26 问卷确认）

| 决策项 | 用户选择 | 后果 |
|---|---|---|
| Q1 尺寸 | **仅 systemMedium** | 单 widget family，主屏幕中号尺寸；不做 small/large/锁屏/待机 |
| Q2 内容 | **P0 - 今日日程列表（最近 3 条 + 打卡状态图标）** | 单一数据视图；不做倒计时/打卡进度环/日记入口/课时余量/医疗提醒 |
| Q3 交互 | **仅展示 + 点击跳转（Deep Link）** | 不做 iOS 17 App Intents 交互按钮；不做 widget 内打卡 |
| Q4 选型 | **由 PM 推荐** | 见下方 §2.1 |

---

## 2. PM 技术选型推荐（基于决策 + 代码现状）

### 2.1 选型结论

| 维度 | 推荐 | 理由 |
|---|---|---|
| 技术栈 | **home_widget 插件 + 原生 WidgetKit (Swift + SwiftUI)** | Q3 选 Deep Link 不需要 App Intents，home_widget 自带 deep link 跳回 App 能力，省去手写 channel |
| 最低 iOS 版本 | **iOS 14.0**（widget 起步版） | 当前工程 deployment target 是 13.0，**必须升级**；用户未要求锁屏/交互按钮，不需要 16/17 |
| 数据通道 | **App Group + JSON 文件** | 数据量极小（最近 3 条日程），JSON 比 sqlite 共享更轻 |
| 刷新策略 | **数据驱动为主 + 时间兜底** | App 内打卡/日程变更立即推；timeline 兜底每 30 分钟 |

### 2.2 Blast Radius 评估

| 受影响范围 | 改动量 | 风险 |
|---|---|---|
| `pubspec.yaml` | +1 依赖 home_widget | 低 |
| `ios/Podfile` | platform 行从注释 13.0 → 启用 14.0 | **中**：所有 Pods 需要重新 install，可能有依赖兼容问题 |
| `ios/Runner.xcodeproj` | IPHONEOS_DEPLOYMENT_TARGET 13.0 → 14.0；新增 widget extension target；新增 App Group capability | **中**：需要在 Xcode 工程文件层面改动 |
| `ios/QQGLBWidget/`（新增） | 全新 Swift/SwiftUI 代码 | 低（独立模块） |
| `lib/services/`（新增） | `widget_data_exporter.dart` 一个新 service | 低 |
| `lib/providers/schedule_provider.dart` | checkIn/添加日程/删除日程后调用 exporter | **中**：耦合点要小心，避免循环或性能退化 |
| `lib/main.dart` | 应用启动时首次推送数据 + Deep Link 接收 | 低 |
| Apple Developer 账号 | 必须有付费账号才能创建 App Group ID | **硬依赖**——如未具备，整个项目阻塞 |

### 2.3 关键技术风险（团队启动前必须读）

1. **iOS 13 → 14 升级风险**：现有依赖（image_picker、share_plus、url_launcher 等 16 个三方包）在 iOS 14 下需要回归一次主流程，确保无 deprecation；建议升级前先在分支验证
2. **Apple Developer 账号硬依赖**：App Group 必须在 Apple Developer Portal 创建并下发 entitlement；如用户尚未购买，请**先告知用户购买后再启动团队**（节省团队空转时间）
3. **数据时效性**：widget 不是 push 模型，timeline 最快 5 分钟刷一次；用户在其他设备改了数据不会立即同步——本期不做云同步，文档要写清"widget 最新延迟约 5 分钟"
4. **测试覆盖盲区**：widget UI 无法用 `flutter test` 覆盖，必须**真机/模拟器手测**，QA 报告需含截图证据
5. **Deep Link 路由**：Flutter 端要给 widget 点击设计 URL Scheme（如 `qqglb://schedule/<id>`），需要在 Info.plist 注册 + 在 main.dart 里处理路由分发
6. **重复日程当日实例**：widget 取数时要复用 `schedule_provider` 的"今日实例"展开逻辑（含 repeatTemplateId 跨天展开），不要在 widget 端重新实现日期匹配（会导致与 App 显示不一致）

---

## 3. 范围定义

### 3.1 In Scope（本期必须做）

- [ ] iOS 工程升级 deployment target 13.0 → 14.0（含 Podfile + project.pbxproj + Pods 重装回归）
- [ ] 新增 Widget Extension target `QQGLBWidget`（Swift + SwiftUI）
- [ ] 配置 App Group capability（main app target + widget target，同一 group ID）
- [ ] Flutter 引入 `home_widget` 插件并完成基础初始化
- [ ] Dart 侧 `WidgetDataExporter` service：把"今日最近 3 条日程 + 打卡状态"序列化为 JSON 写入 App Group
- [ ] `schedule_provider` 在 checkIn / 增 / 删 / 改日程后调用 exporter 推送
- [ ] App 启动时执行一次首推（保证安装后即可看到内容）
- [ ] Swift 侧 TimelineProvider + SwiftUI View，从 App Group 读 JSON、渲染日程列表 + 打卡状态图标
- [ ] Deep Link 跳转：widget 点击 → 唤起 App → 路由到对应日程详情页
- [ ] URL Scheme 注册（Info.plist）+ Flutter 路由分发逻辑
- [ ] Widget 空态（今日无日程）/ 异常态（无数据）UI 设计
- [ ] 真机或模拟器全尺寸截图 + 跳转链路 QA 报告

### 3.2 Out of Scope（本期不做）

- ❌ systemSmall / systemLarge / 锁屏 / 待机 widget（按 Q1 决策）
- ❌ widget 内交互按钮 / 直接打卡（按 Q3 决策，不引入 App Intents）
- ❌ 倒计时、打卡进度环、日记入口、课时余量、医疗提醒（按 Q2 决策）
- ❌ Live Activity / Smart Stack 智能推荐
- ❌ 多语言 widget（沿用 App 当前 zh-CN）
- ❌ Android 同款 widget（仅 iOS）
- ❌ 云同步（widget 仍依赖本地数据库，App 不打开则数据不更新）
- ❌ 任何业务侧（lib/screens/）的视觉重构

### 3.3 待澄清项（团队启动前需用户确认）

| 编号 | 待澄清 | 默认假设（用户不答即按此走） |
|---|---|---|
| Q5 | 是否已有 **Apple Developer 付费账号**？ | 假设有；如无，团队启动前阻塞 |
| Q6 | App Group ID 命名？ | 默认 `group.com.bozzguo.qianqian-growth-logbook` |
| Q7 | URL Scheme 命名？ | 默认 `qqglb://` |
| Q8 | widget 显示名（用户在添加 widget 时看到的标题）？ | 默认 `今日日程` |
| Q9 | 点击 widget 是回到 App 首页还是直接打开对应日程详情？ | 默认 → 直接打开对应日程详情页 |
| Q10 | "最近 3 条"如何排序？ | 默认 → 按 dateTime 升序，跳过已结束的；若全部已结束则显示当日全部最近 3 条 |
| Q11 | 已打卡日程在 widget 上是否要显示得"灰一些"？ | 默认 → 是；用 elegant_kit 中等灰色 + 勾选图标 |

---

## 4. 推荐流水线（按 charter.md 走 G1~G4，不裁剪）

| 阶段 | 责任 | 产物 | 关键内容 |
|---|---|---|---|
| **G0 启动** | PM | 团队组建 + Q5~Q11 澄清 | 把待澄清项答完后再 G1 |
| **G1 PRD** | product-agent | `docs/prd/ios-home-widget.md` | 用户场景（含跨设备/无网/历史日 3 类）+ AC 至少 8 条 + R/D 至少 4 条 |
| **G2 UI** | ux-agent | `docs/design/ios-home-widget.md` | systemMedium 在 light/dark 两态下的视觉稿；与 elegant_kit 配色映射；空态/异常态/已打卡态各一张 |
| **G3 Dev + Review** | dev-agent + PM | `docs/review/ios-home-widget-review.md` | 三个层面 review：① iOS 工程升级（pbxproj/Podfile）② Dart 数据导出层 ③ Swift widget 实现 |
| **G4 QA** | qa-agent | `docs/qa/ios-home-widget-report.md` + 截图证据集 | 真机/模拟器矩阵：iPhone SE / iPhone 15 / iOS 14 最低版本 / iOS 17 最新版本；含 deep link 跳转截屏录制 |

**特殊裁剪声明**：本 case 涉及大量原生 iOS 工程改动，**G3 必须强制走 PM + skill:code-reviewer 双重 review**，不允许仅自检通过。

---

## 5. 团队组建建议

### 5.1 团队名

`qq-glb-ios-widget-team`

### 5.2 标准 4 角色（沿用 charter §2，无新增角色）

- product-agent / ux-agent / dev-agent / qa-agent
- **dev-agent 特殊提示**：本期需要 Swift / SwiftUI / WidgetKit / Xcode 工程改造能力，启动时必读 §2.3 风险列表，并自查是否需要补 Apple 官方文档锚点

### 5.3 启动剧本

按 `team-template.md §3` 执行：
1. `team_create(team_name="qq-glb-ios-widget-team")`
2. 依次 spawn 4 agent 做"上线 Ping"，**特别给 dev-agent 加补必读：本 plan §2.3 风险 + Apple WidgetKit 文档**
3. PM 派发 G1 任务给 product-agent，输入 = 本 plan + Q5~Q11 用户答复

---

## 6. 时间预估（参考，非承诺）

| 阶段 | 预估轮次 | 备注 |
|---|---|---|
| Q5~Q11 澄清 | 1 轮 | 用户答完即可 |
| G1 PRD | 1~2 轮 | 包含至少 8 条 AC |
| G2 UI | 1 轮 | 单尺寸单状态系列 |
| G3 Dev | 3~5 轮 | 工程升级 1~2 轮 + Swift 编码 1~2 轮 + 联调 1 轮 |
| G3 Review | 1 轮 | PM + skill:code-reviewer |
| G4 QA | 2 轮 | 矩阵覆盖 + 报告撰写 |
| **合计** | **9~12 轮** | 比 Task #004 打卡修复（4 轮）显著长，用户预期管理 |

---

## 7. 用户审阅清单（请逐项过一遍）

请用户在启动团队前回答 / 确认：

- [ ] §1 决策快照是否准确反映你的意图？
- [ ] §3.2 Out of Scope 列表是否同意（特别是 Android 不做、云同步不做）？
- [ ] §3.3 Q5~Q11 待澄清项的默认假设是否可接受？如有调整请告知
- [ ] §2.3 关键技术风险中**Apple Developer 账号**你是否已具备？
- [ ] §6 时间预估（9~12 轮）是否可接受？

全部确认后给 PM 发口令：

> "按 docs/plans/ios-home-widget-plan.md 启动团队"

PM 收到后即按 §5.3 启动剧本组建 `qq-glb-ios-widget-team`。

---

## 8. 变更记录

| 版本 | 日期 | 变更 | 作者 |
|---|---|---|---|
| v1.0 | 2026-05-26 | 初版 plan，基于用户问卷决策 + iOS 工程现状勘察 | PM |
