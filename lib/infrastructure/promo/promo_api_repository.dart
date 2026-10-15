import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/promo/promo_api_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/core/config/env_api.dart';

class PromoApiRepository {
  final Dio _dio;

  PromoApiRepository({required Dio dio}) : _dio = dio;

  /// Web Next proxy (`/promo`) → BAMMA; mobil gateway: `{origin}/api/zecorner/promo`.
  /// Query: `page`, `pageSize`, `searchText`, optional `type` / `status` (web ile uyumlu).
  Future<Either<Failure, PromoResponse>> getPromos({
    int page = 1,
    int pageSize = 9999,
    String? search,
    String? category,
    String? status,
    String? promoType,
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

      final baseUrl = EnvApi.origin;
      final endpoint = (dotenv.env["PROMO"] ?? "/api/zecorner/promo").trim();

      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        // Web paginatedQuery / BAMMA: searchText
        'searchText': search?.trim() ?? '',
      };

      final categorySlug = _mapCategoryToSlug(category);
      if (categorySlug != null) {
        queryParams['category'] = categorySlug;
      }
      if (status != null && status.isNotEmpty && status != 'Hepsi') {
        queryParams['status'] = _mapStatusToId(status);
      }
      if (promoType != null && promoType.isNotEmpty) {
        queryParams['type'] = promoType;
      }

      final headers = {
        'X-SESSION': token,
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };

      final response = await _dio.get(
        '$baseUrl$endpoint',
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          // Stale gateway/proxy cache'lerini kır
          extra: {'refresh': true},
        ),
      );

      if (response.statusCode == 200) {
        return Right(PromoResponse.fromJson(response.data));
      } else {
        return Left(ServerFailure(
            message:
                'Failed to load promos: ${response.statusCode} ${response.data}'));
      }
    } on DioException catch (e) {
      return Left(_getErrorMessage(e));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<Either<Failure, void>> deletePromo(int id) async {
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

      final baseUrl = EnvApi.origin;
      final endpoint = (dotenv.env["PROMO"] ?? "/api/zecorner/promo").trim();

      final headers = {
        'X-SESSION': token,
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _dio.delete(
        '$baseUrl$endpoint/$id',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(null);
      }
      return Left(ServerFailure(
          message:
              'Kampanya silinemedi: ${response.statusCode} ${response.data}'));
    } on DioException catch (e) {
      return Left(_getErrorMessage(e));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  Failure _getErrorMessage(DioException e) {
    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      final message = data is Map
          ? (data['message']?.toString() ?? 'Server error')
          : (data?.toString() ?? 'Server error');
      if (statusCode == 401) {
        return AuthFailure(message: message);
      } else {
        return ServerFailure(message: message);
      }
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(message: 'No internet connection.');
    } else {
      return ServerFailure(message: e.message ?? 'An unknown error occurred.');
    }
  }

  /// UI etiketi → API kategori slug (JSON `categories`).
  String? _mapCategoryToSlug(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty || categoryName == 'Hepsi') {
      return null;
    }
    switch (categoryName.trim().toLowerCase()) {
      case 'giyim':
        return 'clothing';
      case 'elektronik':
        return 'electronics';
      case 'gıda':
      case 'gida':
        return 'food';
      case 'kozmetik':
        return 'cosmetics';
      case 'seyahat':
        return 'travel';
      case 'konaklama':
        return 'lodging';
      case 'otomobil':
        return 'automobile';
      case 'eğlence':
      case 'eglence':
        return 'entertainment';
      case 'yeme - içme':
      case 'yeme-içme':
      case 'yeme içme':
        return 'catering';
      case 'diğer':
      case 'diger':
        return 'other';
      case 'sağlık':
      case 'saglik':
        return 'health';
      case 'eğitim':
      case 'egitim':
        return 'education';
      case 'hizmet':
        return 'service';
      case 'market':
        return 'food';
      default:
        return null;
    }
  }

  /// Status string → API `status` (1 aktif, 0 pasif).
  int _mapStatusToId(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'aktif':
        return 1;
      case 'pasif':
        return 0;
      default:
        return 1;
    }
  }
}
