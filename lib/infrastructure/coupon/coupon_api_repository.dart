import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/mixins/update_mixin.dart';
import '../../models/coupon/coupon_model.dart';
import '../../models/coupon/coupon_template_model.dart';
import 'package:zecorner/core/config/env_api.dart';

/// Coupon API Repository
/// Endpoint: GET /api/zecorner/pay/coupons
class CouponApiRepository with UpdateMixin {
  static final CouponApiRepository _instance = CouponApiRepository._internal();
  factory CouponApiRepository() => _instance;
  CouponApiRepository._internal();

  final DioClient _client = DioClient();
  
  @override
  DioClient get dioClient => _client;

  /// Kuponları getir
  /// [page] - Sayfa numarası (default: 1)
  /// [limit] - Sayfa başına kayıt sayısı (default: 20)
  /// [status] - Filtre: 1 (aktif), 0 (pasif)
  /// [type] - Filtre: FREE, DISCOUNT
  /// [search] - Arama terimi
  /// [all] - Tüm kuponları getir (default: true)
  Future<Either<Failure, CouponResponse>> getCoupons({
    int page = 1,
    int limit = 20,
    int? status,
    String? type,
    String? search,
    bool all = true,
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': limit, // Web'de pageSize kullanılıyor
      };

      // All parametresi - tüm kuponları getir
      if (all) {
        queryParams['all'] = 'true';
      }

      // Status filtresi
      if (status != null) {
        queryParams['status'] = status;
      }

      // Type filtresi
      if (type != null && type.isNotEmpty && type != 'Tümü') {
        queryParams['type'] = type;
      }

      // Arama
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final endpoint = dotenv.env["COUPONS"] ?? "/api/zecorner/pay/coupons";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint";

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');
      print('📋 Query Parameters: $queryParams');

      final response = await dioClient.dio.get(
        fullUrl,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Raw Data Type: ${response.data.runtimeType}');
      print('📥 Raw Data: ${response.data}');

      if (response.statusCode == 200) {
        try {
          // Response data'yı kontrol et
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            print('📋 Response Keys: ${data.keys.toList()}');
            print('📋 Coupons Type: ${data['coupons']?.runtimeType}');
            print('📋 Coupons Count: ${(data['coupons'] as List?)?.length ?? 0}');
          }
          
          final couponResponse = CouponResponse.fromJson(response.data);
          print('🎫 Parsed ${couponResponse.coupons.length} coupons');
          print('📊 Total: ${couponResponse.totalCount}, Pages: ${couponResponse.totalPages}, Page: ${couponResponse.page}');
          
          if (couponResponse.coupons.isEmpty) {
            print('⚠️ WARNING: Kupon listesi boş!');
          }
          
          return Right(couponResponse);
        } catch (e, stackTrace) {
          print('❌ Parse Error: $e');
          print('❌ StackTrace: $stackTrace');
          print('❌ Response Data: ${response.data}');
          return Left(ServerFailure(message: 'Veri parse edilemedi: $e'));
        }
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Sunucu hatası oluştu',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz yok."));
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Left(NetworkFailure(message: "Bağlantı zaman aşımına uğradı."));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(NetworkFailure(message: "İnternet bağlantınızı kontrol edin."));
      }

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Kupon şablonlarını getir (dropdown için basit format)
  Future<Either<Failure, List<Map<String, dynamic>>>> getCouponTemplates() async {
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final endpoint = dotenv.env["COUPON_TEMPLATES"] ?? "/api/zecorner/pay/coupon-templates";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint";

      print('🌐 Coupon Templates API: $fullUrl');

      final response = await dioClient.dio.get(
        fullUrl,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> templates = response.data is List 
            ? response.data 
            : (response.data['templates'] ?? response.data['data'] ?? []);
        
        final templatesList = templates.map((template) => {
          'id': template['id']?.toString() ?? '',
          'name': template['name'] ?? '',
          'description': template['description'] ?? '',
          'type': template['type'] ?? '',
        }).toList();
        
        return Right(templatesList);
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Kupon şablonları yüklenemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Kupon tanımla (grant coupon)
  Future<Either<Failure, Map<String, dynamic>>> grantCoupon({
    required int couponTemplateId,
    required int contactId,
    required int amount,
    required DateTime validUntil,
    int status = 1,
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Tarih formatı: YYYY-MM-DD HH:mm:ss.SSS
      final formattedDate = validUntil.toIso8601String().replaceAll('T', ' ').substring(0, 23);

      final requestBody = {
        'coupon': couponTemplateId,
        'contact': contactId,
        'amount': amount,
        'valid_until': formattedDate,
        'status': status,
      };

      final endpoint = dotenv.env["GRANT_COUPON"] ?? "/api/zecorner/pay/grant-coupon";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint";

      print('🌐 Grant Coupon API: $fullUrl');
      print('📋 Request Body: $requestBody');

      final response = await dioClient.dio.post(
        fullUrl,
        data: requestBody,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode}');
      print('📥 Data: ${response.data}');

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return Right(data);
        }
        return Right(<String, dynamic>{});
      }
      return Left(ServerFailure(
        message: response.data?['message'] ?? 'Kupon tanımlanamadı',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Kuponu güncelle
  /// Web'de POST /api/zecorner/pay/coupon/{id} endpoint'i kullanılıyor
  Future<Either<Failure, Map<String, dynamic>>> updateCoupon({
    required String couponId,
    required int couponTemplateId,
    required int contactId,
    required int amount,
    required DateTime validUntil,
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Tarih formatı: YYYY-MM-DD HH:mm:ss.SSS
      final formattedDate = validUntil.toIso8601String().replaceAll('T', ' ').substring(0, 23);

      final requestBody = {
        'template': couponTemplateId,
        'contact': contactId,
        'amount': amount,
        'valid_until': formattedDate,
      };

      // Web'de tekil "coupon" kullanılıyor: /api/zecorner/pay/coupon/{id}
      final endpoint = dotenv.env["UPDATE_COUPON"] ?? "/api/zecorner/pay/coupon";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint/$couponId";

      print('🌐 Update Coupon API: $fullUrl');
      print('📋 Request Body: $requestBody');

      // Web'de POST method kullanılıyor (PUT değil)
      final response = await dioClient.dio.post(
        fullUrl,
        data: requestBody,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode}');
      print('📥 Data: ${response.data}');

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return Right(data);
        }
        return Right(<String, dynamic>{});
      }
      return Left(ServerFailure(
        message: response.data?['message'] ?? 'Kupon güncellenemedi',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Kuponu sil
  /// Web'de DELETE /api/zecorner/pay/coupon/{id} endpoint'i kullanılıyor
  Future<Either<Failure, bool>> deleteCoupon(String couponId) async {
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Web'de tekil "coupon" kullanılıyor: /api/zecorner/pay/coupon/{id}
      final endpoint = dotenv.env["DELETE_COUPON"] ?? "/api/zecorner/pay/coupon";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint/$couponId";

      print('🌐 Delete Coupon API: $fullUrl');
      print('🔑 JWT Token: ${token.substring(0, 20)}...');

      final response = await dioClient.dio.delete(
        fullUrl,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      final dCode = response.statusCode ?? 0;
      if (dCode >= 200 && dCode < 300) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: response.data?['message'] ?? 'Kupon silinemedi',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  static int? _parseTemplatePk(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// API bazen null alanları veya boş [data] gövdesini reddeder; web ile uyum için temizle.
  Map<String, dynamic> _sanitizeCouponTemplateBody(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final e in data.entries) {
      if (e.value == null) continue;
      if (e.value is Map) {
        final raw = Map<dynamic, dynamic>.from(e.value as Map);
        final inner = <String, dynamic>{};
        for (final ie in raw.entries) {
          if (ie.value == null) continue;
          inner[ie.key.toString()] = ie.value;
        }
        if (e.key == 'data' && inner.isEmpty) continue;
        result[e.key] = inner;
      } else {
        result[e.key] = e.value;
      }
    }
    return result;
  }

  Future<Either<Failure, CouponTemplateModel>> _resolveTemplateAfterMutation(
    Map<String, dynamic> data,
  ) async {
    final fetchResult = await getCouponTemplateList();
    return fetchResult.fold(
      (failure) => Left(failure),
      (templateList) {
        CouponTemplateModel? match;
        for (final t in templateList.templates) {
          if (t.name == data['name']?.toString() &&
              t.type == data['type']?.toString()) {
            match = t;
            break;
          }
        }
        if (match != null) return Right(match);
        return Right(CouponTemplateModel(
          id: 0,
          name: data['name']?.toString() ?? '',
          description: data['description']?.toString() ?? '',
          type: data['type']?.toString() ?? 'FREE',
          status: data['status'] is int ? data['status'] as int : 1,
          data: data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null,
          appliesTo: data['applies_to']?.toString(),
        ));
      },
    );
  }

  /// Kupon şablonlarını getir (liste için tam model)
  Future<Either<Failure, CouponTemplateListResponse>> getCouponTemplateList() async {
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final endpoint = dotenv.env["COUPON_TEMPLATES"] ?? "/api/zecorner/pay/coupon-templates";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint";

      print('🌐 Get Coupon Templates API: $fullUrl');
      print('🔑 JWT Token: ${token.substring(0, 20)}...');

      final response = await dioClient.dio.get(
        fullUrl,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = CouponTemplateListResponse.fromJson(response.data);
        print('✅ ${responseData.templates.length} kupon şablonu geldi');
        return Right(responseData);
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Kupon şablonları yüklenemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Kupon şablonu oluştur
  Future<Either<Failure, CouponTemplateModel>> createCouponTemplate(Map<String, dynamic> data) async {
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Web'de tekil endpoint kullanılıyor: /pay/coupon-template
      final endpoint = dotenv.env["CREATE_COUPON_TEMPLATE"] ?? "/api/zecorner/pay/coupon-template";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint";

      final body = _sanitizeCouponTemplateBody(data);
      print('🌐 Create Coupon Template API: $fullUrl');
      print('📤 Data: $body');

      final response = await dioClient.dio.post(
        fullUrl,
        data: body,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      final statusOk = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;

      if (statusOk) {
        if (response.statusCode == 204 || response.data == null || response.data == '') {
          return _resolveTemplateAfterMutation(data);
        }
        // Web response: {"code":"OK", "message": "Eklendi.","pk":14}
        // Eğer response direkt template objesi içeriyorsa onu kullan
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          
          // Eğer response'da template objesi varsa onu kullan (id, name gibi alanlar varsa)
          if (responseData.containsKey('id') || 
              (responseData.containsKey('name') && responseData.containsKey('type'))) {
            try {
              final template = CouponTemplateModel.fromJson(responseData);
              return Right(template);
            } catch (e) {
              print('⚠️ Template parse hatası: $e');
            }
          }

          if (responseData.containsKey('code')) {
            final c = responseData['code']?.toString().toUpperCase();
            if (c != 'OK') {
              return Left(ServerFailure(
                message: responseData['message']?.toString() ??
                    'Kupon şablonu oluşturulamadı',
                statusCode: response.statusCode,
              ));
            }
          }

          final pk = _parseTemplatePk(responseData['pk']);
          if (pk != null) {
            print('📋 Template pk ile fetch ediliyor: $pk');
            
            // Template'i pk ile fetch et
            final fetchResult = await getCouponTemplateList();
            return fetchResult.fold(
              (failure) {
                // Fetch başarısız olursa, pk ile minimal template oluştur
                return Right(CouponTemplateModel(
                  id: pk,
                  name: data['name']?.toString() ?? '',
                  description: data['description']?.toString() ?? '',
                  type: data['type']?.toString() ?? 'FREE',
                  status: data['status'] is int ? data['status'] as int : 1,
                  data: data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null,
                  appliesTo: data['applies_to']?.toString(),
                ));
              },
              (templateList) {
                final template = templateList.templates.firstWhere(
                  (t) => t.id == pk,
                  orElse: () => CouponTemplateModel(
                    id: pk,
                    name: data['name']?.toString() ?? '',
                    description: data['description']?.toString() ?? '',
                    type: data['type']?.toString() ?? 'FREE',
                    status: data['status'] is int ? data['status'] as int : 1,
                    data: data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null,
                    appliesTo: data['applies_to']?.toString(),
                  ),
                );
                return Right(template);
              },
            );
          }

          if (responseData['code']?.toString().toUpperCase() == 'OK') {
            return _resolveTemplateAfterMutation(data);
          }
        }
        
        // Fallback: response'u direkt parse etmeye çalış
        try {
          final template = CouponTemplateModel.fromJson(response.data);
          return Right(template);
        } catch (e) {
          print('⚠️ Response parse hatası: $e');
          // Eğer parse edilemezse, data'dan template oluştur
          return Right(CouponTemplateModel(
            id: 0,
            name: data['name']?.toString() ?? '',
            description: data['description']?.toString() ?? '',
            type: data['type']?.toString() ?? 'FREE',
            status: data['status'] is int ? data['status'] as int : 1,
            data: data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null,
            appliesTo: data['applies_to']?.toString(),
          ));
        }
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Kupon şablonu oluşturulamadı',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  Future<Either<Failure, CouponTemplateModel>> _resolveTemplateAfterUpdate(
    int id,
    Map<String, dynamic> data,
  ) async {
    final fetchResult = await getCouponTemplateList();
    return fetchResult.fold(
      (failure) => Left(failure),
      (templateList) {
        for (final t in templateList.templates) {
          if (t.id == id) return Right(t);
        }
        return Right(CouponTemplateModel(
          id: id,
          name: data['name']?.toString() ?? '',
          description: data['description']?.toString() ?? '',
          type: data['type']?.toString() ?? 'FREE',
          status: data['status'] is int ? data['status'] as int : 1,
          data: data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null,
          appliesTo: data['applies_to']?.toString(),
        ));
      },
    );
  }

  /// Kupon şablonu güncelle
  /// Web'de tekil endpoint kullanılıyor: /pay/coupon-template/{id}
  Future<Either<Failure, CouponTemplateModel>> updateCouponTemplate(int id, Map<String, dynamic> data) async {
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Web'de tekil endpoint kullanılıyor: /pay/coupon-template/{id}
      final endpoint = dotenv.env["UPDATE_COUPON_TEMPLATE"] ?? "/api/zecorner/pay/coupon-template";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint/$id";

      final body = _sanitizeCouponTemplateBody(data);
      print('🌐 Update Coupon Template API: $fullUrl');
      print('📤 Data: $body');

      // Web'de POST method kullanılıyor (PUT değil)
      final response = await dioClient.dio.post(
        fullUrl,
        data: body,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      final statusOk = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;

      if (statusOk) {
        if (response.statusCode == 204 || response.data == null || response.data == '') {
          return _resolveTemplateAfterUpdate(id, data);
        }
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;

          if (responseData.containsKey('id') ||
              (responseData.containsKey('name') && responseData.containsKey('type'))) {
            try {
              final template = CouponTemplateModel.fromJson(responseData);
              return Right(template);
            } catch (e) {
              print('⚠️ Template parse hatası: $e');
            }
          }

          if (responseData.containsKey('code')) {
            final c = responseData['code']?.toString().toUpperCase();
            if (c != 'OK') {
              return Left(ServerFailure(
                message: responseData['message']?.toString() ??
                    'Kupon şablonu güncellenemedi',
                statusCode: response.statusCode,
              ));
            }
          }

          final pk = _parseTemplatePk(responseData['pk']);
          if (pk != null) {
            print('📋 Template pk ile fetch ediliyor: $pk');

            final fetchResult = await getCouponTemplateList();
            return fetchResult.fold(
              (failure) {
                return Right(CouponTemplateModel(
                  id: pk,
                  name: data['name']?.toString() ?? '',
                  description: data['description']?.toString() ?? '',
                  type: data['type']?.toString() ?? 'FREE',
                  status: data['status'] is int ? data['status'] as int : 1,
                  data: data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null,
                  appliesTo: data['applies_to']?.toString(),
                ));
              },
              (templateList) {
                final template = templateList.templates.firstWhere(
                  (t) => t.id == pk,
                  orElse: () => CouponTemplateModel(
                    id: pk,
                    name: data['name']?.toString() ?? '',
                    description: data['description']?.toString() ?? '',
                    type: data['type']?.toString() ?? 'FREE',
                    status: data['status'] is int ? data['status'] as int : 1,
                    data: data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null,
                    appliesTo: data['applies_to']?.toString(),
                  ),
                );
                return Right(template);
              },
            );
          }

          if (responseData['code']?.toString().toUpperCase() == 'OK') {
            return _resolveTemplateAfterUpdate(id, data);
          }
        }

        try {
          final template = CouponTemplateModel.fromJson(response.data);
          return Right(template);
        } catch (e) {
          print('⚠️ Response parse hatası: $e');
          return Right(CouponTemplateModel(
            id: id,
            name: data['name']?.toString() ?? '',
            description: data['description']?.toString() ?? '',
            type: data['type']?.toString() ?? 'FREE',
            status: data['status'] is int ? data['status'] as int : 1,
            data: data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null,
            appliesTo: data['applies_to']?.toString(),
          ));
        }
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Kupon şablonu güncellenemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Kupon şablonu sil (pasif hale getir - soft delete)
  /// Web'de status: 0 yapılarak pasif hale getiriliyor, şablon ekranda kalıyor
  Future<Either<Failure, CouponTemplateModel>> deleteCouponTemplate(int id) async {
    try {
      // Önce mevcut şablonu getir
      final templateListResult = await getCouponTemplateList();
      
      CouponTemplateModel? currentTemplate;
      templateListResult.fold(
        (failure) => null,
        (response) {
          currentTemplate = response.templates.firstWhere(
            (t) => t.id == id,
            orElse: () => CouponTemplateModel(
              id: id,
              name: '',
              description: '',
              type: 'FREE',
              status: 0,
            ),
          );
        },
      );

      // Mevcut şablon bilgilerini koru, sadece status'u 0 yap
      final updateData = {
        'name': currentTemplate?.name ?? '',
        'description': currentTemplate?.description ?? '',
        'type': currentTemplate?.type ?? 'FREE',
        'status': 0, // Pasif hale getir
        'data': currentTemplate?.data,
        'applies_to': currentTemplate?.appliesTo,
      };

      // Update metodunu kullanarak status'u 0 yap
      final updateResult = await updateCouponTemplate(id, updateData);
      
      return updateResult.fold(
        (failure) => Left(failure),
        (updatedTemplate) => Right(updatedTemplate),
      );
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }
}

