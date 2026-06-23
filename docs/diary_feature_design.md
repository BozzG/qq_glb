# 日记功能技术设计文档

**版本**: v3.0  
**日期**: 2026-04-24  
**作者**: Analyst Agent  
**审阅**: Architect Agent, PM Agent  

---

## 一、需求概述

### 1.1 需求背景
1. **删除备忘功能**：现有备忘功能不好用，需要移除
2. **新增日记功能**：记录芊芊的日常表现，包含日期、状态、关联日程、进步点等

### 1.2 核心功能
- 记录每日日记（日期、芊芊状态、日程关联、进步点、需加强点）
- 自动预填当日日程
- 支持多媒体（图片、视频、音频）
- 按月份浏览日记

---

## 二、删除备忘功能 - 实施规格

### 2.1 删除范围清单

| 序号 | 文件 | 操作 | 说明 |
|------|------|------|------|
| 1 | `lib/models/models.dart` | 删除第194-213行 | 删除 `Memo` 类 |
| 2 | `lib/providers/memo_provider.dart` | 删除整个文件 | 备忘录状态管理 |
| 3 | `lib/screens/memo_screen.dart` | 删除整个文件 | 备忘录界面 |
| 4 | `lib/services/database_helper.dart` | 删除第125-136行 | 删除 `memos` 表创建语句 |
| 5 | `lib/services/database_helper.dart` | 修改第301行 | `resetAll()` 移除 `'memos'` |
| 6 | `lib/services/database_helper.dart` | 修改第326行 | `recreateTables()` 移除 `'memos'` |
| 7 | `lib/screens/home_screen.dart` | 修改第463行 | 底部导航标签改为"日记" |
| 8 | `lib/screens/home_screen.dart` | 修改第480-485行 | 导航跳转改为 `DiaryScreen()` |

### 2.2 数据库迁移方案

**方案**：采用方案B（安全迁移）
1. 创建 `diaries` 表
2. 将 `memos` 数据迁移到 `diaries`
3. 删除 `memos` 表

**代码实现**：见第五章

---

## 三、数据模型设计

### 3.1 Diary 模型

**文件**: `lib/models/models.dart`

