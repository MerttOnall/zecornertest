import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/mixins/update_mixin.dart';
import '../../models/announcement/announcement_model.dart';
import '../../models/announcement/contact_type_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class AnnouncementApiRepository with UpdateMixin {
  static final AnnouncementApiRepository _instance = AnnouncementApiRepository._internal();
  factory AnnouncementApiRepository() => _instance;
  AnnouncementApiRepository._internal();

  final DioClient _client = DioClient();
  
  @override
  DioClient get dioClient => _client;

  // GET - Contact Types (Roller) getir
  Future<Either<Failure, List<ContactType>>> getContactTypes() async {
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

      final endpoint = dotenv.env["CONTACTTYPES"] ?? "/api/zecorner/refContactTypes";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint";

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');

      final response = await dioClient.dio.get(
        fullUrl,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        final contactTypes = data
            .map((item) => ContactType.fromJson(item as Map<String, dynamic>))
            .toList();
        return Right(contactTypes);
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

  // GET - Duyuruları getir
  Future<Either<Failure, AnnouncementResponse>> getAnnouncements({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? state,
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
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (state != null && state.isNotEmpty) {
        queryParams['state'] = state;
      }

      final endpoint = dotenv.env["ANNOUNCEMENTS"] ?? "/api/zecorner/announcement";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint";

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');
      print('📋 Query Parameters: $queryParams');
      print('📋 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');

      final response = await dioClient.dio.get(
        fullUrl,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final announcementResponse = AnnouncementResponse.fromJson(response.data);
        return Right(announcementResponse);
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

  // POST - Yeni duyuru oluştur
  Future<Either<Failure, Announcement>> createAnnouncement({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    DateTime? announcementTime,
    required String category,
    required List<int> contactTypes,
    String? content,
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

      final data = {
        'title': title,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        if (announcementTime != null) 'announcement_time': announcementTime.toIso8601String(),
        'category': category,
        'contact_types': contactTypes,
        if (content != null) 'content': content,
      };

      final endpoint = dotenv.env["ANNOUNCEMENTS"] ?? "/api/zecorner/announcement";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint";

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');
      print('📋 Data: $data');

      final response = await dioClient.dio.post(
        fullUrl,
        data: data,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final announcement = Announcement.fromJson(response.data);
        return Right(announcement);
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
}

