# Changelog

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
