import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/auth/auth_session_storage.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/network/dio_client.dart';
import 'package:zecorner/infrastructure/myoffice/myoffice_api_repository.dart';
import 'package:zecorner/infrastructure/office/office_api_repository.dart';
import 'package:zecorner/models/users/user_profile_model.dart';
import 'package:zecorner/services/user_profile_service.dart';

/// GTB EIDS Taşınmaz yanıtındaki `data` alanı.
///
/// Örnek:
/// ```json
/// { "il": "MUĞLA", "ilce": "MARMARİS", "mahalle": "SÖĞÜT M",
///   "ada": "296", "parsel": "88", "ilanSuresi": "2026-12-31T00:00:00" }
/// ```
class EidsTasinmazData {
  final String? il;
  final String? ilce;
  final String? mahalle;
  final String? ada;
  final String? parsel;
  final DateTime? ilanSuresi;
  final Map<String, dynamic> raw;

  const EidsTasinmazData({
    this.il,
    this.ilce,
    this.mahalle,
    this.ada,
    this.parsel,
    this.ilanSuresi,
    this.raw = const {},
  });

  factory EidsTasinmazData.fromMap(Map<String, dynamic> map) {
    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    DateTime? date(dynamic v) {
      final s = str(v);
      if (s == null) return null;
      return DateTime.tryParse(s);
    }

    return EidsTasinmazData(
      il: str(map['il']),
      ilce: str(map['ilce']),
      mahalle: str(map['mahalle']),
      ada: str(map['ada']),
      parsel: str(map['parsel']),
      ilanSuresi: date(map['ilanSuresi']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  /// `ilanSuresi` geçmişse EIDS yetkisi süresi dolmuş demektir.
  bool get isExpired {
    final d = ilanSuresi;
    if (d == null) return false;
    final today = DateTime.now();
    final endOfDay = DateTime(d.year, d.month, d.day, 23, 59, 59);
    return endOfDay.isBefore(today);
  }

  /// "MUĞLA / MARMARİS / SÖĞÜT M · Ada 296 Parsel 88"
  String get summary {
    final loc = [il, ilce, mahalle]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join(' / ');
    final adaParsel = [
      if (ada != null) 'Ada $ada',
      if (parsel != null) 'Parsel $parsel',
    ].join(' ');
    return [loc, adaParsel].where((e) => e.isNotEmpty).join(' · ');
  }
}

class _VergiNoCandidate {
  final String vergiNo;
  final String source;
  const _VergiNoCandidate(this.vergiNo, this.source);
}

class EidsVerificationResult {
  /// Web proxy ile aynı: `{ ok: true, data }` veya `{ ok: false, message }`.
  final bool ok;
  final String? message;

  /// GTB `data` ham haritası (geriye dönük uyumluluk için korunuyor).
  final Map<String, dynamic>? data;

  /// Tiplenmiş `data`.
  final EidsTasinmazData? tasinmaz;

  /// GTB `errors` içindeki okunabilir açıklama (örn. "Taşınmaza ait
  /// yetkilendirme bilgisi bulunmadı."). Kullanıcıya ek bilgi olarak gösterilir.
  final String? detail;

  const EidsVerificationResult({
    required this.ok,
    this.message,
    this.data,
    this.tasinmaz,
    this.detail,
  });
}

/// GTB EIDS Taşınmaz doğrulaması — web `pages/api/eids-validate-tasinmaz.ts`
/// ile birebir aynı istek:
///
/// ```json
/// { "FirmaKod": "...", "Kullanicikodu": "<getUserInfo.eids>",
///   "VergiNo": "<ofis tax_no>", "TasinmazId": 137857839 }
/// ```
///
/// Web akışı (Network): `get-user-info` → `get-contact?no=<connected_contact>`
/// → `eids-validate-tasinmaz`. Mobil de aynı sırayı izler.
class EidsVerificationService {
  static const _defaultGtbUrl = 'https://ws.gtb.gov.tr:8443/EidsTasinmazAPI';
  static const _noAuthMessage = 'EIDS yetkiniz yok';

  final Dio _gtbDio;
  final OfficeApiRepository _officeApiRepository;
  final MyOfficeApiRepository _myOfficeApiRepository;
  final UserProfileService _userProfileService;

  EidsVerificationService({
    Dio? gtbDio,
    OfficeApiRepository? officeApiRepository,
    MyOfficeApiRepository? myOfficeApiRepository,
    UserProfileService? userProfileService,
  })  : _gtbDio = gtbDio ?? _createGtbDio(),
        _officeApiRepository = officeApiRepository ?? OfficeApiRepository(),
        _myOfficeApiRepository =
            myOfficeApiRepository ?? MyOfficeApiRepository(dio: DioClient().dio),
        _userProfileService = userProfileService ?? UserProfileService();

  /// GTB EIDS — BAMMA interceptor'ları olmadan, Basic Auth ile.
  static Dio _createGtbDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Web: validateStatus: () => true — 400/401 de yanıt olarak işlenir.
        validateStatus: (_) => true,
      ),
    );
    // DioClient.attachInspector(dio); // API debug — geri açmak için yorumu kaldır
    return dio;
  }

