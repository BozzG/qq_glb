# UI 设计稿 - 修改重复规则（recurring-rule-edit）

| 字段 | 值 |
| --- | --- |
| 版本号 | v1.0 |
| 责任 agent | ux-agent |
| Task 编号 | #007 |
| Plan ID | 6a4fdf818f2b49b8af2be98edc86accd |
| 上游 PRD | [docs/prd/recurring-rule-edit.md](../prd/recurring-rule-edit.md)（v1.0，24 条 AC） |
| 关联资料 | [团队章程](../team/charter.md) · [elegant_kit.dart](../../lib/widgets/elegant_kit.dart) · [app_theme.dart](../../lib/utils/app_theme.dart) · [add_schedule_screen.dart](../../lib/screens/add_schedule_screen.dart) · [schedule_detail_screen.dart](../../lib/screens/schedule_detail_screen.dart) |
| 生效日期 | 2026-06-03 |
| 状态 | 待 G2 评审 |

---

## 1. 设计原则与风格关键词

延续 CASE-B M3 V2 已锁定的 ColorScheme 16 槽位 + 严格复用 `lib/widgets/elegant_kit.dart` 既有组件，**不引入任何新视觉 token**。本次新增三处 UI（详情页 NavBar 一枚按钮、新屏 EditRecurringRuleScreen、影响范围弹窗 RecurringImpactDialog）一律用 `AppElegant` 命名空间引用色与字号 token，禁止裸写十六进制。

**5 个风格关键词**：
1. 极简卡片（`ElegantCard` radius 18 / hair 0.5px / softShadow）
2. 衬线大标题（`AppText.heroTitle` 30px w700 letterSpacing -0.5）
3. 发丝分隔线（`AppElegant.hair` 0.5px 高度）
4. 单色强调（`AppElegant.accent` Wine Rose 玫瑰粉，仅用于主行动 / 选中态 / 短分隔）
5. 极小动画（180ms `AnimatedContainer`，沿用 `add_schedule_screen` 星期勾选切换节奏）

---

## 2. 涉及屏幕 / 组件清单（带文件路径）

| 类型 | 路径 | 改动性质 |
|---|---|---|
| 屏 · 现有 | `lib/screens/schedule_detail_screen.dart` | 在第 80-103 行 `actions:` 区追加第 3 枚 `ElegantCircleIconButton`（条件渲染） |
| 屏 · 新建 | `lib/screens/edit_recurring_rule_screen.dart` | 新增（沿用 `add_schedule_screen` 卡片节奏） |
| 弹窗 · 新建 | `lib/widgets/recurring_impact_dialog.dart` | 新增（仿 `_showDeleteConfirm` 视觉风格） |

---

## 3. 详情页 NavBar 改动（schedule_detail_screen.dart）

### 3.1 关键状态枚举（按 PRD AC-01 / AC-02）

| 状态条件 | 渲染策略 |
|---|---|
| `schedule.repeatTemplateId != null && schedule.repeatType != RepeatType.none` | NavBar 渲染 **3 枚** 圆形按钮：编辑 / 修改重复规则 / 删除 |
| 否则（单实例日程） | NavBar 渲染 **2 枚**：编辑 / 删除（保持现状，不占位） |

### 3.2 视觉规格（与现有按钮严格一致）

| 项 | 取值 |
|---|---|
| 组件 | `ElegantCircleIconButton`（**复用**，禁止重写） |
| 图标 | `Icons.event_repeat_outlined` |
| 尺寸 | 36 × 36（`size` 参数走默认值） |
| 图标内边 | size=16，颜色继承 `AppElegant.ink` |
| 容器 | 圆形，`AppElegant.card` 底，`AppElegant.hair` 0.5px 描边 |
| 与相邻按钮间距 | `SizedBox(width: 10)`（与编辑↔删除现有间距 100% 一致） |
| 触发反馈 | 组件内置 `HapticFeedback.selectionClick`（无需在调用处再加） |

### 3.3 ASCII 框图

```
┌── ElegantNavBar (height 56) ───────────────────────────────────────────┐
│  [←返回]            "日程详情"            [✎编辑] 10 [⟳重复] 10 [🗑删除] │
│   leading            navTitle              重复组场景才出现 ↑           │
└─────────────────────────────────────────────────────────────────────────┘
                                                  ↑
                                          仅当 isRecurring 时插入
```

### 3.4 dart 伪代码片段（给 dev 定位插入点）

> 在 `schedule_detail_screen.dart` **第 96~98 行**（`SizedBox(width: 10)` 之后、`Icons.delete_outline` 之前）插入如下 3 行；以及在外层用 `if (isRecurring)` 条件包裹，参考 `_showDeleteConfirm` 内 `isRecurring` 的等价判定：

