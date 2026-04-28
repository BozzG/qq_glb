import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _keyEnabled = 'notifications_enabled';
  static const String _keyMinutes = 'reminder_minutes';

  bool _initialized = false;
  bool _enabled = true;
  int _reminderMinutes = 15;

  /// 测试模式标志 - 启用时跳过实际通知调度
  bool isTestMode = false;

  bool get enabled => _enabled;
  int get reminderMinutes => _reminderMinutes;

  Future<void> init() async {
    if (_initialized) return;

    // 测试模式：跳过插件初始化
    if (isTestMode) {
      _initialized = true;
      debugPrint('[NotificationService] 测试模式：跳过插件初始化');
      return;
    }

    // 初始化时区
    tzdata.initializeTimeZones();
    // 设置本地时区
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (e) {
      // fallback: 根据系统偏移查找
      final offset = DateTime.now().timeZoneOffset;
      final locations = tz.timeZoneDatabase.locations;
      for (final loc in locations.values) {
        if (loc.currentTimeZone.offset == offset.inMilliseconds) {
          tz.setLocalLocation(loc);
          break;
        }
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // 不在初始化时请求权限，改为用户手动开启时请求
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 加载用户设置
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyEnabled) ?? true;
    _reminderMinutes = prefs.getInt(_keyMinutes) ?? 15;

    _initialized = true;
    debugPrint('[NotificationService] 初始化完成, enabled=$_enabled, minutes=$_reminderMinutes, tz=${tz.local.name}');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] 通知被点击: ${response.payload}');
  }

  /// 请求通知权限（iOS）
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final result = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final result = await android.requestNotificationsPermission();
      return result ?? false;
    }

    return true;
  }

  /// 设置是否启用通知
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);

    if (!value) {
      await cancelAll();
    }
    debugPrint('[NotificationService] 通知开关: $value');
  }

  /// 设置提前提醒分钟数
  Future<void> setReminderMinutes(int minutes) async {
    _reminderMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinutes, minutes);
    debugPrint('[NotificationService] 提前提醒: $minutes 分钟');
  }

  /// 为日程调度通知
  Future<void> scheduleForSchedule(Schedule schedule) async {
    // 测试模式：跳过实际通知调度
    if (isTestMode) {
      debugPrint('[NotificationService] 测试模式：跳过通知调度: ${schedule.title}');
      return;
    }
    
    if (!_enabled) return;

    final notifyTime = schedule.dateTime.subtract(Duration(minutes: _reminderMinutes));

    // 如果通知时间已过，跳过
    if (notifyTime.isBefore(DateTime.now())) {
      debugPrint('[NotificationService] 通知时间已过，跳过: ${schedule.title}');
      return;
    }

    final notificationId = schedule.id.hashCode.abs() % 2147483647;

    await _plugin.zonedSchedule(
      notificationId,
      '${schedule.typeIcon} ${schedule.title}',
      '将在 $_reminderMinutes 分钟后开始${schedule.location != null && schedule.location!.isNotEmpty ? "，地点：${schedule.location}" : ""}',
      tz.TZDateTime.from(notifyTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_reminder',
          '日程提醒',
          channelDescription: '芊芊成长日志的日程提醒通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: _getMatchComponents(schedule.repeatType),
      payload: schedule.id,
    );

    debugPrint('[NotificationService] 已调度通知: ${schedule.title} -> $notifyTime');
  }

  DateTimeComponents? _getMatchComponents(RepeatType repeatType) {
    switch (repeatType) {
      case RepeatType.daily:
        return DateTimeComponents.time;
      case RepeatType.weekly:
      case RepeatType.custom:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatType.none:
        return null;
    }
  }

  /// 取消日程的通知
  Future<void> cancelForSchedule(String scheduleId) async {
    if (isTestMode) {
      debugPrint('[NotificationService] 测试模式：跳过取消通知: $scheduleId');
      return;
    }
    final notificationId = scheduleId.hashCode.abs() % 2147483647;
    await _plugin.cancel(notificationId);
    debugPrint('[NotificationService] 已取消通知: $scheduleId');
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    if (isTestMode) {
      debugPrint('[NotificationService] 测试模式：跳过取消所有通知');
      return;
    }
    await _plugin.cancelAll();
    debugPrint('[NotificationService] 已取消所有通知');
  }

  /// 为所有日程重新调度通知（设置变更时使用）
  Future<void> rescheduleAll(List<Schedule> schedules) async {
    if (isTestMode) {
      debugPrint('[NotificationService] 测试模式：跳过重新调度所有通知');
      return;
    }
    await cancelAll();
    if (!_enabled) return;

    for (final schedule in schedules) {
      await scheduleForSchedule(schedule);
    }
    debugPrint('[NotificationService] 已重新调度 ${schedules.length} 个日程通知');
  }
}
