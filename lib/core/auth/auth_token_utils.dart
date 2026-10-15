import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_session_storage.dart';

/// Dio ile [LoginRepository] arasında paylaşılan token süresi kontrolü (döngüsel import yok).
class AuthTokenUtils {
  AuthTokenUtils._();

  /// JWT `exp` veya kayıtlı [AuthSessionStorage.keyAuthSessionExpiresMs] ile süre dolmuş mu.
  static Future<bool> isAuthTokenExpired(String token) async {
    if (token.isEmpty) return true;
    final pref = await SharedPreferences.getInstance();
    final ms = pref.getInt(AuthSessionStorage.keyAuthSessionExpiresMs);
    final storedDeadlinePassed = ms != null &&
        DateTime.now().millisecondsSinceEpoch >= ms;

    try {
      if (JwtDecoder.isExpired(token)) return true;
    } catch (_) {
      return storedDeadlinePassed || ms == null;
    }

    if (storedDeadlinePassed) return true;
    return false;
  }
}
