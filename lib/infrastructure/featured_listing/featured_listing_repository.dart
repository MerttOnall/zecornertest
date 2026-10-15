import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/featured_listing/featured_listing_model.dart';
import 'package:zecorner/models/featured_listing/featured_listing_create_request.dart';
import 'package:zecorner/core/config/env_api.dart';

class FeaturedListingRepository {
  final Dio _dio;

  FeaturedListingRepository({required Dio dio}) : _dio = dio;

  /// Get featured listings
  Future<Either<Failure, FeaturedListingResponse>> getFeaturedListings({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final baseUrl = "${EnvApi.origin}/api/zecorner/featuredListing";
      print('🌐 API Endpoint: $baseUrl');

      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(
            AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-HB-USER-AGENT': 'flutter-app',
        'X-HB-IP': '::1',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('📋 Query Params: $queryParams');

      final response = await _dio.get(
        baseUrl,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('✅ Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('📦 Response Data: $data');

        final featuredListingResponse = FeaturedListingResponse.fromJson(data);
        return Right(featuredListingResponse);
      } else {
        return Left(ServerFailure(
            message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data?['message'] ?? 'Geçersiz istek';
        return Left(ServerFailure(message: errorMessage));
      } else if (e.response?.statusCode == 500) {
        return Left(
            ServerFailure(message: 'Sunucu hatası. Lütfen tekrar deneyin.'));
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Left(NetworkFailure(
            message: 'Bağlantı zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.'));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(NetworkFailure(
            message: 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.'));
      } else {
        return Left(ServerFailure(message: 'Bir hata oluştu: ${e.message}'));
      }
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Create featured listing
  Future<Either<Failure, bool>> createFeaturedListing(
      FeaturedListingCreateRequest request) async {
    try {
      final baseUrl = "${EnvApi.origin}/api/zecorner/featuredListing";
      print('📤 CREATE Endpoint: $baseUrl');

      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(
            AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-HB-USER-AGENT': 'flutter-app',
        'X-HB-IP': '::1',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestData = request.toJson();
      print('📋 Request Data: $requestData');

      final response = await _dio.post(
        baseUrl,
        data: requestData,
        options: Options(headers: headers),
      );

      print('✅ Create Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(true);
      } else {
        return Left(ServerFailure(
            message: 'Ekleme işlemi başarısız: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Create DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data?['message'] ?? 'Geçersiz istek';
        return Left(ServerFailure(message: errorMessage));
      } else if (e.response?.statusCode == 500) {
        return Left(
            ServerFailure(message: 'Sunucu hatası. Lütfen tekrar deneyin.'));
      } else {
        return Left(ServerFailure(message: 'Ekleme hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ Create Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Delete featured listing (actually updates status to 0)
  Future<Either<Failure, bool>> deleteFeaturedListing(int id) async {
    try {
      final baseUrl = "${EnvApi.origin}/api/zecorner/featuredListing";
      print('🗑️ DELETE (Status Update) Endpoint: $baseUrl');

      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(
            AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-HB-USER-AGENT': 'flutter-app',
        'X-HB-IP': '::1',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestData = {
        'id': id,
        'status': 0,
      };

      print('📋 Delete Request Data: $requestData');

      final response = await _dio.post(
        baseUrl,
        data: requestData,
        options: Options(headers: headers),
      );

      print('✅ Delete Response Status: ${response.statusCode}');
      print('✅ Delete Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(true);
      } else {
        return Left(ServerFailure(
            message: 'Silme işlemi başarısız: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Delete DioException: ${e.message}');
      print('❌ Delete Response Status: ${e.response?.statusCode}');
      print('❌ Delete Response Data: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'İlan bulunamadı'));
      } else if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Bu işlem için yetkiniz yok'));
      } else if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data?['message'] ?? 'Geçersiz istek';
        return Left(ServerFailure(message: errorMessage));
      }
      
      return Left(ServerFailure(message: 'Silme hatası: ${e.message}'));
    } catch (e) {
      print('❌ Delete Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }
}

