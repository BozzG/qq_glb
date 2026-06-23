import 'package:flutter_test/flutter_test.dart';
import 'package:qianqian_growth_logbook/models/models.dart';

void main() {
  group('Diary Model Tests', () {
    final testDiaryDate = DateTime(2026, 4, 24);
    final testCreatedAt = DateTime(2026, 4, 24, 9, 0);
    final testUpdatedAt = DateTime(2026, 4, 24, 9, 30);

    test('TC-D001: 创建 Diary 对象（完整参数）', () {
      final diary = Diary(
        id: 'diary-1',
        title: '测试日记',
        content: '今天芊芊很开心',
        diaryDate: testDiaryDate,
        qianqianStatus: DiaryStatus.good,
        scheduleIds: ['schedule-1', 'schedule-2'],
        scheduleSnapshots: [
          {'id': 'schedule-1', 'title': '网球课', 'time': '10:00'},
          {'id': 'schedule-2', 'title': '英语课', 'time': '14:00'},
        ],
        progressPoints: '今天打球很认真',
        improvementPoints: '需要加强英语口语',
        imagePaths: ['/path/to/image1.jpg', '/path/to/image2.jpg'],
        videoPaths: ['/path/to/video1.mp4'],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(diary.id, 'diary-1');
      expect(diary.title, '测试日记');
      expect(diary.content, '今天芊芊很开心');
      expect(diary.diaryDate, testDiaryDate);
      expect(diary.qianqianStatus, DiaryStatus.good);
      expect(diary.scheduleIds, ['schedule-1', 'schedule-2']);
      expect(diary.scheduleSnapshots.length, 2);
      expect(diary.scheduleSnapshots[0]['title'], '网球课');
      expect(diary.progressPoints, '今天打球很认真');
      expect(diary.improvementPoints, '需要加强英语口语');
      expect(diary.imagePaths, ['/path/to/image1.jpg', '/path/to/image2.jpg']);
      expect(diary.videoPaths, ['/path/to/video1.mp4']);
      expect(diary.createdAt, testCreatedAt);
      expect(diary.updatedAt, testUpdatedAt);
    });

    test('TC-D002: 创建 Diary 对象（最小参数/默认值）', () {
      final diary = Diary(
        id: 'diary-2',
        content: '简单日记',
        diaryDate: testDiaryDate,
        qianqianStatus: DiaryStatus.normal,
      );

      expect(diary.id, 'diary-2');
      expect(diary.title, null);
      expect(diary.content, '简单日记');
      expect(diary.diaryDate, testDiaryDate);
      expect(diary.qianqianStatus, DiaryStatus.normal);
      expect(diary.scheduleIds, []);
      expect(diary.scheduleSnapshots, []);
      expect(diary.progressPoints, null);
      expect(diary.improvementPoints, null);
      expect(diary.imagePaths, []);
      expect(diary.videoPaths, []);
      expect(diary.createdAt, isA<DateTime>());
      expect(diary.updatedAt, isA<DateTime>());
    });

    test('TC-D003: toMap() 转换', () {
      final diary = Diary(
        id: 'diary-3',
        title: '测试日记3',
        content: '测试内容',
        diaryDate: testDiaryDate,
        qianqianStatus: DiaryStatus.irritable,
        scheduleIds: ['s1', 's2'],
        scheduleSnapshots: [
          {'id': 's1', 'title': '测试'}
        ],
        progressPoints: '进步点',
        improvementPoints: '改进点',
        imagePaths: ['/img1.jpg'],
        videoPaths: ['/vid1.mp4'],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final map = diary.toMap();

      expect(map['id'], 'diary-3');
      expect(map['title'], '测试日记3');
      expect(map['content'], '测试内容');
      expect(map['diaryDate'], testDiaryDate.toIso8601String());
      expect(map['qianqianStatus'], 'irritable');
      expect(map['scheduleIds'], '["s1","s2"]'); // jsonEncode 结果
      expect(map['scheduleSnapshots'], '[{"id":"s1","title":"测试"}]');
      expect(map['progressPoints'], '进步点');
      expect(map['improvementPoints'], '改进点');
      expect(map['imagePaths'], '["/img1.jpg"]');
      expect(map['videoPaths'], '["/vid1.mp4"]');
      expect(map['createdAt'], testCreatedAt.toIso8601String());
      expect(map['updatedAt'], testUpdatedAt.toIso8601String());
    });

    test('TC-D004: fromMap() 转换', () {
      final map = {
        'id': 'diary-4',
        'title': '测试日记4',
        'content': '测试内容4',
        'diaryDate': '2026-04-24T00:00:00.000',
        'qianqianStatus': 'good',
        'scheduleIds': '["s1","s2"]',
        'scheduleSnapshots': '[{"id":"s1","title":"日程1"},{"id":"s2","title":"日程2"}]',
        'progressPoints': '今天表现很好',
        'improvementPoints': '需要多练习',
        'imagePaths': '["/img1.jpg","/img2.jpg"]',
        'videoPaths': '["/vid1.mp4"]',
        'createdAt': '2026-04-24T09:00:00.000',
        'updatedAt': '2026-04-24T09:30:00.000',
      };

      final diary = Diary.fromMap(map);

      expect(diary.id, 'diary-4');
      expect(diary.title, '测试日记4');
      expect(diary.content, '测试内容4');
      expect(diary.diaryDate, DateTime(2026, 4, 24));
      expect(diary.qianqianStatus, DiaryStatus.good);
      expect(diary.scheduleIds, ['s1', 's2']);
      expect(diary.scheduleSnapshots.length, 2);
      expect(diary.scheduleSnapshots[0]['title'], '日程1');
      expect(diary.scheduleSnapshots[1]['title'], '日程2');
      expect(diary.progressPoints, '今天表现很好');
      expect(diary.improvementPoints, '需要多练习');
      expect(diary.imagePaths, ['/img1.jpg', '/img2.jpg']);
      expect(diary.videoPaths, ['/vid1.mp4']);
      expect(diary.createdAt, DateTime(2026, 4, 24, 9, 0));
      expect(diary.updatedAt, DateTime(2026, 4, 24, 9, 30));
    });

    test('TC-D005: fromMap() 处理无效 qianqianStatus 值', () {
      final map = {
        'id': 'diary-5',
        'content': '测试',
        'diaryDate': '2026-04-24T00:00:00.000',
        'qianqianStatus': 'invalid_status', // 无效值
        'scheduleIds': '[]',
        'scheduleSnapshots': '[]',
        'imagePaths': '[]',
        'videoPaths': '[]',
        'createdAt': '2026-04-24T09:00:00.000',
        'updatedAt': '2026-04-24T09:30:00.000',
      };

      final diary = Diary.fromMap(map);

      expect(diary.qianqianStatus, DiaryStatus.normal); // 默认值
    });

    test('TC-D006: fromMap() 处理空 JSON 数组', () {
      final map = {
        'id': 'diary-6',
        'content': '测试',
        'diaryDate': '2026-04-24T00:00:00.000',
        'qianqianStatus': 'normal',
        'scheduleIds': '[]',
        'scheduleSnapshots': '[]',
        'imagePaths': '[]',
        'videoPaths': '[]',
        'createdAt': '2026-04-24T09:00:00.000',
        'updatedAt': '2026-04-24T09:30:00.000',
      };

      final diary = Diary.fromMap(map);

      expect(diary.scheduleIds, []);
      expect(diary.scheduleSnapshots, []);
      expect(diary.imagePaths, []);
      expect(diary.videoPaths, []);
    });

    test('TC-D007: fromMap() 处理 null 可选字段', () {
      final map = {
        'id': 'diary-7',
        'title': null,
        'content': '测试内容',
        'diaryDate': '2026-04-24T00:00:00.000',
        'qianqianStatus': 'good',
        'scheduleIds': '[]',
        'scheduleSnapshots': '[]',
        'progressPoints': null,
        'improvementPoints': null,
        'imagePaths': '[]',
        'videoPaths': '[]',
        'createdAt': '2026-04-24T09:00:00.000',
        'updatedAt': '2026-04-24T09:30:00.000',
      };

      final diary = Diary.fromMap(map);

      expect(diary.title, null);
      expect(diary.progressPoints, null);
      expect(diary.improvementPoints, null);
    });

    test('TC-D008: DiaryStatus 枚举值', () {
      expect(DiaryStatus.good, isA<DiaryStatus>());
      expect(DiaryStatus.normal, isA<DiaryStatus>());
      expect(DiaryStatus.irritable, isA<DiaryStatus>());
      
      // 测试 name 属性（用于 toMap）
      expect(DiaryStatus.good.name, 'good');
      expect(DiaryStatus.normal.name, 'normal');
      expect(DiaryStatus.irritable.name, 'irritable');
    });

    test('TC-D009: toMap() 和 fromMap() 互转', () {
      final original = Diary(
        id: 'diary-9',
        title: '互转测试',
        content: '测试内容',
        diaryDate: testDiaryDate,
        qianqianStatus: DiaryStatus.good,
        scheduleIds: ['s1'],
        scheduleSnapshots: [
          {'id': 's1', 'title': '测试日程'}
        ],
        progressPoints: '进步',
        improvementPoints: '改进',
        imagePaths: ['/img1.jpg'],
        videoPaths: [],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final map = original.toMap();
      final restored = Diary.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.diaryDate, original.diaryDate);
      expect(restored.qianqianStatus, original.qianqianStatus);
      expect(restored.scheduleIds, original.scheduleIds);
      expect(restored.scheduleSnapshots.length, original.scheduleSnapshots.length);
      expect(restored.progressPoints, original.progressPoints);
      expect(restored.improvementPoints, original.improvementPoints);
      expect(restored.imagePaths, original.imagePaths);
      expect(restored.videoPaths, original.videoPaths);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });
  });
}
