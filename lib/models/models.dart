import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart' show AppColors;


class Schedule {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime dateTime;
  final DateTime? endTime;
  final RepeatType repeatType;
  final List<int> repeatDays; // 1-7, Mon-Sun
  final ScheduleType scheduleType;
  final bool isCourse;
  final String? courseId;
  final String? memo;
  // 重复日程关联字段
  final String? parentId;          // 所属重复组ID（组内第一个日程的id，自身为null表示是组长）
  final String? repeatTemplateId;  // 重复模板ID（同一组的所有实例共享此ID，用于标识"这是同一个重复规则生成的"）
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.dateTime,
    this.endTime,
    this.repeatType = RepeatType.none,
    List<int>? repeatDays,
    this.scheduleType = ScheduleType.general,
    this.isCourse = false,
    this.courseId,
    this.memo,
    this.parentId,
    this.repeatTemplateId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    repeatDays = repeatDays ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Color get color {
    switch (scheduleType) {
      case ScheduleType.nursery: return AppColors.scheduleNursery;
      case ScheduleType.sports: return AppColors.scheduleSports;
      case ScheduleType.language: return AppColors.scheduleLanguage;
      case ScheduleType.medical: return AppColors.scheduleMedical;
      case ScheduleType.school: return AppColors.scheduleSchool;
      case ScheduleType.general: return AppColors.scheduleGeneral;
    }
  }

  String get typeIcon {
    switch (scheduleType) {
      case ScheduleType.nursery: return '🏫';
      case ScheduleType.sports: return '⚽';
      case ScheduleType.language: return '💬';
      case ScheduleType.medical: return '🏥';
      case ScheduleType.school: return '🎒';
      case ScheduleType.general: return '📋';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'description': description, 'location': location,
    'dateTime': dateTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'repeatType': repeatType.name,
    'repeatDays': jsonEncode(repeatDays),
    'scheduleType': scheduleType.name,
    'isCourse': isCourse ? 1 : 0,
    'courseId': courseId, 'memo': memo,
    'parentId': parentId,
    'repeatTemplateId': repeatTemplateId,
    'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
  };

  factory Schedule.fromMap(Map<String, dynamic> map) => Schedule(
    id: map['id'], title: map['title'],
    description: map['description'], location: map['location'],
    dateTime: DateTime.parse(map['dateTime']),
    endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    repeatType: RepeatType.values.firstWhere((e) => e.name == map['repeatType'], orElse: () => RepeatType.none),
    repeatDays: (jsonDecode(map['repeatDays'] as String? ?? '[]') as List).cast<int>(),
    scheduleType: ScheduleType.values.firstWhere((e) => e.name == map['scheduleType'], orElse: () => ScheduleType.general),
    isCourse: (map['isCourse'] ?? 0) == 1,
    courseId: map['courseId'], memo: map['memo'],
    parentId: map['parentId'],
    repeatTemplateId: map['repeatTemplateId'],
    createdAt: DateTime.parse(map['createdAt']), updatedAt: DateTime.parse(map['updatedAt']),
  );

  Schedule copyWith({String? title, String? description, String? location, DateTime? dateTime, DateTime? endTime, RepeatType? repeatType, List<int>? repeatDays, ScheduleType? scheduleType, bool? isCourse, String? courseId, String? memo, String? parentId, String? repeatTemplateId}) => Schedule(
    id: id, title: title ?? this.title, description: description ?? this.description,
    location: location ?? this.location, dateTime: dateTime ?? this.dateTime,
    endTime: endTime ?? this.endTime, repeatType: repeatType ?? this.repeatType,
    repeatDays: repeatDays ?? this.repeatDays, scheduleType: scheduleType ?? this.scheduleType,
    isCourse: isCourse ?? this.isCourse, courseId: courseId ?? this.courseId,
    memo: memo ?? this.memo, parentId: parentId ?? this.parentId,
    repeatTemplateId: repeatTemplateId ?? this.repeatTemplateId,
    createdAt: createdAt, updatedAt: updatedAt,
  );
}

enum RepeatType { none, daily, weekly, custom }

enum ScheduleType { nursery, sports, language, medical, school, general }

// ===== CheckIn 打卡记录 =====
class CheckIn {
  final String id;
  final String scheduleId;
  final DateTime checkInTime;
  final String? notes;