```dart
// 仅重复组渲染 PRD AC-01 / AC-02
final isRecurring = _schedule.repeatTemplateId != null &&
    _schedule.repeatType != RepeatType.none;

// actions: [...] 中
ElegantCircleIconButton(
  icon: Icons.edit_outlined,
  onTap: ...原有,
),
const SizedBox(width: 10),
if (isRecurring) ...[
  ElegantCircleIconButton(
    icon: Icons.event_repeat_outlined,
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditRecurringRuleScreen(seed: _schedule),
        ),
      );
      if (result == true && mounted) {
        context.read<ScheduleProvider>().loadSchedules();
        Navigator.pop(context);
      }
    },
  ),
  const SizedBox(width: 10),
],
ElegantCircleIconButton(
  icon: Icons.delete_outline,
  onTap: _showDeleteConfirm,
),
```

> Dev 实现注意：返回值 `true` 与现有"编辑成功"语义一致，统一在外层做 `loadSchedules + pop`。

---

## 4. EditRecurringRuleScreen 新屏布局

### 4.1 整体骨架

```
┌── Scaffold(backgroundColor: AppElegant.bg) ────────────────────────────┐
│ ┌── SafeArea ──────────────────────────────────────────────────────┐  │
│ │  ElegantNavBar(title:'修改重复规则', leading: 关闭X)               │  │
│ │  ┌── SingleChildScrollView (padding: 20,8,20,140) ─────────────┐ │  │
│ │  │  ① 副标题区："生效起始日：明天起 · 2026-06-04（含）"           │ │  │
│ │  │     1px×40 accent 短分隔线                                    │ │  │
│ │  │  ② 标题输入卡（30px w700 大标题）                             │ │  │
│ │  │  ③ 时间卡（仅时分，不显示日期）                                │ │  │
│ │  │  ④ 分类卡（_TypeChip Wrap）                                   │ │  │
│ │  │  ⑤ 重复卡（_SegmentChip 频率 + 星期圆点 daily 隐藏）           │ │  │
│ │  │  ⑥ 详情卡（地点 / 备注 _PlainInputRow）                       │ │  │
│ │  │  ⑦ 关联课程卡                                                 │ │  │
│ │  └─────────────────────────────────────────────────────────────┘ │  │
│ └────────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ElegantFloatingBar (Stack 底，渐隐遮罩)                                │
│   ┌─────────────────────────────────────────────┐                      │
│   │  ElegantPrimaryButton "保存修改"               │                      │
│   └─────────────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 区块逐项规范（自上而下）

#### ⓪ 顶部 NavBar
| 项 | 值 |
|---|---|
| 组件 | `ElegantNavBar` |
| `title` | `'修改重复规则'`（命中 `AppText.navTitle`：16px w600 ink letterSpacing 0.3） |
| `leading` | `ElegantCircleIconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context))` |
| `actions` | `[const SizedBox(width: 40)]` 占位（保持视觉对称） |
| 高度 | 56（组件内置） |

#### ① 副标题区（PRD AC-05）
| 项 | 值 |
|---|---|
| 容器 | `Padding(EdgeInsets.fromLTRB(4, 0, 4, 0))` |
| 上小字 | `Text('生效起始日：明天起 · ${YYYY-MM-DD}（含）', style: AppText.heroHint)` → 12px w500 inkSoft letterSpacing 2 |
| 间距 | `SizedBox(height: 8)` |
| 短分隔线 | `Container(height: 1, width: 40, color: AppElegant.accent)` |
| 与下一卡片间距 | `SizedBox(height: 28)` |

> dev 实现：日期文案 `DateFormat('yyyy-MM-dd').format(tomorrowStart)`，`tomorrowStart = DateTime(now.year, now.month, now.day + 1)`。

#### ② 标题输入卡（沿用 `add_schedule_screen._buildTitleField()` 模式）
| 项 | 值 |
|---|---|
| 容器 | `Padding(horizontal: 4)` 不用 `ElegantCard`，直接裸 Column（与 add 屏一致） |
| 上小字 | `Text('修改重复规则的所有未来实例', style: AppText.heroHint)` |
| 间距 | `SizedBox(height: 10)` |
| 输入框 style | `AppText.heroTitle`（30px w700 ink height 1.25 letterSpacing -0.5），`maxLines: 2 minLines: 1` |
| `cursorColor` | `AppElegant.accent`，cursorWidth 1.5 |
| `hint` | `'未命名日程'`，hintStyle 30px w700 `AppElegant.inkWhisper` letterSpacing -0.5 |
| 间距 | `SizedBox(height: 8)` |
| 下短分隔线 | `Container(height: 1, width: 40, color: AppElegant.accent)` |
| 与下一卡片间距 | `SizedBox(height: 28)` |

#### ③ 时间卡（**仅时分**，PRD AC-09 时分会同步给所有未来实例）
| 项 | 值 |
|---|---|
| 容器 | `ElegantCard`（默认 padding 18,16,18,16） |
| Header | `ElegantCardHeader(icon: Icons.schedule_outlined, label: '时间')`（`AppText.caption`：12px w600 inkSoft letterSpacing 2.5） |
| 间距 | `SizedBox(height: 18)` |
| 提示行 | `Text('日期由重复规则决定，此处仅设定时分', style: AppText.meta)` → 12px inkSoft height 1.4 |
| 间距 | `SizedBox(height: 14)` |
| 开始时间行 | InkWell + Padding(vertical:14)，左 `Text('开始', 13 inkSoft height 2.2)`，右大号 `Text(HH:mm, 36 w300 ink letterSpacing -1)` + `Icon(chevron_right, 18 inkSoft)` |
| 分隔 | `ElegantDivider()` |
| 结束时间行 | 同上结构（label='结束'）；当 `_endTime == null` 隐藏整行 |
| 切换"添加/移除结束时间"行 | InkWell padding(vertical:12)，左 `Icon(_endTime==null? add: remove, 16 ink)` + 6 + `Text('添加结束时间' / '移除结束时间', 13 ink w500)` |
| 与下一卡片间距 | `SizedBox(height: 20)` |

#### ④ 分类卡（沿用 `add_schedule_screen._buildTypeCard()`）
| 项 | 值 |
|---|---|
| 容器 | `ElegantCard` |
| Header | `ElegantCardHeader(icon: Icons.bookmark_border_rounded, label: '分类')` |
| 间距 | `SizedBox(height: 14)` |
| 内容 | `Wrap(spacing: 8, runSpacing: 10, children: ScheduleType.values.map(_TypeChip))` |
| `_TypeChip` 选中态 | 沿用 `_typeColor(t)` 0.08 alpha 底 + 0.5 alpha 描边 1px |
| 与下一卡片间距 | `SizedBox(height: 20)` |

#### ⑤ 重复卡（PRD AC-14 / AC-15 / AC-16）
| 项 | 值 |
|---|---|
| 容器 | `ElegantCard` |
| Header | `ElegantCardHeader(icon: Icons.repeat_rounded, label: '重复')` |
| 间距 | `SizedBox(height: 14)` |
| 频率分段 | `Row` 内 4 个 `_SegmentChip`（不重复 / 每天 / 每周 / 自定义），等宽 + 间距 8，**选中态 fill = `AppElegant.ink`**（沿用 add 屏 `_SegmentChip` 黑底白字） |
| `daily` 时 | 不渲染下方星期勾选区（`if (_repeatType==custom \|\| _repeatType==weekly)` 才渲染） |
| 切换动画 | 用 `AnimatedSize` 或显式 `AnimatedContainer`(180ms) 包裹星期区，沿用 add 屏节奏 |
| 星期圆点行 | 上方 `SizedBox(18)` + `ElegantDivider()` + `SizedBox(16)`，`Row(MainAxisAlignment.spaceBetween)` 7 个圆点，每个 36×36，选中态 fill `AppElegant.accent` 描边同色 1px、未选 transparent 底 + `AppElegant.hair` 1px 描边 |
| 圆点字 | `Text(['一','二','三','四','五','六','日'][i], 13 选中=white w600 / 未选=inkSoft w500)` |
| 与下一卡片间距 | `SizedBox(height: 20)` |

#### ⑥ 详情卡（沿用 `_buildDetailCard()`）
| 项 | 值 |
|---|---|
| 容器 | `ElegantCard` |
| Header | `ElegantCardHeader(icon: Icons.tune_rounded, label: '详情')` |
| 间距 | `SizedBox(height: 6)` |
| 地点行 | `_PlainInputRow(icon: Icons.place_outlined, hint: '添加地点', controller: _locationCtrl)` |
| 分隔 | `ElegantDivider()` |
| 备注行 | `_PlainInputRow(icon: Icons.edit_note_rounded, hint: '添加备注…', controller: _memoCtrl, maxLines: 3)` |
| 与下一卡片间距 | `SizedBox(height: 20)` |

#### ⑦ 关联课程卡（沿用 `_buildCourseCard()`）
| 项 | 值 |
|---|---|
| 容器 | `ElegantCard` |
| 标题区 | `Icons.auto_awesome_outlined` 16 inkSoft + 8 + `'关联课程'`（13 inkSoft letterSpacing 1.2 w500）+ Spacer + `CupertinoSwitch(activeTrackColor: AppElegant.accent)` |
| 副小字 | `'开启后，完成打卡将自动扣除一次课时'`（12 inkSoft height 1.5） |
| 课程列表（开关开启时） | `Wrap(spacing:8, runSpacing:8)` 课程胶囊；选中胶囊用 `Color(course.color)` 0.08/0.6 alpha；空态走"暂无课程"占位（沿用 add 屏） |

#### ⑧ 底部浮动保存按钮
| 项 | 值 |
|---|---|
| 容器 | `ElegantFloatingBar` |
| 按钮 | `ElegantPrimaryButton(label: '保存修改', icon: null, onPressed: _onTapSave, height: 54)` |
| 文案样式 | 组件内置（15 w600 letterSpacing 2 white on accent fill radius 14） |
| disabled 态 | `onPressed: null` 时组件自动切到 `AppElegant.hair` 底 + `inkFaint` 字（PRD AC-08：当 weekly && repeatDays.isEmpty 时按钮置灰；点击 fallback 由 SnackBar 兜底） |

> `_onTapSave` 流程：① 校验 title 非空（沿用 add 屏 SnackBar）→ ② 校验 weekly+repeatDays 非空（PRD AC-08，SnackBar 文案"请至少选择一个星期"）→ ③ 调 `previewRecurringRuleUpdate` → ④ `showDialog(builder: (_) => RecurringImpactDialog(...))`。

---

## 5. RecurringImpactDialog 弹窗设计

### 5.1 整体结构

```
┌─ AlertDialog (radius 20, AppElegant.card 底, elevation 0) ──┐
│                                                              │
│   "确认修改重复规则"   ← 17px w600 ink letterSpacing 0.3      │
│   ─────────────────────────────────                          │
│                                                              │
│   ┌──────────────────────────────────────────┐              │
│   │  🗑(rose 18)  将删除 N 条未来未打卡实例    │   ← 14 ink   │
│   │                                          │              │
│   │  🔒(sage 18)  保留 M 条已打卡或今天及之前 │              │
│   │                                          │              │
│   │  ➕(accent 18) 按新规则重建 K 条实例       │              │
│   └──────────────────────────────────────────┘              │
│                                                              │
│   示例日期：6/4 周四、6/8 周一 …等共 8 条     ← 12 inkSoft   │
│                                                              │
│   ─────────────────────────────────                          │
│         [取消]            [确认修改]                          │
│       TextButton ink     FilledButton accent fill            │
└──────────────────────────────────────────────────────────────┘
```

### 5.2 视觉规格

| 区 | 项 | 值 |
|---|---|---|
| 容器 | `AlertDialog` | `dialogTheme` 已配（card 底 + radius 20 + elevation 0） |
| 标题 | text | `'确认修改重复规则'`（继承 `dialogTheme.titleTextStyle`：17px w600 ink letterSpacing 0.3） |
| Content padding | `EdgeInsets.fromLTRB(24, 12, 24, 0)` | 沿用默认 |
| 三行容器 | `Column(crossAxisAlignment: CrossAxisAlignment.start)` | 行间距 `SizedBox(height: 14)` |
| 单行 | `Row(crossAxisAlignment: CrossAxisAlignment.center)` | `Icon(size:18, color: <见下表>) + SizedBox(width:10) + Expanded(Text(... , style: TextStyle(fontSize:14, color: AppElegant.ink, height:1.4)))` |
| 三行下方间距 | `SizedBox(height: 14)` | |
| 示例日期行 | `Text(<sampleLine>, style: AppText.meta)` | 12px inkSoft height 1.4 |
| 示例上下 padding | `EdgeInsets.only(bottom: 4)` | |
| Actions 区 | `actions: [TextButton, FilledButton]` | `actionsPadding: EdgeInsets.fromLTRB(8, 0, 12, 8)` |
| 取消按钮 | `TextButton(child: Text('取消'))` | 继承 `textButtonTheme.foregroundColor = AppElegant.ink`（实际显示 ink，14px w500） |
| 确认修改按钮 | `FilledButton(style: FilledButton.styleFrom(backgroundColor: AppElegant.accent), child: Text('确认修改'))` | 继承 `filledButtonTheme`（white 字 + radius 12 + horizontal 20 vertical 12） |

### 5.3 三行图标颜色映射（解决 PRD AC-22 → AppElegant token 的对齐）

| PRD 描述 | Icon | 颜色 token | AppElegant 实际值 | 备注 |
|---|---|---|---|---|
| rose | `Icons.delete_sweep_outlined` | `AppElegant.rose` | `Color(0xFFC9526E)` Wine Rose（与 accent 同值） | 表示"删除/警示" |
| sage | `Icons.lock_outline` | `AppElegant.sage` | `Color(0xFF7A9278)` 鼠尾草绿 | 表示"保留/安全" |
| accent | `Icons.add_circle_outline` | `AppElegant.accent` | `Color(0xFFC9526E)` Wine Rose | 表示"重建/正向行动" |

> 注：`rose` 与 `accent` 在当前 AppElegant 调色板中数值同源（均为玫瑰主色），但在语义上拆分为两个 token（`rose` 表"破坏性"、`accent` 表"主行动"）。dev 必须用对应 token 名（`AppElegant.rose` / `AppElegant.accent`），便于未来替换 token 不破坏语义。

### 5.4 示例日期取值矩阵（**解决 PRD AC-22 留下的"K=0~3 中位重复"悬念**）

| K | 显示文案 | "…等共 N 条"后缀 | 备注 |
|---|---|---|---|
| 0 | （不进入弹窗） | — | PRD AC-08 / AC-13 已阻断；UI 层在 `_onTapSave` 校验空 repeatDays 提前 SnackBar，而 commit 校验空 toCreate 提前 return |
| 1 | `示例日期：6/4 周四` | **不带** | 单条直接显示 |
| 2 | `示例日期：6/4 周四、6/8 周一` | **不带** | 两条全列 |
| 3 | `示例日期：6/4 周四、6/6 周六、6/8 周一` | **不带** | 三条全列；本设计**禁止取首/中/尾导致中位 = 首或末**——K=3 时 toCreate[0]/[1]/[2] 直接全列，与"取首/中/尾"等价但不会重复 |
| > 3 | `示例日期：{首}、{中位}、{末} …等共 K 条` | **带** | 首=`toCreate[0]`，中位=`toCreate[(K/2).floor()]`（K=4 时为 [2]，K=5 时为 [2]，K=6 时为 [3]，均不与首末重复），末=`toCreate.last` |

**dev 落地伪代码**：
```dart
String _buildSampleLine(List<DateTime> toCreate) {
  String fmt(DateTime d) {
    const w = ['一','二','三','四','五','六','日'];
    return '${d.month}/${d.day} 周${w[d.weekday - 1]}';
  }
  final K = toCreate.length;
  if (K == 0) return ''; // 不应到达，AC-08 已阻断
  if (K <= 3) {
    return '示例日期：${toCreate.map(fmt).join('、')}';
  }
  final first = toCreate.first;
  final mid = toCreate[(K / 2).floor()];
  final last = toCreate.last;
  return '示例日期：${fmt(first)}、${fmt(mid)}、${fmt(last)} …等共 $K 条';
}
```

> **关键校验（dev/qa 双确认）**：K=4 时 mid index = 2，三个索引 0/2/3 互不相同；K=5 时 0/2/4；K=6 时 0/3/5；均无重复。**该公式可直接落入测试用例**（PRD AC-22 单测部分）。

### 5.5 弹窗调用入口（PRD AC-23）

```dart
showDialog(
  context: context,
  builder: (_) => RecurringImpactDialog(
    deleteCount: preview.toDelete.length,
    keepCount: preview.toKeep.length,
    createCount: preview.toCreate.length,
    sampleLine: _buildSampleLine(preview.toCreate),
    onCancel: () => Navigator.pop(_),
    onConfirm: () async {
      Navigator.pop(_);
      await provider.commitRecurringRuleUpdate(...);
      if (mounted) {
        Navigator.pop(context, true); // 关闭编辑屏，返回 true
      }
    },
  ),
);
```

---

## 6. ColorScheme 16 槽位对齐表

> M3 ColorScheme 完整 16 槽位（按 Material 官方规范）：primary / onPrimary / primaryContainer / onPrimaryContainer / secondary / onSecondary / secondaryContainer / onSecondaryContainer / tertiary / onTertiary / tertiaryContainer / onTertiaryContainer / error / onError / surface / onSurface。
> 当前 `AppTheme.lightTheme.colorScheme` 由 `ColorScheme.fromSeed(seedColor: AppElegant.accent, primary: accent, secondary: accentDark, surface: card)` 派生，本次新增 UI 用到的颜色一一对齐如下：

| 本次 UI 颜色用途 | 对应 16 槽位 | AppElegant token | 实际值 |
|---|---|---|---|
| 主行动按钮底 / 主选中态 / accent 短分隔线 / accent 图标 | **primary** | `AppElegant.accent` | `#C9526E` |
| 主行动按钮文字 / 主图标前景 | **onPrimary** | `Colors.white` (`AppElegant.onAccent`) | `#FFFFFF` |
| 选中态背景（accent 0.08 alpha） / 浅粉装饰 | **primaryContainer**（视觉等价） | `AppElegant.accentLight` | `#EFC9D3` |
| 选中态文字（accent） / 选中态图标 | **onPrimaryContainer** | `AppElegant.accent` | `#C9526E` |
| 按压态/强调（深玫瑰） | **secondary** | `AppElegant.accentDark` | `#A73D56` |
| 按压态前景 | **onSecondary** | `Colors.white` | `#FFFFFF` |
| 弹窗"删除"图标（rose） | **error** 语义槽 | `AppElegant.rose` | `#C9526E`（与 primary 同值，token 名拆分） |
| 弹窗"保留"图标（sage） | **tertiary** 语义槽 | `AppElegant.sage` | `#7A9278` |
| 卡片底 / Dialog 底 | **surface** | `AppElegant.card` | `#FFFFFF` |
| 主文字（卡片标题、输入文字、TextButton 文字） | **onSurface** | `AppElegant.ink` | `#2B1E22` |
| 次级文字（卡片小标题 caption、副小字 meta） | **onSurfaceVariant**（视觉等价） | `AppElegant.inkSoft` | `#7A6268` |
| 占位/提示字 | onSurface low | `AppElegant.inkFaint` / `AppElegant.inkWhisper` | `#A59195` / `#CFBEC2` |
| 屏背景 | scaffold（非槽位） | `AppElegant.bg` | `#FBF8F7` |
| 发丝分隔线 / 卡描边 / Chip 描边 | **outline** | `AppElegant.hair` | `#EDE6E7` |

