import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zecorner/core/config/api_config.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/featured_contact/featured_contact_model.dart';
import 'package:zecorner/models/featured_contact/featured_contact_create_request.dart';

class FeaturedContactRepository {
  final Dio _dio;

  FeaturedContactRepository({required Dio dio}) : _dio = dio;

  /// Get featured contacts
  Future<Either<Failure, FeaturedContactResponse>> getFeaturedContacts() async {
    try {
      final baseUrl = "${ApiConfig.baseUrl}/featuredContact";
      print('📞 GET Featured Contacts Endpoint: $baseUrl');

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

      final response = await _dio.get(
        baseUrl,
        options: Options(headers: headers),
      );

      print('✅ Featured Contacts Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final featuredContactResponse =
            FeaturedContactResponse.fromJson(response.data);
        return Right(featuredContactResponse);
      } else {
        return Left(ServerFailure(
            message: 'Veri alınamadı: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Get Featured Contacts DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else {
        return Left(
            ServerFailure(message: 'Veri alınamadı: ${e.message}'));
      }
    } catch (e) {
      print('❌ Get Featured Contacts Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Create featured contact
  Future<Either<Failure, bool>> createFeaturedContact(
      FeaturedContactCreateRequest request) async {
    try {
      final baseUrl = "${ApiConfig.baseUrl}/featuredContact";
      print('📤 CREATE Featured Contact Endpoint: $baseUrl');

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
      print('📋 Create Featured Contact Request Data: $requestData');

      final response = await _dio.post(
        baseUrl,
        data: requestData,
        options: Options(headers: headers),
      );

      print('✅ Create Featured Contact Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(true);
      } else {
        return Left(ServerFailure(
            message: 'Ekleme işlemi başarısız: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Create Featured Contact DioException: ${e.message}');
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
      print('❌ Create Featured Contact Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Delete featured contact (actually updates status to 0)
  Future<Either<Failure, bool>> deleteFeaturedContact(int id) async {
    try {
      final baseUrl = "${ApiConfig.baseUrl}/featuredContact";
      print('🗑️ DELETE Featured Contact (Status Update) Endpoint: $baseUrl');

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

      print('📋 Delete Featured Contact Request Data: $requestData');

      final response = await _dio.post(
        baseUrl,
        data: requestData,
        options: Options(headers: headers),
      );

      print('✅ Delete Featured Contact Response Status: ${response.statusCode}');
      print('✅ Delete Featured Contact Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(true);
      } else {
        return Left(ServerFailure(
            message: 'Silme işlemi başarısız: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Delete Featured Contact DioException: ${e.message}');
      print('❌ Delete Response Status: ${e.response?.statusCode}');
      print('❌ Delete Response Data: ${e.response?.data}');

      if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Danışman bulunamadı'));
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
      print('❌ Delete Featured Contact Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }
}