```dart
import 'dart:convert';

// ===== DiaryStatus 枚举 =====
enum DiaryStatus {
  good('良好', Color(0xFF4CAF50)),
  normal('一般', Color(0xFFFF9800)),
  irritable('易烦躁', Color(0xFFF44336));

  final String label;
  final Color color;
  
  const DiaryStatus(this.label, this.color);
}

// ===== Diary 日记 =====
class Diary {
  final String id;
  final String? title;              // 可选标题
  final String? content;            // 日记内容（可选）
  final DateTime diaryDate;         // 日记日期（必填，只能今天或过去）
  final DiaryStatus qianqianStatus; // 芊芊状态（必填）
  final List<Map<String, dynamic>> scheduleSnapshots; // 日程快照（必填，默认空数组）
  final String? progressPoints;     // 进步点（可选，多行文本）
  final String? improvementPoints; // 需加强点（可选，多行文本）
  final List<String> imagePaths;    // 图片路径（可选，最多5张）
  final List<String> videoPaths;    // 视频路径（可选，最多2个）
  final List<String> audioPaths;    // 音频路径（可选，最多3个）
  final DateTime createdAt;
  final DateTime updatedAt;

  Diary({
    required this.id,
    this.title,
    this.content,
    required this.diaryDate,
    required this.qianqianStatus,
    List<Map<String, dynamic>>? scheduleSnapshots,
    this.progressPoints,
    this.improvementPoints,
    List<String>? imagePaths,
    List<String>? videoPaths,
    List<String>? audioPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : scheduleSnapshots = scheduleSnapshots ?? [],
       imagePaths = imagePaths ?? [],
       videoPaths = videoPaths ?? [],
       audioPaths = audioPaths ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // 转换为 Map（用于数据库存储）
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'diaryDate': diaryDate.toIso8601String(),
    'qianqianStatus': qianqianStatus.name,
    'scheduleSnapshots': jsonEncode(scheduleSnapshots),
    'progressPoints': progressPoints,
    'improvementPoints': improvementPoints,
    'imagePaths': jsonEncode(imagePaths),
    'videoPaths': jsonEncode(videoPaths),
    'audioPaths': jsonEncode(audioPaths),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // 从 Map 创建（从数据库读取）
  factory Diary.fromMap(Map<String, dynamic> m) => Diary(
    id: m['id'],
    title: m['title'],
    content: m['content'],
    diaryDate: DateTime.parse(m['diaryDate']),
    qianqianStatus: DiaryStatus.values.firstWhere(
      (e) => e.name == m['qianqianStatus'],
      orElse: () => DiaryStatus.normal,
    ),
    scheduleSnapshots: (jsonDecode(m['scheduleSnapshots'] as String? ?? '[]') as List)
        .cast<Map<String, dynamic>>(),
    progressPoints: m['progressPoints'],
    improvementPoints: m['improvementPoints'],
    imagePaths: (jsonDecode(m['imagePaths'] as String? ?? '[]') as List).cast<String>(),
    videoPaths: (jsonDecode(m['videoPaths'] as String? ?? '[]') as List).cast<String>(),
    audioPaths: (jsonDecode(m['audioPaths'] as String? ?? '[]') as List).cast<String>(),
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: DateTime.parse(m['updatedAt']),
  );

  // 创建副本（用于更新）
  Diary copyWith({
    String? title,
    String? content,
    DateTime? diaryDate,
    DiaryStatus? qianqianStatus,
    List<Map<String, dynamic>>? scheduleSnapshots,
    String? progressPoints,
    String? improvementPoints,
    List<String>? imagePaths,
    List<String>? videoPaths,
    List<String>? audioPaths,
  }) => Diary(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    diaryDate: diaryDate ?? this.diaryDate,
    qianqianStatus: qianqianStatus ?? this.qianqianStatus,
    scheduleSnapshots: scheduleSnapshots ?? this.scheduleSnapshots,
    progressPoints: progressPoints ?? this.progressPoints,
    improvementPoints: improvementPoints ?? this.improvementPoints,
    imagePaths: imagePaths ?? this.imagePaths,
    videoPaths: videoPaths ?? this.videoPaths,
    audioPaths: audioPaths ?? this.audioPaths,
    createdAt: createdAt,
    updatedAt: DateTime.now(), // 自动更新
  );
}
```

### 3.2 关键设计决策

| 决策点 | 决定 | 理由 |
|--------|------|------|
| `scheduleIds` vs `scheduleSnapshots` | 采用 `scheduleSnapshots` | 避免 JOIN 查询，缓存日程关键信息 |
| `content` 必填 vs 可选 | **可选** | 用户可能只想记录状态和进步点 |
| 多媒体字段去留 | **保留** | 日记需要灵活性，与 GrowthLog 定位不同 |
| 多媒体数量限制 | **是**（图片5，视频2，音频3） | 避免滥用 |

---

## 四、数据库设计

### 4.1 diaries 表定义

```sql
CREATE TABLE diaries (
  id TEXT PRIMARY KEY,
  title TEXT,
  content TEXT,
  diaryDate TEXT NOT NULL,
  qianqianStatus TEXT NOT NULL,    -- 'good', 'normal', 'irritable'
  scheduleSnapshots TEXT NOT NULL DEFAULT '[]',
  progressPoints TEXT,
  improvementPoints TEXT,
  imagePaths TEXT NOT NULL DEFAULT '[]',
  videoPaths TEXT NOT NULL DEFAULT '[]',
  audioPaths TEXT NOT NULL DEFAULT '[]',
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
```

### 4.2 索引设计

```sql
-- 必要索引：按日期查询和分组
CREATE INDEX idx_diaries_date ON diaries(diaryDate);

-- 可选索引：按状态筛选或统计（根据实际需求决定是否创建）
-- CREATE INDEX idx_diaries_status ON diaries(qianqianStatus);
```