> 落地原则：**dev 不直接写 `Theme.of(context).colorScheme.primary`，统一通过 `AppElegant.<token>` 引用**，避免在 16 槽位语义重命名时（未来 case）连锁改 view 文件；同时若需要响应主题切换，已被 `app_theme.dart` 在 `colorScheme.fromSeed(seedColor: AppElegant.accent)` 处统一接入。

---

## 7. View Token 清单（给 dev 参考；≥ 8 行）

> 规则：**任何颜色 / 字号 / 字重必须走 token，不允许在 view 中裸写十六进制或裸数字字号**。下表是本次 3 个新 UI 文件预期的 token 引用清单。

| # | UI 元素 | 颜色 token | 字号/字重 token | 几何 token |
|---|---|---|---|---|
| 1 | 详情页新增 NavBar 按钮 | `AppElegant.card` 底 + `AppElegant.hair` 描边 + `AppElegant.ink` 图标 | 走组件默认（size=16） | size=36（组件 default） |
| 2 | 编辑屏 NavBar 标题 | `AppElegant.ink` | `AppText.navTitle` | 高度 56（组件 default） |
| 3 | 编辑屏副标题"生效起始日…" | `AppElegant.inkSoft` | `AppText.heroHint` | letterSpacing 走 token |
| 4 | 副标题下方短分隔线 | `AppElegant.accent` | — | `width:40 height:1` |
| 5 | 标题输入框文字 | `AppElegant.ink` | `AppText.heroTitle` | cursor 1.5 |
| 6 | 标题输入框 hint | `AppElegant.inkWhisper` | 30px w700 letterSpacing -0.5（与 heroTitle 同字号） | — |
| 7 | 卡片底 / Dialog 底 | `AppElegant.card` | — | radius 18 / 20，hair 0.5 描边 |
| 8 | 卡片小标题（"时间"/"分类"/"重复"/"详情"） | `AppElegant.inkSoft` | `AppText.caption` | — |
| 9 | 卡片提示语（"日期由重复规则决定…"） | `AppElegant.inkSoft` | `AppText.meta` | — |
| 10 | 时间大数字 | `AppElegant.ink` | 36px w300 letterSpacing -1 height 1（沿用 add 屏） | — |
| 11 | 重复频率分段（选中） | fill=`AppElegant.ink`，字 white | 13 w600 | radius 12 height 40 |
| 12 | 星期圆点（选中） | fill=`AppElegant.accent`，字 white | 13 w600 | size 36×36 圆 |
| 13 | 星期圆点（未选） | transparent 底 + `AppElegant.hair` 描边 1px，字=`AppElegant.inkSoft` | 13 w500 | size 36×36 圆 |
| 14 | 浮动保存按钮 | `AppElegant.accent` 底 + `Colors.white` 字（disabled→`AppElegant.hair`+`AppElegant.inkFaint`） | 15 w600 letterSpacing 2 | radius 14 height 54 |
| 15 | Dialog 三行图标 | `AppElegant.rose` / `AppElegant.sage` / `AppElegant.accent` | size 18 | — |
| 16 | Dialog 三行文字 | `AppElegant.ink` | 14 w400 height 1.4 | — |
| 17 | Dialog 示例日期行 | `AppElegant.inkSoft` | `AppText.meta` | — |
| 18 | Dialog 取消按钮 | `AppElegant.ink`（继承 textButtonTheme） | 14 w500（继承 theme） | — |
| 19 | Dialog 确认按钮 | `AppElegant.accent` 底（filledButtonTheme） + white 字 | 继承 filledButtonTheme | radius 12 |

