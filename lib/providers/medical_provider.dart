import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class MedicalProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<MedicalRecord> _records = [];
  bool _isLoading = false;

  List<MedicalRecord> get records => _records;
  bool get isLoading => _isLoading;

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();
    try {
      final maps = await _db.query('medical_records', orderBy: 'visitDate DESC');
      _records = maps.map((m) => MedicalRecord.fromMap(m)).toList();
    } catch (e) {
      debugPrint('加载医疗记录失败: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecord(MedicalRecord record) async {
    await _db.insert('medical_records', record.toMap());
    await loadRecords();
  }

  Future<void> updateRecord(MedicalRecord record) async {
    await _db.update('medical_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
    await loadRecords();
  }

  Future<void> deleteRecord(String id) async {
    await _db.delete('medical_records', where: 'id = ?', whereArgs: [id]);
    await loadRecords();
  }
}
