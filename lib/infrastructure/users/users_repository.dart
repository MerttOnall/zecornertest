import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/error/failures.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/users/users_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class UsersRepository with BaseRepository {
  static final UsersRepository _instance = UsersRepository._internal();
  factory UsersRepository() => _instance;
  UsersRepository._internal();

  final DioClient _client = DioClient();

  /// Web handler: `GET {BAMMA_APP_URL}/users` + X-SESSION, X-API-KEY, X-APP-ID.
  /// Arama ekranda local; `search` API’ye gitmez.
  Future<Either<Failure, UsersResponseModel>> getUsers({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      final apiKey = dotenv.env['X_API_KEY'];
      final appId = dotenv.env['X_APP_ID'];

      if (token == null || token.isEmpty) {
        return left(const AuthFailure(
            message:
                "Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın."));
      }
      if (apiKey == null || appId == null) {
        return left(const AuthFailure(message: "API anahtarları bulunamadı."));
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
        'pageSize': limit,
        'searchText': '',
      };
      if (status == 'Aktif') {
        queryParams['status'] = 1;
      } else if (status == 'Pasif') {
        queryParams['status'] = 0;
      }

      final usersPath =
          (dotenv.env['USERS'] ?? '/api/zecorner/users').trim();
      final path = usersPath.startsWith('/') ? usersPath : '/$usersPath';
      final url = '${EnvApi.origin}$path';

      final response = await _client.dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          extra: const {'skipSessionExpire': true},
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        return left(ServerFailure(
          message: "Kullanıcılar alınamadı",
          statusCode: response.statusCode,
        ));
      }

      final data = response.data;
      if (data is! Map || data['users'] is! List) {
        return left(const ServerFailure(message: "Kullanıcılar alınamadı"));
      }

      return right(UsersResponseModel.fromJson(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return left(const AuthFailure(message: "Kimlik doğrulama hatası"));
      }
      return left(
          NetworkFailure(message: "Ağ bağlantısı hatası: ${e.message}"));
    } catch (e) {
      return left(UnknownFailure(message: "Beklenmeyen hata: $e"));
    }
  }

  /// Kullanıcı durumunu güncelle
  Future<Either<Failure, bool>> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      print('🔄 Kullanıcı durumu güncelleniyor: $userId -> ${isActive ? "Aktif" : "Pasif"}');
      
      // JWT token'ı al
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');
      
      if (userJWT == null) {
        print('❌ JWT token bulunamadı');
        return left(AuthFailure(message: "Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın."));
      }

      final apiKey = dotenv.env["X_API_KEY"] ?? 'ed017c68-24ca-4239-ae68-0fa041391855';
      final appId = dotenv.env["X_APP_ID"] ?? 'zecorner';

      final baseUrl = "${EnvApi.origin}/api/zecorner";
      final url = "$baseUrl/users/$userId/status";
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': userJWT, // JWT token'ı X-SESSION header'ına ekle
      };

      final Map<String, dynamic> body = {
        'status': isActive ? 1 : 0,
      };

      final response = await _client.dio.put(
        url,
        data: body,
        options: Options(headers: headers),
      );
      
      if (response.statusCode == 200) {
        print('✅ Kullanıcı durumu başarıyla güncellendi');
        return right(true);
      } else {
        print('❌ Kullanıcı durumu güncellenemedi: ${response.statusCode}');
        return left(ServerFailure(
          message: "Kullanıcı durumu güncellenemedi",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Kimlik doğrulama hatası"));
      } else if (e.response?.statusCode == 403) {
        return left(AuthFailure(message: "Bu işlem için yetkiniz yok"));
      } else {
        return left(NetworkFailure(message: "Ağ bağlantısı hatası: ${e.message}"));
      }
    } catch (e) {
      print('❌ Genel hata: $e');
      return left(UnknownFailure(message: "Beklenmeyen hata: $e"));
    }
  }

  /// Yeni kullanıcı oluştur
  Future<Either<Failure, Map<String, dynamic>>> createUser({
    required int contactId,
    required List<int> roleIds,
  }) async {
    try {
      print('👤 Yeni kullanıcı oluşturuluyor...');
      print('📞 Contact ID: $contactId');
      print('🔑 Role IDs: $roleIds');
      
      // JWT token'ı al
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');
      
      if (userJWT == null) {
        print('❌ JWT token bulunamadı');
        return left(AuthFailure(message: "Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın."));
      }

      final apiKey = dotenv.env["X_API_KEY"] ?? 'ed017c68-24ca-4239-ae68-0fa041391855';
      final appId = dotenv.env["X_APP_ID"] ?? 'zecorner';

      final baseUrl = "${EnvApi.origin}/api/zecorner";
      final url = "$baseUrl/users";
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': userJWT,
      };

      final Map<String, dynamic> body = {
        'contact_id': contactId,
        'role_ids': roleIds,
      };

      print('📡 User Creation API çağrısı: $url');
      print('📋 Body: $body');

      final response = await _client.dio.post(
        url,
        data: body,
        options: Options(headers: headers),
      );
      
      print('📦 Status: ${response.statusCode}');
      print('📦 Response: ${response.data}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Kullanıcı başarıyla oluşturuldu');
        return right(response.data);
      } else {
        print('❌ Kullanıcı oluşturulamadı: ${response.statusCode}');
        return left(ServerFailure(
          message: response.data['message'] ?? "Kullanıcı oluşturulamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Kimlik doğrulama hatası"));
      } else if (e.response?.statusCode == 403) {
        return left(AuthFailure(message: "Bu işlem için yetkiniz yok"));
      } else if (e.response?.statusCode == 400) {
        return left(ServerFailure(message: e.response?.data['message'] ?? "Geçersiz kullanıcı bilgileri"));
      } else if (e.response?.statusCode == 409) {
        return left(ServerFailure(message: "Bu kişi zaten kullanıcı olarak kayıtlı"));
      } else {
        return left(NetworkFailure(message: "Ağ bağlantısı hatası: ${e.message}"));
      }
    } catch (e) {
      print('❌ Genel hata: $e');
      return left(UnknownFailure(message: "Beklenmeyen hata: $e"));
    }
  }
}
