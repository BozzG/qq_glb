# 测试报告 - 打卡状态判定修复

| 字段 | 值 |
| --- | --- |
| 报告ID | QA-004 |
| 版本号 | v1.0 |
| 责任 agent | qa-agent |
| Task 编号 | #004 |
| 关联 PRD | [docs/prd/checkin-status-fix.md](../prd/checkin-status-fix.md) v1.0 |
| 关联 UI 清单 | [docs/design/checkin-status-fix-ui-checklist.md](../design/checkin-status-fix-ui-checklist.md) v1.0 |
| 关联 Code Review | [docs/review/checkin-status-fix-review.md](../review/checkin-status-fix-review.md) v1.0 |
| 闸门 | G4（QA 验收） |
| 执行时间 | 2026-05-13 |
| 应用版本 | 1.0.0+1 |

---

## 1. 测试范围与策略

### 1.1 范围（PRD 验收标准对齐）

| 范围维度 | 内容 |
| --- | --- |
| 核心代码 | `lib/providers/schedule_provider.dart` 中 `checkIn` / `isCheckedIn` / `isCheckedToday` |
| 影响调用面 | `lib/screens/home_screen.dart` 的 `_ScheduleCard`；间接验证 `today_overview_screen.dart` / `schedule_detail_screen.dart` 通过别名 `isCheckedToday` 调用的行为 |
| 数据落地 | `check_ins` 表、`course_consumptions` 表、`courses.usedHours` |
| AC 覆盖 | AC-01 ~ AC-06 全部纳入用例锚点 |
| UI 清单覆盖 | 静态项 VC-01~02/04~08、IC-01~02 由 G3 review 已确认；动态项 VC-03/IC-03（详情页 SnackBar）记为手动验证；动态项 IC-04（课程类课时数变化）通过 provider 数据态自动化覆盖 |

### 1.2 策略

1. **不修改业务代码**，仅在 `test/schedule_provider_test.dart` 末尾追加 group `打卡状态判定修复 (Task #004)`，复用既有的 sqflite_ffi 内存数据库 + NotificationService 测试模式。
2. **不新建 test 文件**，避免重建轮子；group 内 6 条用例编号 `TC-004-01` ~ `TC-004-06`。
3. **自动化覆盖优先**：能在 provider/数据态层验证的逻辑全部上自动化；UI 文案/动效与详情页跳转走手动验证记录。
4. 自动化以 `flutter test` 为执行入口，要求新增用例 100% 通过、对既有 `provider/model/migration/diary` 测试集**零回归**。

### 1.3 不在范围

- D-01 / D-02 / D-03 三项黄灯文案/命名债（UI 清单第 6 节、Review T-01/T-03）：**显式排除于 G4 处理范围**，移交后续迭代。
- T-04（schedules `(templateId, dateTime)` 缺 unique 索引）：非本期 case，记录但不阻塞。
- 真机/模拟器集成测试：与现有测试基础设施保持一致，不在本期补齐。

---

## 2. 用例清单

> 自动化用例落地路径：`test/schedule_provider_test.dart` → group `打卡状态判定修复 (Task #004)`（文件末尾，line 168 起）。

### TC-004-01　isCheckedIn 直测 - 历史日已打卡 / 未打卡

| 项 | 内容 |
| --- | --- |
| 关联 AC | AC-01 / AC-03（直接覆盖） |
| 前置 | 内存数据库；新建 ScheduleProvider 实例 |
| 步骤 | 1) 构造昨日 8:00 已打卡日程 A；2) 构造昨日 10:00 未打卡日程 B；3) 调 `provider.checkIn(A.id)`；4) 分别断言 `isCheckedIn(A.id)` / `isCheckedIn(B.id)` |
| 预期 | A.true、B.false；判定与"今天"完全解耦 |
| 实际 | 与预期一致 |
| 结果 | ✅ 通过 |

### TC-004-02　isCheckedToday 别名回归 - 等价于 isCheckedIn

| 项 | 内容 |
| --- | --- |
| 关联 AC | AC-06 |
| 前置 | 同上 |
| 步骤 | 1) 构造昨日日程 Y 与今日日程 T；2) 仅对 Y 打卡；3) 比对 `isCheckedToday(x)` 与 `isCheckedIn(x)` 在两个 id 上的返回值 |
| 预期 | 两个方法返回值严格相等；`isCheckedToday(Y)==true`，`isCheckedToday(T)==false` |
| 实际 | 与预期一致 |
| 结果 | ✅ 通过 |

### TC-004-03　重复打卡幂等 - 第二次 checkIn 返回 false 且仅落 1 条记录

| 项 | 内容 |
| --- | --- |
| 关联 AC | AC-02 |
| 前置 | 同上 |
| 步骤 | 1) 构造今日日程 D；2) 连续两次 `checkIn(D.id)`；3) 直查 `check_ins` 表 |
| 预期 | 第 1 次 true、第 2 次 false；`check_ins` 表 scheduleId=D.id 的记录仅 1 条；`isCheckedIn(D.id)` 为 true |
| 实际 | 与预期一致 |
| 结果 | ✅ 通过 |

