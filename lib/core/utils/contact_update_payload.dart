import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/core/config/env_api.dart';

/// Next.js `save-contact` — yalnızca **`USE_WEB_SAVE_CONTACT=true`** iken kullanılır.
///
/// Varsayılan **kapalı**: Next çoğu kurulumda tarayıcı cookie / farklı JWT bekler; mobil `X-SESSION` ile
/// **401 unauthorized** verir. Mobil güncelleme **`BASE_URL` + `PCONTACTS`** (BAMMA) ile çalışır.
///
/// Host: `WEB_SAVE_CONTACT_BASE` → yoksa `UPLOAD_API_URL` / `UPLOAD_FILE_API_URL` origin.
String? webSaveContactOrigin() {
  final enabled = dotenv.env['USE_WEB_SAVE_CONTACT']?.trim().toLowerCase() == 'true';
  if (!enabled) return null;

  final explicit = dotenv.env['WEB_SAVE_CONTACT_BASE']?.trim();
  if (explicit != null && explicit.isNotEmpty) {
    return explicit.replaceAll(RegExp(r'/$'), '');
  }
  for (final key in ['UPLOAD_API_URL', 'UPLOAD_FILE_API_URL']) {
    final raw = dotenv.env[key]?.trim();
    if (raw == null || raw.isEmpty) continue;
    final u = Uri.tryParse(raw);
    if (u != null &&
        (u.scheme == 'http' || u.scheme == 'https') &&
        u.host.isNotEmpty) {
      return u.origin;
    }
  }
  return null;
}

/// Next.js `save-contact` / APIMiddleware genelde **Bearer** bekler; BAMMA doğrudan çağrıda `X-SESSION` yeterli olabilir.
void applyWebSaveContactAuth(Map<String, String> headers, String token) {
  if (webSaveContactOrigin() == null) return;
  headers['Authorization'] = 'Bearer $token';
}

/// Contact güncelleme URL’i:
/// 1) **save-contact** (web ile aynı): `POST {webOrigin}{SAVE_CONTACT_PATH}?type=detail&no={id}`
///    — Next handler `detail ?? {}`, `files` → BAMMA gövdesi.
/// 2) Web kökü çözülemezse: **[EnvApi.origin] + [PCONTACTS] + /{id}** ve `?type=detail`.
Uri contactUpdateRequestUri(
  int contactNo, {
  bool includeTypeDetailQuery = true,
}) {
  final origin = webSaveContactOrigin();
  if (origin != null && origin.isNotEmpty) {
    var path = (dotenv.env['SAVE_CONTACT_PATH'] ?? '/api/save-contact').trim();
    if (!path.startsWith('/')) path = '/$path';
    // Amplify/CloudFront 308: `/api/save-contact` → `/api/save-contact/` (trailing slash). POST’ta redirect takibi sorun çıkarır.
    if (!path.endsWith('/')) path = '$path/';
    return Uri.parse('$origin$path').replace(
      queryParameters: {
        'type': 'detail',
        'no': contactNo.toString(),
      },
    );
  }

  final baseUrl = EnvApi.origin;
  final ep = (dotenv.env['PCONTACTS'] ?? '/api/zecorner/contact').trim();
  final basePath = ep.startsWith('/') ? ep : '/$ep';
  final baseUri = Uri.parse('$baseUrl$basePath/$contactNo');
  if (!includeTypeDetailQuery) return baseUri;
  return baseUri.replace(queryParameters: const {'type': 'detail'});
}

/// POST contact güncelleme yanıtı: `data` veya `result` sarmalayıcıları
Map<String, dynamic>? unwrapContactUpdatePayload(dynamic raw) {
  if (raw is! Map) return null;
  final m = Map<String, dynamic>.from(raw);
  dynamic inner = m['data'] ?? m['result'] ?? m;
  if (inner is! Map) return m;
  var im = Map<String, dynamic>.from(inner);
  if (im['data'] is Map) {
    im = Map<String, dynamic>.from(im['data'] as Map);
  }
  return im;
}

/// Örnek: `{"code":"CONTACT_UPDATED","description":"...","pk":29}` — tam kayıt yok, sadece onay.
bool isContactMutationAckOnly(Map<String, dynamic> p) {
  final c = p['code']?.toString();
  if (c != 'CONTACT_UPDATED' && c != 'CONTACT_CREATED') return false;
  return !p.containsKey('contact_no');
}
