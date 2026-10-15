import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/realestate/myrealestate_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class MyRealEstateRepository with BaseRepository {
  static final MyRealEstateRepository _instance = MyRealEstateRepository._internal();
  factory MyRealEstateRepository() => _instance;
  MyRealEstateRepository._internal();

  final DioClient _client = DioClient();

  /// Kullanıcının emlak listesini getir - sadece GET işlemi
  Future<Either<Failure, MyRealEstateResponseModel>> getMyRealEstates({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return left(AuthFailure(message: "Token bulunamadı"));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
      };

      final queryParams = {
        'page': page,
        'limit': limit,
      };

      print('🏠 Benim emlakların listesi çekiliyor - Sayfa: $page, Limit: $limit');

      final baseUrl = dotenv.env["BASE_URL"] ?? "${EnvApi.origin}";
      final endpoint = dotenv.env["MY_REAL_ESTATES_ENDPOINT"] ?? "/api/zecorner/myRealEstates";
      
      final response = await _client.dio.get(
        "$baseUrl$endpoint",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Benim emlakların listesi başarıyla alındı');
        return right(MyRealEstateResponseModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Emlak listesi alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Benim emlaklar API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Emlak listesi çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel benim emlaklar hatası: $e');
      return left(UnknownFailure(message: "Emlak listesi hatası: $e"));
    }
  }

  /// Tüm kullanıcı emlakları - pagination olmadan (tümünü getir)
  Future<Either<Failure, MyRealEstateResponseModel>> getAllMyRealEstates() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return left(AuthFailure(message: "Token bulunamadı"));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
      };

      print('🏠 Tüm emlakların listesi çekiliyor...');

      final baseUrl = dotenv.env["BASE_URL"] ?? "${EnvApi.origin}";
      final endpoint = dotenv.env["MY_REAL_ESTATES_ENDPOINT"] ?? "/api/zecorner/myRealEstates";
      
      final response = await _client.dio.get(
        "$baseUrl$endpoint",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Tüm emlakların listesi başarıyla alındı');
        return right(MyRealEstateResponseModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Tüm emlak listesi alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Tüm emlaklar API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Tüm emlak listesi çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel tüm emlaklar hatası: $e');
      return left(UnknownFailure(message: "Tüm emlak listesi hatası: $e"));
    }
  }

  /// Emlak türüne göre filtreleme
  Future<Either<Failure, MyRealEstateResponseModel>> getMyRealEstatesByType({
    required String type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return left(AuthFailure(message: "Token bulunamadı"));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
      };

      final queryParams = {
        'type': type,
        'page': page,
        'limit': limit,
      };

      print('🏠 Emlak türüne göre liste çekiliyor - Tür: $type, Sayfa: $page');

      final baseUrl = dotenv.env["BASE_URL"] ?? "${EnvApi.origin}";
      final endpoint = dotenv.env["MY_REAL_ESTATES_BY_TYPE_ENDPOINT"] ?? "/api/zecorner/myRealEstates/by-type";
      
      final response = await _client.dio.get(
        "$baseUrl$endpoint",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Türe göre emlak listesi başarıyla alındı');
        return right(MyRealEstateResponseModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Türe göre emlak listesi alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Türe göre emlak API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Türe göre emlak listesi çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel türe göre emlak hatası: $e');
      return left(UnknownFailure(message: "Türe göre emlak listesi hatası: $e"));
    }
  }

  /// Duruma göre emlak listesi (aktif, pasif, vb.)
  Future<Either<Failure, MyRealEstateResponseModel>> getMyRealEstatesByStatus({
    required int status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return left(AuthFailure(message: "Token bulunamadı"));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
      };

      final queryParams = {
        'status': status,
        'page': page,
        'limit': limit,
      };

      print('🏠 Emlak durumuna göre liste çekiliyor - Durum: $status, Sayfa: $page');

      final baseUrl = dotenv.env["BASE_URL"] ?? "${EnvApi.origin}";
      final endpoint = dotenv.env["MY_REAL_ESTATES_BY_STATUS_ENDPOINT"] ?? "/api/zecorner/myRealEstates/by-status";
      
      final response = await _client.dio.get(
        "$baseUrl$endpoint",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Duruma göre emlak listesi başarıyla alındı');
        return right(MyRealEstateResponseModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Duruma göre emlak listesi alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Duruma göre emlak API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Duruma göre emlak listesi çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel duruma göre emlak hatası: $e');
      return left(UnknownFailure(message: "Duruma göre emlak listesi hatası: $e"));
    }
  }

  /// Basit arama (sadece başlık ve açıklamada)
  Future<Either<Failure, MyRealEstateResponseModel>> searchMyRealEstates({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return left(AuthFailure(message: "Token bulunamadı"));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
      };

      final queryParams = {
        'q': query,
        'page': page,
        'limit': limit,
      };

      print('🔍 Benim emlaklar aranıyor - Sorgu: $query, Sayfa: $page');

      final baseUrl = dotenv.env["BASE_URL"] ?? "${EnvApi.origin}";
      final endpoint = dotenv.env["MY_REAL_ESTATES_SEARCH_ENDPOINT"] ?? "/api/zecorner/myRealEstates/search";
      
      final response = await _client.dio.get(
        "$baseUrl$endpoint",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Emlak arama sonuçları başarıyla alındı');
        return right(MyRealEstateResponseModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Emlak arama yapılamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Emlak arama API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Emlak arama sırasında hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel emlak arama hatası: $e');
      return left(UnknownFailure(message: "Emlak arama hatası: $e"));
    }
  }
}