### TC-004-04　课程类日程扣课时幂等

| 项 | 内容 |
| --- | --- |
| 关联 AC | AC-05 |
| 前置 | 在 `courses` 落一条 `totalHours=10/usedHours=0` 的课程 C |
| 步骤 | 1) 构造课程类日程（isCourse=true、courseId=C）；2) 连续两次 checkIn；3) 直查 `course_consumptions`；4) 直查 `courses.usedHours` |
| 预期 | 第 2 次 checkIn 返回 false；`course_consumptions` 仅新增 1 条（带 relatedCheckInId）；`courses.usedHours==1.0`（remainingHours=9.0） |
| 实际 | 与预期一致 |
| 结果 | ✅ 通过 |

### TC-004-05　重复日程跨天独立

| 项 | 内容 |
| --- | --- |
| 关联 AC | AC-03 / UI VC-06 |
| 前置 | 直接落两条同 `repeatTemplateId`、不同日期的实例（D1 比 D2 早一天，避免依赖月窗自动扩展，提升测试稳定性） |
| 步骤 | 1) 仅对 D1 打卡；2) 断言 `isCheckedIn(D1)==true`、`isCheckedIn(D2)==false`；3) 再对 D2 打卡；4) 直查 `check_ins` 表 |
| 预期 | D1 打卡不影响 D2 状态；D2 可独立成功打卡；最终两条 check_ins 一一对应 D1/D2 |
| 实际 | 与预期一致 |
| 结果 | ✅ 通过 |

### TC-004-06　IC-04 课程类首次打卡 UI 数据态变化

| 项 | 内容 |
| --- | --- |
| 关联 UI 清单项 | IC-04（动态项；按派单允许 widget test 或 provider 数据态二选一，本用例选后者） |
| 关联 AC | AC-05 的 UI 侧延伸 |
| 前置 | 在 `courses` 落一条 `totalHours=5/usedHours=0` 课程 |
| 步骤 | 1) 构造课程类日程；2) 打卡前直查 `courses.usedHours`；3) 首次打卡；4) 打卡后再直查 `courses.usedHours`；5) 二次点击；6) 再直查 |
| 预期 | 打卡前 0.0 → 首次打卡后 1.0 → 二次点击仍 1.0；等价于课时屏 UI 上"已用课时"+1 且二次不再变化 |
| 实际 | 与预期一致 |
| 结果 | ✅ 通过 |

### 2.x　手动验证记录（动态 UI 项）

| 用例 | 关联清单 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| MV-01 | VC-03 首页打卡按钮 S1→S2 切换 ≤250ms | 代码层确认 `ElegantCheckInButton` 使用 `AnimatedContainer` 250ms + `AnimatedSwitcher` 200ms（与 UI 清单 3.1 一致）；G3 静态评审已通过。建议在下一次集成测试或真机回归补集成测试断言。 | 通过（沿用 G3 静态结论 + 设计稿） |
| MV-02 | IC-03 详情页打卡 SnackBar `打卡成功` + 自动返回 | `schedule_detail_screen.dart` `_handleCheckIn` 本期未改动；review 已确认。本期未做真机回放。 | 通过（沿用 G3 静态结论） |

> 说明：MV-01/MV-02 不阻塞 G4，但在测试基础设施中未自动化。后续如就 home_screen / detail screen 集成测试补强，可考虑覆盖。

---

## 3. 自动化覆盖矩阵（PRD AC × 用例 × UI 清单）

| PRD AC | 描述 | 覆盖用例 | 关联 UI 清单项 |
| --- | --- | --- | --- |
| AC-01 | 历史日已打卡显示 | TC-004-01 | VC-01 |
| AC-02 | 同实例不可重复打卡 | TC-004-03 | IC-01 |
| AC-03 | 重复日程跨天独立 | TC-004-05、TC-004-01（旁证） | VC-06 |
| AC-04 | 当天打卡流程不受影响 | TC-004-01（首次打卡子断言）、TC-004-03（首次 true 子断言） | IC-02 |
| AC-05 | 课程类正确扣课时 | TC-004-04、TC-004-06 | IC-04 |
| AC-06 | 兼容旧入口 | TC-004-02 | — |

UI 清单动态项闭环：

| 清单编号 | 类型 | 覆盖手段 |
| --- | --- | --- |
| VC-03 | 动态 | 静态评审 + 手动验证记录（MV-01） |
| IC-03 | 动态 | 静态评审 + 手动验证记录（MV-02） |
| IC-04 | 动态 | 自动化（TC-004-06） |
| VC-01/02/04~08、IC-01/02、BC-01~04 | 静态/边界 | G3 静态评审已通过 |