  Future<Either<Failure, EidsVerificationResult>> verifyTasinmaz({
    required String tasinmazIdRaw,
  }) async {
    try {
      // 1) Taşınmaz no — ağ çağrısı yapmadan önce doğrula.
      final tasinmazId =
          int.tryParse(tasinmazIdRaw.replaceAll(RegExp(r'\D'), ''));
      if (tasinmazId == null || tasinmazId <= 0) {
        return const Left(
          ValidationFailure(
            message:
                'EIDS doğrulaması için geçerli bir taşınmaz numarası giriniz.',
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final generation = AuthSessionStorage.sessionGeneration;

      // 2) get-user-info — tek sefer çek, hem Kullanicikodu hem ofis için kullan.
      final profile = await _loadProfile();
      if (!AuthSessionStorage.isCurrent(generation)) {
        return const Left(AuthFailure(message: 'Oturum değişti.'));
      }

      final kullanicikodu =
          await _resolveKullanicikodu(prefs, profile, generation);
      if (kullanicikodu == null || kullanicikodu.isEmpty) {
        return const Left(
          ValidationFailure(message: 'Sizin EIDS\'niz bulunmamakta.'),
        );
      }

      // 3) VergiNo adayları — EİDS'de hangi VKN'nin kayıtlı olduğunu yalnızca
      //    GTB bilir: bağlı ofis → kişinin kendi VKN'si → myOffice sırasıyla denenir.
      final vergiNoCandidates = await _collectVergiNoCandidates(prefs, profile);
      if (vergiNoCandidates.isEmpty) {
        return const Left(
          ValidationFailure(
            message:
                'Vergi numarası bulunamadı. EIDS doğrulaması için ofis/işletme vergi numarası gerekli.',
          ),
        );
      }

      final endpoint = _resolveGtbEndpoint();
      final firmaKod = _resolveFirmaKod();
      if (firmaKod == null || firmaKod.isEmpty) {
        return const Left(
          ServerFailure(message: 'EIDS_FIRMA_KOD yapılandırması eksik.'),
        );
      }

      final gtbAuth = _resolveGtbBasicAuth();
      if (gtbAuth == null) {
        return const Left(
          ServerFailure(
            message: 'EIDS GTB kimlik bilgileri yapılandırması eksik.',
          ),
        );
      }

      final authHeader =
          'Basic ${base64Encode(utf8.encode('${gtbAuth.$1}:${gtbAuth.$2}'))}';

      EidsVerificationResult? lastResult;
      for (final candidate in vergiNoCandidates) {
        final requestBody = {
          'FirmaKod': firmaKod,
          'Kullanicikodu': kullanicikodu,
          'VergiNo': candidate.vergiNo,
          'TasinmazId': tasinmazId,
        };

        if (kDebugMode) {
          debugPrint('🔎 GTB EIDS POST $endpoint [${candidate.source}]');
          debugPrint('🔎 GTB EIDS body: ${jsonEncode(requestBody)}');
        }

        Response response;
        try {
          response = await _gtbDio.post(
            endpoint,
            data: requestBody,
            options: Options(headers: {'Authorization': authHeader}),
          );
        } on DioException catch (e) {
          // Web: axios hatası + HTTP status → { ok:false, "EIDS yetkiniz yok" }
          final res = e.response;
          if (res?.statusCode != null) {
            response = res!;
          } else {
            final isTimeout = e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout;
            return Left(
              NetworkFailure(
                message: isTimeout
                    ? 'EIDS sunucusu zaman aşımına uğradı. Lütfen tekrar deneyin.'
                    : 'EIDS sunucusuna ulaşılamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
              ),
            );
          }
        }

        if (kDebugMode) {
          debugPrint(
            '🔎 GTB EIDS ${response.statusCode} [${candidate.source}]: ${response.data}',
          );
        }

        final result = _parseGtbResponse(response);
        if (result.ok) return Right(result);
        lastResult = result;

        // Sunucu/altyapı hatasında (5xx, 401 Basic Auth) başka VKN denemek anlamsız.
        final status = response.statusCode ?? 0;
        if (status == 401 || status == 403 || status >= 500) break;
      }

      return Right(
        lastResult ??
            const EidsVerificationResult(ok: false, message: _noAuthMessage),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'EIDS doğrulama hatası: $e'));
    }
  }

  /// Web proxy mantığı:
  /// `httpOk = status === 200`, `businessOk = body.statusCode === 200 && body.data`
  /// → ok:true + data; aksi halde ok:false "EIDS yetkiniz yok".
  EidsVerificationResult _parseGtbResponse(Response response) {
    final payload = _asStringKeyMap(response.data);
    final httpOk = response.statusCode == 200;
    final businessStatus = _asInt(payload?['statusCode']);
    final data = _asStringKeyMap(payload?['data']);
    final businessOk = businessStatus == 200 && data != null;

    if (httpOk && businessOk) {
      return EidsVerificationResult(
        ok: true,
        data: data,
        tasinmaz: EidsTasinmazData.fromMap(data),
      );
    }

    // GTB 400 örneği:
    // {"data":null,"statusCode":400,
    //  "errors":["Taşınmaza ait yetkilendirme bilgisi bulunmadı.","ERR-004"]}
    return EidsVerificationResult(
      ok: false,
      message: _noAuthMessage,
      detail: _readableErrors(payload?['errors']),
    );
  }

  /// `errors` listesinden "ERR-004" gibi kodları ayıklayıp okunabilir metni döndürür.
  String? _readableErrors(dynamic errors) {
    Iterable<String> items;
    if (errors is List) {
      items = errors.where((e) => e != null).map((e) => e.toString());
    } else if (errors is String) {
      items = [errors];
    } else if (errors is Map) {
      items = errors.values.where((e) => e != null).map((e) => e.toString());
    } else {
      return null;
    }
    final codeRe = RegExp(r'^[A-Z]{2,5}-?\d{1,4}$');
    final readable = items
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !codeRe.hasMatch(e))
        .toList();
    if (readable.isEmpty) return null;
    return readable.join('\n');
  }

  Future<UserProfileModel?> _loadProfile() async {
    try {
      return await _userProfileService.getUserInfo();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ EIDS getUserInfo başarısız: $e');
      return null;
    }
  }

  /// getUserInfo → `eids` alanı (contact_no değil). Başarısızsa prefs.
  Future<String?> _resolveKullanicikodu(
    SharedPreferences prefs,
    UserProfileModel? profile,
    int generation,
  ) async {
    final fromProfile = profile?.eids?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) {
      await AuthSessionStorage.synchronized(() async {
        if (!AuthSessionStorage.isCurrent(generation)) return;
        await prefs.setString('userEids', fromProfile);
      });
      if (!AuthSessionStorage.isCurrent(generation)) return null;
      return fromProfile;
    }
    // Profil `eids` boşsa kişinin EIDS kaydı yoktur; prefs yalnızca
    // getUserInfo'ya ulaşılamadığında yedek olarak kullanılır.
    if (profile != null) return null;
    return prefs.getString('userEids')?.trim();
  }