---

## 8. 边界与状态枚举（charter §4.G2 必填）

### 8.1 EditRecurringRuleScreen 状态

| 状态 | 触发条件 | 视觉/交互定义 |
|---|---|---|
| **正常编辑态** | 默认 | 全部卡片可交互；保存按钮 accent 底白字可按 |
| **空标题** | `_titleCtrl.text.trim().isEmpty` | 保存按钮可按；点击触发 SnackBar `'请输入日程标题'`，不进入预演 |
| **空 repeatDays（weekly）** | `_repeatType == weekly && _repeatDays.isEmpty` | 保存按钮**禁用**（`onPressed: null`，组件自动转 disabled 灰）；如用户绕过（理论上不可能，作兜底）调 `_onTapSave` 时再 SnackBar `'请至少选择一个星期'` |
| **daily 模式** | `_repeatType == daily` | 星期勾选区**整体不渲染**（用 `if (...weekly\|\|custom)` 包裹），保留卡片其余视觉 |
| **课程开关关** | `_isCourse == false` | 课程胶囊列表整段隐藏（沿用 add 屏） |
| **加载/保存中** | `commitRecurringRuleUpdate` 进行中 | （增强建议）保存按钮文案切换为"保存中…"且禁用 + 屏幕 IgnorePointer 包裹；commit 失败 SnackBar `'保存失败：$e'` |

