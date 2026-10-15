import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:zecorner/core/services/app_reminder_catalog.dart';
import 'package:zecorner/models/notification/p_notification_model.dart'
    show PNotificationModel;
import 'package:zecorner/models/task/task_model.dart';
import 'package:zecorner/router/app_navigator.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Telefon bildirim çubuğu / kilit ekranı için yerel bildirimler.
class LocalDeviceNotificationService {
  LocalDeviceNotificationService._();
  static final LocalDeviceNotificationService instance =
      LocalDeviceNotificationService._();

  static const String _channelApiId = 'zecorner_api_notifications';
  static const String _channelReminderId = 'zecorner_reminders';
  static const String _prefsScheduledTaskIds = 'local_scheduled_task_reminder_ids';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static int _safeApiNotificationId(int apiId) {
    final masked = apiId & 0x7FFFFFFF;
    if (masked >= 2000000000) {
      return 1000000 + (apiId.hashCode & 0x0FFFFFFF);
    }
    return masked;
  }

  /// API bildirim id’leri ile çakışmaması için ayrı aralık (32-bit güvenli).
  static int taskReminderNotificationId(String taskId) {
    const base = 1900000000;
    return base + (taskId.hashCode.abs() % 1000000);
  }

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelApiId,
          'Zecorner Test bildirimleri',
          description: 'Uygulama içi bildirimlerin telefon bildirimi olarak gösterilmesi',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelReminderId,
          'Hatırlatmalar',
          description: 'Görev ve ajanda hatırlatmaları',
          importance: Importance.high,
        ),
      );
      if (!kIsWeb) {
        await Permission.notification.request();
      }
    }

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    if (payload.startsWith('api')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appNavigatorKey.currentState?.pushNamed(AppRouter.profileNotification);
      });
    }
  }

  /// Uygulama bildirim tıklamasıyla mı açıldı?
  Future<NotificationLaunchTarget> consumeAppLaunchRouting() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) {
      return NotificationLaunchTarget.none;
    }
    final payload = details!.notificationResponse?.payload;
    if (payload != null && payload.startsWith('api')) {
      return NotificationLaunchTarget.profileNotifications;
    }
    return NotificationLaunchTarget.none;
  }

  NotificationDetails _apiDetails(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelApiId,
        'Zecorner bildirimleri',
        channelDescription:
            'Uygulama bildirimleriniz',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: body.length > 120
            ? BigTextStyleInformation(body)
            : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
      ),
    );
  }

  NotificationDetails _reminderDetails() {
    return NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelReminderId,
        'Hatırlatmalar',
        channelDescription: 'Görev ve ajanda hatırlatmaları',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
      ),
    );
  }

  String _truncate(String text, int max) {
    final t = text.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1)}…';
  }

  /// API’den gelen bildirimi sistem tepsisinde göster.
  Future<void> showApiNotification(PNotificationModel n) async {
    if (!_initialized) await initialize();
    final id = _safeApiNotificationId(n.id);
    final body = _truncate(
      n.content.isNotEmpty ? n.content : n.title,
      500,
    );
    await _plugin.show(
      id: id,
      title: _truncate(n.title, 80),
      body: _truncate(body, 200),
      notificationDetails: _apiDetails(body),
      payload: 'api|${n.id}',
    );
  }

  /// Belirli bir zamanda tek seferlik hatırlatma (görev bitişi vb.).
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime whenLocal,
  }) async {
    if (!_initialized) await initialize();
    if (!whenLocal.isAfter(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(whenLocal, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: scheduled,
      notificationDetails: _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: _truncate(title, 80),
      body: _truncate(body, 300),
      payload: 'reminder|$id',
    );
  }

  Future<void> cancelNotification(int id) => _plugin.cancel(id: id);

  tz.TZDateTime _nextDailyInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleOneReminder(AppReminderDefinition def) async {
    final details = _reminderDetails();
    final payload = 'nudge|${def.key}';

    if (def.repeatInterval != null) {
      await _plugin.periodicallyShow(
        id: def.notificationId,
        repeatInterval: def.repeatInterval!,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: _truncate(def.title, 80),
        body: _truncate(def.body, 300),
        payload: payload,
      );
      return;
    }

    if (def.repeatEveryHours != null) {
      await _plugin.periodicallyShowWithDuration(
        id: def.notificationId,
        repeatDurationInterval: Duration(hours: def.repeatEveryHours!),
        notificationDetails: details,
        title: _truncate(def.title, 80),
        body: _truncate(def.body, 300),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      return;
    }

    if (def.dailyHour != null) {
      final scheduled = _nextDailyInstance(def.dailyHour!, def.dailyMinute);
      await _plugin.zonedSchedule(
        id: def.notificationId,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: _truncate(def.title, 80),
        body: _truncate(def.body, 300),
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Eski sık hatırlatıcıları kapatır. Üç günlük olan zaten kuruluysa yeniden kurmaz;
  /// her açılışta sayaç sıfırlanmasın.
  Future<void> syncAppRemindersFromPreferences() async {
    if (!_initialized) await initialize();
    final prefs = await SharedPreferences.getInstance();

    for (final id in AppReminderCatalog.retiredNotificationIds) {
      await _plugin.cancel(id: id);
    }

    final pending = await _plugin.pendingNotificationRequests();
    final pendingIds = pending.map((request) => request.id).toSet();

    for (final def in AppReminderCatalog.definitions) {
      final enabled = prefs.getBool(def.prefKey) ?? def.defaultEnabled;
      if (!enabled) {
        await _plugin.cancel(id: def.notificationId);
        continue;
      }
      if (pendingIds.contains(def.notificationId)) continue;
      await _scheduleOneReminder(def);
    }
  }

  /// Çıkışta periyodik hatırlatıcıları durdur.
  Future<void> cancelAllAppReminderSchedules() async {
    if (!_initialized) await initialize();
    for (final id in AppReminderCatalog.retiredNotificationIds) {
      await _plugin.cancel(id: id);
    }
    for (final def in AppReminderCatalog.definitions) {
      await _plugin.cancel(id: def.notificationId);
    }
  }

  /// Tanımlı bir hatırlatıcıyı hemen önizle (tek seferlik).
  Future<void> showReminderPreview(String key) async {
    if (!_initialized) await initialize();
    final def = AppReminderCatalog.byKey(key);
    if (def == null) return;
    final previewId = AppReminderCatalog.previewNotificationIdForKey(key);
    await _plugin.show(
      id: previewId,
      title: _truncate(def.title, 80),
      body: _truncate(def.body, 300),
      notificationDetails: _reminderDetails(),
      payload: 'nudge|preview|$key',
    );
  }

  /// Görev listesine göre bitiş tarihi yaklaşan görevler için hatırlatma planla.
  Future<void> syncTaskDueReminders(List<Task> tasks) async {
    if (!_initialized) await initialize();
    final prefs = await SharedPreferences.getInstance();
    final prev =
        prefs.getStringList(_prefsScheduledTaskIds)?.toSet() ?? <String>{};
    final next = <String>{};
    final now = DateTime.now();

    for (final t in tasks) {
      final due = t.due;
      if (due == null || !due.isAfter(now)) continue;
      if (due.difference(now).inDays > 120) continue;

      final nid = taskReminderNotificationId(t.id);
      next.add('$nid');
      await scheduleReminder(
        id: nid,
        title: 'Görev hatırlatması',
        body: t.title,
        whenLocal: due,
      );
    }

    for (final idStr in prev.difference(next)) {
      final parsed = int.tryParse(idStr);
      if (parsed != null) await cancelNotification(parsed);
    }
    await prefs.setStringList(_prefsScheduledTaskIds, next.toList());
  }
}

enum NotificationLaunchTarget {
  none,
  profileNotifications,
}
