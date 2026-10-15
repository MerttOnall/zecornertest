import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/realestate/myrealestate_model.dart';
import '../../models/realestate/realestate_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class RealEstateRepository with BaseRepository {
  static final RealEstateRepository _instance = RealEstateRepository._internal();
  factory RealEstateRepository() => _instance;
  RealEstateRepository._internal();

  final DioClient _client = DioClient();

  // =====================================================
  // GET OPERATIONS - Veri Getirme İşlemleri
  // =====================================================

  /// Kullanıcının emlak listesini getir (pagination ile)
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

      print('🏠 Emlak listesi çekiliyor - Sayfa: $page, Limit: $limit');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/my-real-estates",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Emlak listesi başarıyla alındı');
        return right(MyRealEstateResponseModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Emlak listesi alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Emlak listesi API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Emlak listesi çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel emlak listesi hatası: $e');
      return left(UnknownFailure(message: "Emlak listesi hatası: $e"));
    }
  }

  /// Belirli bir emlakin detayını getir
  Future<Either<Failure, RealEstateDetailModel>> getRealEstateDetail(String realEstateId) async {
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

      print('🏠 Emlak detayı çekiliyor - ID: $realEstateId');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/real-estates/$realEstateId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Emlak detayı başarıyla alındı');
        return right(RealEstateDetailModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Emlak detayı alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Emlak detayı API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Emlak detayı çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel emlak detayı hatası: $e');
      return left(UnknownFailure(message: "Emlak detayı hatası: $e"));
    }
  }

  /// Tüm emlakları getir (arama ve filtreleme ile)
  Future<Either<Failure, MyRealEstateResponseModel>> searchRealEstates({
    String? search,
    String? type,
    String? status,
    double? minPrice,
    double? maxPrice,
    String? city,
    String? district,
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

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      // Filtreleri ekle
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (district != null && district.isNotEmpty) queryParams['district'] = district;

      print('🔍 Emlak arama yapılıyor - Filtreler: $queryParams');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/real-estates/search",
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

  // =====================================================
  // POST OPERATIONS - Veri Ekleme İşlemleri
  // =====================================================

  /// Yeni emlak ekle
  Future<Either<Failure, RealEstateDetailModel>> createRealEstate({
    required String type,
    required String title,
    required String description,
    required Map<String, dynamic> address,
    required List<Map<String, dynamic>> properties,
    List<String>? mediaIds,
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

      final requestBody = {
        'type': type,
        'title': title,
        'description': description,
        'address': address,
        'properties': properties,
        'status': 1, // Varsayılan aktif
      };

      if (mediaIds != null && mediaIds.isNotEmpty) {
        requestBody['media_ids'] = mediaIds;
      }

      print('🏠 Yeni emlak ekleniyor: $title');
      print('📋 Request Body: ${requestBody.toString().substring(0, 200)}...');

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zonnin/real-estates",
        data: requestBody,
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Emlak başarıyla eklendi');
        return right(RealEstateDetailModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Emlak eklenemedi",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Emlak ekleme API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Emlak eklenirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel emlak ekleme hatası: $e');
      return left(UnknownFailure(message: "Emlak ekleme hatası: $e"));
    }
  }

  /// Mevcut emlaği güncelle
  Future<Either<Failure, RealEstateDetailModel>> updateRealEstate({
    required String realEstateId,
    String? type,
    String? title,
    String? description,
    Map<String, dynamic>? address,
    List<Map<String, dynamic>>? properties,
    List<String>? mediaIds,
    int? status,
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

      final requestBody = <String, dynamic>{};
      
      // Sadece değişen alanları ekle
      if (type != null) requestBody['type'] = type;
      if (title != null) requestBody['title'] = title;
      if (description != null) requestBody['description'] = description;
      if (address != null) requestBody['address'] = address;
      if (properties != null) requestBody['properties'] = properties;
      if (mediaIds != null) requestBody['media_ids'] = mediaIds;
      if (status != null) requestBody['status'] = status;

      print('🏠 Emlak güncelleniyor - ID: $realEstateId');
      print('📋 Güncellenen alanlar: ${requestBody.keys.toList()}');

      final response = await _client.dio.put(
        "${EnvApi.origin}/api/zonnin/real-estates/$realEstateId",
        data: requestBody,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Emlak başarıyla güncellendi');
        return right(RealEstateDetailModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Emlak güncellenemedi",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Emlak güncelleme API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Emlak güncellenirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel emlak güncelleme hatası: $e');
      return left(UnknownFailure(message: "Emlak güncelleme hatası: $e"));
    }
  }

  // =====================================================
  // DELETE OPERATIONS - Veri Silme İşlemleri
  // =====================================================

  /// Emlaği sil
  Future<Either<Failure, bool>> deleteRealEstate(String realEstateId) async {
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

      print('🗑️ Emlak siliniyor - ID: $realEstateId');

      final response = await _client.dio.delete(
        "${EnvApi.origin}/api/zonnin/real-estates/$realEstateId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Emlak başarıyla silindi');
        return right(true);
      } else {
        return left(ServerFailure(
          message: "Emlak silinemedi",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Emlak silme API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Emlak silinirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel emlak silme hatası: $e');
      return left(UnknownFailure(message: "Emlak silme hatası: $e"));
    }
  }

  /// Emlaği geçici olarak deaktif et
  Future<Either<Failure, RealEstateDetailModel>> deactivateRealEstate(String realEstateId) async {
    return await updateRealEstate(
      realEstateId: realEstateId,
      status: 0, // Pasif duruma al
    );
  }

  /// Emlaği tekrar aktif et
  Future<Either<Failure, RealEstateDetailModel>> activateRealEstate(String realEstateId) async {
    return await updateRealEstate(
      realEstateId: realEstateId,
      status: 1, // Aktif duruma al
    );
  }

  /// Çoklu emlak silme
  Future<Either<Failure, Map<String, bool>>> deleteMultipleRealEstates(List<String> realEstateIds) async {
    Map<String, bool> results = {};
    
    for (String id in realEstateIds) {
      final result = await deleteRealEstate(id);
      results[id] = result.fold(
        (failure) => false,
        (success) => success,
      );
    }
    
    return right(results);
  }
}