  /// Denenecek VKN adayları (sıralı, tekilleştirilmiş):
  /// 1) bağlı ofis (`get-contact?no=connected_contact` → tax_no) — web ile aynı
  /// 2) kişinin kendi `tax_no`'su (EİDS kaydı şahıs işletmesine açılmış olabilir)
  /// 3) myOffice tax_no
  Future<List<_VergiNoCandidate>> _collectVergiNoCandidates(
    SharedPreferences prefs,
    UserProfileModel? profile,
  ) async {
    final out = <_VergiNoCandidate>[];
    final seen = <String>{};

    void add(String? raw, String source) {
      if (raw == null) return;
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return;
      if (seen.add(digits)) out.add(_VergiNoCandidate(digits, source));
    }

    // 1) Bağlı ofis kaydı
    final officeContactNo = _resolveOfficeContactNo(prefs, profile);
    if (officeContactNo != null && officeContactNo > 0) {
      final officeRes =
          await _officeApiRepository.getOfficeById(officeContactNo);
      officeRes.fold(
        (f) {
          if (kDebugMode) {
            debugPrint('⚠️ EIDS ofis($officeContactNo) alınamadı: ${f.message}');
          }
        },
        (office) => add(office.taxNo, 'ofis#$officeContactNo'),
      );
    }

    // 2) Kişinin kendi vergi no'su
    add(profile?.taxNo, 'profil.tax_no');

    // 3) myOffice
    final myOfficeRes = await _myOfficeApiRepository.getMyOffice();
    myOfficeRes.fold(
      (_) {},
      (office) => add(office.taxNo, 'myOffice#${office.contactNo}'),
    );

    if (kDebugMode) {
      debugPrint(
        '🔎 EIDS VergiNo adayları: ${out.map((c) => '${c.source}=${c.vergiNo}').join(', ')}',
      );
    }
    return out;
  }

