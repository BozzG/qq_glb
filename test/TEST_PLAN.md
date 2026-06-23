# 测试计划 - QQ成长日志应用

**计划ID**: TP-001  
**设计ID**: TD-001  
**测试人员**: Tester Agent  
**创建日期**: 2026-04-24  

## 1. 测试范围

### 1.1 功能模块
- [ ] 日程管理（Schedule）
  - 创建日程（单次/重复）
  - 编辑日程
  - 删除日程（单个/整个重复组）
  - 重复日程实例自动扩展
- [ ] 打卡功能（CheckIn）
  - 打卡操作
  - 重复打卡检测
  - 课时自动扣减
- [ ] 课程管理（Course）
  - 创建课程
  - 编辑课程
  - 删除课程
  - 课时调整
- [ ] 备忘录（Memo）
  - 创建备忘录
  - 编辑备忘录
  - 删除备忘录
- [ ] 医疗记录（MedicalRecord）
  - 创建医疗记录
  - 编辑医疗记录
  - 删除医疗记录
- [ ] 成长日志（GrowthLog）
  - 创建成长日志
  - 编辑成长日志
  - 删除成长日志
- [ ] 通知服务（NotificationService）
  - 调度通知
  - 取消通知
  - 权限请求

### 1.2 非功能需求
- 数据库操作性能
- UI 响应速度
- 内存占用

## 2. 测试策略

### 2.1 单元测试
- **目标覆盖率**: > 80%
- **测试框架**: test package
- **Mock 策略**: 使用 mockito 或手动 mock

#### 测试对象：
1. **Models** - 数据模型
   - Schedule
   - CheckIn
   - Course
   - CourseConsumption
   - Memo
   - MedicalRecord
   - GrowthLog

2. **Providers** - 业务逻辑
   - ScheduleProvider
   - CourseProvider
   - MemoProvider
   - MedicalProvider
   - GrowthLogProvider

3. **Services** - 服务层
   - DatabaseHelper
   - NotificationService

### 2.2 集成测试
- **测试框架**: integration_test package
- **测试场景**：
  1. 完整日程创建流程
  2. 打卡并扣减课时流程
  3. 重复日程实例扩展
  4. 数据持久化

### 2.3 UI 测试
- **测试框架**: flutter_test package
- **测试场景**：
  1. 主页加载
  2. 添加日程界面
  3. 打卡界面
  4. 课程设置界面

## 3. 测试用例

### 3.1 Schedule Model 测试用例

| ID | 描述 | 优先级 | 前置条件 | 测试步骤 | 预期结果 |
|----|------|--------|----------|----------|----------|
| TC-001 | 创建 Schedule 对象 | High | 无 | 1. 调用 Schedule 构造函数 | 对象创建成功，属性正确 |
| TC-002 | toMap() 转换 | High | Schedule 对象 | 1. 调用 toMap() | 返回正确的 Map |
| TC-003 | fromMap() 转换 | High | Map 数据 | 1. 调用 Schedule.fromMap() | 返回正确的 Schedule 对象 |
| TC-004 | copyWith() 修改属性 | Medium | Schedule 对象 | 1. 调用 copyWith() | 属性正确修改，其他属性不变 |
| TC-005 | color getter | Medium | Schedule 对象 | 1. 设置不同 scheduleType | 返回正确的颜色 |
| TC-006 | typeIcon getter | Medium | Schedule 对象 | 1. 设置不同 scheduleType | 返回正确的图标 |

### 3.2 ScheduleProvider 测试用例