  CheckIn({required this.id, required this.scheduleId, required this.checkInTime, this.notes});

  Map<String, dynamic> toMap() => {'id': id, 'scheduleId': scheduleId, 'checkInTime': checkInTime.toIso8601String(), 'notes': notes};
  
  factory CheckIn.fromMap(Map<String, dynamic> m) => CheckIn(
    id: m['id'], scheduleId: m['scheduleId'],
    checkInTime: DateTime.parse(m['checkInTime']), notes: m['notes'],
  );
}

// ===== Course 课程 =====
class Course {
  final String id;
  final String name;
  final CourseType courseType;
  final double totalHours;
  final double usedHours;
  final String unitName;
  final int color;
  final String? iconData;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id, required this.name, this.courseType = CourseType.other,
    this.totalHours = 0, this.usedHours = 0, this.unitName = '课时',
    this.color = 0xFFE91E63, this.iconData, DateTime? createdAt, DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(), updatedAt = updatedAt ?? DateTime.now();

  double get remainingHours => totalHours - usedHours;
  double get usagePercent => totalHours > 0 ? usedHours / totalHours : 0;

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'courseType': courseType.name,
    'totalHours': totalHours, 'usedHours': usedHours, 'unitName': unitName,
    'color': color, 'iconData': iconData, 'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String()};

  factory Course.fromMap(Map<String, dynamic> m) => Course(
    id: m['id'], name: m['name'],
    courseType: CourseType.values.firstWhere((e) => e.name == m['courseType'], orElse: () => CourseType.other),
    totalHours: (m['totalHours'] ?? 0.0).toDouble(), usedHours: (m['usedHours'] ?? 0.0).toDouble(),
    unitName: m['unitName'] ?? '课时', color: int.parse(m['color'].toString()), iconData: m['iconData'],
    createdAt: DateTime.parse(m['createdAt']), updatedAt: DateTime.parse(m['updatedAt']),
  );
}

enum CourseType { sports, language, other }

// ===== CourseConsumption 课时消耗 =====
class CourseConsumption {
  final String id;
  final String courseId;
  final double consumedAmount;
  final ConsumptionType consumptionType;
  final String? relatedCheckInId;
  final String? note;
  final DateTime createdAt;