  int? _resolveOfficeContactNo(
    SharedPreferences prefs,
    UserProfileModel? profile,
  ) {
    if (profile != null) {
      final fromProfile = _officeContactNoFromProfile(profile);
      if (fromProfile != null) return fromProfile;
    }

    final fromInt = prefs.getInt('officeId');
    if (fromInt != null && fromInt > 0) return fromInt;

    final fromString = prefs.getString('officeId')?.trim();
    if (fromString != null && fromString.isNotEmpty) {
      final parsed = int.tryParse(fromString);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  int? _officeContactNoFromProfile(UserProfileModel profile) {
    if (profile.connectedContact > 0) {
      return profile.connectedContact;
    }

    if ((profile.isAgency || profile.isCompany) && profile.contactNo > 0) {
      return profile.contactNo;
    }

    return null;
  }

  String _resolveGtbEndpoint() {
    final fromEnv = dotenv.env['EIDS_TASINMAZ_API_URL']?.trim() ??
        dotenv.env['EIDS_TASINMAZ_VERIFY_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv.replaceAll(RegExp(r'/+$'), '');
    }
    return _defaultGtbUrl;
  }

  String? _resolveFirmaKod() {
    final fromEnv = dotenv.env['EIDS_FIRMA_KOD']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return '6de42143-707c-4b67-814c-c0b4559cd317';
  }

  (String, String)? _resolveGtbBasicAuth() {
    final user = dotenv.env['EIDS_GTB_USER']?.trim();
    final pass = dotenv.env['EIDS_GTB_PASSWORD']?.trim();
    if (user != null && user.isNotEmpty && pass != null && pass.isNotEmpty) {
      return (user, pass);
    }
    return ('EidsZerenUser', 'Gj7x63M.X7U!');
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  Map<String, dynamic>? _asStringKeyMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }
    return null;
  }
}
