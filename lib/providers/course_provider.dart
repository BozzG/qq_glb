import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class CourseProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Course> _courses = [];
  List<CourseConsumption> _consumptions = [];
  bool _isLoading = false;

  List<Course> get courses => _courses;
  List<CourseConsumption> get consumptions => _consumptions;
  bool get isLoading => _isLoading;

  Future<void> loadCourses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final maps = await _db.query('courses', orderBy: 'createdAt DESC');
      _courses = maps.map((m) => Course.fromMap(m)).toList();
      
      final consMaps = await _db.query('course_consumptions', orderBy: 'createdAt DESC');
      _consumptions = consMaps.map((m) => CourseConsumption.fromMap(m)).toList();
    } catch (e) {
      debugPrint('加载课程失败: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCourse(Course course) async {
    await _db.insert('courses', course.toMap());
    await loadCourses();
  }

  Future<void> updateCourse(Course course) async {
    await _db.update('courses', course.toMap(), where: 'id = ?', whereArgs: [course.id]);
    await loadCourses();
  }

  Future<void> deleteCourse(String id) async {
    await _db.delete('courses', where: 'id = ?', whereArgs: [id]);
    await _db.delete('course_consumptions', where: 'courseId = ?', whereArgs: [id]);
    await loadCourses();
  }

  // 手动调整课时
  // 注意：adjustment 表示"已用课时"的变化量（正数=已用增加=剩余减少）
  Future<void> adjustHours(String courseId, double adjustment, {String? note}) async {
    final consumption = CourseConsumption(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: courseId,
      consumedAmount: adjustment,
      consumptionType: ConsumptionType.manual,
      // adjustment > 0 → 已用增加 → 对用户视角是"扣减剩余"
      note: note?.isNotEmpty == true
          ? note
          : (adjustment > 0 ? '手动扣减课时' : '手动增加课时'),
    );
    await _db.insert('course_consumptions', consumption.toMap());
    
    final course = _courses.firstWhere((c) => c.id == courseId);
    await _db.update('courses', {'usedHours': course.usedHours + adjustment}, where: 'id = ?', whereArgs: [courseId]);
    await loadCourses();
  }

  // 获取某课程的消耗记录
  List<CourseConsumption> getConsumptionsForCourse(String courseId) {
    return _consumptions.where((c) => c.courseId == courseId).toList();
  }
}
