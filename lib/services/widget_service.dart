import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/models.dart';

/// P1-7 桥接层：把「今日日程」同步给 iOS 桌面 Widget。
///
/// - 仅在 iOS 生效；其它平台（Android/macOS/Web/单测 VM）全部 no-op，
///   保证不影响既有流程，单测可正常运行。
/// - 与原生 WidgetKit 扩展通过 App Group + 约定的 key 共享数据：
///   * App Group: [appGroupId]
///   * 数据 key: [_kPayloadKey]（今日日程 JSON）、[_kDateKey]（今日日期文案）
///   * Widget kind（iOS）: [iosWidgetName]
class WidgetService {
  WidgetService._();

  /// App Group 标识，需与 iOS Runner / Widget target 的 entitlements 一致。
  static const String appGroupId = 'group.com.qianqian.qianqianGrowthLogbook';

  /// iOS WidgetKit 扩展中的 Widget kind 名称。
  static const String iosWidgetName = 'QianqianWidget';

  static const String _kPayloadKey = 'today_schedules';
  static const String _kDateKey = 'today_date';
  static const String _kCountKey = 'today_count';

  static bool _inited = false;

  /// 是否启用：仅原生 iOS。
  static bool get _enabled {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _ensureInit() async {
    if (_inited) return;
    await HomeWidget.setAppGroupId(appGroupId);
    _inited = true;
  }

  /// 同步今日日程到 Widget 并触发刷新。
  ///
  /// [todaySchedules] 今日（自然日）日程实例；[isChecked] 判断某日程是否已打卡。
  /// 失败仅记录日志，不抛出，避免影响主流程。
  static Future<void> syncTodaySchedules({
    required List<Schedule> todaySchedules,
    required bool Function(String scheduleId) isChecked,
  }) async {
    if (!_enabled) return;
    try {
      await _ensureInit();

      final sorted = [...todaySchedules]
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // 控制条数，避免 Widget 数据过大
      final limited = sorted.take(8).toList();

      final items = limited
          .map((s) => {
                'title': s.title,
                'time':
                    '${s.dateTime.hour.toString().padLeft(2, '0')}:${s.dateTime.minute.toString().padLeft(2, '0')}',
                'icon': s.typeIcon,
                'color': s.color.toARGB32(),
                'checked': isChecked(s.id),
              })
          .toList();

      final now = DateTime.now();
      final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
      final dateLabel =
          '${now.month}月${now.day}日 周${weekdays[now.weekday - 1]}';

      await HomeWidget.saveWidgetData<String>(
          _kPayloadKey, jsonEncode(items));
      await HomeWidget.saveWidgetData<String>(_kDateKey, dateLabel);
      await HomeWidget.saveWidgetData<int>(_kCountKey, sorted.length);

      await HomeWidget.updateWidget(
        iOSName: iosWidgetName,
      );
    } catch (e) {
      debugPrint('WidgetService.syncTodaySchedules failed: $e');
    }
  }
}
