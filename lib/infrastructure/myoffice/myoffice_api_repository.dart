import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/myoffice/myoffice_api_model.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyOfficeApiRepository {
  final Dio _dio;

  MyOfficeApiRepository({
    required Dio dio,
  })  : _dio = dio;

  Future<Either<Failure, MyOfficeApiModel>> getMyOffice() async {
    try {
      print('🌐 API Endpoint: ${dotenv.env["BASE_URL"]}${dotenv.env["MYOFFICE"]}');
      
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

      print('📋 Headers: $headers');
      
      final response = await _dio.get(
        '${dotenv.env["BASE_URL"]}${dotenv.env["MYOFFICE"]}',
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['office'] != null) {
          final office = MyOfficeApiModel.fromJson(data['office']);
          return Right(office);
        } else {
          return Left(ServerFailure(message: 'Ofis bilgisi bulunamadı'));
        }
      } else {
        return Left(ServerFailure(message: 'Ofis bilgisi getirilemedi'));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      print('❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}');
      
      if (e.response?.statusCode == 401) {
        return Left(ServerFailure(message: 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Ofis bulunamadı'));
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        return Left(ServerFailure(message: 'Bağlantı zaman aşımı. Lütfen tekrar deneyin.'));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(ServerFailure(message: 'İnternet bağlantınızı kontrol edin.'));
      } else {
        return Left(ServerFailure(message: e.response?.data?['message'] ?? 'Ofis bilgisi getirilemedi'));
      }
    } catch (e) {
      print('❌ UNEXPECTED ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu'));
    }
  }

  Future<Either<Failure, MyOfficeApiModel>> updateMyOffice(MyOfficeApiModel office) async {
    try {
      print('🌐 API Endpoint: ${dotenv.env["BASE_URL"]}${dotenv.env["MYOFFICE"]}');
      
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
      
      final response = await _dio.put(
        '${dotenv.env["BASE_URL"]}${dotenv.env["MYOFFICE"]}',
        data: office.toJson(),
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['office'] != null) {
          final updatedOffice = MyOfficeApiModel.fromJson(data['office']);
          return Right(updatedOffice);
        } else {
          return Left(ServerFailure(message: 'Ofis güncellenemedi'));
        }
      } else {
        return Left(ServerFailure(message: 'Ofis güncellenemedi'));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      print('❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}');
      
      if (e.response?.statusCode == 401) {
        return Left(ServerFailure(message: 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Ofis bulunamadı'));
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        return Left(ServerFailure(message: 'Bağlantı zaman aşımı. Lütfen tekrar deneyin.'));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(ServerFailure(message: 'İnternet bağlantınızı kontrol edin.'));
      } else {
        return Left(ServerFailure(message: e.response?.data?['message'] ?? 'Ofis güncellenemedi'));
      }
    } catch (e) {
      print('❌ UNEXPECTED ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu'));
    }
  }
}
