import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:qianqian_growth_logbook/services/database_helper.dart';

void main() {
  // 初始化内存数据库用于测试
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    // 启用测试模式，使用内存数据库
    DatabaseHelper.isTestMode = true;
  });

  group('Database Migration Tests (v2 → v3)', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      dbHelper = DatabaseHelper();
    });

    tearDown(() async {
      await dbHelper.recreateTables();
    });

    test('TC-M001: v2 → v3 迁移创建 diaries 表', () async {
      // 创建一个 v2 版本的数据库（不含 diaries 表）
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onCreate: (db, version) async {
          // 创建 v2 版本的表（不含 diaries）
          await db.execute('''
            CREATE TABLE schedules (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              location TEXT,
              dateTime TEXT NOT NULL,
              endTime TEXT,
              repeatType TEXT,
              repeatDays TEXT,
              scheduleType TEXT,
              isCourse INTEGER DEFAULT 0,
              courseId TEXT,
              memo TEXT,
              parentId TEXT,
              repeatTemplateId TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT
            )
          ''');
          
          await db.execute('''
            CREATE TABLE memos (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              content TEXT,
              reminderTime TEXT,
              isCompleted INTEGER DEFAULT 0,
              createdAt TEXT NOT NULL,
              updatedAt TEXT
            )
          ''');
          
          // 其他 v2 表...
          await db.execute('''
            CREATE TABLE check_ins (
              id TEXT PRIMARY KEY,
              scheduleId TEXT NOT NULL,
              checkInTime TEXT NOT NULL,
              notes TEXT
            )
          ''');
          
          await db.execute('''
            CREATE TABLE courses (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              courseType TEXT,
              totalHours REAL NOT NULL DEFAULT 0,
              usedHours REAL NOT NULL DEFAULT 0,
              unitName TEXT DEFAULT '课时',
              color TEXT,
              iconData TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT
            )
          ''');
          
          await db.execute('''
            CREATE TABLE app_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          
          await db.insert('app_settings', {'key': 'theme_mode', 'value': 'light'});
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // 不应该在这个阶段被调用
        },
      );

      // 验证 memos 表存在
      final tables = await db.query('sqlite_master', 
        where: 'type = ? AND name = ?', 
        whereArgs: ['table', 'memos']);
      expect(tables.length, 1);

      // 验证 diaries 表不存在
      final diariesTables = await db.query('sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'diaries']);
      expect(diariesTables.length, 0);

      await db.close();
    });

    test('TC-M002: 验证 diaries 表结构', () async {
      // 使用 v3 数据库
      DatabaseHelper().resetDatabase();
      final db = await DatabaseHelper().database;

      // 验证 diaries 表存在
      final tables = await db.query('sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'diaries']);
      expect(tables.length, 1);

      // 验证表结构
      final tableInfo = await db.rawQuery('PRAGMA table_info(diaries)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toList();
      
      expect(columnNames, contains('id'));
      expect(columnNames, contains('title'));
      expect(columnNames, contains('content'));
      expect(columnNames, contains('diaryDate'));
      expect(columnNames, contains('qianqianStatus'));
      expect(columnNames, contains('scheduleIds'));
      expect(columnNames, contains('scheduleSnapshots'));
      expect(columnNames, contains('progressPoints'));
      expect(columnNames, contains('improvementPoints'));
      expect(columnNames, contains('imagePaths'));
      expect(columnNames, contains('videoPaths'));
      expect(columnNames, contains('createdAt'));
      expect(columnNames, contains('updatedAt'));
    });

    test('TC-M003: 向 diaries 表插入和读取数据', () async {
      DatabaseHelper().resetDatabase();
      final db = await DatabaseHelper().database;

      // 插入测试数据
      final testData = {
        'id': 'test-diary-1',
        'title': '测试日记',
        'content': '测试内容',
        'diaryDate': '2026-04-24T00:00:00.000',
        'qianqianStatus': 'good',
        'scheduleIds': '["s1","s2"]',
        'scheduleSnapshots': '[{"id":"s1","title":"测试"}]',
        'progressPoints': '进步点',
        'improvementPoints': '改进点',
        'imagePaths': '["/img1.jpg"]',
        'videoPaths': '[]',
        'createdAt': '2026-04-24T09:00:00.000',
        'updatedAt': '2026-04-24T09:30:00.000',
      };

      await db.insert('diaries', testData);

      // 读取数据
      final results = await db.query('diaries');
      expect(results.length, 1);
      expect(results.first['id'], 'test-diary-1');
      expect(results.first['title'], '测试日记');
      expect(results.first['content'], '测试内容');
      expect(results.first['qianqianStatus'], 'good');
    });

    test('TC-M004: memos 表在 v3 中不存在', () async {
      DatabaseHelper().resetDatabase();
      final db = await DatabaseHelper().database;

      // 验证 memos 表不存在
      final tables = await db.query('sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'memos']);
      expect(tables.length, 0);
    });

    test('TC-M005: 数据库版本是 4', () async {
      DatabaseHelper().resetDatabase();
      final db = await DatabaseHelper().database;

      final version = await db.getVersion();
      expect(version, 4);
    });

    test('TC-M006: v4 schedules 表含 courseHours 列且默认 1', () async {
      DatabaseHelper().resetDatabase();
      final db = await DatabaseHelper().database;

      final tableInfo = await db.rawQuery('PRAGMA table_info(schedules)');
      final columnNames =
          tableInfo.map((col) => col['name'] as String).toList();
      expect(columnNames, contains('courseHours'));

      // 插入一条不带 courseHours 的行，应取默认值 1
      await db.insert('schedules', {
        'id': 'm006-1',
        'title': '默认课时',
        'dateTime': '2026-01-01T10:00:00.000',
        'repeatType': 'none',
        'repeatDays': '[]',
        'scheduleType': 'general',
        'isCourse': 1,
        'courseId': 'c1',
        'createdAt': '2026-01-01T09:00:00.000',
        'updatedAt': '2026-01-01T09:00:00.000',
      });
      final rows =
          await db.query('schedules', where: 'id = ?', whereArgs: ['m006-1']);
      expect((rows.first['courseHours'] as num).toDouble(),
          closeTo(1.0, 0.0001));
    });
  });
}
