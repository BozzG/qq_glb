import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:qianqian_growth_logbook/models/models.dart';

void main() {
  group('Schedule Model Tests', () {
    final testDateTime = DateTime(2026, 4, 24, 10, 0);
    final testEndTime = DateTime(2026, 4, 24, 11, 0);
    final testCreatedAt = DateTime(2026, 4, 24, 9, 0);
    final testUpdatedAt = DateTime(2026, 4, 24, 9, 30);

    test('TC-001: 创建 Schedule 对象', () {
      final schedule = Schedule(
        id: 'test-id-1',
        title: '测试日程',
        description: '测试描述',
        location: '测试地点',
        dateTime: testDateTime,
        endTime: testEndTime,
        repeatType: RepeatType.daily,
        repeatDays: [1, 3, 5],
        scheduleType: ScheduleType.sports,
        isCourse: true,
        courseId: 'course-1',
        memo: '测试备注',
        parentId: null,
        repeatTemplateId: 'template-1',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(schedule.id, 'test-id-1');
      expect(schedule.title, '测试日程');
      expect(schedule.description, '测试描述');
      expect(schedule.location, '测试地点');
      expect(schedule.dateTime, testDateTime);
      expect(schedule.endTime, testEndTime);
      expect(schedule.repeatType, RepeatType.daily);
      expect(schedule.repeatDays, [1, 3, 5]);
      expect(schedule.scheduleType, ScheduleType.sports);
      expect(schedule.isCourse, true);
      expect(schedule.courseId, 'course-1');
      expect(schedule.memo, '测试备注');
      expect(schedule.parentId, null);
      expect(schedule.repeatTemplateId, 'template-1');
      expect(schedule.createdAt, testCreatedAt);
      expect(schedule.updatedAt, testUpdatedAt);
    });

    test('TC-001: 创建 Schedule 对象（默认值）', () {
      final schedule = Schedule(
        id: 'test-id-2',
        title: '测试日程2',
        dateTime: testDateTime,
      );

      expect(schedule.description, null);
      expect(schedule.location, null);
      expect(schedule.endTime, null);
      expect(schedule.repeatType, RepeatType.none);
      expect(schedule.repeatDays, []);
      expect(schedule.scheduleType, ScheduleType.general);
      expect(schedule.isCourse, false);
      expect(schedule.courseId, null);
      expect(schedule.memo, null);
      expect(schedule.parentId, null);
      expect(schedule.repeatTemplateId, null);
      expect(schedule.createdAt, isA<DateTime>());
      expect(schedule.updatedAt, isA<DateTime>());
    });

    test('TC-002: toMap() 转换', () {
      final schedule = Schedule(
        id: 'test-id-3',
        title: '测试日程3',
        description: '描述',
        location: '地点',
        dateTime: testDateTime,
        endTime: testEndTime,
        repeatType: RepeatType.weekly,
        repeatDays: [1, 2, 3],
        scheduleType: ScheduleType.language,
        isCourse: false,
        courseId: null,
        memo: '备注',
        parentId: 'parent-1',
        repeatTemplateId: 'tpl-1',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final map = schedule.toMap();

      expect(map['id'], 'test-id-3');
      expect(map['title'], '测试日程3');
      expect(map['description'], '描述');
      expect(map['location'], '地点');
      expect(map['dateTime'], testDateTime.toIso8601String());
      expect(map['endTime'], testEndTime.toIso8601String());
      expect(map['repeatType'], 'weekly');
      expect(map['repeatDays'], '[1,2,3]'); // jsonEncode 结果
      expect(map['scheduleType'], 'language');
      expect(map['isCourse'], 0); // false -> 0
      expect(map['courseId'], null);
      expect(map['memo'], '备注');
      expect(map['parentId'], 'parent-1');
      expect(map['repeatTemplateId'], 'tpl-1');
      expect(map['createdAt'], testCreatedAt.toIso8601String());
      expect(map['updatedAt'], testUpdatedAt.toIso8601String());
    });

    test('TC-003: fromMap() 转换', () {
      final map = {
        'id': 'test-id-4',
        'title': '测试日程4',
        'description': '描述4',
        'location': '地点4',
        'dateTime': '2026-04-24T10:00:00.000',
        'endTime': '2026-04-24T11:00:00.000',
        'repeatType': 'custom',
        'repeatDays': '[2,4,6]',
        'scheduleType': 'medical',
        'isCourse': 1, // true -> 1
        'courseId': 'course-4',
        'memo': '备注4',
        'parentId': 'parent-4',
        'repeatTemplateId': 'tpl-4',
        'createdAt': '2026-04-24T09:00:00.000',
        'updatedAt': '2026-04-24T09:30:00.000',
      };

      final schedule = Schedule.fromMap(map);

      expect(schedule.id, 'test-id-4');
      expect(schedule.title, '测试日程4');
      expect(schedule.description, '描述4');
      expect(schedule.location, '地点4');
      expect(schedule.dateTime, DateTime(2026, 4, 24, 10, 0));
      expect(schedule.endTime, DateTime(2026, 4, 24, 11, 0));
      expect(schedule.repeatType, RepeatType.custom);
      expect(schedule.repeatDays, [2, 4, 6]);
      expect(schedule.scheduleType, ScheduleType.medical);
      expect(schedule.isCourse, true);
      expect(schedule.courseId, 'course-4');
      expect(schedule.memo, '备注4');
      expect(schedule.parentId, 'parent-4');
      expect(schedule.repeatTemplateId, 'tpl-4');
      expect(schedule.createdAt, DateTime(2026, 4, 24, 9, 0));
      expect(schedule.updatedAt, DateTime(2026, 4, 24, 9, 30));
    });

    test('TC-003: fromMap() 处理无效枚举值', () {
      final map = {
        'id': 'test-id-5',
        'title': '测试日程5',
        'dateTime': '2026-04-24T10:00:00.000',
        'repeatType': 'invalid_type',
        'repeatDays': '[]',
        'scheduleType': 'invalid_type',
        'isCourse': 0,
        'createdAt': '2026-04-24T09:00:00.000',
        'updatedAt': '2026-04-24T09:30:00.000',
      };

      final schedule = Schedule.fromMap(map);

      expect(schedule.repeatType, RepeatType.none); // 默认值
      expect(schedule.scheduleType, ScheduleType.general); // 默认值
    });

    test('TC-004: copyWith() 修改属性', () {
      final original = Schedule(
        id: 'test-id-6',
        title: '原始标题',
        description: '原始描述',
        location: '原始地点',
        dateTime: testDateTime,
        endTime: testEndTime,
        repeatType: RepeatType.none,
        scheduleType: ScheduleType.general,
        isCourse: false,
      );

      final copy = original.copyWith(
        title: '修改标题',
        description: '修改描述',
        scheduleType: ScheduleType.school,
      );

      // 修改的属性
      expect(copy.title, '修改标题');
      expect(copy.description, '修改描述');
      expect(copy.scheduleType, ScheduleType.school);

      // 未修改的属性
      expect(copy.id, original.id);
      expect(copy.location, original.location);
      expect(copy.dateTime, original.dateTime);
      expect(copy.endTime, original.endTime);
      expect(copy.repeatType, original.repeatType);
      expect(copy.isCourse, original.isCourse);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
    });

    test('TC-005: color getter', () {
      expect(
        Schedule(id: '1', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.nursery).color,
        isA<Color>(),
      );
      expect(
        Schedule(id: '2', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.sports).color,
        isA<Color>(),
      );
      expect(
        Schedule(id: '3', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.language).color,
        isA<Color>(),
      );
      expect(
        Schedule(id: '4', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.medical).color,
        isA<Color>(),
      );
      expect(
        Schedule(id: '5', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.school).color,
        isA<Color>(),
      );
      expect(
        Schedule(id: '6', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.general).color,
        isA<Color>(),
      );
    });

    test('TC-006: typeIcon getter', () {
      expect(
        Schedule(id: '1', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.nursery).typeIcon,
        '🏫',
      );
      expect(
        Schedule(id: '2', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.sports).typeIcon,
        '⚽',
      );
      expect(
        Schedule(id: '3', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.language).typeIcon,
        '💬',
      );
      expect(
        Schedule(id: '4', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.medical).typeIcon,
        '🏥',
      );
      expect(
        Schedule(id: '5', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.school).typeIcon,
        '🎒',
      );
      expect(
        Schedule(id: '6', title: 't', dateTime: testDateTime, scheduleType: ScheduleType.general).typeIcon,
        '📋',
      );
    });
  });

  group('CheckIn Model Tests', () {
    test('创建 CheckIn 对象', () {
      final checkIn = CheckIn(
        id: 'checkin-1',
        scheduleId: 'schedule-1',
        checkInTime: DateTime(2026, 4, 24, 10, 30),
        notes: '测试备注',
      );

      expect(checkIn.id, 'checkin-1');
      expect(checkIn.scheduleId, 'schedule-1');
      expect(checkIn.checkInTime, DateTime(2026, 4, 24, 10, 30));
      expect(checkIn.notes, '测试备注');
    });

    test('toMap() 转换', () {
      final checkIn = CheckIn(
        id: 'checkin-2',
        scheduleId: 'schedule-2',
        checkInTime: DateTime(2026, 4, 24, 11, 0),
        notes: '备注2',
      );

      final map = checkIn.toMap();

      expect(map['id'], 'checkin-2');
      expect(map['scheduleId'], 'schedule-2');
      expect(map['checkInTime'], '2026-04-24T11:00:00.000');
      expect(map['notes'], '备注2');
    });

    test('fromMap() 转换', () {
      final map = {
        'id': 'checkin-3',
        'scheduleId': 'schedule-3',
        'checkInTime': '2026-04-24T14:00:00.000',
        'notes': '备注3',
      };

      final checkIn = CheckIn.fromMap(map);

      expect(checkIn.id, 'checkin-3');
      expect(checkIn.scheduleId, 'schedule-3');
      expect(checkIn.checkInTime, DateTime(2026, 4, 24, 14, 0));
      expect(checkIn.notes, '备注3');
    });
  });

  group('Course Model Tests', () {
    test('创建 Course 对象', () {
      final course = Course(
        id: 'course-1',
        name: '网球课',
        courseType: CourseType.sports,
        totalHours: 20.0,
        usedHours: 5.0,
        unitName: '课时',
        color: 0xFFE91E63,
        iconData: 'sports_tennis',
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 24),
      );

      expect(course.id, 'course-1');
      expect(course.name, '网球课');
      expect(course.courseType, CourseType.sports);
      expect(course.totalHours, 20.0);
      expect(course.usedHours, 5.0);
      expect(course.remainingHours, 15.0);
      expect(course.usagePercent, 0.25);
      expect(course.unitName, '课时');
      expect(course.color, 0xFFE91E63);
      expect(course.iconData, 'sports_tennis');
    });

    test('remainingHours 和 usagePercent getter', () {
      final course1 = Course(
        id: 'c1',
        name: 'Test',
        totalHours: 10.0,
        usedHours: 0.0,
      );
      expect(course1.remainingHours, 10.0);
      expect(course1.usagePercent, 0.0);

      final course2 = Course(
        id: 'c2',
        name: 'Test',
        totalHours: 10.0,
        usedHours: 10.0,
      );
      expect(course2.remainingHours, 0.0);
      expect(course2.usagePercent, 1.0);

      final course3 = Course(
        id: 'c3',
        name: 'Test',
        totalHours: 0.0, // 避免除以零
        usedHours: 0.0,
      );
      expect(course3.usagePercent, 0.0); // totalHours > 0 检查
    });

    test('toMap() 和 fromMap() 转换', () {
      final course = Course(
        id: 'course-2',
        name: '英语课',
        courseType: CourseType.language,
        totalHours: 30.0,
        usedHours: 10.0,
        unitName: '小时',
        color: 0xFF2196F3,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 24),
      );

      final map = course.toMap();
      expect(map['id'], 'course-2');
      expect(map['name'], '英语课');
      expect(map['courseType'], 'language');
      expect(map['totalHours'], 30.0);
      expect(map['usedHours'], 10.0);

      final restored = Course.fromMap(map);
      expect(restored.id, course.id);
      expect(restored.name, course.name);
      expect(restored.courseType, course.courseType);
      expect(restored.totalHours, course.totalHours);
      expect(restored.usedHours, course.usedHours);
    });
  });

  group('MedicalRecord Model Tests', () {
    test('创建 MedicalRecord 对象', () {
      final record = MedicalRecord(
        id: 'med-1',
        scheduleId: 'schedule-1',
        hospitalName: '北京儿童医院',
        doctorName: '张医生',
        diagnosis: '感冒',
        medication: '退烧药',
        reportImagePaths: ['/path/to/image1.jpg', '/path/to/image2.jpg'],
        notes: '注意休息',
        visitDate: DateTime(2026, 4, 23),
        createdAt: DateTime(2026, 4, 24),
      );

      expect(record.id, 'med-1');
      expect(record.hospitalName, '北京儿童医院');
      expect(record.doctorName, '张医生');
      expect(record.diagnosis, '感冒');
      expect(record.medication, '退烧药');
      expect(record.reportImagePaths, ['/path/to/image1.jpg', '/path/to/image2.jpg']);
      expect(record.notes, '注意休息');
      expect(record.visitDate, DateTime(2026, 4, 23));
    });

    test('toMap() 和 fromMap() 转换 - reportImagePaths JSON 编码', () {
      final record = MedicalRecord(
        id: 'med-2',
        hospitalName: '测试医院',
        doctorName: '测试医生',
        diagnosis: '测试诊断',
        medication: '测试药物',
        reportImagePaths: ['/path/1.jpg', '/path/2.jpg'],
        notes: '测试备注',
        visitDate: DateTime(2026, 4, 24),
      );

      final map = record.toMap();
      expect(map['reportImagePaths'], '["/path/1.jpg","/path/2.jpg"]');

      final restored = MedicalRecord.fromMap(map);
      expect(restored.reportImagePaths, ['/path/1.jpg', '/path/2.jpg']);
    });

    test('fromMap() 处理空 reportImagePaths', () {
      final map = {
        'id': 'med-3',
        'hospitalName': '医院3',
        'doctorName': '医生3',
        'diagnosis': '诊断3',
        'medication': '药物3',
        'reportImagePaths': '[]',
        'notes': '备注3',
        'visitDate': '2026-04-24T00:00:00.000',
        'createdAt': '2026-04-24T00:00:00.000',
      };

      final record = MedicalRecord.fromMap(map);
      expect(record.reportImagePaths, []);
    });
  });

  group('GrowthLog Model Tests', () {
    test('创建 GrowthLog 对象', () {
      final log = GrowthLog(
        id: 'log-1',
        title: '第一次走路',
        content: '今天宝宝第一次走路了！',
        imagePaths: ['/path/to/photo1.jpg'],
        videoPaths: ['/path/to/video1.mp4'],
        mood: Mood.excited,
        tags: ['成长', '里程碑'],
        scheduleId: 'schedule-1',
        createdAt: DateTime(2026, 4, 24),
        updatedAt: DateTime(2026, 4, 24),
      );

      expect(log.id, 'log-1');
      expect(log.title, '第一次走路');
      expect(log.content, '今天宝宝第一次走路了！');
      expect(log.imagePaths, ['/path/to/photo1.jpg']);
      expect(log.videoPaths, ['/path/to/video1.mp4']);
      expect(log.mood, Mood.excited);
      expect(log.tags, ['成长', '里程碑']);
      expect(log.scheduleId, 'schedule-1');
    });

    test('toMap() 和 fromMap() 转换 - JSON 数组字段', () {
      final log = GrowthLog(
        id: 'log-2',
        title: '测试日志',
        content: '测试内容',
        imagePaths: ['/img1.jpg', '/img2.jpg'],
        videoPaths: ['/vid1.mp4'],
        mood: Mood.happy,
        tags: ['测试'],
        scheduleId: null,
        createdAt: DateTime(2026, 4, 24),
        updatedAt: DateTime(2026, 4, 24),
      );

      final map = log.toMap();
      expect(map['imagePaths'], '["/img1.jpg","/img2.jpg"]');
      expect(map['videoPaths'], '["/vid1.mp4"]');
      expect(map['mood'], 'happy');
      expect(map['tags'], '["测试"]');

      final restored = GrowthLog.fromMap(map);
      expect(restored.imagePaths, ['/img1.jpg', '/img2.jpg']);
      expect(restored.videoPaths, ['/vid1.mp4']);
      expect(restored.mood, Mood.happy);
      expect(restored.tags, ['测试']);
    });

    test('fromMap() 处理无效 mood 值', () {
      final map = {
        'id': 'log-3',
        'title': '测试',
        'content': '测试',
        'imagePaths': '[]',
        'videoPaths': '[]',
        'mood': 'invalid_mood',
        'tags': '[]',
        'scheduleId': null,
        'createdAt': '2026-04-24T00:00:00.000',
        'updatedAt': '2026-04-24T00:00:00.000',
      };

      final log = GrowthLog.fromMap(map);
      expect(log.mood, Mood.happy); // 默认值
    });
  });
}
