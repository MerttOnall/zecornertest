import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API origin ve zecorner tabanı — tek kaynak [.env].
///
/// Öncelik: `BASE_URL` → yoksa `BAMMA_URL` (eski projeler) → son çare sabit.
/// `BASE_URL` yalnızca origin olmalı (örn. `http://3.77.159.125`), sonda `/` olmasın.
abstract final class EnvApi {
  EnvApi._();

  static String get origin {
    for (final key in ['BASE_URL', 'BAMMA_URL']) {
      final v = dotenv.env[key]?.trim();
      if (v != null && v.isNotEmpty) {
        return v.replaceAll(RegExp(r'/$'), '');
      }
    }
    return 'http://3.77.159.125';
  }

  /// Çoğu endpoint: `{origin}/api/zecorner`.
  static String get zecornerBase => '$origin/api/zecorner';

  /// Zaten tanımlı upload / web URL’lerinden origin (Amplify = web ile aynı host).
  static String? _originFromExistingEnvUrls() {
    for (final key in ['UPLOAD_API_URL', 'UPLOAD_FILE_API_URL', 'WEB_SAVE_CONTACT_BASE']) {
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

  /// Next.js (Amplify) kökü — **medya** (`UPLOAD_*`, presign, upload API) ve Dio’da aynı host’a HB header.
  ///
  /// Öncelik: `WEB_NEXT_API_ORIGIN` → `UPLOAD_*` origin → `NEXT_PUBLIC_HOST`.
  /// Portföy/ilan **kaydı** her zaman BAMMA [zecornerBase] üzerinden yapılır.
  static String? get webNextApiOrigin {
    final explicit = dotenv.env['WEB_NEXT_API_ORIGIN']?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      final normalized =
          explicit.startsWith('http') ? explicit : 'https://$explicit';
      final u = Uri.tryParse(normalized.replaceAll(RegExp(r'/$'), ''));
      if (u != null &&
          (u.scheme == 'http' || u.scheme == 'https') &&
          u.host.isNotEmpty) {
        return '${u.scheme}://${u.authority}';
      }
    }
    final fromUpload = _originFromExistingEnvUrls();
    if (fromUpload != null) return fromUpload;
    final host = dotenv.env['NEXT_PUBLIC_HOST']?.trim();
    if (host != null && host.isNotEmpty) {
      final normalized = host.startsWith('http') ? host : 'https://$host';
      final u = Uri.tryParse(normalized.replaceAll(RegExp(r'/$'), ''));
      if (u != null &&
          (u.scheme == 'http' || u.scheme == 'https') &&
          u.host.isNotEmpty) {
        return '${u.scheme}://${u.authority}';
      }
    }
    return null;
  }

  /// Amplify/Next: `/api/foo` çoğu deploy’da **`/api/foo/`** olmadan **308** döner.
  /// Tarayıcı yönlendirmeyi sessizce izler; mobil Dio [validateStatus] 200–299 olduğu için 308 hataya düşer.
  static String? amplifyStyleTrailingSlash(String? url) {
    if (url == null || url.isEmpty) return url;
    final u = Uri.tryParse(url.trim());
    if (u == null || (u.scheme != 'http' && u.scheme != 'https')) {
      return url.trim();
    }
    if (u.path.endsWith('/')) return url.trim();
    return u.replace(path: '${u.path}/').toString();
  }

  /// Web ile aynı host: `UPLOAD_FILE_API_URL` veya [webNextApiOrigin] + `/api/upload-file/` (308 önleme).
  static String get webUploadFileAbsoluteUrl {
    final e = dotenv.env['UPLOAD_FILE_API_URL']?.trim();
    if (e != null && e.isNotEmpty) return amplifyStyleTrailingSlash(e)!;
    final o = webNextApiOrigin;
    if (o != null) return amplifyStyleTrailingSlash('$o/api/upload-file')!;
    return amplifyStyleTrailingSlash(
      'https://test.d1cegqpdj9080.amplifyapp.com/api/upload-file',
    )!;
  }

  /// Eğitici videolar liste endpoint'i (Next API). Tercih edilen anahtar:
  /// `TRAINING_VIDEOS_API_URL` (örn: https://.../api/list-s3-videos/).
  static String? get trainingVideosApiUrl {
    final explicit = dotenv.env['TRAINING_VIDEOS_API_URL']?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return amplifyStyleTrailingSlash(explicit);
    }
    return null;
  }

  /// S3 doğrudan kök (bucket herkese açıksa). Kapalı bucket’ta doğrudan URL 403 verir;
  /// Study ekranı önce [webNextApiOrigin]/api/retrieve-file/ kullanır, bu yalnızca yedek.
  /// Örn: `https://hausberry-public.s3.amazonaws.com/`
  static String get trainingVideosPublicBaseUrl {
    final explicit = dotenv.env['TRAINING_VIDEOS_PUBLIC_BASE_URL']?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit.replaceAll(RegExp(r'/*$'), '/') ;
    }
    return 'https://hausberry-public.s3.amazonaws.com/';
  }

  /// `flutter_map` sokak/uydusuz katmanı. OSM bazen ağ/kotala gri kalır; MapTiler vb. için `.env` kullanın.
  /// Örnek: `https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=KEY`
  static String get mapRasterTileUrlTemplate {
    final t = dotenv.env['MAP_RASTER_TILE_URL_TEMPLATE']?.trim();
    if (t != null && t.isNotEmpty) return t;
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// Uydu görüntüsü (isteğe bağlı). Boşsa ArcGIS World Imagery.
  static String get mapRasterSatelliteTileUrlTemplate {
    final t = dotenv.env['MAP_RASTER_SATELLITE_TILE_URL_TEMPLATE']?.trim();
    if (t != null && t.isNotEmpty) return t;
    return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  }

  /// İlan oluşturma: BAMMA `{origin}/api/zecorner/listing` (web ile aynı gateway).
  static String get listingCreateUrl => '$origin/api/zecorner/listing';

  /// Eski mobil yapılandırması; gider ekleme artık [origin] + `/api/zecorner/finance/add-expense` (BAMMA) kullanır.
  @Deprecated('addExpense için EnvApi.origin + FINANCE_ADD_EXPENSE kullanın')
  static String get financeAddExpenseOrigin =>
      _originFromExistingEnvUrls() ?? origin;
}
