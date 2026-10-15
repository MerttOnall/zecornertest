import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/auth/advisor_office_scope.dart';
import '../../core/config/env_api.dart';
import '../../core/error/failures.dart';
import '../../core/utils/contact_update_payload.dart'
    show
        applyWebSaveContactAuth,
        contactUpdateRequestUri,
        isContactMutationAckOnly,
        unwrapContactUpdatePayload,
        webSaveContactOrigin;
import '../../core/network/dio_client.dart';
import '../../models/office/office_api_model.dart';

class OfficeApiRepository {
  static final OfficeApiRepository _instance = OfficeApiRepository._internal();
  factory OfficeApiRepository() => _instance;
  OfficeApiRepository._internal();

  final DioClient _client = DioClient();

  /// Liste / oluşturma / toggle: `.env` → `BASE_URL` + `DCONTACTS` veya `CONTACTS` (çoğul `/contacts`).
  static String _contactsCollectionBase() {
    final origin = EnvApi.origin;
    final path = (dotenv.env['DCONTACTS'] ?? dotenv.env['CONTACTS'] ?? '/api/zecorner/contacts').trim();
    final p = path.startsWith('/') ? path : '/$path';
    return '$origin$p';
  }

  // GET - Sayfalama ile ofisleri getir
  Future<Either<Failure, OfficeApiResponse>> getOffices({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    List<int>? types,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token, // Authorization: Bearer yerine X-SESSION kullanıyoruz
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Query parametrelerini oluştur
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': limit,
        'sortOrder': 'asc',
        'sortColumn': 'contact_no',
      };

      if (search != null && search.isNotEmpty) {
        queryParams['searchText'] = search;
      }

      if (status != null && status.isNotEmpty && status != 'Tümü') {
        if (status == 'Aktif') {
          queryParams['status'] = 1;
        } else if (status == 'Pasif') {
          queryParams['status'] = 0;
        }
      }

      // Office tiplerini ekle (101: Zecorner Ofis, 102: Broker Ofis)
      final typesToUse = types ?? [101, 102]; // Varsayılan olarak her iki tipi de ekle
      
      // Dio'da aynı key'i birden fazla kez kullanmak için URL'i manuel olarak oluştur
      final baseUrl = _contactsCollectionBase();
      final queryString = StringBuffer();
      
      // Normal parametreleri ekle
      queryParams.forEach((key, value) {
        if (queryString.isNotEmpty) queryString.write('&');
        queryString.write(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}',
        );
      });
      
      // Types parametrelerini ekle
      for (int type in typesToUse) {
        if (queryString.isNotEmpty) queryString.write('&');
        queryString.write('types=$type');
      }
      
      final fullUrl = '$baseUrl?$queryString';

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');
      print('📋 Query Parameters: $queryParams + types: $typesToUse');
      print('📋 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');

      final response = await _client.dio.get(
        fullUrl,
        options: Options(headers: headers),
      );

