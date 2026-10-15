import 'dart:math' as math;
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/note/note_model.dart';

class NoteRepository with BaseRepository {
  static final NoteRepository _instance = NoteRepository._internal();
  factory NoteRepository() => _instance;
  NoteRepository._internal();

  final DioClient _client = DioClient();

  // Note endpoint (web API is /api/get-calendar-notes?page=0&pageSize=25, mapping to backend)
  static const String _endpoint = '/api/zecorner/calendar/note';

  // Get user context data
  Future<Map<String, dynamic>> _getUserContext() async {
    final pref = await SharedPreferences.getInstance();
    return {
      'token': pref.getString('userJWT'),
      'userId': pref.getString('userID'),
      'roleId': pref.getString('roleId'),
      'userType': pref.getString('userType'),
      'userTypeDescription': pref.getString('userTypeDescription'),
      'officeId': pref.getString('officeId'),
      'advisorId': pref.getString('advisorId'),
    };
  }

  // Get all notes with pagination
  Future<Either<Failure, NoteResponse>> getNotes({
    int page = 0,
    int? pageSize,
    String? search,
  }) async {
    try {
      final userContext = await _getUserContext();
      final token = userContext['token'] as String?;
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];
      final baseUrl = dotenv.env["BASE_URL"];

      if (token == null || token.isEmpty) {
        print('❌ Note: Token bulunamadı - Kullanıcı giriş yapmamış');
        return left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null || baseUrl == null) {
        return left(ServerFailure(
          message: "Uygulama yapılandırması eksik. Lütfen yöneticiye başvurun.",
          statusCode: 500,
        ));
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final queryParams = <String, dynamic>{
        'page': page,
      };

      if (pageSize != null && pageSize > 0) {
        queryParams['pageSize'] = pageSize;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      print('🎯 Note Request: $baseUrl$_endpoint');
      print('📋 Query Params: $queryParams');

      final fullUrl = "$baseUrl$_endpoint";
      
      final response = await _client.dio.get(
        fullUrl,
        options: Options(headers: headers),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        print('✅ Note data alındı');
        final noteResponse = NoteResponse.fromJson(response.data as Map<String, dynamic>);
        return right(noteResponse);
      } else {
        // Not bulunamadığında (404) veya boş liste döndüğünde boş NotResponse dön
        if (response.statusCode == 404) {
          print('ℹ️ Not bulunamadı (404), boş liste dönüyor');
          return right(NoteResponse(notes: [], totalCount: 0, totalPages: 1, page: 1));
        }
        print('❌ Note response hatası: ${response.statusCode}');
        return left(ServerFailure(
          message: "Not verisi alınamadı (${response.statusCode})",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Note API DioException: ${e.message}');
      
      // DioExceptionType.badResponse 404 durumu için de boş NotResponse dönebiliriz.
      if (e.response?.statusCode == 404) {
        print('ℹ️ Not bulunamadı (404), boş liste dönüyor');
        return right(NoteResponse(notes: [], totalCount: 0, totalPages: 1, page: 1));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(
          message: "Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.",
          statusCode: 401,
        ));
      }
      
      return left(NetworkFailure(
        message: "Not verisi çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel note hatası: $e');
      return left(UnknownFailure(message: "Not hatası: $e"));
    }
  }
}