### 8.2 RecurringImpactDialog 状态

| 状态 | 描述 |
|---|---|
| **正常态** | 三行计数 + 示例日期 + 两枚按钮（PRD AC-22 / AC-23 默认场景） |
| **K = 0 兜底** | 不进入此弹窗（preview 阶段已经 SnackBar `'请至少选择一个星期'` 或 `'当前规则下无新实例可生成'` 兜底） |
| **commit 中** | 确认按钮 disabled + 文案切"提交中…"（沿用 PrimaryButton disabled 视觉） |
| **commit 错误** | 弹窗保持开启 + Dialog 内部底部追加 14px rose 错误小字 `'保存失败，请重试'` |

### 8.3 详情页 NavBar 状态

| 状态 | 视觉 |
|---|---|
| 单实例日程 | 2 枚按钮（编辑 / 删除） |
| 重复组实例 | 3 枚按钮（编辑 / 修改重复规则 / 删除） |
| 主题色变化（未来） | 全部 token 自动跟随 `AppElegant`，无需 view 改动 |

---

## 9. 实现注意事项（给 dev 的提示）

1. **字段预填策略**（PRD AC 未明说，plan.md 已锁）：
   - `EditRecurringRuleScreen` 接收 `seed: Schedule`（用户点击的"那条实例"）。
   - `initState` 内调 `provider.getGroupScheduleIds(seed.repeatTemplateId)`，找出 `parentId == null` 的组长；存在则用组长字段预填，不存在（异常）回退用 `seed`。
   - 组长字段：`title / description / location / memo / dateTime（仅时分） / endTime / repeatType / repeatDays / scheduleType / isCourse / courseId`。

