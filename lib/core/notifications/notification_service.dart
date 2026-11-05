import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/appointments/data/appointment_model.dart';
import '../formatting/arabic_plural.dart';
import '../formatting/date_formatter.dart';

/// حالة إذن الإشعارات من النظام.
enum NotificationPermission { granted, denied, unknown }

/// الإشعارات المحلية للتذكير بالمواعيد (القسم 9).
///
/// معرّف الإشعار هو معرّف الموعد نفسه، فيمكن تحديثه أو إلغاؤه دائماً.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  var _initialized = false;

  static const _channelId = 'appointment_reminders';
  static const _channelName = 'تذكير المواعيد';
  static const _channelDescription = 'تنبيه قبل موعدك في الوقت الذي تختاره';

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_initialized || !_supported) return;
    tz_data.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      // منطقة غير معروفة لقاعدة timezone: نستخدم فرق التوقيت الحالي للجهاز.
      tz.setLocalLocation(_fixedOffsetLocation());
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        // الإذن يُطلب لاحقاً في الوقت المناسب وليس عند الفتح الأول.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  tz.Location _fixedOffsetLocation() {
    final offset = DateTime.now().timeZoneOffset;
    return tz.Location('Local', [tz.minTime], [0], [
      tz.TimeZone(offset, isDst: false, abbreviation: 'LOCAL'),
    ]);
  }

  /// يطلب الإذن من المستخدم. يعيد `true` إن أصبح مسموحاً.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  Future<NotificationPermission> permissionStatus() async {
    if (!_supported) return NotificationPermission.unknown;
    await initialize();
    final bool? enabled;
    if (defaultTargetPlatform == TargetPlatform.android) {
      enabled = await _android?.areNotificationsEnabled();
    } else {
      enabled = (await _ios?.checkPermissions())?.isEnabled;
    }
    return switch (enabled) {
      true => NotificationPermission.granted,
      false => NotificationPermission.denied,
      null => NotificationPermission.unknown,
    };
  }

  Future<void> openSystemSettings() async {
    if (!_supported) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _android?.openAppNotificationSettings();
    } else {
      await _ios?.openAppNotificationSettings();
    }
  }

  /// هل يسمح النظام بالتنبيهات الدقيقة (Android فقط)؟
  Future<bool> canScheduleExact() async {
    if (!_supported || defaultTargetPlatform != TargetPlatform.android) return true;
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  /// يفتح شاشة النظام لمنح «المنبهات والتذكيرات» (Android 12+).
  Future<bool> requestExactAlarms() async {
    if (!_supported || defaultTargetPlatform != TargetPlatform.android) return true;
    return await _android?.requestExactAlarmsPermission() ?? false;
  }

  /// يجدول تذكير الموعد، ويستبدل أي إشعار سابق بالمعرّف نفسه.
  ///
  /// لا يُنشأ إشعار لموعد مكتمل أو بلا تذكير. إن فات وقت التنبيه والموعد
  /// لم يبدأ بعد، يُنبَّه عند بدء الموعد.
  Future<void> schedule(Appointment appointment) async {
    if (!_supported) return;
    await initialize();
    final id = appointment.notificationId ?? appointment.id;
    if (id == null) return;
    await _plugin.cancel(id: id);

    final remindAt = appointment.remindAt;
    if (appointment.isCompleted || remindAt == null) return;
    final now = DateTime.now();
    final fireAt = remindAt.isAfter(now) ? remindAt : appointment.startAt;
    if (!fireAt.isAfter(now)) return;

    final exact = await canScheduleExact();
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      title: appointment.title,
      body: _body(appointment, fireAt),
      payload: '${appointment.id}',
      androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          color: Color(0xFF246BFE),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBanner: true),
      ),
    );
  }

  String _body(Appointment a, DateTime fireAt) {
    final when = '${DateFormatter.relativeDay(a.startAt)} الساعة ${DateFormatter.time(a.startAt)}';
    final minutesLeft = a.startAt.difference(fireAt).inMinutes;
    if (minutesLeft <= 0) return 'حان موعدك الآن · $when';
    return 'يبدأ بعد ${ArabicPlural.minutes(minutesLeft)} · $when';
  }

  Future<void> cancel(int id) async {
    if (!_supported) return;
    await initialize();
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    if (!_supported) return;
    await initialize();
    await _plugin.cancelAllPendingNotifications();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