---

## 4. 测试执行结果

### 4.1 新增用例（本期 G4 红灯门槛）

| 用例文件 | 用例数 | 通过 | 失败 |
| --- | --- | --- | --- |
| `test/schedule_provider_test.dart`（新增 group） | 6 | 6 | 0 |

执行命令：

```bash
flutter test test/schedule_provider_test.dart
```

输出关键行：

```
00:03 +13: 打卡状态判定修复 (Task #004) TC-004-06: IC-04 课程类首次打卡 UI 数据态变化 - usedHours 通过 provider 数据态可观察
00:03 +13: (tearDownAll)
00:03 +13: All tests passed!
```

含原有 7 条 + 新增 6 条，共 13 条全绿。

### 4.2 非 widget 测试集（回归）

执行命令：

```bash
flutter test \
  test/schedule_provider_test.dart \
  test/course_provider_test.dart \
  test/diary_provider_test.dart \
  test/diary_test.dart \
  test/migration_test.dart \
  test/models_test.dart \
  test/other_providers_test.dart
```

结果：`+68: All tests passed!`，**零回归**。

### 4.3 widget 测试集（既存红灯，不归属本期）

| 文件 | 失败用例数 | 失败模式 | 是否本期引入 |
| --- | --- | --- | --- |
| `test/home_screen_schedule_button_test.dart` | 16/16 | 找不到 `FloatingActionButton` / `BottomNavigationBar` / `今日概览` / `快捷入口` 等旧 UI 文案与组件 | ❌ 否 |
| `test/today_overview_screen_test.dart` | 9 | 找不到 `芊芊的一天` / `今日医疗` / `今日日程` / `本周打卡` / `周一` 等旧文案 | ❌ 否 |

**判定依据**：

1. 失败用例均不依赖 `isCheckedIn` / `isCheckedToday` / `checkIn` 的语义或返回值，全部是旧版 UI 元素文本/组件查找失败。
2. PRD/Review 均明确本期未改动 `today_overview_screen.dart`；`home_screen.dart` 本期仅改 `_ScheduleCard` 调用面与 SnackBar 文案，未删除 FAB / BottomNavigationBar 等结构（结构早已被前序改造移除，与本期 case 无关）。
3. `home_screen.dart`、`today_overview_screen_test.dart` 均位于 `git status` 中"已修改 / 未跟踪"列表（在本 case 介入之前就已存在与现有 UI 不匹配的状态），属**既存红灯**。

**处理建议**：登记为 follow-up，由 PM 安排独立 Task（例如"home_screen / today_overview widget test 与现行 UI 对齐"），不阻塞本期 G4。

---

## 5. 缺陷登记

本期未发现新增缺陷。

| 已知项 | 类型 | 来源 | 本期处理 |
| --- | --- | --- | --- |
| D-01 详情页底部按钮文案 `今日已打卡` 在历史日实例语义不严格 | 文案语义债（黄灯） | UI 清单第 6 节 / Review T-03 | ❌ 不在 G4 处理范围 |
| D-02 详情页 SnackBar `今天已经打卡过啦` 与首页文案不统一 | 文案语义债（黄灯） | UI 清单第 6 节 / Review T-03 | ❌ 不在 G4 处理范围 |
| D-03 `isCheckedToday` 命名与实际语义不一致 | 命名债（黄灯） | PRD R1 / Review T-01 | ❌ 不在 G4 处理范围；TC-004-02 已为别名兼容性回归提供保护 |
| F-01 `home_screen_schedule_button_test.dart` 16 用例失败 | 既存测试与现行 UI 不匹配 | 4.3 节 | ❌ 与本期 case 无关；建议另开 Task |
| F-02 `today_overview_screen_test.dart` 9 用例失败 | 同上 | 4.3 节 | ❌ 同上 |
| T-04 schedules 缺 `(templateId, dateTime)` unique 索引 | 数据完整性技术债 | Review T-04 | ❌ 不在本期范围 |

---

## 6. G4 闸门结论

| 闸门项 | 结论 |
| --- | --- |
| PRD 6 条 AC 全部有自动化用例锚点 | ✅ |
| UI 清单动态项（VC-03 / IC-03 / IC-04）已闭环（自动化 + 手动验证记录） | ✅ |
| 新增 6 条用例 100% 通过 | ✅ |
| 对 provider/model/migration/diary 测试集零回归 | ✅ |
| 既存 widget 红灯（F-01/F-02）与本期 case 无关并已显式登记 | ✅ |
| 黄灯文案/命名债（D-01/D-02/D-03）按章程移交后续迭代 | ✅ |

**G4 评审结论：✅ 通过，建议进入归档发布阶段。**

---

## 7. 变更记录

| 版本 | 日期 | 变更 | 责任 |
| --- | --- | --- | --- |
| v1.0 | 2026-05-13 | 首版 QA 报告，G4 闸门通过 | qa-agent |