2. **daily ↔ weekly 切换动画**：
   - 用 `AnimatedSize(duration: 180.ms, curve: Curves.easeOutCubic)` 包裹星期勾选区；
   - 或显式 `AnimatedContainer(duration: 180.ms)`（沿用 `add_schedule_screen` 第 595 行的节奏）；
   - 切到 `daily` 时把 `_repeatDays` 清空（不影响 commit，因 daily 走全周）。

3. **空 repeatDays 兜底**（PRD AC-08 / AC-13）：
   - UI 层：`_onTapSave` 第一道关卡，校验 weekly+empty 直接 SnackBar return；
   - Provider 层：`previewRecurringRuleUpdate` 收到 `weekly && empty` 抛 `ArgumentError`，UI 用 try/catch 容错（**双保险**）。

4. **K = 0 阻断 commit**：
   - 即便用户绕过 UI，`commitRecurringRuleUpdate` 第一步必须 `if (preview.toCreate.isEmpty) return;`，避免静默删空原组。

5. **示例日期 date 转换**：
   - PRD AC-22 文案"M/d 周X"，月/日**不补 0**（`6/4` 而非 `06/04`），用 `'${d.month}/${d.day}'` 直接拼接。

6. **导航返回值**：
   - 编辑屏 `Navigator.pop(context, true)` 触发详情屏 `loadSchedules + Navigator.pop(context)`，与现有"编辑成功"语义一致。

