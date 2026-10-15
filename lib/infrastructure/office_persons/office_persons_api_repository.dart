import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../models/office_persons/office_persons_api_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class OfficePersonsApiRepository {
  static final OfficePersonsApiRepository _instance = OfficePersonsApiRepository._internal();
  factory OfficePersonsApiRepository() => _instance;
  OfficePersonsApiRepository._internal();

  final DioClient _client = DioClient();

  // GET - Ofise bağlı kişileri getir
  Future<Either<Failure, OfficePersonsApiResponse>> getOfficePersons({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    List<int>? types,
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

      // Query parametrelerini oluştur
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': limit,
        'sortOrder': 'asc',
        'sortColumn': 'contact_no',
      };

      // Arama parametresi ekle (web officeContacts ile aynı: searchText)
      if (search != null && search.isNotEmpty) {
        queryParams['searchText'] = search;
      }

      // Durum filtresi ekle
      if (status != null && status.isNotEmpty && status != 'Tümü') {
        queryParams['status'] = status == 'Aktif' ? '1' : '0';
      }

      // Tip filtresi: null/boş = tüm ofis kişileri (oturum ofisine bağlı)
      final typesToUse = types ?? const <int>[];
      final officeContactsEndpoint = dotenv.env["MYOFFICEC"] ?? "/api/zecorner/officeContacts";
      final baseUrl = "${EnvApi.origin}$officeContactsEndpoint";
      final queryString = StringBuffer();
      queryParams.forEach((key, value) {
        if (queryString.isNotEmpty) queryString.write('&');
        queryString.write('$key=$value');
      });
      for (final type in typesToUse) {
        if (queryString.isNotEmpty) queryString.write('&');
        queryString.write('types=$type');
      }
      final fullUrl = '$baseUrl?$queryString';

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');
      print('📋 Query Parameters: $queryParams + types: $typesToUse');
      print('📋 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');
      print('🔍 DEBUG: Office Contacts Endpoint: $officeContactsEndpoint');

      final response = await _client.dio.get(
        fullUrl,
        options: Options(
          headers: headers,
          extra: {'skipSessionExpire': true},
        ),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('contacts')) {
          final officePersonsResponse = OfficePersonsApiResponse.fromJson(data);
          return Right(officePersonsResponse);
        } else {
          print('❌ Invalid response format: $data');
          return Left(ServerFailure(message: 'Geçersiz API yanıtı'));
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Office Persons API Error: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
        print('❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}');
        
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 400) {
          return Left(ServerFailure(message: 'Geçersiz istek: ${responseData?['message'] ?? 'Bilinmeyen hata'}'));
        } else if (statusCode == 401) {
          return Left(AuthFailure(message: 'Yetkilendirme hatası. Lütfen tekrar giriş yapın.'));
        } else if (statusCode == 403) {
          return Left(AuthFailure(message: 'Bu işlem için yetkiniz bulunmuyor.'));
        } else if (statusCode == 404) {
          return Left(ServerFailure(message: 'Ofise bağlı kişi bulunamadı.'));
        } else if (statusCode == 500) {
          return Left(ServerFailure(message: 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.'));
        } else {
          return Left(ServerFailure(message: 'API hatası: ${responseData?['message'] ?? e.message}'));
        }
      } else {
        return Left(NetworkFailure(message: 'İnternet bağlantınızı kontrol edin.'));
      }
    } catch (e) {
      print('❌ Office Persons Repository Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  // PUT - Kişi durumunu güncelle
  Future<Either<Failure, OfficePersonsApiModel>> updatePersonStatus({
    required int contactNo,
    required int status,
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
        'status': status,
      };

      final officeContactsEndpoint = dotenv.env["MYOFFICEC"] ?? "/api/zecorner/officeContacts";
      final baseUrl = "${EnvApi.origin}$officeContactsEndpoint";
      
      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $baseUrl/$contactNo');
      print('📋 Data: $data');
      print('📋 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');

      final response = await _client.dio.put(
        "$baseUrl/$contactNo",
        data: data,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final officePerson = OfficePersonsApiModel.fromJson(data);
          return Right(officePerson);
        } else {
          return Left(ServerFailure(message: 'Geçersiz API yanıtı'));
        }
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Update Person Status API Error: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
        print('❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}');
        
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 400) {
          return Left(ServerFailure(message: 'Geçersiz istek: ${responseData?['message'] ?? 'Bilinmeyen hata'}'));
        } else if (statusCode == 401) {
          return Left(AuthFailure(message: 'Yetkilendirme hatası. Lütfen tekrar giriş yapın.'));
        } else if (statusCode == 403) {
          return Left(AuthFailure(message: 'Bu işlem için yetkiniz bulunmuyor.'));
        } else if (statusCode == 404) {
          return Left(ServerFailure(message: 'Kişi bulunamadı.'));
        } else if (statusCode == 500) {
          return Left(ServerFailure(message: 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.'));
        } else {
          return Left(ServerFailure(message: 'API hatası: ${responseData?['message'] ?? e.message}'));
        }
      } else {
        return Left(NetworkFailure(message: 'İnternet bağlantınızı kontrol edin.'));
      }
    } catch (e) {
      print('❌ Update Person Status Repository Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  // GET - Kişi detayını getir
  Future<Either<Failure, OfficePersonsApiModel>> getPersonById(int contactNo) async {
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

      final officeContactsEndpoint = dotenv.env["MYOFFICEC"] ?? "/api/zecorner/officeContacts";
      final baseUrl = "${EnvApi.origin}$officeContactsEndpoint";
      
      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $baseUrl/$contactNo');
      print('📋 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');

      final response = await _client.dio.get(
        "$baseUrl/$contactNo",
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final officePerson = OfficePersonsApiModel.fromJson(data);
          return Right(officePerson);
        } else {
          return Left(ServerFailure(message: 'Geçersiz API yanıtı'));
        }
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Get Person By ID API Error: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
        print('❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}');
        
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 400) {
          return Left(ServerFailure(message: 'Geçersiz istek: ${responseData?['message'] ?? 'Bilinmeyen hata'}'));
        } else if (statusCode == 401) {
          return Left(AuthFailure(message: 'Yetkilendirme hatası. Lütfen tekrar giriş yapın.'));
        } else if (statusCode == 403) {
          return Left(AuthFailure(message: 'Bu işlem için yetkiniz bulunmuyor.'));
        } else if (statusCode == 404) {
          return Left(ServerFailure(message: 'Kişi bulunamadı.'));
        } else if (statusCode == 500) {
          return Left(ServerFailure(message: 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.'));
        } else {
          return Left(ServerFailure(message: 'API hatası: ${responseData?['message'] ?? e.message}'));
        }
      } else {
        return Left(NetworkFailure(message: 'İnternet bağlantınızı kontrol edin.'));
      }
    } catch (e) {
      print('❌ Get Person By ID Repository Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  // PUT - Kişi bilgilerini güncelle (tam güncelleme)
  Future<Either<Failure, OfficePersonsApiModel>> updatePerson({
    required int contactNo,
    required Map<String, dynamic> data,
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

      final officeContactsEndpoint = dotenv.env["MYOFFICEC"] ?? "/api/zecorner/officeContacts";
      final baseUrl = "${EnvApi.origin}$officeContactsEndpoint";

      print('🔄 Update Person (ID: $contactNo)');
      print('📋 Data: $data');

      final response = await _client.dio.put(
        "$baseUrl/$contactNo",
        data: data,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final officePerson = OfficePersonsApiModel.fromJson(responseData);
          return Right(officePerson);
        } else {
          return Left(ServerFailure(message: 'Geçersiz API yanıtı'));
        }
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Update Person API Error: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 400) {
          return Left(ServerFailure(message: 'Geçersiz istek: ${responseData?['message'] ?? 'Bilinmeyen hata'}'));
        } else if (statusCode == 401) {
          return Left(AuthFailure(message: 'Yetkilendirme hatası. Lütfen tekrar giriş yapın.'));
        } else if (statusCode == 403) {
          return Left(AuthFailure(message: 'Bu işlem için yetkiniz bulunmuyor.'));
        } else if (statusCode == 404) {
          return Left(ServerFailure(message: 'Kişi bulunamadı.'));
        } else if (statusCode == 500) {
          return Left(ServerFailure(message: 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.'));
        } else {
          return Left(ServerFailure(message: 'API hatası: ${responseData?['message'] ?? e.message}'));
        }
      } else {
        return Left(NetworkFailure(message: 'İnternet bağlantınızı kontrol edin.'));
      }
    } catch (e) {
      print('❌ Update Person Repository Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }
}
