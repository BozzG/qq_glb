import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:qianqian_growth_logbook/models/models.dart';
import 'package:qianqian_growth_logbook/providers/medical_provider.dart';
import 'package:qianqian_growth_logbook/services/database_helper.dart';

void main() {
  // 初始化内存数据库用于测试
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    // 启用测试模式，使用内存数据库
    DatabaseHelper.isTestMode = true;
  });

  group('MedicalProvider Tests', () {
    late MedicalProvider provider;

    setUp(() async {
      DatabaseHelper().resetDatabase();
      provider = MedicalProvider();
      await provider.loadRecords();
    });

    tearDown(() async {
      await DatabaseHelper().recreateTables();
    });

    test('添加医疗记录', () async {
      final record = MedicalRecord(
        id: 'med-1',
        hospitalName: '北京儿童医院',
        doctorName: '张医生',
        diagnosis: '感冒',
        medication: '退烧药',
        visitDate: DateTime(2026, 4, 23),
      );

      await provider.addRecord(record);
      
      expect(provider.records.length, 1);
      expect(provider.records.first.hospitalName, '北京儿童医院');
      expect(provider.records.first.diagnosis, '感冒');
    });

    test('更新医疗记录', () async {
      final record = MedicalRecord(
        id: 'med-2',
        hospitalName: '原始医院',
        doctorName: '原始医生',
        diagnosis: '原始诊断',
        visitDate: DateTime(2026, 4, 23),
      );

      await provider.addRecord(record);
      
      final updatedRecord = MedicalRecord(
        id: 'med-2',
        hospitalName: '更新医院',
        doctorName: '更新医生',
        diagnosis: '更新诊断',
        visitDate: DateTime(2026, 4, 23),
      );

      await provider.updateRecord(updatedRecord);
      
      final recordFromProvider = provider.records.firstWhere((r) => r.id == 'med-2');
      expect(recordFromProvider.hospitalName, '更新医院');
      expect(recordFromProvider.diagnosis, '更新诊断');
    });

    test('删除医疗记录', () async {
      final record = MedicalRecord(
        id: 'med-3',
        hospitalName: '待删除医院',
        doctorName: '医生',
        diagnosis: '诊断',
        visitDate: DateTime(2026, 4, 23),
      );

      await provider.addRecord(record);
      expect(provider.records.length, 1);

      await provider.deleteRecord('med-3');
      expect(provider.records.length, 0);
    });
  });
}
