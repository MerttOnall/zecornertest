import 'package:shared_preferences/shared_preferences.dart';

/// Oturum / kullanıcı verisi anahtarları (Dio ve [LoginRepository] ortak).
/// [LoginRepository] dışındaki katmanlar Dio döngüsüne girmemek için burayı kullanır.
class AuthSessionStorage {
  AuthSessionStorage._();

  static const String keyUserJwt = 'userJWT';
  static const String keyAuthToken = 'auth_token';
  static const String keyAuthPersistSession = 'auth_persist_session';
  static const String keyAuthSessionExpiresMs = 'auth_session_expires_at_ms';
  static const String keyLoginRememberMeDefault = 'login_remember_me_default';

  /// Eski karışık oturumlar bir kez silinir. Bu bayrak çıkışta da silinmez;
  /// sonraki açılışlarda hesap durur.
  static const int currentEpoch = 2;
  static const String keySessionEpoch = 'auth_session_epoch';
  static const String keyOneTimeResetDone = 'auth_one_time_reset_done';

  /// Bellekteki oturum nesli. Çıkış/girişte artar; eski isteğin cevabı
  /// yeni hesabın token ve rol verisinin üstüne yazamaz.
  static int sessionGeneration = 0;

  static Future<void> _writeQueue = Future<void>.value();

  /// Oturum yazıları sırayla gider. Çıkış ile geç gelen profil cevabı iç içe geçmez.
  static Future<T> synchronized<T>(Future<T> Function() action) {
    final result = _writeQueue.then((_) => action());
    _writeQueue = result.then((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static void bumpSessionGeneration() {
    sessionGeneration++;
  }

  static bool isCurrent(int generation) => generation == sessionGeneration;

  /// Karışık eski oturumu yalnız bir kez siler. Bayrak yazıldıktan sonra
  /// uygulama kaç kez açılırsa açılsın kayıtlı hesap durur.
  static Future<void> enforceCurrentEpoch() async {
    await synchronized(() async {
      final pref = await SharedPreferences.getInstance();
      if (pref.getBool(keyOneTimeResetDone) == true) return;
      if (pref.getInt(keySessionEpoch) == currentEpoch) {
        await pref.setBool(keyOneTimeResetDone, true);
        return;
      }
      await clearAuthSessionData();
      await pref.setInt(keySessionEpoch, currentEpoch);
      await pref.setBool(keyOneTimeResetDone, true);
    });
  }

  /// Önceki hesabın anahtarlarını siler ve yeni yazıların kullanacağı nesli döner.
  static Future<int> beginFreshSession() async {
    await clearAuthSessionData();
    return sessionGeneration;
  }

  /// İstek header'ından JWT'yi çıkarır (`X-SESSION` veya `Authorization: Bearer`).
  static String? tokenFromHeaders(Map<String, dynamic> headers) {
    String? bearer;
    String? session;
    for (final entry in headers.entries) {
      final key = entry.key.toString().toLowerCase();
      final value = entry.value?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      if (key == 'x-session') {
        session = value;
      } else if (key == 'authorization') {
        final lower = value.toLowerCase();
        if (lower.startsWith('bearer ')) {
          bearer = value.substring(7).trim();
        }
      }
    }
    if (session != null && session.isNotEmpty) return session;
    if (bearer != null && bearer.isNotEmpty) return bearer;
    return null;
  }

  /// [LoginRepository.clearAuthSessionPreservingAppPrefs] ile aynı anahtarlar.
  static const List<String> authDataKeysToClearOnLogout = [
    keyUserJwt,
    keyAuthToken,
    keyAuthPersistSession,
    keyAuthSessionExpiresMs,
    'userID',
    'userEids',
    'userName',
    'userSurname',
    'userEmail',
    'userPhone',
    'userType',
    'userTypeDescription',
    'roleId',
    'roleCode',
    'userIsAdmin',
    'userPermissions',
    'userRoles',
    'userStatus',
    'companyId',
    'officeId',
    'advisorId',
    'contactType',
    'userRoleCodes',
    'officeTitle',
  ];

  static Future<void> clearAuthSessionData() async {
    bumpSessionGeneration();
    final pref = await SharedPreferences.getInstance();
    for (final k in authDataKeysToClearOnLogout) {
      await pref.remove(k);
    }
  }
}
