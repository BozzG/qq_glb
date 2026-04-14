import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class GrowthLogProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<GrowthLog> _logs = [];
  bool _isLoading = false;

  List<GrowthLog> get logs => _logs;
  bool get isLoading => _isLoading;

  Future<void> loadLogs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final maps = await _db.query('growth_logs', orderBy: 'createdAt DESC');
      _logs = maps.map((m) => GrowthLog.fromMap(m)).toList();
    } catch (e) {
      debugPrint('加载成长日志失败: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(GrowthLog log) async {
    await _db.insert('growth_logs', log.toMap());
    await loadLogs();
  }

  Future<void> updateLog(GrowthLog log) async {
    await _db.update('growth_logs', log.toMap(), where: 'id = ?', whereArgs: [log.id]);
    await loadLogs();
  }

  Future<void> deleteLog(String id) async {
    await _db.delete('growth_logs', where: 'id = ?', whereArgs: [id]);
    await loadLogs();
  }
}
