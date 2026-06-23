import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:qianqian_growth_logbook/models/models.dart';
import 'package:qianqian_growth_logbook/providers/diary_provider.dart';
import 'package:qianqian_growth_logbook/services/database_helper.dart';

void main() {
  // 初始化内存数据库用于测试
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    // 启用测试模式，使用内存数据库
    DatabaseHelper.isTestMode = true;
  });

  group('DiaryProvider Tests', () {
    late DiaryProvider provider;

    setUp(() async {
      DatabaseHelper().resetDatabase();
      provider = DiaryProvider();
      await provider.loadDiaries();
    });

    tearDown(() async {
      await DatabaseHelper().recreateTables();
    });

    test('TC-PD001: 添加日记', () async {
      final diary = Diary(
        id: 'diary-1',
        title: '第一次测试日记',
        content: '今天芊芊很开心',
        diaryDate: DateTime(2026, 4, 24),
        qianqianStatus: DiaryStatus.good,
        scheduleIds: ['schedule-1'],
        progressPoints: '今天表现很好',
        imagePaths: ['/path/to/image1.jpg'],
      );

      await provider.addDiary(diary);
      
      expect(provider.diaries.length, 1);
      expect(provider.diaries.first.title, '第一次测试日记');
      expect(provider.diaries.first.content, '今天芊芊很开心');
      expect(provider.diaries.first.qianqianStatus, DiaryStatus.good);
      expect(provider.diaries.first.scheduleIds, ['schedule-1']);
      expect(provider.diaries.first.progressPoints, '今天表现很好');
      expect(provider.diaries.first.imagePaths, ['/path/to/image1.jpg']);
    });

    test('TC-PD002: 添加多个日记并按日期降序排列', () async {
      final diary1 = Diary(
        id: 'diary-2',
        title: 'older 日记',
        content: '内容2',
        diaryDate: DateTime(2026, 4, 20),
        qianqianStatus: DiaryStatus.normal,
      );

      final diary2 = Diary(
        id: 'diary-3',
        title: 'newer 日记',
        content: '内容3',
        diaryDate: DateTime(2026, 4, 25),
        qianqianStatus: DiaryStatus.good,
      );

      await provider.addDiary(diary1);
      await provider.addDiary(diary2);

      expect(provider.diaries.length, 2);
      // 应该按 diaryDate DESC 排序，newer 在前
      expect(provider.diaries[0].title, 'newer 日记');
      expect(provider.diaries[1].title, 'older 日记');
    });

    test('TC-PD003: 更新日记', () async {
      final diary = Diary(
        id: 'diary-4',
        title: '原始标题',
        content: '原始内容',
        diaryDate: DateTime(2026, 4, 24),
        qianqianStatus: DiaryStatus.normal,
        progressPoints: '原始进步点',
        improvementPoints: '原始改进点',
      );

      await provider.addDiary(diary);
      
      final updatedDiary = Diary(
        id: 'diary-4',
        title: '更新标题',
        content: '更新内容',
        diaryDate: DateTime(2026, 4, 24),
        qianqianStatus: DiaryStatus.good,
        progressPoints: '更新进步点',
        improvementPoints: '更新改进点',
        imagePaths: ['/new/image.jpg'],
      );

      await provider.updateDiary(updatedDiary);
      
      final diaryFromProvider = provider.diaries.firstWhere((d) => d.id == 'diary-4');
      expect(diaryFromProvider.title, '更新标题');
      expect(diaryFromProvider.content, '更新内容');
      expect(diaryFromProvider.qianqianStatus, DiaryStatus.good);
      expect(diaryFromProvider.progressPoints, '更新进步点');
      expect(diaryFromProvider.improvementPoints, '更新改进点');
      expect(diaryFromProvider.imagePaths, ['/new/image.jpg']);
    });

    test('TC-PD004: 删除日记', () async {
      final diary = Diary(
        id: 'diary-5',
        title: '待删除',
        content: '内容',
        diaryDate: DateTime(2026, 4, 24),
        qianqianStatus: DiaryStatus.normal,
      );

      await provider.addDiary(diary);
      expect(provider.diaries.length, 1);

      await provider.deleteDiary('diary-5');
      expect(provider.diaries.length, 0);
    });

    test('TC-PD005: getDiariesByMonth() 获取指定月份的日记', () async {
      final diary1 = Diary(
        id: 'diary-6',
        title: '4月日记1',
        content: '内容',
        diaryDate: DateTime(2026, 4, 10),
        qianqianStatus: DiaryStatus.good,
      );

      final diary2 = Diary(
        id: 'diary-7',
        title: '4月日记2',
        content: '内容',
        diaryDate: DateTime(2026, 4, 20),
        qianqianStatus: DiaryStatus.normal,
      );

      final diary3 = Diary(
        id: 'diary-8',
        title: '5月日记',
        content: '内容',
        diaryDate: DateTime(2026, 5, 1),
        qianqianStatus: DiaryStatus.good,
      );

      await provider.addDiary(diary1);
      await provider.addDiary(diary2);
      await provider.addDiary(diary3);

      final aprilDiaries = provider.getDiariesByMonth(DateTime(2026, 4));
      expect(aprilDiaries.length, 2);
      // getDiariesByMonth 返回的是按日期降序排列（与 _diaries 顺序一致）
      expect(aprilDiaries[0].title, '4月日记2'); // 4月20日 在 4月10日 前面
      expect(aprilDiaries[1].title, '4月日记1');

      final mayDiaries = provider.getDiariesByMonth(DateTime(2026, 5));
      expect(mayDiaries.length, 1);
      expect(mayDiaries[0].title, '5月日记');
    });

    test('TC-PD006: getDiaryById() 根据ID获取日记', () async {
      final diary = Diary(
        id: 'diary-9',
        title: '测试日记',
        content: '内容',
        diaryDate: DateTime(2026, 4, 24),
        qianqianStatus: DiaryStatus.good,
      );

      await provider.addDiary(diary);

      final found = provider.getDiaryById('diary-9');
      expect(found, isNotNull);
      expect(found!.title, '测试日记');

      final notFound = provider.getDiaryById('non-existent-id');
      expect(notFound, isNull);
    });

    test('TC-PD007: 添加日记时包含媒体路径', () async {
      final diary = Diary(
        id: 'diary-10',
        title: '带媒体的日记',
        content: '内容',
        diaryDate: DateTime(2026, 4, 24),
        qianqianStatus: DiaryStatus.good,
        imagePaths: ['/img1.jpg', '/img2.jpg'],
        videoPaths: ['/vid1.mp4'],
      );

      await provider.addDiary(diary);
      
      final saved = provider.getDiaryById('diary-10');
      expect(saved!.imagePaths, ['/img1.jpg', '/img2.jpg']);
      expect(saved.videoPaths, ['/vid1.mp4']);
    });

    test('TC-PD008: 添加日记时包含 scheduleSnapshots', () async {
      final diary = Diary(
        id: 'diary-11',
        title: '带日程快照的日记',
        content: '内容',
        diaryDate: DateTime(2026, 4, 24),
        qianqianStatus: DiaryStatus.good,
        scheduleIds: ['s1', 's2'],
        scheduleSnapshots: [
          {'id': 's1', 'title': '网球课', 'time': '10:00'},
          {'id': 's2', 'title': '英语课', 'time': '14:00'},
        ],
      );

      await provider.addDiary(diary);
      
      final saved = provider.getDiaryById('diary-11');
      expect(saved!.scheduleIds, ['s1', 's2']);
      expect(saved.scheduleSnapshots.length, 2);
      expect(saved.scheduleSnapshots[0]['title'], '网球课');
      expect(saved.scheduleSnapshots[1]['title'], '英语课');
    });

    test('TC-PD009: isLoading 状态', () async {
      expect(provider.isLoading, false);
      
      // loadDiaries 会设置 isLoading，但由于是异步的，我们需要验证它在加载时为真
      // 这里我们可以测试初始状态和加载后的状态
      await provider.loadDiaries();
      expect(provider.isLoading, false);
    });
  });
}
