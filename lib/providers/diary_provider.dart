import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class DiaryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Diary> _diaries = [];
  bool _isLoading = false;

  List<Diary> get diaries => _diaries;
  bool get isLoading => _isLoading;

  /// 加载所有日记（按日期降序）
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

  /// 获取指定月份的日记
  List<Diary> getDiariesByMonth(DateTime month) {
    return _diaries.where((diary) {
      return diary.diaryDate.year == month.year &&
          diary.diaryDate.month == month.month;
    }).toList();
  }

  /// 根据ID获取日记
  Diary? getDiaryById(String id) {
    try {
      return _diaries.firstWhere((diary) => diary.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 添加日记
  Future<void> addDiary(Diary diary) async {
    await _db.insert('diaries', diary.toMap());
    await loadDiaries();
  }

  /// 更新日记
  Future<void> updateDiary(Diary diary) async {
    await _db.update('diaries', diary.toMap(),
        where: 'id = ?', whereArgs: [diary.id]);
    await loadDiaries();
  }

  /// 删除日记
  Future<void> deleteDiary(String id) async {
    await _db.delete('diaries', where: 'id = ?', whereArgs: [id]);
    await loadDiaries();
  }
}