7. **HapticFeedback**：
   - 所有 elegant_kit 组件已内置；新增的非组件 InkWell（如时间行）需补 `HapticFeedback.selectionClick()`。

8. **`isRecurring` 判定一致性**：
   - 详情页已有 `_showDeleteConfirm` 内同款判定，dev 可提取 `_isRecurring` getter 供 NavBar 与删除弹窗共用，避免散落。

---

## 10. 自评 G2 闸门标准

### 10.1 对照 charter §4.G2 逐条勾选

- [x] 涉及屏幕/组件清单（带文件路径） → §2
- [x] 关键状态枚举（如：未打卡 / 已打卡 / 已过期 → 本 case 改为重复组/单实例/空 repeatDays/K=0/commit 中） → §3.1、§8.1、§8.2、§8.3
- [x] 每个状态的视觉/交互定义（图标、颜色、文案、可点击性） → §3.2、§4.2 各小节、§5.2、§5.3
- [x] 与 `elegant_kit` 现有组件的复用关系 → §1（5 个关键词）+ §3.2 + §4.2 表中"组件"列全部点明，**无新组件发明**
- [x] 边界场景（空态、加载态、错误态） → §8 三张表分别覆盖

### 10.2 上游 PRD 24 条 AC 全覆盖对应表

| AC | 描述要点 | 设计稿位置 |
|---|---|---|
| AC-01 | 重复组渲染第 3 枚按钮 | §3.1、§3.2、§3.3、§3.4 |
| AC-02 | 单实例不渲染 | §3.1、§3.4（`if (isRecurring)` 包裹）、§8.3 |
| AC-03 | 普通编辑按钮行为不变 | §3.4（仅插入新按钮，不动现有 `Icons.edit_outlined` 分支） |
| AC-04 | 未来边界 = 明天 00:00 | §4.2 ① 副标题区（dev 落地 `tomorrowStart`） |
| AC-05 | 副标题"生效起始日"+ 1px×40 accent 短线 + 12 letterSpacing 2 | §4.2 ① |
| AC-06 | 已打卡未来实例落入保留集 | §9.1（字段预填走组长，不动其它实例） |
| AC-07 | 同日冲突保留旧 | （UI 不暴露；commit 内部解决，弹窗 K 数自动反映） |
| AC-08 | 空 repeatDays 阻断 + SnackBar `'请至少选择一个星期'` | §4.2 ⑧ disabled 态 + §8.1 第 3 行 + §9.3 |
| AC-09 | 模板字段同步 | §4.2 ②③④⑥⑦（输入控件全部 `_xxxCtrl` 绑定） |
| AC-10 | 已打卡未来实例不被同步 | §9.1（不动其它实例，仅组长 update） |
| AC-11 | 组长接力（被删时） | §9.1 + provider 内部，UI 层无视觉变化 |
| AC-12 | 组长保留时仅刷新时分 | §9.1（dateTime 年月日不动，时分跟新模板） |
| AC-13 | provider 空 repeatDays 抛 ArgumentError | §9.3（UI/Provider 双保险） |
| AC-14 | weekly→daily 自动忽略 repeatDays，不渲染勾选区 | §4.2 ⑤（`if (weekly\|\|custom)` 才渲染）+ §9.2 |
| AC-15 | daily→weekly 渲染勾选区 + AC-08 兜底 | §4.2 ⑤ + §8.1 |
| AC-16 | weekly↔custom 等价 | §4.2 ⑤（视觉一致） |
| AC-17 | 跨月续期用新组长 | （UI 不暴露，dev 在 commit 后调 `loadSchedules` 即可） |
| AC-18 | 通知刷新-删除 | （UI 不暴露） |
| AC-19 | 通知刷新-新建 | （UI 不暴露） |
| AC-20 | 通知刷新-组长 update | （UI 不暴露） |
| AC-21 | 弹窗计数精确 | §5.5（直接绑 preview 三组 length） |
| AC-22 | 弹窗文案 + 示例日期矩阵 | §5.1、§5.3、§5.4（含 K=0/1/2/3/>3 完整矩阵） |
| AC-23 | 取消（TextButton）+ 确认修改（FilledButton accent） | §5.2 表底两行 |
| AC-24 | 事务原子性 | （UI 不暴露；commit 失败由 §8.2 错误态展示） |

**结论**：24 条 AC 全部在设计稿中有对应章节或在"UI 不暴露"中明确标注由 provider 落地。

### 10.3 自评结论

满足 charter §4.G2 全部 5 项硬性要求；上游 PRD 24 条 AC 100% 覆盖；无新组件发明；ColorScheme 16 槽位与 AppElegant 一一对齐；K=0~K>3 的示例日期矩阵已完整给出（解决 PRD 留下的中位重复悬念）。**等待 PM G2 评审。**
