import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/customer/customer_api_model.dart';
import '../../models/realestate/search_realestate_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class SearchRealEstateRepository with BaseRepository {
  static final SearchRealEstateRepository _instance = SearchRealEstateRepository._internal();
  factory SearchRealEstateRepository() => _instance;
  SearchRealEstateRepository._internal();

  final DioClient _client = DioClient();

  /// Genel emlak arama - kapsamlı filtreler ile
  Future<Either<Failure, SearchRealEstateResponseModel>> searchRealEstates({
    String? query,
    String? type,
    String? status,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    String? city,
    String? district,
    String? roomCount,
    bool? furnished,
    bool? hasBalcony,
    bool? hasElevator,
    String? heatingType,
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
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (minArea != null) queryParams['min_area'] = minArea;
      if (maxArea != null) queryParams['max_area'] = maxArea;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (district != null && district.isNotEmpty) queryParams['district'] = district;
      if (roomCount != null && roomCount.isNotEmpty) queryParams['room_count'] = roomCount;
      if (furnished != null) queryParams['furnished'] = furnished;
      if (hasBalcony != null) queryParams['has_balcony'] = hasBalcony;
      if (hasElevator != null) queryParams['has_elevator'] = hasElevator;
      if (heatingType != null && heatingType.isNotEmpty) queryParams['heating_type'] = heatingType;

      print('🔍 Emlak arama yapılıyor...');
      print('📋 Filtreler: $queryParams');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/real-estates/search",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Emlak arama sonuçları başarıyla alındı');
        return right(SearchRealEstateResponseModel.fromJson(response.data));
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

  /// Web endpoint'i için mülk arama (/api/zecorner/search/realEstates)
  Future<Either<Failure, SearchRealEstateResponseModel>> searchRealEstatesForCustomer({
    String? query,
    int size = 20,
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
        'size': size,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      print('🔍 Mülk arama (Customer): "$query", size: $size');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/search/realEstates",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Mülk arama sonuçları başarıyla alındı');
        return right(SearchRealEstateResponseModel.fromJson(response.data));
      } else {
        return left(ServerFailure(
          message: "Mülk arama yapılamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Mülk arama API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Mülk arama sırasında hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel mülk arama hatası: $e');
      return left(UnknownFailure(message: "Mülk arama hatası: $e"));
    }
  }

  /// Web `search/listings` — müşteri düzenlemede ilgilendiği ilanlar.
  Future<Either<Failure, List<CustomerAsset>>> searchListingsForCustomer({
    String? query,
    int size = 20,
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

      final queryParams = <String, dynamic>{'size': size};
      if (query != null && query.isNotEmpty) queryParams['q'] = query;

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/search/listings",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return right(_listingHits(response.data));
      }
      return left(ServerFailure(
        message: "İlan arama yapılamadı",
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return left(NetworkFailure(
        message: "İlan arama sırasında hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return left(UnknownFailure(message: "İlan arama hatası: $e"));
    }
  }

  List<CustomerAsset> _listingHits(dynamic data) {
    dynamic raw = data;
    for (var i = 0; i < 3 && raw is Map; i++) {
      final map = Map<String, dynamic>.from(raw);
      final next = map['listings'] ?? map['data'] ?? map['items'] ?? map['results'] ?? map['ads'];
      if (next == null) break;
      raw = next;
    }
    return CustomerAsset.listFrom(raw);
  }

  /// Basit metin arama
  Future<Either<Failure, SearchRealEstateResponseModel>> quickSearch({
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

      print('🔍 Hızlı emlak arama: "$query"');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/real-estates/quick-search",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Hızlı arama sonuçları başarıyla alındı');
        return right(SearchRealEstateResponseModel.fromJson(response.data));
      } else {
        return left(ServerFailure(
          message: "Hızlı arama yapılamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Hızlı arama API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Hızlı arama sırasında hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel hızlı arama hatası: $e');
      return left(UnknownFailure(message: "Hızlı arama hatası: $e"));
    }
  }

  /// Emlak türüne göre arama
  Future<Either<Failure, SearchRealEstateResponseModel>> searchByType({
    required String type,
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
        'type': type,
        'page': page,
        'limit': limit,
      };

      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (district != null && district.isNotEmpty) queryParams['district'] = district;

      print('🏠 Emlak türü arama: $type');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/real-estates/by-type",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Türe göre arama sonuçları başarıyla alındı');
        return right(SearchRealEstateResponseModel.fromJson(response.data));
      } else {
        return left(ServerFailure(
          message: "Türe göre arama yapılamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Türe göre arama API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Türe göre arama sırasında hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel türe göre arama hatası: $e');
      return left(UnknownFailure(message: "Türe göre arama hatası: $e"));
    }
  }

  /// Lokasyona göre arama
  Future<Either<Failure, SearchRealEstateResponseModel>> searchByLocation({
    required String city,
    String? district,
    String? quarter,
    double? lat,
    double? lon,
    double? radius, // km cinsinden
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
        'city': city,
        'page': page,
        'limit': limit,
      };

      if (district != null && district.isNotEmpty) queryParams['district'] = district;
      if (quarter != null && quarter.isNotEmpty) queryParams['quarter'] = quarter;
      if (lat != null) queryParams['lat'] = lat;
      if (lon != null) queryParams['lon'] = lon;
      if (radius != null) queryParams['radius'] = radius;

      print('📍 Lokasyon arama: $city${district != null ? ' / $district' : ''}');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/real-estates/by-location",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Lokasyon arama sonuçları başarıyla alındı');
        return right(SearchRealEstateResponseModel.fromJson(response.data));
      } else {
        return left(ServerFailure(
          message: "Lokasyon arama yapılamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Lokasyon arama API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Lokasyon arama sırasında hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel lokasyon arama hatası: $e');
      return left(UnknownFailure(message: "Lokasyon arama hatası: $e"));
    }
  }

  /// Fiyat aralığına göre arama
  Future<Either<Failure, SearchRealEstateResponseModel>> searchByPriceRange({
    required double minPrice,
    required double maxPrice,
    String? type,
    String? city,
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
        'min_price': minPrice,
        'max_price': maxPrice,
        'page': page,
        'limit': limit,
      };

      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;

      print('💰 Fiyat aralığı arama: ${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)} TL');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/real-estates/by-price",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Fiyat aralığı arama sonuçları başarıyla alındı');
        return right(SearchRealEstateResponseModel.fromJson(response.data));
      } else {
        return left(ServerFailure(
          message: "Fiyat aralığı arama yapılamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Fiyat aralığı arama API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Fiyat aralığı arama sırasında hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel fiyat aralığı arama hatası: $e');
      return left(UnknownFailure(message: "Fiyat aralığı arama hatası: $e"));
    }
  }

  /// Popüler emlaklar
  Future<Either<Failure, SearchRealEstateResponseModel>> getPopularRealEstates({
    String? city,
    String? type,
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

      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;

      print('🔥 Popüler emlaklar getiriliyor...');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/real-estates/popular",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Popüler emlaklar başarıyla alındı');
        return right(SearchRealEstateResponseModel.fromJson(response.data));
      } else {
        return left(ServerFailure(
          message: "Popüler emlaklar alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Popüler emlaklar API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Popüler emlaklar çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel popüler emlaklar hatası: $e');
      return left(UnknownFailure(message: "Popüler emlaklar hatası: $e"));
    }
  }

  /// Yeni eklenen emlaklar
  Future<Either<Failure, SearchRealEstateResponseModel>> getLatestRealEstates({
    String? city,
    String? type,
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

      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;

      print('🆕 Yeni emlaklar getiriliyor...');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/real-estates/latest",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Yeni emlaklar başarıyla alındı');
        return right(SearchRealEstateResponseModel.fromJson(response.data));
      } else {
        return left(ServerFailure(
          message: "Yeni emlaklar alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Yeni emlaklar API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Yeni emlaklar çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel yeni emlaklar hatası: $e');
      return left(UnknownFailure(message: "Yeni emlaklar hatası: $e"));
    }
  }
}
