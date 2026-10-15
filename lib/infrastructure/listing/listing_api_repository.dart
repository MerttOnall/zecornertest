import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/listing/listing_api_model.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/config/env_api.dart';

class ListingApiRepository {
  final Dio _dio;

  ListingApiRepository({
    required Dio dio,
  })  : _dio = dio;

  Future<Either<Failure, ListingResponse>> getListings({
    int page = 1,
    int limit = 20,
    String? search,
    /// Kiralık / satılık — API: `listing_type` (örn. kiralik, satilik)
    String? listingType,
    /// Konut / iş yeri / arsa — API: `real_estate_type` (örn. konut, is-yeri, arsa)
    String? realEstateType,
    /// Ülke — API: `country_code` (TR / CT)
    String? countryCode,
    int? provinceCode,
    int? districtCode,
    int? quarterCode,
    /// Bazı gateway'ler il adı ile filtreler (`province` query)
    String? provinceName,
    String? districtName,
    String? quarterName,
    int? minPrice,
    int? maxPrice,
    int? minArea,
    int? maxArea,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final baseUrl = "${EnvApi.origin}/api/zecorner/listing";
      print('🌐 API Endpoint: $baseUrl');

      final pref = await SharedPreferences.getInstance();
      final token =
          pref.getString('userJWT') ?? pref.getString('auth_token');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Query parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'pageSize': limit,
        'searchText': search?.trim() ?? '',
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      if (listingType != null && listingType.isNotEmpty) {
        queryParams['listing_type'] = listingType;
      }

      if (realEstateType != null && realEstateType.isNotEmpty) {
        queryParams['real_estate_type'] = realEstateType;
      }

      if (countryCode != null && countryCode.trim().isNotEmpty) {
        queryParams['country_code'] = countryCode.trim();
      }

      if (provinceCode != null) {
        queryParams['province_code'] = provinceCode;
      }

      if (districtCode != null) {
        queryParams['district_code'] = districtCode;
      }

      if (quarterCode != null) {
        queryParams['quarter_code'] = quarterCode;
      }

      final pName = provinceName?.trim();
      if (pName != null && pName.isNotEmpty) {
        queryParams['province'] = pName;
      }
      final dName = districtName?.trim();
      if (dName != null && dName.isNotEmpty) {
        queryParams['district'] = dName;
      }
      final qName = quarterName?.trim();
      if (qName != null && qName.isNotEmpty) {
        queryParams['quarter'] = qName;
      }

      if (minPrice != null) {
        queryParams['min_price'] = minPrice;
        queryParams['price_min'] = minPrice;
      }

      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice;
        queryParams['price_max'] = maxPrice;
      }

      if (minArea != null) {
        queryParams['min_area'] = minArea;
        queryParams['m2_min'] = minArea;
      }

      if (maxArea != null) {
        queryParams['max_area'] = maxArea;
        queryParams['m2_max'] = maxArea;
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
        // Bazı gateway'ler camelCase bekler
        queryParams['sortBy'] = sortBy;
        // Django REST tarzı (yok sayılırsa zararsız)
        if (sortOrder == 'desc') {
          queryParams['ordering'] = '-$sortBy';
        } else if (sortOrder == 'asc') {
          queryParams['ordering'] = sortBy;
        }
      }

      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParams['sort_order'] = sortOrder;
        queryParams['sortOrder'] = sortOrder;
      }

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $baseUrl');
      print('📋 Query Parameters: $queryParams');
      print('📋 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');

      final response = await _dio.get(
        baseUrl,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final listingResponse = ListingResponse.fromJson(response.data);
        return Right(listingResponse);
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Sunucu hatası oluştu',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      print('❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz bulunmuyor."));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: "İlan bulunamadı."));
      } else if (e.response?.statusCode == 500) {
        return Left(ServerFailure(message: "Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin."));
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return Left(NetworkFailure(message: "Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin."));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(NetworkFailure(message: "İnternet bağlantınızı kontrol edin."));
      } else {
        return Left(ServerFailure(
          message: e.response?.data?['message'] ?? 'Beklenmeyen bir hata oluştu',
          statusCode: e.response?.statusCode,
        ));
      }
    } catch (e) {
      print('❌ UNEXPECTED ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  Future<Either<Failure, ListingApiModel>> getListingById(String id) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token =
          pref.getString('userJWT') ?? pref.getString('auth_token');
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

      final baseUrl = "${EnvApi.origin}/api/zecorner/listing";
      
      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $baseUrl/$id');
      print('📋 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');

      final response = await _dio.get(
        '$baseUrl/$id',
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final listing = ListingApiModel.fromJson(response.data);
        return Right(listing);
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Sunucu hatası oluştu',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      print('❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz bulunmuyor."));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: "İlan bulunamadı."));
      } else if (e.response?.statusCode == 500) {
        return Left(ServerFailure(message: "Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin."));
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return Left(NetworkFailure(message: "Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin."));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(NetworkFailure(message: "İnternet bağlantınızı kontrol edin."));
      } else {
        return Left(ServerFailure(
          message: e.response?.data?['message'] ?? 'Beklenmeyen bir hata oluştu',
          statusCode: e.response?.statusCode,
        ));
      }
    } catch (e) {
      print('❌ UNEXPECTED ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  Future<Either<Failure, bool>> toggleFavorite(String listingId) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token =
          pref.getString('userJWT') ?? pref.getString('auth_token');
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

      final baseUrl = "${EnvApi.origin}/api/zecorner/listing";
      
      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $baseUrl/$listingId/favorite');
      print('📋 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');

      final response = await _dio.post(
        '$baseUrl/$listingId/favorite',
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Sunucu hatası oluştu',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      print('❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz bulunmuyor."));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: "İlan bulunamadı."));
      } else if (e.response?.statusCode == 500) {
        return Left(ServerFailure(message: "Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin."));
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return Left(NetworkFailure(message: "Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin."));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(NetworkFailure(message: "İnternet bağlantınızı kontrol edin."));
      } else {
        return Left(ServerFailure(
          message: e.response?.data?['message'] ?? 'Beklenmeyen bir hata oluştu',
          statusCode: e.response?.statusCode,
        ));
      }
    } catch (e) {
      print('❌ UNEXPECTED ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  // POST - İlan oluştur
  Future<Either<Failure, Map<String, dynamic>>> createListing(Map<String, dynamic> listingData) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token =
          pref.getString('userJWT') ?? pref.getString('auth_token');
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
        'X-HB-USER-AGENT': 'flutter-app',
        'X-HB-IP': '::1', // ✅ Backend bu header'ı da bekliyor (localhost IP)
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final baseUrl = EnvApi.listingCreateUrl;
      
      print('🔄 Create Listing Request:');
      print('📋 Listing Data: $listingData');
      print('📋 Endpoint: $baseUrl');
      print('📋 Headers: $headers');

      final response = await _dio.post(
        baseUrl,
        data: listingData,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'İlan oluşturulamadı',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Message: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      }

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz bulunmuyor."));
      } else if (e.response?.statusCode == 400) {
        return Left(ServerFailure(
          message: e.response?.data?['message'] ?? 'Geçersiz veri. Lütfen tüm alanları kontrol edin.',
        ));
      } else if (e.response?.statusCode == 500) {
        return Left(ServerFailure(message: "Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin."));
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return Left(NetworkFailure(message: "Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin."));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(NetworkFailure(message: "İnternet bağlantınızı kontrol edin."));
      } else {
        return Left(ServerFailure(
          message: e.response?.data?['message'] ?? 'Beklenmeyen bir hata oluştu',
          statusCode: e.response?.statusCode,
        ));
      }
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }
}
