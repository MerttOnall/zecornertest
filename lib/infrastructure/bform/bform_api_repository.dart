import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/auth/advisor_office_scope.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/bform/bform_api_model.dart';
import 'package:zecorner/models/contact/contact_search_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:zecorner/core/config/env_api.dart';

class BformApiRepository {
  final Dio _dio;

  BformApiRepository({required Dio dio}) : _dio = dio;

  /// Form tipine göre doğru endpoint'i seç
  /// formType: 'office', 'advisor', 'sale-request', 'blacklist'
  ///
  /// Web Next proxy → BAMMA:
  /// - get-office-forms.ts → `/form/office` (kara liste: aynı uç + blacklist=true)
  /// - get-advisor-forms.ts → `/form/advisor`
  /// - get-sale-forms.ts → `/form/sale`
  /// Mobil doğrudan BAMMA gateway kullanır.
  String _getEndpointForFormType(String? formType) {
    switch (formType) {
      case 'office':
        return dotenv.env["FAPPLICATION"] ??
            dotenv.env["GET_OFFICE_FORMS"] ??
            "/api/zecorner/form/office";
      case 'advisor':
        return dotenv.env["FADVISOR"] ??
            dotenv.env["GET_ADVISOR_FORMS"] ??
            "/api/zecorner/form/advisor";
      case 'sale-request':
        return dotenv.env["FSALE"] ??
            dotenv.env["GET_SALE_FORMS"] ??
            "/api/zecorner/form/sale";
      case 'blacklist':
        return dotenv.env["FBLACKLIST"] ??
            dotenv.env["FAPPLICATION"] ??
            dotenv.env["GET_OFFICE_FORMS"] ??
            "/api/zecorner/form/office";
      default:
        // Varsayılan olarak kullanıcının rolüne göre endpoint seç
        return dotenv.env["FSALE"] ?? "/api/zecorner/form/sale";
    }
  }

  /// Kullanıcının rolüne göre doğru endpoint'i seç (geriye dönük uyumluluk için)
  /// Web'deki mantığa göre:
  /// - role_form_applications veya role_form_applications_admin -> /form/office
  /// - role_sale_applications veya role_sale_applications_admin -> /form/sale
  /// - role_franchise_sales -> /form/sale
  Future<String> _getEndpointForRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Role kodları StringList olarak kaydediliyor
      final roleCodes = prefs.getStringList('userRoleCodes') ?? [];
      
      print('📋 Kullanıcı rolleri: $roleCodes');
      
      if (roleCodes.isNotEmpty) {
        // Form applications rolü için office endpoint'i kullan (Web'deki gibi)
        if (roleCodes.contains('role_form_applications') || 
            roleCodes.contains('role_form_applications_admin')) {
          print('📋 Form applications endpoint seçildi: /api/zecorner/form/office');
          return dotenv.env["FAPPLICATION"] ?? "/api/zecorner/form/office";
        }
        
        // Sale applications veya franchise sales rolü için sale endpoint'i kullan
        if (roleCodes.contains('role_sale_applications') || 
            roleCodes.contains('role_sale_applications_admin') ||
            roleCodes.contains('role_franchise_sales')) {
          print('📋 Sale applications endpoint seçildi: /api/zecorner/form/sale');
          return dotenv.env["FSALE"] ?? "/api/zecorner/form/sale";
        }
      }
      
