import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
      version: 1,
      onCreate: _onCreate,
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
}
