import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Kullanıcının açıp kapatabileceği yerel hatırlatıcı tanımları.
class AppReminderDefinition {
  const AppReminderDefinition({
    required this.key,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.scheduleLabel,
    required this.defaultEnabled,
    this.repeatInterval,
    this.repeatEveryHours,
    this.dailyHour,
    this.dailyMinute = 0,
  }) : assert(
          (repeatInterval != null ? 1 : 0) +
                  (repeatEveryHours != null ? 1 : 0) +
                  (dailyHour != null ? 1 : 0) ==
              1,
          'Tam bir zamanlama türü seçilmeli',
        );

  final String key;
  final int notificationId;
  final String title;
  final String body;

  /// Ayar ekranında gösterilen kısa açıklama (örn. "Her saat").
  final String scheduleLabel;
  final bool defaultEnabled;

  final RepeatInterval? repeatInterval;
  final int? repeatEveryHours;
  final int? dailyHour;
  final int dailyMinute;

  String get prefKey => '${AppReminderCatalog.prefPrefix}$key';
}

class AppReminderCatalog {
  AppReminderCatalog._();

  static const String prefPrefix = 'app_reminder_enabled_';

  /// Önizleme için tek seferlik id (tanımlı hatırlatıcı id’leriyle çakışmaz).
  static int previewNotificationIdForKey(String key) {
    return 1980000000 + (key.hashCode.abs() % 999999);
  }

  /// Daha önce saatlik / günlük basılan hatırlatıcılar. Açılışta iptal edilir.
  static const List<int> retiredNotificationIds = [
    1999999901,
    1999999903,
    1999999904,
    1999999905,
    1999999906,
  ];

  static const List<AppReminderDefinition> definitions = [
    AppReminderDefinition(
      key: 'transactions_check',
      notificationId: 1999999910,
      title: 'Zecorner Test',
      body: 'İşlemlerinizi yaptınız mı?',
      scheduleLabel: '3 günde bir',
      defaultEnabled: true,
      repeatEveryHours: 72,
    ),
  ];

  static AppReminderDefinition? byKey(String key) {
    for (final d in definitions) {
      if (d.key == key) return d;
    }
    return null;
  }
}
