import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/network/network_info.dart';
import 'package:zecorner/models/users/user_profile_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class UserProfileRepository {
  final Dio _dio;
  final NetworkInfo _networkInfo;

  UserProfileRepository({
    required Dio dio,
    required NetworkInfo networkInfo,
  })  : _dio = dio,
        _networkInfo = networkInfo;

  Future<Either<Failure, UserProfileModel>> getUserProfile() async {
    try {
      // Check network connection
      if (!await _networkInfo.isConnected) {
        return Left(const NetworkFailure(message: 'İnternet bağlantısı bulunamadı'));
      }

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      if (token == null || token.isEmpty) {
        return Left(const AuthFailure(message: 'Oturum bulunamadı'));
      }

      final apiKey = dotenv.env['X_API_KEY'] ?? '';
      final appId = dotenv.env['X_APP_ID'] ?? 'zecorner';

      // BAMMA / getUserInfo X-SESSION bekler (Bearer değil)
      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final baseUrl = dotenv.env['BAMMA_URL'] ?? EnvApi.origin;
      final endpoint = dotenv.env['UPROFILE'] ?? '/api/zecorner/getUserInfo';
      final url = '$baseUrl$endpoint';

      print('🔍 User Profile API Call: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: headers,
          extra: {'skipAuthBearer': true},
        ),
      );

      print('✅ User Profile API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final raw = response.data;
          final Map<String, dynamic> json = raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw as Map);
          final userProfile = UserProfileModel.fromJson(json);
          return Right(userProfile);
        } catch (e) {
          print('❌ User Profile Parse Error: $e');
          return Left(ParseFailure(message: 'Kullanıcı bilgileri işlenirken hata oluştu: $e'));
        }
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ User Profile Dio Error: ${e.message}');
      print('❌ User Profile Dio Response: ${e.response?.data}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Left(const NetworkFailure(message: 'Bağlantı zaman aşımı'));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(const NetworkFailure(message: 'Bağlantı hatası'));
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ User Profile Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  Future<Either<Failure, UserProfileModel>> updateUserProfile({
    required String name,
    required String surname,
    required String profession,
    required String phone,
    required String city,
    required String district,
    required String neighborhood,
    required String address,
    required String about,
    String? facebook,
    String? instagram,
    String? x,
    String? linkedin,
    required String education,
    required bool marketingPermission,
  }) async {
    try {
      // Check network connection
      if (!await _networkInfo.isConnected) {
        return Left(const NetworkFailure(message: 'İnternet bağlantısı bulunamadı'));
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      if (token == null || token.isEmpty) {
        return Left(const AuthFailure(message: 'Oturum bulunamadı'));
      }

      final apiKey = dotenv.env['X_API_KEY'] ?? '';
      final appId = dotenv.env['X_APP_ID'] ?? 'zecorner';

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestData = {
        'name': name,
        'surname': surname,
        'profession': profession,
        'phone': phone,
        'city': city,
        'district': district,
        'neighborhood': neighborhood,
        'address': address,
        'cover_letter': about,
        'social_media': {
          'facebook': facebook,
          'instagram': instagram,
          'x': x,
          'linkedin': linkedin,
        },
        'education': education,
        'marketing_communication_permission': marketingPermission,
      };

      final baseUrl = dotenv.env['BAMMA_URL'] ?? EnvApi.origin;
      final endpoint = dotenv.env['UPROFILE'] ?? '/api/zecorner/getUserInfo';
      final url = '$baseUrl$endpoint';

      print('🔍 Update User Profile API Call: $url');

      final response = await _dio.put(
        url,
        data: requestData,
        options: Options(
          headers: headers,
          extra: {'skipAuthBearer': true},
        ),
      );

      print('✅ Update User Profile API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final raw = response.data;
          final Map<String, dynamic> json = raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw as Map);
          final userProfile = UserProfileModel.fromJson(json);
          return Right(userProfile);
        } catch (e) {
          print('❌ Update User Profile Parse Error: $e');
          return Left(ParseFailure(message: 'Güncellenmiş kullanıcı bilgileri işlenirken hata oluştu: $e'));
        }
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Update User Profile Dio Error: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Left(const NetworkFailure(message: 'Bağlantı zaman aşımı'));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(const NetworkFailure(message: 'Bağlantı hatası'));
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ Update User Profile Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }
}