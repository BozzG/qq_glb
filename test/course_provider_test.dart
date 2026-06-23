import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:qianqian_growth_logbook/models/models.dart';
import 'package:qianqian_growth_logbook/providers/course_provider.dart';
import 'package:qianqian_growth_logbook/services/database_helper.dart';

void main() {
  // 初始化内存数据库用于测试
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    // 启用测试模式，使用内存数据库
    DatabaseHelper.isTestMode = true;
  });

  group('CourseProvider Tests', () {
    late CourseProvider provider;

    setUp(() async {
      // 重置数据库实例，确保使用内存数据库
      DatabaseHelper().resetDatabase();
      provider = CourseProvider();
      await provider.loadCourses();
    });

    tearDown(() async {
      // 清理并重新创建表
      await DatabaseHelper().recreateTables();
    });

    test('TC-020: 初始状态', () {
      expect(provider.courses, isEmpty);
      expect(provider.consumptions, isEmpty);
      expect(provider.isLoading, false);
    });

    test('TC-021: 添加课程', () async {
      final course = Course(
        id: 'course-1',
        name: '网球课',
        courseType: CourseType.sports,
        totalHours: 20.0,
        usedHours: 0.0,
      );

      await provider.addCourse(course);
      
      expect(provider.courses.length, 1);
      expect(provider.courses.first.id, 'course-1');
      expect(provider.courses.first.name, '网球课');
      expect(provider.courses.first.totalHours, 20.0);
      expect(provider.courses.first.usedHours, 0.0);
    });

    test('TC-021: 添加课程 - 验证 remainingHours 和 usagePercent', () async {
      final course = Course(
        id: 'course-2',
        name: '英语课',
        totalHours: 30.0,
        usedHours: 10.0,
      );

      await provider.addCourse(course);
      
      final addedCourse = provider.courses.firstWhere((c) => c.id == 'course-2');
      expect(addedCourse.remainingHours, 20.0);
      expect(addedCourse.usagePercent, closeTo(0.333, 0.001));
    });

    test('TC-022: 更新课程', () async {
      final course = Course(
        id: 'course-3',
        name: '原始名称',
        totalHours: 10.0,
        usedHours: 0.0,
      );

      await provider.addCourse(course);
      
      final updatedCourse = Course(
        id: 'course-3',
        name: '更新名称',
        totalHours: 15.0,
        usedHours: 5.0,
      );

      await provider.updateCourse(updatedCourse);
      
      final courseFromProvider = provider.courses.firstWhere((c) => c.id == 'course-3');
      expect(courseFromProvider.name, '更新名称');
      expect(courseFromProvider.totalHours, 15.0);
      expect(courseFromProvider.usedHours, 5.0);
    });

    test('TC-023: 删除课程', () async {
      final course = Course(
        id: 'course-4',
        name: '待删除课程',
        totalHours: 10.0,
      );

      await provider.addCourse(course);
      expect(provider.courses.length, 1);

      await provider.deleteCourse('course-4');
      expect(provider.courses.length, 0);
    });

    test('TC-023: 删除课程时同时删除消耗记录', () async {
      final course = Course(
        id: 'course-5',
        name: '课程 with 消耗',
        totalHours: 10.0,
      );

      await provider.addCourse(course);
      
      // 手动添加消耗记录
      final consumption = CourseConsumption(
        id: 'cons-1',
        courseId: 'course-5',
        consumedAmount: 2.0,
        consumptionType: ConsumptionType.manual,
      );
      
      final db = await DatabaseHelper().database;
      await db.insert('course_consumptions', consumption.toMap());
      await provider.loadCourses();
      
      expect(provider.consumptions.length, 1);
      
      // 删除课程
      await provider.deleteCourse('course-5');
      
      // 重新加载以验证消耗记录也被删除
      await provider.loadCourses();
      expect(provider.courses.length, 0);
      
      // 检查消耗记录是否被删除（通过查询数据库）
      final remainingConsumptions = await db.query('course_consumptions', 
        where: 'courseId = ?', whereArgs: ['course-5']);
      expect(remainingConsumptions.length, 0);
    });

    test('TC-024: 调整课时 - 增加', () async {
      final course = Course(
        id: 'course-6',
        name: '课时调整测试',
        totalHours: 10.0,
        usedHours: 2.0,
      );

      await provider.addCourse(course);
      
      // 增加 3 课时
      await provider.adjustHours('course-6', 3.0, note: '增加3课时');
      
      final updatedCourse = provider.courses.firstWhere((c) => c.id == 'course-6');
      expect(updatedCourse.usedHours, 5.0); // 2.0 + 3.0
      
      // 检查消耗记录
      expect(provider.consumptions.length, 1);
      expect(provider.consumptions.first.consumedAmount, 3.0);
      expect(provider.consumptions.first.note, '增加3课时');
    });

    test('TC-024: 调整课时 - 扣减', () async {
      final course = Course(
        id: 'course-7',
        name: '课时扣减测试',
        totalHours: 10.0,
        usedHours: 5.0,
      );

      await provider.addCourse(course);
      
      // 扣减 2 课时
      await provider.adjustHours('course-7', -2.0, note: '扣减2课时');
      
      final updatedCourse = provider.courses.firstWhere((c) => c.id == 'course-7');
      expect(updatedCourse.usedHours, 3.0); // 5.0 - 2.0
    });

    test('获取某课程的消耗记录', () async {
      final course = Course(
        id: 'course-8',
        name: '消耗记录测试',
        totalHours: 10.0,
      );

      await provider.addCourse(course);
      
      // 添加两条消耗记录
      final db = await DatabaseHelper().database;
      await db.insert('course_consumptions', CourseConsumption(
        id: 'cons-1',
        courseId: 'course-8',
        consumedAmount: 1.0,
        consumptionType: ConsumptionType.auto,
      ).toMap());
      
      await db.insert('course_consumptions', CourseConsumption(
        id: 'cons-2',
        courseId: 'course-8',
        consumedAmount: 2.0,
        consumptionType: ConsumptionType.manual,
        note: '手动调整',
      ).toMap());
      
      await provider.loadCourses();
      
      final consumptions = provider.getConsumptionsForCourse('course-8');
      expect(consumptions.length, 2);
    });
  });
}