### 4.3 数据库迁移（v2 → v3）

**文件**: `lib/services/database_helper.dart`

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // 现有 v1→v2 迁移代码（保持不变）
    await db.execute('ALTER TABLE schedules ADD COLUMN parentId TEXT');
    await db.execute('ALTER TABLE schedules ADD COLUMN repeatTemplateId TEXT');
    
    // ... 其他 v1→v2 逻辑（生成重复日程实例）
  }
  
  if (oldVersion < 3) {
    // v2 → v3: 删除 memos 表，添加 diaries 表
    
    // 1. 创建 diaries 表
    await db.execute('''
      CREATE TABLE diaries (
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        diaryDate TEXT NOT NULL,
        qianqianStatus TEXT NOT NULL,
        scheduleSnapshots TEXT NOT NULL DEFAULT '[]',
        progressPoints TEXT,
        improvementPoints TEXT,
        imagePaths TEXT NOT NULL DEFAULT '[]',
        videoPaths TEXT NOT NULL DEFAULT '[]',
        audioPaths TEXT NOT NULL DEFAULT '[]',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    
    // 2. 创建索引
    await db.execute('CREATE INDEX idx_diaries_date ON diaries(diaryDate)');
    
    // 3. 将 memos 数据迁移到 diaries
    final memos = await db.query('memos');
    for (final memo in memos) {
      await db.insert('diaries', {
        'id': memo['id'],
        'title': memo['title'],
        'content': memo['content'],
        'diaryDate': memo['createdAt'],  // 用创建时间作为日记日期
        'qianqianStatus': 'normal',     // 默认"一般"
        'scheduleSnapshots': '[]',
        'progressPoints': null,
        'improvementPoints': null,
        'imagePaths': '[]',
        'videoPaths': '[]',
        'audioPaths': '[]',
        'createdAt': memo['createdAt'],
        'updatedAt': memo['updatedAt'],
      });
    }
    
    // 4. 删除 memos 表
    await db.execute('DROP TABLE IF EXISTS memos');
  }
}
```

### 4.4 更新 _onCreate 方法

**重要**：新安装的数据库也需要包含 `diaries` 表

```dart
Future<void> _onCreate(Database db, int version) async {
  // ... 其他表（schedules, check_ins, courses, course_consumptions）...
  
  // 医疗记录表
  await db.execute('''
    CREATE TABLE medical_records (
      id TEXT PRIMARY KEY,
      scheduleId TEXT,
      hospitalName TEXT,
      doctorName TEXT,
      diagnosis TEXT,
      medication TEXT,
      reportImagePaths TEXT,
      notes TEXT,
      visitDate TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      FOREIGN KEY (scheduleId) REFERENCES schedules(id)
    )
  ''');
  
  // 成长日志表
  await db.execute('''
    CREATE TABLE growth_logs (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      content TEXT,
      imagePaths TEXT,
      videoPaths TEXT,
      audioPaths TEXT,
      mood TEXT,
      tags TEXT,
      scheduleId TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT
    )
  ''');
  
  // +++ 新增：日记表 +++
  await db.execute('''
    CREATE TABLE diaries (
      id TEXT PRIMARY KEY,
      title TEXT,
      content TEXT,
      diaryDate TEXT NOT NULL,
      qianqianStatus TEXT NOT NULL,
      scheduleSnapshots TEXT NOT NULL DEFAULT '[]',
      progressPoints TEXT,
      improvementPoints TEXT,
      imagePaths TEXT NOT NULL DEFAULT '[]',
      videoPaths TEXT NOT NULL DEFAULT '[]',
      audioPaths TEXT NOT NULL DEFAULT '[]',
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');
  
  await db.execute('CREATE INDEX idx_diaries_date ON diaries(diaryDate)');
  
  // 主题设置表
  await db.execute('''
    CREATE TABLE app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
  
  // 插入默认设置
  await db.insert('app_settings', {'key': 'theme_mode', 'value': 'light'});
  await db.insert('app_settings', {'key': 'cartoon_theme', 'value': 'pink'});
  await db.insert('app_settings', {'key': 'reminder_minutes', 'value': '15'});
}
```

### 4.5 更新数据库版本号

**文件**: `lib/services/database_helper.dart`

```dart
Future<Database> _initDatabase() async {
  // ... 路径逻辑 ...
  
  return await openDatabase(
    dbPath,
    version: 3,  // +++ 从 2 改为 3 +++
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}
```

---

## 五、Provider 设计

### 5.1 DiaryProvider 完整实现

**新文件**: `lib/providers/diary_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class DiaryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Diary> _diaries = [];
  bool _isLoading = false;

  // Getter
  List<Diary> get diaries => _diaries;
  bool get isLoading => _isLoading;

  // 1. 加载所有日记（按日期倒序）
  Future<void> loadDiaries() async {
    _isLoading = true;
    notifyListeners();
    try {
      final maps = await _db.query('diaries', orderBy: 'diaryDate DESC');
      _diaries = maps.map((m) => Diary.fromMap(m)).toList();
    } catch (e) {
      debugPrint('加载日记失败: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // 2. 获取某月的日记
  List<Diary> getDiariesByMonth(DateTime month) {
    return _diaries.where((d) {
      return d.diaryDate.year == month.year && d.diaryDate.month == month.month;
    }).toList();
  }

  // 3. 根据ID获取日记
  Diary? getDiaryById(String id) {
    try {
      return _diaries.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  // 4. 根据日期获取日记
  List<Diary> getDiariesByDate(DateTime date) {
    return _diaries.where((d) => DatabaseHelper.isSameDay(d.diaryDate, date)).toList();
  }

  // 5. 检查某天是否已有日记
  bool hasDiaryOnDate(DateTime date) {
    return _diaries.any((d) => DatabaseHelper.isSameDay(d.diaryDate, date));
  }

  // 6. 获取最近 N 篇日记（首页展示）
  List<Diary> getRecentDiaries(int limit) {
    final sorted = [..._diaries]..sort((a, b) => b.diaryDate.compareTo(a.diaryDate));
    return sorted.take(limit).toList();
  }

  // 7. 添加日记（自动生成快照）
  Future<void> addDiary(Diary diary, List<Schedule> schedules) async {
    final snapshots = schedules.map(_createScheduleSnapshot).toList();
    final diaryWithSnapshots = diary.copyWith(
      scheduleSnapshots: snapshots,
      updatedAt: DateTime.now(),
    );
    await _db.insert('diaries', diaryWithSnapshots.toMap());
    await loadDiaries();
  }

  // 8. 更新日记（可选择是否更新快照）
  Future<void> updateDiary(Diary diary, {bool updateSnapshots = false, List<Schedule> schedules = const []}) async {
    final updatedDiary = updateSnapshots && schedules.isNotEmpty
        ? diary.copyWith(
            scheduleSnapshots: schedules.map(_createScheduleSnapshot).toList(),
            updatedAt: DateTime.now(),
          )
        : diary.copyWith(updatedAt: DateTime.now());
    
    await _db.update('diaries', updatedDiary.toMap(), where: 'id = ?', whereArgs: [diary.id]);
    await loadDiaries();
  }

  // 9. 删除日记
  Future<void> deleteDiary(String id) async {
    await _db.delete('diaries', where: 'id = ?', whereArgs: [id]);
    await loadDiaries();
  }

  // 私有辅助方法：创建日程快照
  Map<String, dynamic> _createScheduleSnapshot(Schedule s) => {
    'id': s.id,
    'title': s.title,
    'time': TimeOfDay.fromDateTime(s.dateTime).format(context), // 需要 context，改为静态方法
    'typeIcon': s.typeIcon,
    'location': s.location,
  };
}
```

**注意**：`_createScheduleSnapshot` 中的 `TimeOfDay.fromDateTime(s.dateTime).format(context)` 需要 `context`，建议改为：

```dart
// 改为静态方法（不需要 context）
Map<String, dynamic> _createScheduleSnapshot(Schedule s) => {
  'id': s.id,
  'title': s.title,
  'time': '${s.dateTime.hour.toString().padLeft(2, '0')}:${s.dateTime.minute.toString().padLeft(2, '0')}',
  'typeIcon': s.typeIcon,
  'location': s.location,
};
```

---

## 六、UI 架构设计

### 6.1 界面清单

| 界面 | 文件 | 功能 | 模式 |
|------|------|------|------|
| 日记列表页 | `lib/screens/diary_screen.dart` | 显示所有日记，按月份分组 | - |
| 日记编辑页 | `lib/screens/diary_edit_screen.dart` | 新建/编辑/查看日记 | 根据参数决定 |

### 6.2 界面1：日记列表页（DiaryScreen）

**文件**: `lib/screens/diary_screen.dart`

**布局**：
```
AppBar:
  - 标题："日记"
  - 右侧："+" 按钮（新建日记）

Body:
  - 月份选择器（显示当前月份，可切换）
  - 日记列表（按日期分组）
    - 每个日记卡片：
      - 日期（左侧，大字体）
      - 芊芊状态图标（😊 / 😐 / 😣）
      - 关联日程数量标签
      - 内容预览（2行）
      - 进步点/需加强点预览（如有）
```

**交互**：
- 点击 "+" → 跳转新建日记页
- 点击日记卡片 → 跳转日记详情页（只读模式）
- 长按日记卡片 → 显示"编辑"/"删除"菜单

**关键代码框架**：

```dart
class DiaryScreen extends StatefulWidget {
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _selectedMonth = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadDiaries();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('日记'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DiaryEditScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<DiaryProvider>(
        builder: (ctx, provider, _) {
          final monthDiaries = provider.getDiariesByMonth(_selectedMonth);
          
          if (monthDiaries.isEmpty) {
            return _buildEmptyView();
          }
          
          return Column(
            children: [
              _buildMonthSelector(),
              Expanded(child: _buildDiaryList(monthDiaries)),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildMonthSelector() { /* 月份选择器 */ }
  Widget _buildDiaryList(List<Diary> diaries) { /* 日记列表 */ }
  Widget _buildDiaryCard(Diary diary) { /* 日记卡片 */ }
  Widget _buildEmptyView() { /* 空状态 */ }
}
```

### 6.3 界面2：日记编辑页（DiaryEditScreen）

**文件**: `lib/screens/diary_edit_screen.dart`

**支持三种模式**：
1. **新建模式**：`DiaryEditScreen()`（无参数）
2. **详情模式**：`DiaryEditScreen(diary: diary, readOnly: true)`
3. **编辑模式**：`DiaryEditScreen(diary: diary, readOnly: false)`

**表单字段**：

| 字段 | 控件类型 | 默认值 | 必填 | 说明 |
|------|---------|--------|------|------|
| 日期 | DatePicker | 今天 | ✓ | 只能选择今天或过去 |
| 芊芊状态 | ChoiceChip | 未选中 | ✓ | good/normal/irritable |
| 关联日程 | Checkbox列表 | 自动加载并全选 | ✗ | 可取消勾选 |
| 进步点 | TextField (多行) | 空 | ✗ | 可选 |
| 需加强点 | TextField (多行) | 空 | ✗ | 可选 |
| 日记内容 | TextField (多行) | 空 | ✗ | 可选 |
| 图片 | 多选图片按钮 | 空 | ✗ | 最多5张 |
| 视频 | 多选视频按钮 | 空 | ✗ | 最多2个 |
| 音频 | 多选音频按钮 | 空 | ✗ | 最多3个 |

**交互流程**：
1. 进入页面 → 默认今天日期 → 自动加载当天日程并预选所有
2. 用户选择日期 → 重新加载该日日程并预选所有
3. 用户填写表单 → 芊芊状态必须选择（否则保存按钮禁用）
4. 点击"保存" → 验证必填项 → 存入数据库 → 返回列表页

**关键代码框架**：

```dart
class DiaryEditScreen extends StatefulWidget {
  final Diary? diary;
  final bool readOnly;
  
  const DiaryEditScreen({this.diary, this.readOnly = false});
  
  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  late DateTime _selectedDate;
  DiaryStatus? _selectedStatus;
  List<Map<String, dynamic>> _scheduleSnapshots = [];
  Set<String> _selectedScheduleIds = {};
  final _contentCtrl = TextEditingController();
  final _progressCtrl = TextEditingController();
  final _improvementCtrl = TextEditingController();
  final _imagePaths = <String>[];
  final _videoPaths = <String>[];
  final _audioPaths = <String>[];
  
  @override
  void initState() {
    super.initState();
    
    if (widget.diary != null) {
      // 编辑/详情模式：从 diary 对象初始化
      _selectedDate = widget.diary!.diaryDate;
      _selectedStatus = widget.diary!.qianqianStatus;
      _scheduleSnapshots = widget.diary!.scheduleSnapshots;
      _selectedScheduleIds = _scheduleSnapshots.map((s) => s['id'] as String).toSet();
      _contentCtrl.text = widget.diary!.content ?? '';
      _progressCtrl.text = widget.diary!.progressPoints ?? '';
      _improvementCtrl.text = widget.diary!.improvementPoints ?? '';
      _imagePaths.addAll(widget.diary!.imagePaths);
      _videoPaths.addAll(widget.diary!.videoPaths);
      _audioPaths.addAll(widget.diary!.audioPaths);
    } else {
      // 新建模式：默认今天
      _selectedDate = DateTime.now();
      _preloadSchedules();
    }
  }
  
  // 预填日程快照
  Future<void> _preloadSchedules() async {
    final scheduleProvider = context.read<ScheduleProvider>();
    final schedules = scheduleProvider.getSchedulesForDay(_selectedDate);
    
    setState(() {
      _scheduleSnapshots = schedules.map(_createScheduleSnapshot).toList();
      _selectedScheduleIds = schedules.map((s) => s.id).toSet();
    });
  }
  
  // 日期选择器（只能选今天或过去）
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(), // 关键：限制不能超过今天
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _preloadSchedules();
    }
  }
  
  // 保存日记
  Future<void> _saveDiary() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请选择芊芊状态')),
      );
      return;
    }
    
    final provider = context.read<DiaryProvider>();
    final id = widget.diary?.id ?? const Uuid().v4();
    
    // 过滤出选中的日程快照
    final selectedSnapshots = _scheduleSnapshots
        .where((s) => _selectedScheduleIds.contains(s['id']))
        .toList();
    
    final diary = Diary(
      id: id,
      title: null, // 可选，可以从内容自动生成
      content: _contentCtrl.text.trim(),
      diaryDate: _selectedDate,
      qianqianStatus: _selectedStatus!,
      scheduleSnapshots: selectedSnapshots,
      progressPoints: _progressCtrl.text.trim(),
      improvementPoints: _improvementCtrl.text.trim(),
      imagePaths: _imagePaths,
      videoPaths: _videoPaths,
      audioPaths: _audioPaths,
    );
    
    if (widget.diary == null) {
      // 新建
      final schedules = context.read<ScheduleProvider>().getSchedulesForDay(_selectedDate);
      await provider.addDiary(diary, schedules);
    } else {
      // 更新
      await provider.updateDiary(diary);
    }
    
    if (mounted) Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diary == null ? '新建日记' : (widget.readOnly ? '日记详情' : '编辑日记')),
        actions: [
          if (widget.readOnly)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => DiaryEditScreen(diary: widget.diary, readOnly: false)),
              ),
            ),
          if (!widget.readOnly)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveDiary,
            ),
        ],
      ),
      body: widget.readOnly ? _buildReadOnlyView() : _buildEditView(),
    );
  }
  
  Widget _buildReadOnlyView() { /* 只读模式 */ }
  Widget _buildEditView() { /* 编辑模式 */ }
  Widget _buildStatusSelector() { /* 芊芊状态选择器 */ }
  Widget _buildScheduleList() { /* 关联日程列表 */ }
  Widget _buildMediaPicker() { /* 多媒体选择器 */ }
}
```

---

## 七、底部导航修改

### 7.1 修改 home_screen.dart

**文件**: `lib/screens/home_screen.dart`

**修改点1**：底部导航标签（第463行）

```dart
BottomNavigationBarItem(icon: Icon(Icons.book), label: '日记'),  // 原来是"备忘"
```

**修改点2**：导航跳转（第480-485行）

```dart
case 3:
  Navigator.push(context, MaterialPageRoute(builder: (_) => DiaryScreen()));
  break;
```

---

## 八、Provider 注册

### 8.1 修改 main.dart

**文件**: `lib/main.dart`

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => CheckInProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => MedicalRecordProvider()),
        ChangeNotifierProvider(create: (_) => GrowthLogProvider()),
        // +++ 新增：DiaryProvider +++
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 九、实施顺序和工时预估

| 阶段 | 任务 | 预估工时 | 负责人 |
|------|------|----------|--------|
| **阶段1** | 删除备忘功能 | 1-2小时 | Developer |
| 1.1 | 删除 Memo 类（models.dart） | 0.5小时 | Developer |
| 1.2 | 删除 memo_provider.dart 和 memo_screen.dart | 0.5小时 | Developer |
| 1.3 | 修改 database_helper.dart（删除 memos 表） | 0.5小时 | Developer |
| 1.4 | 修改 home_screen.dart（底部导航） | 0.5小时 | Developer |
| **阶段2** | 新增日记功能 - 数据层 | 2-3小时 | Developer |
| 2.1 | 添加 Diary 和 DiaryStatus 到 models.dart | 0.5小时 | Developer |
| 2.2 | 创建 diary_provider.dart | 1小时 | Developer |
| 2.3 | 修改 database_helper.dart（添加 diaries 表） | 0.5小时 | Developer |
| 2.4 | 数据库迁移测试 | 0.5小时 | Developer |
| **阶段3** | 新增日记功能 - UI层 | 3-4小时 | Developer |
| 3.1 | 创建 diary_screen.dart（列表页） | 1.5小时 | Developer |
| 3.2 | 创建 diary_edit_screen.dart（编辑页） | 1.5小时 | Developer |
| 3.3 | 注册 DiaryProvider（main.dart） | 0.5小时 | Developer |
| **阶段4** | 集成和测试 | 2-3小时 | Tester |
| 4.1 | Provider 注册验证 | 0.5小时 | Tester |
| 4.2 | 导航集成测试 | 0.5小时 | Tester |
| 4.3 | 功能完整测试 | 1小时 | Tester |
| 4.4 | Bug修复 | 1小时 | Developer |
| **总计** | | **8-12小时** | |

---

## 十、测试计划

### 10.1 单元测试

| 测试对象 | 测试用例 | 预期结果 |
|----------|----------|----------|
| Diary.fromMap() | 传入合法 Map | 返回正确的 Diary 对象 |
| Diary.fromMap() | 传入非法 status | 返回默认 status (normal) |
| Diary.toMap() | 正常调用 | 返回正确的 Map |
| Diary.copyWith() | 修改部分字段 | 只有指定字段被修改 |
| DiaryStatus | 访问 label 和 color 属性 | 返回正确的值 |

### 10.2 Widget 测试

| 测试对象 | 测试用例 | 预期结果 |
|----------|----------|----------|
| DiaryEditScreen | 新建模式 | 日期默认为今天，状态未选中 |
| DiaryEditScreen | 详情模式 | 所有字段只读 |
| DiaryEditScreen | 编辑模式 | 所有字段可编辑 |
| _StatusSelector | 选择状态 | 选中的 Chip 高亮 |
| _ScheduleCheckboxList | 预填日程 | 所有日程被选中 |

### 10.3 集成测试

| 测试流程 | 测试步骤 | 预期结果 |
|----------|----------|----------|
| 完整新建流程 | 1. 点击"+" 2. 选择状态 3. 填写内容 4. 点击保存 | 日记出现在列表中 |
| 数据库迁移 | 1. 安装旧版本（v2） 2. 升级到新版本（v3） | memos 数据迁移到 diaries |
| 日期限制 | 1. 新建日记 2. 尝试选择未来日期 | 无法选择未来日期 |

---

## 十一、风险点和注意事项

### 11.1 数据库迁移风险

**风险**：用户可能有重要的备忘数据

**缓解措施**：
1. 采用方案B（迁移数据而非直接删除）
2. 在更新说明中告知用户"备忘功能已移除，数据已迁移到日记"
3. 提供"导出日记"功能（未来优化）

### 11.2 日程关联的准确性

**风险**：如果日程后续被删除，`scheduleSnapshots` 成为唯一信息来源

**缓解措施**：
1. `scheduleSnapshots` 缓存了关键信息（title, time, typeIcon, location）
2. 即使原日程被删除，日记中仍能显示日程信息
3. 未来可以支持"点击快照查看详情"（需要查询数据库）

### 11.3 日期选择限制

**风险**：用户可能想补记过去的日记，但忘记了具体哪一天

**缓解措施**：
1. 提供"选择月份"的快速入口
2. 在列表页显示月份选择器
3. 支持按月份快速跳转

### 11.4 多媒体文件存储

**风险**：图片/视频/音频文件可能占用大量存储空间

**缓解措施**：
1. 限制数量（图片5，视频2，音频3）
2. 未来可以集成云存储（可选）
3. 提供"清理多媒体文件"功能（未来优化）

---

## 十二、交付物清单

1. ✅ 更新的 `lib/models/models.dart`（删除 Memo，添加 Diary 和 DiaryStatus）
2. ✅ 删除 `lib/providers/memo_provider.dart`
3. ✅ 删除 `lib/screens/memo_screen.dart`
4. ✅ 新的 `lib/providers/diary_provider.dart`
5. ✅ 新的 `lib/screens/diary_screen.dart`
6. ✅ 新的 `lib/screens/diary_edit_screen.dart`
7. ✅ 更新的 `lib/services/database_helper.dart`
8. ✅ 更新的 `lib/screens/home_screen.dart`
9. ✅ 更新的 `lib/main.dart`（注册 DiaryProvider）
10. ✅ 测试报告
11. ✅ 技术设计文档（本文档）

---

## 十三、附录：scheduleSnapshots 数据结构

### 13.1 示例数据

```json
[
  {
    "id": "schedule_123",
    "title": "钢琴课",
    "time": "10:00",
    "typeIcon": "💬",
    "location": "音乐学校"
  },
  {
    "id": "schedule_456",
    "title": "足球训练",
    "time": "14:00",
    "typeIcon": "⚽",
    "location": null
  }
]
```

### 13.2 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 日程ID（用于未来可能的关联查询） |
| title | String | 日程标题 |
| time | String | 时间（格式："HH:mm"） |
| typeIcon | String | 日程类型图标（emoji） |
| location | String? | 地点（可选） |

---

**文档结束**

---

## 变更记录

| 版本 | 日期 | 修改内容 | 作者 |
|------|------|----------|------|
| v1.0 | 2026-04-24 | 初始版本 | Analyst |
| v2.0 | 2026-04-24 | 根据 PM 确认更新 | Analyst |
| v3.0 | 2026-04-24 | 根据 Architect 评审优化 | Analyst |

---

**联系方式**
- Analyst Agent: 需求分析、技术设计
- PM Agent: 产品需求、优先级管理
- Architect Agent: 技术方案评审、优化建议
- Developer Agent: 代码实现
- Tester Agent: 测试验证
- Reviewer Agent: 代码审查
- Gatekeeper Agent: 质量把关