      print('✅ API Response Status: ${response.statusCode}');
      print('📦 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // JSON yapısına göre parse et
        final List<dynamic> officesData = data['contacts'] ?? data['data'] ?? [];
        final parsed = officesData.map((json) => OfficeApiModel.fromJson(json)).toList();
        final scope = await AdvisorOfficeScope.load();
        final ownOffices = parsed.where((office) {
          return !scope.isForeignOffice(
            officeId: office.contactNo,
            officeTitle: office.title,
          );
        }).toList();
        final offices = scope.officeTeam && ownOffices.isEmpty ? parsed : ownOffices;
        
        return Right(OfficeApiResponse(
          offices: offices,
          totalCount: data['totalCount'] ?? data['total'] ?? 0,
          totalPages: data['totalPages'] ?? data['total_pages'] ?? 0,
          page: data['page'] ?? page,
        ));
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Ofisler getirilemedi'));
      }
    } on DioException catch (e) {
      print('❌ Office API Error: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'API endpoint bulunamadı'));
      } else {
        return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ Office Repository Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  // GET - ID'ye göre ofis getir
  Future<Either<Failure, OfficeApiModel>> getOfficeById(int officeId) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token, // Authorization: Bearer yerine X-SESSION kullanıyoruz
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        '${_contactsCollectionBase()}/$officeId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final office = OfficeApiModel.fromJson(response.data['data'] ?? response.data);
        return Right(office);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Ofis bulunamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  static String _messageFromResponse(dynamic data) {
    if (data is Map) {
      final desc = data['DESCRIPTION'] ?? data['description'];
      if (desc != null) return desc.toString();
      final m = data['message'] ?? data['error'] ?? data['detail'];
      if (m != null) return m.toString();
    }
    return 'İşlem başarısız';
  }

  static bool _isNotFoundLike(dynamic data) {
    final msg = _messageFromResponse(data).toLowerCase();
    return msg.contains('not found') ||
        msg.contains('endpoint') ||
        msg.contains('bulunamadı');
  }

  Future<Response<dynamic>> _postStatusToggle({
    required String url,
    required Map<String, String> headers,
    required int timeoutMs,
  }) {
    return _client.dio.post(
      url,
      options: Options(
        headers: headers,
        validateStatus: (status) => status != null && status < 600,
        sendTimeout: Duration(milliseconds: timeoutMs),
        receiveTimeout: Duration(milliseconds: timeoutMs),
      ),
    );
  }

  Future<Response<dynamic>> _postSetUserStatus({
    required int officeId,
    required bool nextIsActive,
    required Map<String, String> headers,
    required int timeoutMs,
  }) {
    final setUserStatusEndpoint =
        (dotenv.env["SETUSERSTATUS"] ?? "/api/zecorner/setUserStatus").trim();
    final rawBase = "${EnvApi.origin}${setUserStatusEndpoint.startsWith('/') ? '' : '/'}$setUserStatusEndpoint";
    final endpoint = rawBase.contains('/id')
        ? rawBase.replaceAll('/id', '/$officeId')
        : '$rawBase/$officeId';
    return _client.dio.post(
      endpoint,
      data: {'status': nextIsActive ? 1 : 0},
      options: Options(
        headers: headers,
        validateStatus: (status) => status != null && status < 600,
        sendTimeout: Duration(milliseconds: timeoutMs),
        receiveTimeout: Duration(milliseconds: timeoutMs),
      ),
    );
  }

  /// Sunucu: `POST /contacts/{contactNo}/toggle-status` (contacts_repository / contact_detail_repo ile aynı).
  /// `PUT .../status` yok — "API not found" dönerdi.
  Future<Either<Failure, bool>> toggleOfficeStatus(
    int officeId, {
    required bool currentIsActive,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT') ?? pref.getString('auth_token');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token,
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final primaryResponse = await _postStatusToggle(
        url: '${_contactsCollectionBase()}/$officeId/toggle-status',
        headers: headers,
        timeoutMs: 12000,
      );

      if (primaryResponse.statusCode == 200) {
        return Right(true);
      }

      final shouldTryFallbackToggle = primaryResponse.statusCode == 404 ||
          _isNotFoundLike(primaryResponse.data);
      if (shouldTryFallbackToggle) {
        final fallbackToggleResponse = await _postStatusToggle(
          url: '${EnvApi.origin}/api/zecorner/contacts/$officeId/toggle-status',
          headers: headers,
          timeoutMs: 12000,
        );
        if (fallbackToggleResponse.statusCode == 200) {
          return Right(true);
        }

        final shouldTrySetUserStatus = fallbackToggleResponse.statusCode == 404 ||
            _isNotFoundLike(fallbackToggleResponse.data);
        if (shouldTrySetUserStatus) {
          final setUserStatusResponse = await _postSetUserStatus(
            officeId: officeId,
            nextIsActive: !currentIsActive,
            headers: headers,
            timeoutMs: 12000,
          );
          if (setUserStatusResponse.statusCode == 200) {
            return Right(true);
          }
          return Left(
            ServerFailure(message: _messageFromResponse(setUserStatusResponse.data)),
          );
        }

        return Left(
          ServerFailure(message: _messageFromResponse(fallbackToggleResponse.data)),
        );
      }

      return Left(ServerFailure(message: _messageFromResponse(primaryResponse.data)));
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = e.response?.statusCode;
      if (code == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      }
      return Left(ServerFailure(message: _messageFromResponse(data)));
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Yeni ofis oluştur
  Future<Either<Failure, OfficeApiModel>> createOffice(OfficeApiModel office) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token, // Authorization: Bearer yerine X-SESSION kullanıyoruz
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.post(
        _contactsCollectionBase(),
        data: office.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdOffice = OfficeApiModel.fromJson(response.data['data'] ?? response.data);
        return Right(createdOffice);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Ofis oluşturulamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Ofis güncelle (Contact mantığıyla aynı)
  Future<Either<Failure, OfficeApiModel>> updateOffice(int officeId, OfficeApiModel office) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT') ?? pref.getString('auth_token');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = <String, String>{
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      applyWebSaveContactAuth(headers, token);

      // Debug: Request payload'ı göster (Update için özel JSON metodu kullan)
      final requestData = office.toUpdateJson();
      
      final uri = contactUpdateRequestUri(officeId);

      print('🔄 Update Office Request (ID: $officeId):');
      print('📋 Office Data: $requestData');
      print(
        '📋 POST $uri (${webSaveContactOrigin() != null ? "Next save-contact (web)" : "doğrudan BAMMA"})',
      );

      final response = await _client.dio.postUri(
        uri,
        data: requestData,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Office başarıyla güncellendi (ID: $officeId)');
        final payload = unwrapContactUpdatePayload(response.data);
        if (payload == null) {
          return Left(ServerFailure(message: 'Geçersiz API yanıtı'));
        }
        // Sunucu bazen sadece { code: CONTACT_UPDATED, pk } döner; tam JSON yoktur.
        if (isContactMutationAckOnly(payload)) {
          return Right(office);
        }
        try {
          return Right(OfficeApiModel.fromJson(payload));
        } catch (_) {
          return Right(office);
        }
      }
      print('❌ Office güncellenemedi: ${response.statusCode} — ${response.data}');
      return Left(ServerFailure(message: _messageFromResponse(response.data)));
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Message: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      }
      final errBody = _messageFromResponse(e.response?.data);
      return Left(ServerFailure(
        message: errBody != 'İşlem başarısız' ? errBody : 'Bağlantı hatası: ${e.message}',
      ));
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // DELETE - Ofis sil
  Future<Either<Failure, bool>> deleteOffice(int officeId) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token, // Authorization: Bearer yerine X-SESSION kullanıyoruz
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.delete(
        '${_contactsCollectionBase()}/$officeId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Ofis silinemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }
}
