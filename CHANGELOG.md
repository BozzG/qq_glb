# Changelog

## [2.5.0] - 2026-06-23

> v2.5 增长启动（首批）：P1-6 成长报告 + P1-7 iOS 桌面小组件（只读）。

### Added
- **成长报告（P1-6）**：新增 `GrowthReportScreen`，支持「周报 / 月报」切换与历史区间前后翻阅，自动汇总三块数据——打卡概况（完成率环形 + 总打卡/活跃天数/连续天数）、课程进度（已用/总课时进度条）、日记情绪趋势（愉悦/平静/烦躁分布）。入口位于「打卡统计」页导航栏。
- **成长报告分享为长图**：报告内容经 `RepaintBoundary` 渲染为 PNG（pixelRatio 3.0），写入临时目录后调用系统分享（`share_plus`）。
- **聚合层** `GrowthReportService` / `GrowthReportData`：纯函数计算，打卡口径与 `getCheckInStats` 一致（按日程自身日期归属、半开区间）；新增 `test/growth_report_service_test.dart`（13 用例，覆盖打卡率/连续天数/课程进度/情绪分布/周月边界/空区间）。
- **iOS 桌面小组件（P1-7，只读）**：新增 WidgetKit 扩展 `QianqianWidget`，展示今日日程（分类色条 + 图标 + 标题 + 时间 + 打卡状态），支持 small/medium/large。新增 `WidgetService` 桥接层（`home_widget`），在 `ScheduleProvider.loadSchedules` 末尾统一收口同步今日数据并刷新 Widget；非 iOS 平台 no-op。
- 新增 `ios/Runner/Runner.entitlements`、`ios/QianqianWidget/`（Swift/Info.plist/entitlements）及 `docs/ios-widget-setup.md`（Xcode 接入手册）。

### Changed
- 依赖：新增 `home_widget`。
- 版本号升至 `2.5.0+6`。

### Notes
- P1-7 本期裁剪为「仅 iOS、只读今日概览」，桌面快捷打卡（需 iOS 17+ App Intents）顺延。
- iOS Widget Extension target 需在本机 Xcode 按 `docs/ios-widget-setup.md` 完成一次性接入与签名验证。


## [2.3.0] - 2026-06-10

> v2.3 P0 收口：基础保障与体系一致性。

### Added
- **数据备份与恢复**：设置页新增「数据备份」区块，支持整库导出为 JSON 文件（经系统分享保存）与从备份文件恢复（事务化整库覆盖，失败回滚）。新增 `BackupService` 与 `DatabaseHelper.exportAllTables / importAll`。
- **打卡成功爆发动效**：`ElegantCheckInButton` 在「未打卡→已打卡」时叠加扩散光环 + 放射粒子 + 中等触感，强化记录成长的仪式感。
- **统一确认弹窗** `ElegantConfirmDialog`：精致风格的二次确认组件，支持取消/确认两键与多分支（重复日程的 仅此项/全部）。
- 健康记录删除新增二次确认（原先无确认直接删除）。
- 新增 `test/backup_service_test.dart`（7 个往返/校验用例）。

### Changed
- **`add_schedule_screen` 设计体系对齐**：移除 7 个重复 `elegant_kit` 的私有组件（`_Card`/`_CardHeader`/`_HairDivider`/`_RowTile`/`_CircleIconButton`/`_TypeChip`/`_SegmentChip`），改用 `ElegantCard`/`ElegantCardHeader`/`ElegantDivider`/`ElegantRowTile`/`ElegantCircleIconButton`/`ElegantChip`/`ElegantSegment`；硬编码灰全部改引 `AppElegant` token；重复频率分段选中态由黑色统一为 accent 玫瑰。
- 各处删除/重置弹窗（日程详情、日记、设置、健康记录）统一替换为 `ElegantConfirmDialog`，视觉与交互一致。
- 打卡文案统一：详情页失败提示与按钮文案与首页对齐（「已打卡」/「这条日程已经打过卡啦」）；首页打卡成功补「已打卡 · 记录成功」提示。
- 依赖：重新引入 `file_picker`（用于数据恢复时选取备份文件）。

### Removed
- 删除 `ScheduleProvider.isCheckedToday` 兼容别名，全部调用统一为 `isCheckedIn`（语义按日程实例判定，与自然日无关）。

### Fixed
- 清理 analyzer 告警至 0（`use_build_context_synchronously`、`unnecessary_underscores`）。

## [2.0.0] - 2026-04-29

### Added
- 日记功能：心情状态、关联日程、进步/改进复盘、图片/视频附件
- 底部导航新结构（7 格）：首页 · 今日 · 统计 · [+] · 课时 · 健康 · 日记
- 课程类型扩展：新增「兴趣」「奥赛」，顺序调整为 运动 / 兴趣 / 语言 / 奥赛 / 其他
- 打卡统计按日程本身日期归档（提前打卡场景归属正确）

### Changed
- 整体 UI 设计升级：精致玫瑰粉主题（`AppElegant` 色板 + `elegant_kit` 组件库）
- 首页顶栏与问候区合并，保留设置按钮
- 今日概览顶部导航栏固定，不随内容滚动
- 添加课程 / 添加就诊记录弹窗改为底部 Bottom Sheet，风格与其他页面一致
- Splash 页上方留白填充纯色 `#FDD4D6`，保留原启动图
- 数据库：删除 `audioPaths` 列（日记 / 成长日志）

### Removed
- 成长日志功能（`GrowthLogScreen` / `GrowthLogProvider`）——与日记功能合并
- 首页中间的快捷入口区块
- 日记的音频附件支持
- 依赖：`file_picker`

### Fixed
- 打卡统计日期区间边界错误（原 ±1 day 缓冲导致次日打卡被误算）
- 首页顶栏"今日日程数"不再随日历选中日期变化，始终按系统当天计算

## [Unreleased]

### Testing Debt
- **TodayOverviewScreen 测试覆盖率 62.2%，未达 80% 标准**
  - 原因：私有 Widget（`_DateHeader`、`_StatCard` 等）难以直接测试，是 Flutter 测试的常见难题
  - 待补充：
    - 私有 Widget 的单元测试（需提取为公开 Widget 或使用 `@visibleForTesting`）
    - 数据展示的边界情况测试（空数据、超长文本等）
    - 用户交互测试（下拉刷新、点击操作等）
  - 计划：下个迭代优先处理，目标覆盖率 >80%

### Bug Fixes
- 修复 TodayOverviewScreen 本周进度计算逻辑（完成率 = 已打卡天数 / 本周已过天数）
- 修复多记录显示问题（医疗记录、待办备忘存在多条时显示汇总信息）
- 优化 build 方法性能（将 `DateTime.now()` 改为可选构造函数参数）
- 提取 `_DateHeader` 中的 `weekdayNames` 为静态常量

## [0.1.0] - 2026-04-23

### Added
- 初始项目结构
- 今日概览页面（TodayOverviewScreen）
- 基础数据模型（MedicalRecord、Schedule、Memo）
