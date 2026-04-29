# Changelog

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