      // Varsayılan olarak sale endpoint'i kullan
      print('📋 Varsayılan sale endpoint seçildi: /api/zecorner/form/sale');
      return dotenv.env["FSALE"] ?? "/api/zecorner/form/sale";
    } catch (e) {
      print('⚠️ Endpoint seçiminde hata: $e');
      // Hata durumunda varsayılan endpoint'i kullan
      return dotenv.env["FSALE"] ?? "/api/zecorner/form/sale";
    }
  }

  Future<Either<Failure, BformResponse>> getBforms({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? formType, // 'office', 'advisor', 'sale-request', 'blacklist'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = await AdvisorOfficeScope.load();
      final token = prefs.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: 'JWT token not found.'));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: 'API anahtarları bulunamadı.'));
      }

      final baseUrl = "${EnvApi.origin}";
      // FormType varsa onu kullan, yoksa rol bazlı endpoint seç
      final endpoint = formType != null 
          ? _getEndpointForFormType(formType)
          : await _getEndpointForRole();

      // Advisor ve sale-request formType için web'deki API formatını kullan (searchText, _pageSize)
      // Blacklist için office endpoint'i kullan ama blacklist=true query parametresi ekle
      // Diğer form tipleri için mevcut formatı kullan (search, limit)
      final queryParams = <String, dynamic>{};
      
      if (formType == 'advisor' || formType == 'sale-request') {
        // Web: get-advisor-forms.ts → /form/advisor
        // Web: get-sale-forms.ts → /form/sale
        // Query: paginationProps + type (blacklist yok)
        queryParams['page'] = page;
        queryParams['_pageSize'] = limit;
        queryParams['pageSize'] = limit;

        if (search != null && search.isNotEmpty) {
          queryParams['searchText'] = search;
        }
        if (status != null && status.isNotEmpty && status != 'Tümü') {
          queryParams['type'] = _mapStatusToId(status);
        }
      } else if (formType == 'blacklist') {
        // Blacklist için office endpoint'i kullan ama blacklist=true ekle
        queryParams['page'] = page;
        queryParams['_pageSize'] = limit;
        queryParams['blacklist'] = true; // Kara liste için özel parametre
        
        if (search != null && search.isNotEmpty) {
          queryParams['searchText'] = search;
        }
        // Blacklist API'si type parametresi de alabilir (status için)
        if (status != null && status.isNotEmpty && status != 'Tümü') {
          queryParams['type'] = _mapStatusToId(status);
        }
      } else {
        // Ofis: web get-office-forms.ts ile aynı BAMMA /form/office
        // Mevcut çalışan paramlar korunur, web isimleri yanına eklenir.
        queryParams['page'] = page;
        queryParams['limit'] = limit;
        queryParams['_pageSize'] = limit;

        // Web her istekte blacklist gönderir ("true" / "false")
        if (formType == 'office') {
          queryParams['blacklist'] = 'false';
        }

        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
          queryParams['searchText'] = search;
        }
        if (status != null && status.isNotEmpty && status != 'Tümü') {
          final mapped = _mapStatusToId(status);
          queryParams['status'] = mapped;
          queryParams['type'] = mapped;
        }
      }
      
      // Tarih filtreleri her iki formType için de aynı
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      if (scope.restricted) {
        queryParams['page'] = 1;
        queryParams['limit'] = 500;
        queryParams['_pageSize'] = 500;
      }

      print('🌐 API Endpoint: $baseUrl$endpoint');
      print('📋 Query Params: $queryParams');
      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🔑 API Key: $apiKey');
      print('🔑 App ID: $appId');

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print('📤 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');

      final response = await _dio.get(
        '$baseUrl$endpoint',
        queryParameters: queryParams,
        options: Options(
          headers: headers,
        ),
      );

      print('📥 Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        final parsed = BformResponse.fromJson(response.data);
        if (!scope.restricted) return Right(parsed);
        final ownOffice = parsed.data.where((form) {
          return scope.allows(
            officeId: form.officeId > 0 ? form.officeId : null,
            personId: form.relatedContact,
            officeTitle: form.officeTitle,
          );
        }).toList();
        return Right(
          BformResponse(
            data: ownOffice,
            totalCount: ownOffice.length,
            totalPages: 1,
            page: 1,
          ),
        );
      } else {
        return Left(ServerFailure(
            message: 'Failed to load forms: ${response.statusCode} ${response.data}'));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      print('❌ Request: ${e.requestOptions.uri}');
      return Left(_getErrorMessage(e));
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  Failure _getErrorMessage(DioException e) {
    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data['message'] ?? 'Server error';
      if (statusCode == 401) {
        return AuthFailure(message: message);
      } else if (statusCode == 403) {
        // 403 hatası için özel mesaj
        return AuthFailure(
          message: 'Bu sayfaya erişim izniniz bulunmamaktadır. Lütfen sistem yöneticinizle iletişime geçin.'
        );
      } else {
        return ServerFailure(message: message);
      }
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(message: 'No internet connection.');
    } else {
      return ServerFailure(message: e.message ?? 'An unknown error occurred.');
    }
  }

  /// Status string'ini ID'ye çevir
  String _mapStatusToId(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'arandı':
        return 'called';
      case 'devam ediyor':
        return 'on-going';
      case 'görüşülmedi':
        return 'not-interviewed';
      case 'reddedildi':
      case 'rejected':
        return 'rejected';
      case 'onaylandı':
      case 'approved':
        return 'approved';
      default:
        return statusName.toLowerCase();
    }
  }

  /// Yeni başvuru formu oluştur
  Future<Either<Failure, BformApiModel>> createBform({
    required String name,
    required String surname,
    required String email,
    required String phone,
    String? education,
    String? educationDescription,
    String? profession,
    String? professionDescription,
    int? provinceCode,
    int? districtCode,
    String? formType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: 'JWT token not found.'));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: 'API anahtarları bulunamadı.'));
      }

      final baseUrl = "${EnvApi.origin}";
      // GET ve POST aynı endpoint: /form/office (Postman'da doğrulandı)
      final endpoint = formType != null
          ? _getEndpointForFormType(formType)
          : "/api/zecorner/form/office";

      // BAMMA API formatı (Postman'da TOO_MANY_APPLICATIONS dönen format):
      // eMail (camelCase), education/profession obje olarak
      // e_mail + string formatı 500 veriyor, eMail + obje formatı çalışıyor
      final requestData = <String, dynamic>{
        'name': name,
        'surname': surname,
        'tel': phone,
        'eMail': email, // camelCase - BAMMA API bu formatı kabul ediyor
      };

      if (provinceCode != null) {
        requestData['city'] = provinceCode;
      }
      if (districtCode != null) {
        requestData['district'] = districtCode;
      }
      if (education != null && education.isNotEmpty) {
        // Obje formatı - BAMMA API bu formatı kabul ediyor
        requestData['education'] = {
          'code': education,
          'description': educationDescription ?? '',
        };
      }
      if (profession != null && profession.isNotEmpty) {
        // Obje formatı - BAMMA API bu formatı kabul ediyor
        requestData['profession'] = {
          'code': profession,
          'description': professionDescription ?? '',
        };
      }

      print('🌐 API Endpoint: $baseUrl$endpoint');
      print('📋 Request Data: $requestData');

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // validateStatus: tüm status kodlarını yakala, Dio exception fırlatmasın
      final response = await _dio.post(
        '$baseUrl$endpoint',
        data: requestData,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      print('📥 Response: ${response.statusCode} - ${response.data}');

      // Başarılı (200/201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Başvuru başarıyla oluşturuldu');
        return Right(_buildLocalBform(name, surname, email, phone,
            provinceCode, districtCode, education, educationDescription,
            profession, professionDescription, response.data));
      }

      // TOO_MANY_APPLICATIONS - API çalışıyor ama kullanıcının çok fazla aktif başvurusu var
      if (response.statusCode == 400 &&
          response.data is Map &&
          response.data['code'] == 'TOO_MANY_APPLICATIONS') {
        final msg = response.data['message'] ?? 'En fazla 3 aktif başvurunuz olabilir.';
        print('⚠️ TOO_MANY_APPLICATIONS: $msg');
        return Left(ServerFailure(message: msg.toString()));
      }

      // Diğer hata durumları
      final errorMessage = response.data is Map
          ? (response.data['message'] ?? response.data['error'] ?? 'Sunucu hatası: ${response.statusCode}')
          : 'Sunucu hatası: ${response.statusCode}';
      print('❌ API Hatası: $errorMessage (${response.statusCode})');
      return Left(ServerFailure(message: errorMessage.toString()));
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response != null && e.response!.data is Map) {
        final msg = e.response!.data['message'] ?? 'Sunucu hatası';
        return Left(ServerFailure(message: msg.toString()));
      }
      return Left(_getErrorMessage(e));
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Durum kaydı oluştur (Kaydet).
  /// Web: GET `/api/get-office-form-status/{formId}/?status_type=&contact_type=&related_contact=&...`
  /// → BAMMA `/form/office/status/{formId}`
  /// formId = ofis başvuru id (ör. 1581); related_contact = atanan kişi contact_no (ör. 1036)
  /// Başarı yanıtı: status history `{ data: [...] }` veya form gövdesi (`current_status`, `related_contact`).
  Future<Either<Failure, List<BformStatusHistory>>> createStatusRecord({
    required int formId,
    required String statusType,
    required String contactType,
    int? relatedContact,
    int? rating,
    String? description,
    String? formType,
  }) async {
    try {
      final auth = await _formAuth();
      if (auth == null) {
        return Left(AuthFailure(message: 'JWT token not found.'));
      }

      // Web örneği: status_type=called, contact_type=mail, related_contact=<contact_no>
      // not-interviewed + related_contact → BAMMA "invalid operation"
      var safeContactType = contactType;
      const allowedInterview = {'mail', 'video', 'face-to-face', 'phone'};
      if (!allowedInterview.contains(safeContactType)) {
        safeContactType = 'mail';
      }

      var safeStatusType = statusType.trim().isEmpty ? 'called' : statusType;
      if (relatedContact != null &&
          relatedContact > 0 &&
          safeStatusType == 'not-interviewed') {
        safeStatusType = 'called';
      }

      final queryParams = <String, dynamic>{
        'status_type': safeStatusType,
        'contact_type': safeContactType,
        'date': DateTime.now().toUtc().toIso8601String(),
      };
      if (relatedContact != null && relatedContact > 0) {
        queryParams['related_contact'] = relatedContact;
      }
      if (rating != null) {
        queryParams['rating'] = rating;
      }
      if (description != null && description.isNotEmpty) {
        queryParams['description'] = description;
      }

      // Yazma: önce BAMMA (tek yazım). Web Next yedek — çift istek "invalid operation" üretebiliyor.
      final urls = _statusWriteUrls(formType: formType, formId: formId);
      Failure? lastFailure;
      var attemptedWrite = false;

      for (final url in urls) {
        try {
          final response = await _dio.get(
            url,
            queryParameters: queryParams,
            options: Options(
              headers: auth.headers,
              followRedirects: true,
              maxRedirects: 5,
              validateStatus: (status) =>
                  status != null && (status < 600),
            ),
          );

          // 308/301 sonrası Dio follow etmezse manuel trailing-slash dene
          var effective = response;
          if (response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 307 ||
              response.statusCode == 308) {
            final loc = response.headers.value('location');
            final nextUrl = (loc != null && loc.isNotEmpty)
                ? (loc.startsWith('http') ? loc : '${EnvApi.origin}$loc')
                : (url.endsWith('/') ? url : '$url/');
            effective = await _dio.get(
              nextUrl,
              queryParameters: queryParams,
              options: Options(
                headers: auth.headers,
                validateStatus: (status) => status != null && status < 600,
              ),
            );
          }

          attemptedWrite = true;

          if (_isSuccessfulStatusWrite(effective)) {
            final packed = _packStatusWriteSuccess(
              effective.data,
              formId: formId,
              statusType: safeStatusType,
              contactType: safeContactType,
              relatedContact: relatedContact,
              rating: rating,
              description: description,
            );
            if (packed.isNotEmpty) return Right(packed);

            final verified = await _verifyStatusWrite(
              formId: formId,
              formType: formType,
              relatedContact: relatedContact,
            );
            if (verified != null) return Right(verified);
            return const Right([]);
          }

          if (effective.statusCode == 405 || effective.statusCode == 500) {
            final post = await _dio.post(
              url.endsWith('/') ? url : '$url/',
              queryParameters: queryParams,
              data: queryParams,
              options: Options(
                headers: auth.headers,
                validateStatus: (status) => status != null && status < 600,
              ),
            );
            if (_isSuccessfulStatusWrite(post)) {
              final packed = _packStatusWriteSuccess(
                post.data,
                formId: formId,
                statusType: safeStatusType,
                contactType: safeContactType,
                relatedContact: relatedContact,
                rating: rating,
                description: description,
              );
              if (packed.isNotEmpty) return Right(packed);
              final verified = await _verifyStatusWrite(
                formId: formId,
                formType: formType,
                relatedContact: relatedContact,
              );
              if (verified != null) return Right(verified);
              return const Right([]);
            }
            lastFailure = ServerFailure(message: _messageFromResponse(post));
          } else {
            lastFailure = ServerFailure(message: _messageFromResponse(effective));
          }

          // BAMMA yazdı ama gövde hata gibi / boş olabilir → history ile doğrula
          final verified = await _verifyStatusWrite(
            formId: formId,
            formType: formType,
            relatedContact: relatedContact,
          );
          if (verified != null) return Right(verified);

          // Net iş kuralı hatasıysa diğer URL'lere yazma (çift kayıt / invalid)
          final failMsg = (lastFailure?.message ?? '').toLowerCase();
          if (failMsg.contains('invalid') || failMsg.contains('internal')) {
            break;
          }
        } on DioException catch (e) {
          lastFailure = _statusFailure(e);
        }
      }

      if (attemptedWrite) {
        final verified = await _verifyStatusWrite(
          formId: formId,
          formType: formType,
          relatedContact: relatedContact,
        );
        if (verified != null) return Right(verified);
      }

      return Left(
        lastFailure ??
            ServerFailure(message: 'Durum kaydı oluşturulamadı'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Yazma sonrası history'de atanan kişi görünüyorsa başarı say.
  Future<List<BformStatusHistory>?> _verifyStatusWrite({
    required int formId,
    String? formType,
    int? relatedContact,
  }) async {
    final result = await getFormStatusHistory(
      formId: formId,
      formType: formType,
    );
    return result.fold(
      (_) => null,
      (history) {
        if (history.isEmpty) return null;
        if (relatedContact == null || relatedContact <= 0) return history;
        final hit = history.any((h) => h.relatedContact == relatedContact);
        return hit ? history : null;
      },
    );
  }

  List<BformStatusHistory> _packStatusWriteSuccess(
    dynamic raw, {
    required int formId,
    required String statusType,
    required String contactType,
    int? relatedContact,
    int? rating,
    String? description,
  }) {
    final history = _parseStatusHistoryList(raw);
    if (history.isNotEmpty) return history;

    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    if (map['current_status'] == null && map['related_contact'] == null) {
      return const [];
    }

    int? asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '');
    }

    String? asStr(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return [
      BformStatusHistory(
        id: asInt(map['id']) ?? formId,
        statusType: statusType,
        contactType: contactType,
        relatedContact: relatedContact ?? asInt(map['related_contact']),
        name: asStr(map['rc_name']),
        surname: asStr(map['rc_surname']),
        description: description,
        rating: rating,
        createdAt: DateTime.now(),
        email: asStr(map['related_contact_e_mail']) ?? asStr(map['rc_email']),
        typeDescription: asStr(map['rc_type_description']),
        picture: asStr(map['rc_picture']),
      ),
    ];
  }

  bool _isSuccessfulStatusWrite(Response response) {
    final code = response.statusCode ?? 0;
    if (code == 204) return true;
    if (code != 200 && code != 201) return false;

    final data = response.data;
    if (data == null) return false;
    if (data is List) return data.isNotEmpty;
    if (data is! Map) return true;

    final map = Map<String, dynamic>.from(data);
    if (map.isEmpty) return false;
    if (map['state'] == false) return false;

    final err = (map['error'] ?? '').toString().toLowerCase();
    final msg = (map['message'] ?? '').toString().toLowerCase();
    if (err.contains('internal') ||
        msg.contains('internal server') ||
        err.contains('invalid') ||
        msg.contains('invalid')) {
      return false;
    }

    // Status history: { data: [ { office_form_id, status_type, related_contact, ... } ] }
    if (map['data'] is List && (map['data'] as List).isNotEmpty) return true;
    if (map['status_type'] != null || map['office_form_id'] != null) {
      return true;
    }
    // Form güncellendi: current_status=assigned, related_contact=1036
    if (map['current_status'] != null) return true;
    if (map['related_contact'] != null || map['related_contact_no'] != null) {
      return true;
    }
    if (map['id'] != null &&
        (map['name'] != null || map['e_mail'] != null || map['mail'] != null)) {
      return true;
    }
    return false;
  }

  /// Durum yazma URL'leri — BAMMA önce, Web Next sadece yedek (tek yazım tercihi).
  List<String> _statusWriteUrls({
    required String? formType,
    required int formId,
  }) {
    final urls = <String>[];
    final kind = formType ?? 'office';

    String statusPath;
    switch (kind) {
      case 'advisor':
        statusPath = (dotenv.env['GET_ADVISOR_FORM_STATUS'] ??
                '/api/zecorner/form/advisor/status')
            .trim();
        break;
      case 'sale-request':
        statusPath = (dotenv.env['GET_SALE_FORM_STATUS'] ??
                '/api/zecorner/form/sale/status')
            .trim();
        break;
      default:
        statusPath = (dotenv.env['GET_OFFICE_FORM_STATUS'] ??
                '/api/zecorner/form/office/status')
            .trim();
    }
    urls.add('${EnvApi.origin}$statusPath/$formId');

    final web = EnvApi.webNextApiOrigin;
    if (web != null && web.isNotEmpty) {
      switch (kind) {
        case 'advisor':
          urls.add(
            EnvApi.amplifyStyleTrailingSlash(
              '$web/api/get-advisor-form-status/$formId',
            )!,
          );
          break;
        case 'sale-request':
          urls.add(
            EnvApi.amplifyStyleTrailingSlash(
              '$web/api/get-sale-form-status/$formId',
            )!,
          );
          break;
        default:
          urls.add(
            EnvApi.amplifyStyleTrailingSlash(
              '$web/api/get-office-form-status/$formId',
            )!,
          );
      }
    }

    return urls.toSet().toList();
  }

  /// Web: GET status history / create aynı uç.
  Future<Either<Failure, List<BformStatusHistory>>> getFormStatusHistory({
    required int formId,
    String? formType,
  }) async {
    try {
      final auth = await _formAuth();
      if (auth == null) {
        return Left(AuthFailure(message: 'JWT token not found.'));
      }

      // Önce BAMMA (mobil X-SESSION), sonra Next
      final urls = _statusRecordUrls(formType: formType, formId: formId);
      Failure? lastFailure;

      for (final url in urls) {
        try {
          final response = await _dio.get(
            url,
            queryParameters: const {
              'page': 1,
              'pageSize': 10,
              '_pageSize': 10,
            },
            options: Options(
              headers: auth.headers,
              followRedirects: true,
              maxRedirects: 5,
              validateStatus: (status) => status != null && status < 600,
            ),
          );

          var effective = response;
          if (response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 307 ||
              response.statusCode == 308) {
            final slashUrl = url.endsWith('/') ? url : '$url/';
            effective = await _dio.get(
              slashUrl,
              queryParameters: const {
                'page': 1,
                'pageSize': 10,
                '_pageSize': 10,
              },
              options: Options(
                headers: auth.headers,
                validateStatus: (status) => status != null && status < 600,
              ),
            );
          }

          if (effective.statusCode == 200) {
            return Right(_parseStatusHistoryList(effective.data));
          }
          lastFailure = ServerFailure(message: _messageFromResponse(effective));
        } on DioException catch (e) {
          lastFailure = _statusFailure(e);
        }
      }

      if (lastFailure != null) return Left(lastFailure);
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(message: 'Durum listesi alınamadı: $e'));
    }
  }

  /// Web Next → BAMMA `/form/assignables`
  /// Response: `{ "contacts": [ { contact_no, title, e_mail, type_description, picture, ... } ] }`
  Future<Either<Failure, List<ContactSearchModel>>> searchFormAssignables({
    required String query,
    int pageSize = 50,
    int page = 1,
  }) async {
    try {
      final auth = await _formAuth();
      if (auth == null) {
        return Left(AuthFailure(message: 'JWT token not found.'));
      }

      final urls = _assignablesUrls();
      Failure? lastFailure;

      // getContactsValidation / web: page genelde 1+
      final queryParams = <String, dynamic>{
        'pageSize': pageSize,
        '_pageSize': pageSize,
        'page': page < 1 ? 1 : page,
      };
      if (query.trim().isNotEmpty) {
        queryParams['searchText'] = query.trim();
      }

      for (final url in urls) {
        try {
          final response = await _dio.get(
            url,
            queryParameters: queryParams,
            options: Options(
              headers: auth.headers,
              validateStatus: (status) => status != null && status < 600,
            ),
          );

          if (response.statusCode == 200) {
            var list = _parseContactList(response.data);
            final q = query.trim().toLowerCase();
            if (q.isNotEmpty && list.isNotEmpty) {
              final filtered = list.where((c) {
                return c.title.toLowerCase().contains(q) ||
                    c.email.toLowerCase().contains(q) ||
                    c.typeDescription.toLowerCase().contains(q) ||
                    c.contactNo.toString().contains(q) ||
                    c.title.toLowerCase().split(' ').any((p) => p.startsWith(q));
              }).toList();
              if (filtered.isNotEmpty) list = filtered;
            }
            return Right(list);
          }
          lastFailure = ServerFailure(message: _messageFromResponse(response));
        } on DioException catch (e) {
          lastFailure = _statusFailure(e);
        }
      }

      return Left(
        lastFailure ?? ServerFailure(message: 'Kişi araması başarısız'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Kişi araması başarısız: $e'));
    }
  }

  List<String> _assignablesUrls() {
    final urls = <String>[];
    // Mobil: doğrudan BAMMA (X-SESSION) — web Next boş `{}` dönebiliyor
    final path = (dotenv.env['GET_FORM_ASSIGNABLES'] ??
            '/api/zecorner/form/assignables')
        .trim();
    urls.add('${EnvApi.origin}$path');

    final web = EnvApi.webNextApiOrigin;
    if (web != null && web.isNotEmpty) {
      urls.add(
        EnvApi.amplifyStyleTrailingSlash('$web/api/get-form-assignables')!,
      );
      urls.add('$web/api/get-form-assignables');
    }
    return urls;
  }

  List<String> _statusRecordUrls({
    required String? formType,
    required int formId,
  }) {
    final urls = <String>[];
    final kind = formType ?? 'office';

    // 1) BAMMA önce
    String statusPath;
    switch (kind) {
      case 'advisor':
        statusPath = (dotenv.env['GET_ADVISOR_FORM_STATUS'] ??
                '/api/zecorner/form/advisor/status')
            .trim();
        break;
      case 'sale-request':
        statusPath = (dotenv.env['GET_SALE_FORM_STATUS'] ??
                '/api/zecorner/form/sale/status')
            .trim();
        break;
      default:
        statusPath = (dotenv.env['GET_OFFICE_FORM_STATUS'] ??
                '/api/zecorner/form/office/status')
            .trim();
    }
    urls.add('${EnvApi.origin}$statusPath/$formId');

    final formPath = _getEndpointForFormType(formType).trim();
    urls.add('${EnvApi.origin}$formPath/status/$formId');

    // 2) Web Next yedek
    final web = EnvApi.webNextApiOrigin;
    if (web != null && web.isNotEmpty) {
      switch (kind) {
        case 'advisor':
          urls.add(
            EnvApi.amplifyStyleTrailingSlash(
              '$web/api/get-advisor-form-status/$formId',
            )!,
          );
          break;
        case 'sale-request':
          urls.add(
            EnvApi.amplifyStyleTrailingSlash(
              '$web/api/get-sale-form-status/$formId',
            )!,
          );
          break;
        default:
          urls.add(
            EnvApi.amplifyStyleTrailingSlash(
              '$web/api/get-office-form-status/$formId',
            )!,
          );
          urls.add(
            EnvApi.amplifyStyleTrailingSlash(
              '$web/api/office-form-status/$formId',
            )!,
          );
      }
    }

    return urls.toSet().toList();
  }

  /// Web: GET `/api/get-multiple-contact-info/?no=` → BAMMA `/contact-info?no=`
  Future<Either<Failure, ContactSearchModel?>> getContactInfo(int contactNo) async {
    try {
      final auth = await _formAuth();
      if (auth == null) {
        return Left(AuthFailure(message: 'JWT token not found.'));
      }

      final path =
          dotenv.env['GET_CONTACT_INFO'] ?? '/api/zecorner/contact-info';
      final url = '${auth.baseUrl}$path';

      final response = await _dio.get(
        url,
        queryParameters: {'no': contactNo},
        options: Options(
          headers: auth.headers,
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response.statusCode != 200) {
        return Left(ServerFailure(message: _messageFromResponse(response)));
      }

      final list = _parseContactList(response.data);
      if (list.isEmpty) return const Right(null);
      return Right(list.first);
    } on DioException catch (e) {
      return Left(_statusFailure(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Kişi bilgisi alınamadı: $e'));
    }
  }

  Future<_FormAuth?> _formAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT');
    final apiKey = dotenv.env["X_API_KEY"];
    final appId = dotenv.env["X_APP_ID"];
    if (token == null || apiKey == null || appId == null) return null;
    return _FormAuth(
      baseUrl: EnvApi.origin,
      headers: {
        'X-SESSION': token,
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    );
  }

  String _messageFromResponse(Response response) {
    if (response.data is Map) {
      return (response.data['message'] ??
              response.data['error'] ??
              response.data['DESCRIPTION'] ??
              'Sunucu hatası: ${response.statusCode}')
          .toString();
    }
    if (response.data is String && (response.data as String).trim().isNotEmpty) {
      return (response.data as String).trim();
    }
    return 'Sunucu hatası: ${response.statusCode}';
  }

  Failure _statusFailure(DioException e) {
    if (e.response != null && e.response!.data is Map) {
      final msg = e.response!.data['message'] ??
          e.response!.data['error'] ??
          'Sunucu hatası';
      return ServerFailure(message: msg.toString());
    }
    return _getErrorMessage(e);
  }

  List<BformStatusHistory> _parseStatusHistoryList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is Map && raw.isEmpty) return const [];

    List<dynamic> items = const [];
    if (raw is Map) {
      if (raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw['records'] is List) {
        items = raw['records'] as List;
      } else if (raw['statuses'] is List) {
        items = raw['statuses'] as List;
      } else if (raw['history'] is List) {
        items = raw['history'] as List;
      } else if (raw['results'] is List) {
        items = raw['results'] as List;
      }
    } else if (raw is List) {
      items = raw;
    }

    final out = <BformStatusHistory>[];
    for (final item in items) {
      if (item is! Map) continue;
      try {
        out.add(
          BformStatusHistory.fromJson(Map<String, dynamic>.from(item)),
        );
      } catch (_) {}
    }
    return out;
  }

  List<ContactSearchModel> _parseContactList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is Map && raw.isEmpty) return const [];

    List<dynamic> items = const [];
    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      for (final key in [
        'data',
        'contacts',
        'assignables',
        'results',
        'items',
        'records',
        'users',
      ]) {
        if (raw[key] is List) {
          items = raw[key] as List;
          break;
        }
      }
      if (items.isEmpty &&
          (raw.containsKey('contact_no') ||
              raw.containsKey('no') ||
              raw.containsKey('id') ||
              raw.containsKey('title'))) {
        items = [raw];
      }
    }

    return items
        .whereType<Map>()
        .map((item) => ContactSearchModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((c) => c.contactNo > 0)
        .toList();
  }

  /// Başvuruyu kara listeye ekle/çıkar (blacklist toggle)
  /// BAMMA API: GET /form/office/status/{id}
  /// Web backend: axios.get(`${BAMMA_APP_URL}/form/office/status/${formId}`)
  Future<Either<Failure, bool>> toggleBlacklist({
    required int formId,
    required bool blacklist,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: 'JWT token not found.'));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: 'API anahtarları bulunamadı.'));
      }

      final baseUrl = "${EnvApi.origin}";
      // Web backend: axios.get(`${BAMMA_APP_URL}/form/office/${id}`)
      final url = '$baseUrl/api/zecorner/form/office/$formId';

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
      };

      print('🌐 Blacklist Toggle (http): GET $url');
      print('📋 Headers: $headers');

      // Dio yerine dart http paketi ile doğrudan istek at
      final httpResponse = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 HTTP Response: ${httpResponse.statusCode} - ${httpResponse.body}');

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204) {
        print('✅ Kara liste güncellendi: id=$formId');
        return Right(blacklist);
      }

      // 500 hatası alırsak POST method da dene (aynı URL)
      if (httpResponse.statusCode == 500) {
        print('⚠️ GET 500, POST deneniyor...');
        final postResponse = await http.post(
          Uri.parse(url),
          headers: {
            ...headers,
            'Content-Type': 'application/json',
          },
        );
        print('📥 POST Response: ${postResponse.statusCode} - ${postResponse.body}');

        if (postResponse.statusCode == 200 || postResponse.statusCode == 201 || postResponse.statusCode == 204) {
          print('✅ Kara liste güncellendi (POST): id=$formId');
          return Right(blacklist);
        }
      }

      return Left(ServerFailure(message: 'Sunucu hatası: ${httpResponse.statusCode} - ${httpResponse.body}'));
    } catch (e) {
      print('❌ Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Başarılı response veya TOO_MANY_APPLICATIONS bypass için yerel BformApiModel oluştur
  BformApiModel _buildLocalBform(
    String name, String surname, String email, String phone,
    int? provinceCode, int? districtCode,
    String? education, String? educationDescription,
    String? profession, String? professionDescription,
    dynamic responseData,
  ) {
    // Response body varsa parse etmeyi dene
    if (responseData != null && responseData is Map) {
      try {
        final data = responseData as Map<String, dynamic>;
        final bformData = data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data;
        return BformApiModel.fromJson(bformData);
      } catch (_) {
        // parse başarısızsa aşağıdaki fallback'e düş
      }
    }

    // Response yoksa veya parse edilemezse gönderilen verilerle oluştur
    return BformApiModel(
      id: 0,
      name: name,
      surname: surname,
      mail: email,
      phone: phone,
      createdAt: DateTime.now(),
      currentStatus: 'pending',
      districtText: '',
      city: provinceCode,
      district: districtCode,
      education: education,
      educationDescription: educationDescription,
      profession: profession,
      professionDescription: professionDescription,
    );
  }
}

class _FormAuth {
  const _FormAuth({required this.baseUrl, required this.headers});

  final String baseUrl;
  final Map<String, String> headers;
}
