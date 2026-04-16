import 'dart:io';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  /// 初始化数据库工厂（桌面平台需要 sqflite_common_ffi）
  static void initDatabaseFactory() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 桌面平台使用应用数据目录
      final appSupportDir = await getApplicationSupportDirectory();
      dbPath = join(appSupportDir.path, 'qianqian_growth.db');
    } else {
      // 移动平台使用默认数据库路径
      dbPath = join(await getDatabasesPath(), 'qianqian_growth.db');
    }
    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // 日程表
    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        location TEXT,
        dateTime TEXT NOT NULL,
        endTime TEXT,
        repeatType TEXT, -- none, daily, weekly, custom
        repeatDays TEXT, -- JSON array: [1,3,5] for Mon, Wed, Fri
        scheduleType TEXT, -- nursery, sports, language, medical, school, general
        isCourse INTEGER DEFAULT 0,
        courseId TEXT,
        memo TEXT,
        parentId TEXT,
        repeatTemplateId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    
    // 打卡记录表
    await db.execute('''
      CREATE TABLE check_ins (
        id TEXT PRIMARY KEY,
        scheduleId TEXT NOT NULL,
        checkInTime TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (scheduleId) REFERENCES schedules(id)
      )
    ''');
    
    // 课程表
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        courseType TEXT, -- sports, language, other
        totalHours REAL NOT NULL DEFAULT 0,
        usedHours REAL NOT NULL DEFAULT 0,
        unitName TEXT DEFAULT '课时',
        color TEXT,
        iconData TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    
    // 课时消耗记录表
    await db.execute('''
      CREATE TABLE course_consumptions (
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        consumedAmount REAL NOT NULL,
        consumptionType TEXT, -- auto, manual
        relatedCheckInId TEXT,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (courseId) REFERENCES courses(id)
      )
    ''');
    
    // 备忘录表（独立备忘，不关联日程）
    await db.execute('''
      CREATE TABLE memos (
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        reminderTime TEXT,
        isCompleted INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    
    // 医疗记录表
    await db.execute('''
      CREATE TABLE medical_records (
        id TEXT PRIMARY KEY,
        scheduleId TEXT,
        hospitalName TEXT,
        doctorName TEXT,
        diagnosis TEXT,
        medication TEXT,
        reportImagePaths TEXT, -- JSON array of image paths
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
        imagePaths TEXT,     -- JSON array
        videoPaths TEXT,     -- JSON array
        audioPaths TEXT,     -- JSON array
        mood TEXT,           -- happy, sad, excited, etc.
        tags TEXT,           -- JSON array
        scheduleId TEXT,     -- 关联的日程
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    
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
  
  /// 数据库版本升级迁移
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: 添加 parentId 和 repeatTemplateId 列，用于支持重复日程的独立实例模式
      await db.execute('ALTER TABLE schedules ADD COLUMN parentId TEXT');
      await db.execute('ALTER TABLE schedules ADD COLUMN repeatTemplateId TEXT');
      
      // 将现有的重复日程按规则拆分为独立实例
      final rows = await db.query('schedules', where: "repeatType != 'none'", orderBy: 'dateTime ASC');
      for (final row in rows) {
        final id = row['id'] as String;
        final repeatTypeStr = row['repeatType'] as String? ?? 'none';
        final repeatDaysJson = row['repeatDays'] as String? ?? '[]';
        final repeatDays = (jsonDecode(repeatDaysJson) as List).cast<int>();
        
        if (repeatTypeStr == 'none' || (repeatTypeStr == 'custom' && repeatDays.isEmpty)) continue;
        
        // 生成模板ID
        final templateId = const Uuid().v4();
        
        // 更新原始日程为组长
        await db.update(
          'schedules',
          {'repeatTemplateId': templateId},
          where: 'id = ?',
          whereArgs: [id],
        );
        
        final baseDateTime = DateTime.parse(row['dateTime'] as String);
        final now = DateTime.now();
        
        // 生成当前月+下一个月的独立日程实例（从原始日期到下月末）
        final endMonth = now.month == 12 ? 1 : now.month + 1;
        final endYear = now.month == 12 ? now.year + 1 : now.year;
        final endDate = DateTime(endYear, endMonth + 1, 0); // 下个月最后一天
        
        List<Map<String, dynamic>> instances = [];
        DateTime current = DateTime(baseDateTime.year, baseDateTime.month, baseDateTime.day);
        
        while (!current.isAfter(endDate)) {
          // 跳过自身（第一个实例就是原始记录）
          if (isSameDay(current, baseDateTime)) {
            current = current.add(Duration(days: 1));
            continue;
          }
          
          bool shouldCreate = false;
          if (repeatTypeStr == 'daily') {
            shouldCreate = true;
          } else if (repeatTypeStr == 'weekly' || repeatTypeStr == 'custom') {
            shouldCreate = repeatDays.contains(current.weekday);
          }
          
          if (shouldCreate) {
            final instanceId = const Uuid().v4();
            final instanceDateTime = DateTime(
              current.year, current.month, current.day,
              baseDateTime.hour, baseDateTime.minute,
            );
            instances.add({
              'id': instanceId,
              'title': row['title'],
              'description': row['description'],
              'location': row['location'],
              'dateTime': instanceDateTime.toIso8601String(),
              'endTime': row['endTime'],
              'repeatType': row['repeatType'],
              'repeatDays': row['repeatDays'],
              'scheduleType': row['scheduleType'],
              'isCourse': row['isCourse'],
              'courseId': row['courseId'],
              'memo': row['memo'],
              'parentId': id,           // 组长是原始日程
              'repeatTemplateId': templateId,
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
            });
          }
          
          current = current.add(Duration(days: 1));
        }
        
        for (final inst in instances) {
          await db.insert('schedules', inst);
        }
      }
    }
  }
  
  // 通用CRUD操作
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object>? whereArgs, String? orderBy, int? limit}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }
  
  Future<int> update(String table, Map<String, dynamic> data, {required String where, List<Object>? whereArgs}) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }
  
  Future<int> delete(String table, {required String where, List<Object>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// 重置所有数据（清空所有表并重新插入默认设置）
  Future<void> resetAll() async {
    final db = await database;
    await db.transaction((txn) async {
      final tables = [
        'schedules', 'check_ins', 'courses', 'course_consumptions',
        'memos', 'medical_records', 'growth_logs', 'app_settings',
      ];
      for (final table in tables) {
        await txn.delete(table);
      }
      await txn.insert('app_settings', {'key': 'theme_mode', 'value': 'light'});
      await txn.insert('app_settings', {'key': 'cartoon_theme', 'value': 'pink'});
      await txn.insert('app_settings', {'key': 'reminder_minutes', 'value': '15'});
    });
  }

  /// 判断两个DateTime是否是同一天
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
