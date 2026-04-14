import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class MemoProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Memo> _memos = [];
  bool _isLoading = false;

  List<Memo> get memos => _memos;
  bool get isLoading => _isLoading;

  Future<void> loadMemos() async {
    _isLoading = true;
    notifyListeners();
    try {
      final maps = await _db.query('memos', orderBy: 'createdAt DESC');
      _memos = maps.map((m) => Memo.fromMap(m)).toList();
    } catch (e) {
      debugPrint('加载备忘失败: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMemo(Memo memo) async {
    await _db.insert('memos', memo.toMap());
    await loadMemos();
  }

  Future<void> updateMemo(Memo memo) async {
    await _db.update('memos', memo.toMap(), where: 'id = ?', whereArgs: [memo.id]);
    await loadMemos();
  }

  Future<void> deleteMemo(String id) async {
    await _db.delete('memos', where: 'id = ?', whereArgs: [id]);
    await loadMemos();
  }
}