| ID | 描述 | 优先级 | 前置条件 | 测试步骤 | 预期结果 |
|----|------|--------|----------|----------|----------|
| TC-010 | 加载日程 | High | 数据库有数据 | 1. 调用 loadSchedules() | _schedules 正确加载 |
| TC-011 | 添加单次日程 | High | 无 | 1. 创建 Schedule (repeatType=none) 2. 调用 addSchedule() | 日程插入数据库，通知已调度 |
| TC-012 | 添加重复日程 | High | 无 | 1. 创建 Schedule (repeatType=daily) 2. 调用 addSchedule() | 多个实例插入数据库 |
| TC-013 | 删除单个日程 | High | 存在日程 | 1. 调用 deleteSchedule(id) | 日程和打卡记录删除，通知取消 |
| TC-014 | 删除整个重复组 | High | 存在重复日程 | 1. 调用 deleteSchedule(id, deleteAllRecurring=true) | 所有实例删除 |
| TC-015 | 打卡 | High | 存在日程 | 1. 调用 checkIn(scheduleId) | 打卡记录创建，课时扣减（如果是课程） |
| TC-016 | 重复打卡检测 | Medium | 已打卡 | 1. 再次调用 checkIn(scheduleId) | 返回 false |
| TC-017 | 获取某天日程 | Medium | 存在日程 | 1. 调用 getSchedulesForDay(day) | 返回正确的日程列表 |
| TC-018 | 重复日程自动扩展 | Medium | 存在重复日程 | 1. 加载日程 2. 检查日期范围 | 自动扩展到下个月 |

### 3.3 CourseProvider 测试用例

| ID | 描述 | 优先级 | 前置条件 | 测试步骤 | 预期结果 |
|----|------|--------|----------|----------|----------|
| TC-020 | 加载课程 | High | 数据库有数据 | 1. 调用 loadCourses() | _courses 正确加载 |
| TC-021 | 添加课程 | High | 无 | 1. 创建 Course 2. 调用 addCourse() | 课程插入数据库 |
| TC-022 | 更新课程 | Medium | 存在课程 | 1. 修改 Course 2. 调用 updateCourse() | 课程更新 |
| TC-023 | 删除课程 | High | 存在课程 | 1. 调用 deleteCourse(id) | 课程和消耗记录删除 |
| TC-024 | 调整课时 | Medium | 存在课程 | 1. 调用 adjustHours(id, amount) | 消耗记录创建，usedHours 更新 |

### 3.4 DatabaseHelper 测试用例

| ID | 描述 | 优先级 | 前置条件 | 测试步骤 | 预期结果 |
|----|------|--------|----------|----------|----------|
| TC-030 | 初始化数据库 | High | 无 | 1. 调用 database getter | 数据库创建，表结构正确 |
| TC-031 | 插入数据 | High | 数据库已初始化 | 1. 调用 insert(table, data) | 数据插入成功 |
| TC-032 | 查询数据 | High | 有数据 | 1. 调用 query(table) | 返回正确数据 |
| TC-033 | 更新数据 | Medium | 有数据 | 1. 调用 update(table, data) | 数据更新成功 |
| TC-034 | 删除数据 | Medium | 有数据 | 1. 调用 delete(table) | 数据删除成功 |
| TC-035 | 重置数据库 | Low | 有数据 | 1. 调用 resetAll() | 所有表清空，默认设置恢复 |

## 4. 测试时间表

| 阶段 | 任务 | 预计时间 | 状态 |
|------|------|----------|------|
| 1 | 测试环境搭建 | 0.5h | Pending |
| 2 | Model 单元测试 | 2h | Pending |
| 3 | Provider 单元测试 | 3h | Pending |
| 4 | Service 单元测试 | 2h | Pending |
| 5 | 集成测试 | 2h | Pending |
| 6 | UI 测试 | 2h | Pending |
| 7 | 测试报告 | 1h | Pending |

## 5. 测试环境

- **操作系统**: macOS
- **Flutter 版本**: 3.10.0+
- **测试设备**: 
  - iOS Simulator
  - Android Emulator
  - Web (Chrome)

## 6. 风险评估

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 数据库测试需要真实环境 | Medium | 使用内存数据库或 mock |
| 通知测试需要真实设备 | Low | 使用 mock 或跳过 |
| UI 测试需要模拟器 | Medium | 使用集成测试 |

## 7. 交付物

1. 单元测试代码
2. 集成测试代码
3. UI 测试代码
4. 测试报告（包含覆盖率）
5. Bug 列表（如有）