  CourseConsumption({
    required this.id, required this.courseId, required this.consumedAmount,
    this.consumptionType = ConsumptionType.auto, this.relatedCheckInId, this.note, DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {'id': id, 'courseId': courseId, 'consumedAmount': consumedAmount,
    'consumptionType': consumptionType.name, 'relatedCheckInId': relatedCheckInId, 'note': note, 'createdAt': createdAt.toIso8601String()};
  factory CourseConsumption.fromMap(Map<String, dynamic> m) => CourseConsumption(
    id: m['id'], courseId: m['courseId'], consumedAmount: (m['consumedAmount'] ?? 0).toDouble(),
    consumptionType: ConsumptionType.values.firstWhere((e) => e.name == m['consumptionType'], orElse: () => ConsumptionType.auto),
    relatedCheckInId: m['relatedCheckInId'], note: m['note'], createdAt: DateTime.parse(m['createdAt']),
  );
}

enum ConsumptionType { auto, manual }

// ===== Memo 备忘录 =====
class Memo {
  final String id;
  final String? title;
  final String content;
  final DateTime? reminderTime;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Memo({required this.id, this.title, required this.content, this.reminderTime, this.isCompleted = false, DateTime? createdAt, DateTime? updatedAt})
    : createdAt = createdAt ?? DateTime.now(), updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'content': content,
    'reminderTime': reminderTime?.toIso8601String(), 'isCompleted': isCompleted ? 1 : 0,
    'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String()};
  factory Memo.fromMap(Map<String, dynamic> m) => Memo(id: m['id'], title: m['title'],
    content: m['content'] ?? '', reminderTime: m['reminderTime'] != null ? DateTime.parse(m['reminderTime']) : null,
    isCompleted: (m['isCompleted'] ?? 0) == 1, createdAt: DateTime.parse(m['createdAt']), updatedAt: DateTime.parse(m['updatedAt']));
}

// ===== MedicalRecord 医疗记录 =====
class MedicalRecord {
  final String id;
  final String? scheduleId;
  final String hospitalName;
  final String doctorName;
  final String diagnosis;
  final String medication;
  final List<String> reportImagePaths;
  final String notes;
  final DateTime visitDate;
  final DateTime createdAt;

  MedicalRecord({
    required this.id, this.scheduleId, this.hospitalName = '', this.doctorName = '',
    this.diagnosis = '', this.medication = '', List<String>? reportImagePaths,
    this.notes = '', required this.visitDate, DateTime? createdAt,
  }) : reportImagePaths = reportImagePaths ?? [], createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {'id': id, 'scheduleId': scheduleId, 'hospitalName': hospitalName,
    'doctorName': doctorName, 'diagnosis': diagnosis, 'medication': medication,
    'reportImagePaths': jsonEncode(reportImagePaths), 'notes': notes,
    'visitDate': visitDate.toIso8601String(), 'createdAt': createdAt.toIso8601String()};
  factory MedicalRecord.fromMap(Map<String, dynamic> m) => MedicalRecord(
    id: m['id'], scheduleId: m['scheduleId'], hospitalName: m['hospitalName'] ?? '',
    doctorName: m['doctorName'] ?? '', diagnosis: m['diagnosis'] ?? '',
    medication: m['medication'] ?? '',
    reportImagePaths: (jsonDecode(m['reportImagePaths'] as String? ?? '[]') as List).cast<String>(),
    notes: m['notes'] ?? '', visitDate: DateTime.parse(m['visitDate']), createdAt: DateTime.parse(m['createdAt']));
}

// ===== GrowthLog 成长日志 =====
class GrowthLog {
  final String id;
  final String title;
  final String content;
  final List<String> imagePaths;
  final List<String> videoPaths;
  final List<String> audioPaths;
  final Mood mood;
  final List<String> tags;
  final String? scheduleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  GrowthLog({
    required this.id, required this.title, this.content = '',
    List<String>? imagePaths, List<String>? videoPaths, List<String>? audioPaths,
    this.mood = Mood.happy, List<String>? tags, this.scheduleId, DateTime? createdAt, DateTime? updatedAt,
  }) : imagePaths = imagePaths ?? [], videoPaths = videoPaths ?? [], audioPaths = audioPaths ?? [],
       tags = tags ?? [], createdAt = createdAt ?? DateTime.now(), updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'content': content,
    'imagePaths': jsonEncode(imagePaths), 'videoPaths': jsonEncode(videoPaths),
    'audioPaths': jsonEncode(audioPaths), 'mood': mood.name, 'tags': jsonEncode(tags),
    'scheduleId': scheduleId, 'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String()};
  factory GrowthLog.fromMap(Map<String, dynamic> m) => GrowthLog(id: m['id'], title: m['title'],
    content: m['content'] ?? '', imagePaths: (jsonDecode(m['imagePaths'] as String? ?? '[]') as List).cast<String>(),
    videoPaths: (jsonDecode(m['videoPaths'] as String? ?? '[]') as List).cast<String>(),
    audioPaths: (jsonDecode(m['audioPaths'] as String? ?? '[]') as List).cast<String>(),
    mood: Mood.values.firstWhere((e) => e.name == m['mood'], orElse: () => Mood.happy),
    tags: (jsonDecode(m['tags'] as String? ?? '[]') as List).cast<String>(), scheduleId: m['scheduleId'],
    createdAt: DateTime.parse(m['createdAt']), updatedAt: DateTime.parse(m['updatedAt']));
}

enum Mood { happy, sad, excited, calm, proud, tired }
