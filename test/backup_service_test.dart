import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:qianqian_growth_logbook/services/database_helper.dart';
import 'package:qianqian_growth_logbook/services/backup_service.dart';

/// P0-1 数据备份与恢复 · 服务层往返测试
///
/// 不依赖 file_picker / share_plus 等平台插件，直接验证：
/// · 整库导出 → JSON 序列化 → 解析 → 整库导入 的数据无损往返
/// · parseBackup 的格式与来源校验
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseHelper.isTestMode = true;
  });

  group('BackupService 往返与校验', () {
    late DatabaseHelper db;
    late BackupService backup;

    setUp(() async {
      db = DatabaseHelper();
      db.resetDatabase();
      await db.recreateTables();
      backup = BackupService(db: db);
    });

    tearDown(() async {
      await db.recreateTables();
    });

    Future<void> seed() async {
      final now = DateTime.now().toIso8601String();
      await db.insert('schedules', {
        'id': 'bk-s1',
        'title': '钢琴课',
        'dateTime': now,
        'repeatType': 'none',
        'repeatDays': '[]',
        'scheduleType': 'general',
        'isCourse': 0,
        'createdAt': now,
      });
      await db.insert('check_ins', {
        'id': 'bk-c1',
        'scheduleId': 'bk-s1',
        'checkInTime': now,
      });
      await db.insert('courses', {
        'id': 'bk-course1',
        'name': '钢琴',
        'totalHours': 20,
        'usedHours': 1,
        'createdAt': now,
      });
      await db.insert('diaries', {
        'id': 'bk-d1',
        'content': '今天很开心',
        'diaryDate': now,
        'qianqianStatus': 'good',
        'createdAt': now,
      });
    }

    test('TC-BK-01: 导出 payload 包含全部表与正确行数', () async {
      await seed();
      final payload = await backup.buildBackupPayload();

      expect(payload['app'], BackupService.appTag);
      expect(payload['backupVersion'], BackupService.backupVersion);
      final tables = payload['tables'] as Map;
      expect(tables.keys, containsAll(DatabaseHelper.allTables));
      expect((tables['schedules'] as List).length, 1);
      expect((tables['check_ins'] as List).length, 1);
      expect((tables['courses'] as List).length, 1);
      expect((tables['diaries'] as List).length, 1);
    });

    test('TC-BK-02: 导出→清空→导入 数据无损往返', () async {
      await seed();
      final payload = await backup.buildBackupPayload();
      final json = jsonEncode(payload);

      // 模拟换机：清空全部数据
      await db.resetAll();
      final afterReset = await db.exportAllTables();
      expect(afterReset['schedules'], isEmpty);
      expect(afterReset['check_ins'], isEmpty);
      // 从备份恢复
      final parsed = backup.parseBackup(json);
      final counts = await db.importAll(parsed);

      expect(counts['schedules'], 1);
      expect(counts['check_ins'], 1);
      expect(counts['courses'], 1);
      expect(counts['diaries'], 1);

      // 校验内容确实回填
      final restored = await db.exportAllTables();
      expect(restored['schedules']!.single['title'], '钢琴课');
      expect(restored['check_ins']!.single['scheduleId'], 'bk-s1');
      expect(restored['diaries']!.single['content'], '今天很开心');
    });

    test('TC-BK-03: 导入为整库覆盖，旧数据被清除', () async {
      // 先放一条"旧"数据
      final now = DateTime.now().toIso8601String();
      await db.insert('schedules', {
        'id': 'old-1',
        'title': '旧日程',
        'dateTime': now,
        'repeatType': 'none',
        'repeatDays': '[]',
        'scheduleType': 'general',
        'isCourse': 0,
        'createdAt': now,
      });
      // 备份仅含 bk-s1
      await db.recreateTables();
      await seed();
      final payload = await backup.buildBackupPayload();

      // 再次写入旧数据后恢复，旧数据应被清除
      await db.recreateTables();
      await db.insert('schedules', {
        'id': 'old-2',
        'title': '另一条旧日程',
        'dateTime': now,
        'repeatType': 'none',
        'repeatDays': '[]',
        'scheduleType': 'general',
        'isCourse': 0,
        'createdAt': now,
      });
      await db.importAll(backup.parseBackup(jsonEncode(payload)));

      final restored = await db.exportAllTables();
      final ids = restored['schedules']!.map((r) => r['id']).toList();
      expect(ids, ['bk-s1']);
      expect(ids, isNot(contains('old-2')));
    });

    test('TC-BK-04: parseBackup 拒绝非法 JSON', () {
      expect(() => backup.parseBackup('not a json'),
          throwsA(isA<FormatException>()));
    });

    test('TC-BK-05: parseBackup 拒绝缺少 tables 字段', () {
      expect(() => backup.parseBackup('{"app":"x"}'),
          throwsA(isA<FormatException>()));
    });

    test('TC-BK-06: parseBackup 拒绝其它应用的备份', () {
      final foreign = jsonEncode({'app': 'other_app', 'tables': {}});
      expect(() => backup.parseBackup(foreign),
          throwsA(isA<FormatException>()));
    });

    test('TC-BK-07: parseBackup 容忍缺失的表（按空列表处理）', () {
      final partial = jsonEncode({
        'app': BackupService.appTag,
        'tables': {
          'schedules': [
            {
              'id': 's',
              'title': 't',
              'dateTime': DateTime.now().toIso8601String(),
              'createdAt': DateTime.now().toIso8601String(),
            }
          ]
        }
      });
      final parsed = backup.parseBackup(partial);
      expect(parsed['schedules']!.length, 1);
      expect(parsed['diaries'], isEmpty);
      expect(parsed.keys, containsAll(DatabaseHelper.allTables));
    });
  });
}
