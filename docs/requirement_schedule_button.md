# 需求文档：首页添加日程按钮

## 1. 需求概述

| 项目 | 内容 |
|------|------|
| 需求编号 | REQ-001 |
| 需求名称 | 首页添加日程快捷按钮 |
| 需求描述 | 在首页（HomeScreen）底部导航栏最下方中间位置添加日程快捷按钮，用户可一键跳转到添加日程页面 |
| 优先级 | 高 |
| 需求方 | 产品需求 |

## 2. 背景分析

### 2.1 当前状态
- 首页（HomeScreen）使用 `BottomNavigationBar` 作为底部导航
- 当前底部导航栏包含4个Tab：首页、日志、统计、日记
- 已存在 `AddScheduleScreen` 页面用于添加日程

### 2.2 用户痛点
- 用户添加日程需要从底部导航进入「日志」Tab，再找到添加入口
- 操作路径较长，不够便捷
- 用户希望能快速添加日程

## 3. 功能需求

### 3.1 功能描述
在首页底部导航栏的中间位置添加一个突出的日程添加按钮。

### 3.2 UI设计方案

#### 方案一：FloatingActionButton（推荐）
- 在 `Scaffold` 中添加 `floatingActionButton`
- 位置：底部居中
- 样式：圆形按钮，使用主题色（AppColors.primary）
- 图标：加号（add）或日历图标（add_circle）
- 点击效果：跳转至 `AddScheduleScreen`

#### 方案二：自定义底部导航栏
- 将 `BottomNavigationBar` 替换为自定义底部导航组件
- 中间位置使用突出的"添加"按钮
- 需要处理底部安全区域

### 3.3 交互流程
```
用户点击日程按钮 → 跳转 AddScheduleScreen → 用户填写信息 → 保存 → 返回首页
```

### 3.4 验收标准
1. 首页底部中间位置显示日程添加按钮
2. 按钮样式与App整体风格一致（使用AppColors.primary）
3. 点击按钮可正常跳转到添加日程页面
4. 跳转后页面功能正常
5. 无性能问题或布局异常

## 4. 技术约束

### 4.1 技术栈
- Flutter 3.x
- Dart 3.x
- Provider状态管理

### 4.2 文件影响范围
| 文件 | 影响 |
|------|------|
| lib/screens/home_screen.dart | 主要修改文件 |
| lib/screens/add_schedule_screen.dart | 跳转目标（无需修改） |

### 4.3 注意事项
- 避免与现有底部导航栏冲突
- 考虑iOS和Android的差异
- 确保按钮在各种屏幕尺寸下显示正常

## 5. 实现方案（推荐）

在 `HomeScreen` 的 `Scaffold` 中添加 `floatingActionButton`：

```dart
Scaffold(
  body: ..., // 现有代码
  floatingActionButton: FloatingActionButton(
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddScheduleScreen()),
    ),
    backgroundColor: AppColors.primary,
    child: Icon(Icons.add, color: Colors.white),
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  bottomNavigationBar: ..., // 现有代码
)
```

## 6. 风险评估

| 风险 | 等级 | 应对措施 |
|------|------|----------|
| FAB与BottomNav冲突 | 低 | 使用 centerDocked 让FAB嵌入导航栏 |
| 按钮位置影响内容 | 低 | 适当调整padding |
| 跨平台兼容 | 低 | Flutter默认支持 |

## 7. 测试用例

| 用例编号 | 描述 | 预期结果 |
|-----------|------|----------|
| TC-001 | 首页显示日程按钮 | 按钮正确显示在底部中间 |
| TC-002 | 点击日程按钮 | 正常跳转至添加日程页面 |
| TC-003 | 添加日程后返回 | 返回首页，按钮仍正常显示 |
| TC-004 | 横竖屏切换 | 布局正常，无异常 |

---

**文档版本**: v1.0
**创建日期**: 2026-04-27
**状态**: 待评审
