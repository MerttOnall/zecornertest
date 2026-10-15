import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/infrastructure/login/login_repository.dart';
import 'package:zecorner/infrastructure/notification/notification_repository.dart';
import 'package:zecorner/core/services/local_device_notification_service.dart';

/// API’den okunmamış bildirimleri telefon bildirim tepsisine taşır (daha önce gösterilmemişse).
class NotificationTraySyncService {
  NotificationTraySyncService._();
  static final NotificationTraySyncService instance =
      NotificationTraySyncService._();

  static const String _prefsShownIds = 'tray_shown_notification_ids';
  static const int _maxStoredIds = 400;
  static const int _maxPerSync = 12;

  final NotificationRepository _repository = NotificationRepository();

  DateTime? _lastSyncAt;
  static const Duration _minInterval = Duration(seconds: 20);

  /// Aynı anda çok sık API çağrısını engelle.
  Future<void> syncDebounced() async {
    final now = DateTime.now();
    if (_lastSyncAt != null &&
        now.difference(_lastSyncAt!) < _minInterval) {
      return;
    }
    _lastSyncAt = now;
    await syncFromApi();
  }

  Future<void> syncFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginRepository.keyUserJwt);
    if (token == null || token.isEmpty) return;

    final result = await _repository.getNotifications(page: 1, limit: 40);
    await result.fold<Future<void>>(
      (_) async {},
      (response) async {
        var shown = prefs.getStringList(_prefsShownIds) ?? <String>[];
        final shownSet = shown.toSet();

        var shownThisSync = 0;
        for (final n in response.notifications) {
          if (n.isRead) continue;
          final key = '${n.id}';
          if (shownSet.contains(key)) continue;
          if (shownThisSync >= _maxPerSync) break;

          await LocalDeviceNotificationService.instance.showApiNotification(n);
          shownSet.add(key);
          shownThisSync++;
        }

        shown = shownSet.toList();
        if (shown.length > _maxStoredIds) {
          shown = shown.sublist(shown.length - _maxStoredIds);
        }
        await prefs.setStringList(_prefsShownIds, shown);
      },
    );
  }
}
