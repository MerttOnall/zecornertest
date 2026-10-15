import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_config.dart';
import '../../models/list/listings_response_model.dart';
import '../../models/favorite/favorite_advisors_response_model.dart';
import 'package:zecorner/core/config/env_api.dart';

/// Favori ilanlar için API repository.
/// GET /favorite/listings endpoint'ini kullanır (auth gerekli).
class FavoriteRepository {
  static final FavoriteRepository _instance = FavoriteRepository._internal();
  factory FavoriteRepository() => _instance;
  FavoriteRepository._internal();

  final DioClient _client = DioClient();

  /// Favori ilanları getir (GET /favorite/listings)
  Future<Either<Failure, ListingsResponseModel>> getFavoriteListings({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      final apiKey = dotenv.env['X_API_KEY'] ?? ApiConfig.apiKey;
      final appId = dotenv.env['X_APP_ID'] ?? ApiConfig.appId;

      if (token == null || token.isEmpty) {
        return left(AuthFailure(message: 'Oturum açmanız gerekiyor. Lütfen giriş yapın.'));
      }

      final url = '${ApiConfig.baseUrl}/favorite/listings';
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      final headers = {
        ...ApiConfig.defaultHeaders,
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
      };

      final response = await _client.dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final result = ListingsResponseModel.fromJson(data);
          return right(result);
        }
        return left(ParseFailure(message: 'Geçersiz yanıt formatı'));
      }

      return left(ServerFailure(
        message: 'Favori ilanlar alınamadı',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.response!.data['error'] ?? e.message)
          : e.message;
      if (statusCode == 401) {
        return left(AuthFailure(
          message: message?.toString() ?? 'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
          statusCode: statusCode,
        ));
      }
      return left(NetworkFailure(
        message: message?.toString() ?? 'Bağlantı hatası',
        statusCode: statusCode,
      ));
    } catch (e) {
      return left(UnknownFailure(message: 'Hata: $e'));
    }
  }

  /// Favori danışmanları getir (GET /favorite/advisors)
  Future<Either<Failure, FavoriteAdvisorsResponseModel>> getFavoriteAdvisors({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      final apiKey = dotenv.env['X_API_KEY'] ?? ApiConfig.apiKey;
      final appId = dotenv.env['X_APP_ID'] ?? ApiConfig.appId;

      if (token == null || token.isEmpty) {
        return left(AuthFailure(message: 'Oturum açmanız gerekiyor. Lütfen giriş yapın.'));
      }

      final baseHost = dotenv.env['BASE_URL']?.trim() ?? '${EnvApi.origin}';
      final favoriteAdvisorsPath = (dotenv.env['FAVORITED'] ?? '/api/zecorner/favorite/advisors').trim();
      final url = baseHost + favoriteAdvisorsPath;
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      final headers = {
        ...ApiConfig.defaultHeaders,
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
      };

      final response = await _client.dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final result = FavoriteAdvisorsResponseModel.fromJson(data);
          return right(result);
        }
        return left(ParseFailure(message: 'Geçersiz yanıt formatı'));
      }

      return left(ServerFailure(
        message: 'Favori danışmanlar alınamadı',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.response!.data['error'] ?? e.message)
          : e.message;
      if (statusCode == 401) {
        return left(AuthFailure(
          message: message?.toString() ?? 'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
          statusCode: statusCode,
        ));
      }
      return left(NetworkFailure(
        message: message?.toString() ?? 'Bağlantı hatası',
        statusCode: statusCode,
      ));
    } catch (e) {
      return left(UnknownFailure(message: 'Hata: $e'));
    }
  }
}
