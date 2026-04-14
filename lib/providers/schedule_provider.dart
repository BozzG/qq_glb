import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class ScheduleProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  List<Schedule> _schedules = [];
  List<CheckIn> _checkIns = [];
  bool _isLoading = false;

  List<Schedule> get schedules => _schedules;
  List<CheckIn> get checkIns => _checkIns;
  bool get isLoading => _isLoading;

  // 获取某天的日程
  List<Schedule> getSchedulesForDay(DateTime day) {
    return _schedules.where((s) {
      if (s.repeatType == RepeatType.none) {
        return isSameDay(s.dateTime, day);
      } else if (s.repeatType == RepeatType.daily) {
        return s.dateTime.isBefore(day.add(Duration(days: 1))) || isSameDay(s.dateTime, day);
      } else if (s.repeatType == RepeatType.weekly || s.repeatType == RepeatType.custom) {
        int targetWeekday = day.weekday; // 1=Mon, 7=Sun
        return s.repeatDays.contains(targetWeekday) && !s.dateTime.isAfter(day);
      }
      return false;
    }).toList();
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> loadSchedules() async {
    _isLoading = true;
    notifyListeners();
    try {
      final maps = await _db.query('schedules', orderBy: 'dateTime ASC');
      _schedules = maps.map((m) => Schedule.fromMap(m)).toList();
      
      final checkInMaps = await _db.query('check_ins', orderBy: 'checkInTime DESC');
      _checkIns = checkInMaps.map((m) => CheckIn.fromMap(m)).toList();
    } catch (e) {
      debugPrint('加载日程失败: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSchedule(Schedule schedule) async {
    try {
      await _db.insert('schedules', schedule.toMap());
      await _notificationService.scheduleForSchedule(schedule);
      await loadSchedules();
    } catch (e) {
      debugPrint('添加日程失败: $e');
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _db.update('schedules', schedule.toMap(), where: 'id = ?', whereArgs: [schedule.id]);
      await _notificationService.cancelForSchedule(schedule.id);
      await _notificationService.scheduleForSchedule(schedule);
      await loadSchedules();
    } catch (e) {
      debugPrint('更新日程失败: $e');
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _db.delete('schedules', where: 'id = ?', whereArgs: [id]);
      await _db.delete('check_ins', where: 'scheduleId = ?', whereArgs: [id]);
      await _notificationService.cancelForSchedule(id);
      await loadSchedules();
    } catch (e) {
      debugPrint('删除日程失败: $e');
    }
  }

  // 打卡
  Future<bool> checkIn(String scheduleId, {String? notes}) async {
    try {
      // 检查今天是否已打卡
      final today = DateTime.now();
      final alreadyChecked = _checkIns.any((c) =>
          c.scheduleId == scheduleId &&
          isSameDay(c.checkInTime, today));
      if (alreadyChecked) return false;

      final checkIn = CheckIn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        scheduleId: scheduleId,
        checkInTime: DateTime.now(),
        notes: notes,
      );
      await _db.insert('check_ins', checkIn.toMap());

      // 如果是课程，自动扣课时
      final schedule = _schedules.firstWhere(
        (s) => s.id == scheduleId,
        orElse: () => throw Exception('Schedule not found'),
      );
      if (schedule.isCourse && schedule.courseId != null) {
        await _deductCourseHours(schedule.courseId!, checkIn.id, 1.0);
      }

      await loadSchedules();
      return true;
    } catch (e) {
      debugPrint('打卡失败: $e');
      return false;
    }
  }

  bool isCheckedToday(String scheduleId) {
    final today = DateTime.now();
    return _checkIns.any((c) =>
        c.scheduleId == scheduleId &&
        c.checkInTime.year == today.year &&
        c.checkInTime.month == today.month &&
        c.checkInTime.day == today.day);
  }

  Future<void> _deductCourseHours(String courseId, String checkInId, double amount) async {
    final consumption = CourseConsumption(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: courseId,
      consumedAmount: amount,
      consumptionType: ConsumptionType.auto,
      relatedCheckInId: checkInId,
    );
    await _db.insert('course_consumptions', consumption.toMap());
    
    // 更新课程已用课时
    final courseMaps = await _db.query('courses', where: 'id = ?', whereArgs: [courseId]);
    if (courseMaps.isNotEmpty) {
      final course = Course.fromMap(courseMaps.first);
      await _db.update('courses', {'usedHours': course.usedHours + amount}, where: 'id = ?', whereArgs: [courseId]);
    }
  }

  // 获取打卡统计
  Map<String, dynamic> getCheckInStats({required DateTime start, required DateTime end}) {
    final filtered = _checkIns.where((c) =>
        c.checkInTime.isAfter(start.subtract(Duration(days: 1))) &&
        c.checkInTime.isBefore(end.add(Duration(days: 1)))).toList();

    // 按日期分组
    Map<String, int> dailyCounts = {};
    for (var ci in filtered) {
      final key = '${ci.checkInTime.year}-${ci.checkInTime.month.toString().padLeft(2, "0")}-${ci.checkInTime.day.toString().padLeft(2, "0")}';
      dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
    }

    return {
      'totalCount': filtered.length,
      'uniqueDays': dailyCounts.keys.length,
      'dailyCounts': dailyCounts,
    };
  }
}
