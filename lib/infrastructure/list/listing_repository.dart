import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_config.dart';
import '../../models/list/listings_response_model.dart';
import '../../models/list/listing_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class ListingRepository {
  static final ListingRepository _instance = ListingRepository._internal();
  factory ListingRepository() => _instance;
  ListingRepository._internal();

  final DioClient _client = DioClient();

  /// İlanları getir - basit ve düzgün
  Future<Either<Failure, ListingsResponseModel>> getListings({
    int page = 1,
    int limit = 10,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final apiKey = dotenv.env["X_API_KEY"] ?? 'ed017c68-24ca-4239-ae68-0fa041391855';
      final appId = dotenv.env["X_APP_ID"] ?? 'zecorner';

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (filters != null) ...filters,
      };

      final headers = {
        ...ApiConfig.defaultHeaders,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
      };

      // Doğru endpoint: /api/zecorner/listing (sonda s yok!)
      final url = "${EnvApi.origin}/api/zecorner/listing";
      
      print('🔄 İlanlar çekiliyor: sayfa $page, params: $queryParams');

      final response = await _client.dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ İlanlar alındı: ${response.data['totalCount']} ilan');
        return right(ListingsResponseModel.fromJson(response.data));
      } else {
        return left(ServerFailure(
          message: "İlanlar alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ API Hatası: ${e.message}');
      return left(NetworkFailure(
        message: "İlanlar yüklenemedi: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Hata: $e');
      return left(UnknownFailure(message: "Hata: $e"));
    }
  }

  /// Danışmana ait ilanları state'e göre getir (get-advisor-listings endpoint - web ile aynı)
  /// state: LIVE | SOLD | RENTED
  Future<Either<Failure, ListingsResponseModel>> getAdvisorListingsByState({
    required int contactNo,
    int page = 1,
    int pageSize = 50,
    required String state,
    String? excludedListingId,
  }) async {
    try {
      final apiKey = dotenv.env["X_API_KEY"] ?? ApiConfig.apiKey;
      final appId = dotenv.env["X_APP_ID"] ?? ApiConfig.appId;
      final pref = await SharedPreferences.getInstance();
      final session =
          pref.getString('userJWT') ?? pref.getString('auth_token');
      final baseUrl = ApiConfig.baseUrl;
      final url = '$baseUrl/get-advisor-listings/$contactNo';
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'state': state,
        if (excludedListingId != null && excludedListingId.isNotEmpty)
          'excludedListingId': excludedListingId,
      };
      final headers = {
        ...ApiConfig.defaultHeaders,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        if (session != null && session.isNotEmpty) 'X-SESSION': session,
      };
      print('🔄 get-advisor-listings: $url params: $queryParams');
      final response = await _client.dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      if (response.statusCode == 200) {
        print('✅ get-advisor-listings ($state): ${response.data is Map ? (response.data['listings'] as List?)?.length ?? 0 : 0} ilan');
        return right(ListingsResponseModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        return left(ServerFailure(
          message: "Danışman ilanları alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ get-advisor-listings API Hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Danışman ilanları yüklenemedi: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ get-advisor-listings Hata: $e');
      return left(UnknownFailure(message: "Hata: $e"));
    }
  }

  /// Danışmanın diğer ilanlarını getir (mevcut ilan hariç) — web ile aynı endpoint
  Future<Either<Failure, ListingsResponseModel>> getConsultantOtherListings({
    required int contactNo,
    required String excludedListingId,
    int page = 1,
    int pageSize = 4,
    String state = 'LIVE',
  }) async {
    if (contactNo <= 0) {
      return left(ServerFailure(message: 'Danışman contact_no bulunamadı'));
    }

    // 1) Web detay sayfası: state=LIVE + excludedListingId
    final primary = await getAdvisorListingsByState(
      contactNo: contactNo,
      page: page,
      pageSize: pageSize,
      state: state,
      excludedListingId: excludedListingId,
    );

    final primaryListings = primary.fold((_) => <ListingModel>[], (r) => r.listings);
    if (primaryListings.isNotEmpty) {
      return primary;
    }

    // 2) excludedListingId olmadan dene, client-side filtrele
    final withoutExclude = await getAdvisorListingsByState(
      contactNo: contactNo,
      page: page,
      pageSize: pageSize + 1,
      state: state,
    );

    return withoutExclude.fold(
      (failure) => primary.fold((_) => left(failure), right),
      (response) {
        final filtered = response.listings
            .where((listing) => listing.id != excludedListingId)
            .take(pageSize)
            .toList();
        if (filtered.isNotEmpty) {
          return right(
            ListingsResponseModel(
              listings: filtered,
              totalCount: filtered.length,
              totalPages: 1,
              page: page,
            ),
          );
        }
        return primary.fold((_) => right(response), right);
      },
    );
  }

  /// Tek bir ilan detayını getir (slug kullanarak)
  Future<Either<Failure, ListingModel>> getListingDetail(String slugOrId) async {
    try {
      final apiKey = dotenv.env["X_API_KEY"] ?? 'ed017c68-24ca-4239-ae68-0fa041391855';
      final appId = dotenv.env["X_APP_ID"] ?? 'zecorner';

      final pref = await SharedPreferences.getInstance();
      final session =
          pref.getString('userJWT') ?? pref.getString('auth_token');

      final headers = {
        ...ApiConfig.defaultHeaders,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        if (session != null && session.isNotEmpty) 'X-SESSION': session,
      };

      // Detay endpoint'ini dene - önce listing/{id} sonra diğerleri
      final baseUrl = "${EnvApi.origin}/api/zecorner";
      List<String> possibleUrls = [
        "$baseUrl/listing/$slugOrId",
        "$baseUrl/listing-detail/$slugOrId", 
        "$baseUrl/property/$slugOrId",
        "$baseUrl/ilan/$slugOrId",
        "$baseUrl/listing/detail/$slugOrId",
      ];
      
      String url = possibleUrls[0]; // İlk olarak bu denenecek
      
      print('🔄 İlan detayı çekiliyor: Slug/ID $slugOrId');
      print('🌐 URL: $url');

      final response = await _client.dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ API Response alındı');
        
        // Response içeriğini kontrol et
        if (response.data is Map) {
          final Map<String, dynamic> data = response.data;
          print('📦 Response Keys: ${data.keys.toList()}');
          
          // Eğer data içinde wrapper varsa
          Map<String, dynamic> listingData;
          if (data.containsKey('detail')) {
            print('📦 Detail wrapper bulundu!');
            listingData = data['detail'];
          } else if (data.containsKey('data')) {
            print('📦 Data wrapper bulundu');
            listingData = data['data'];
          } else if (data.containsKey('listing')) {
            print('📦 Listing wrapper bulundu');
            listingData = data['listing'];
          } else {
            // Direkt parse et
            print('📦 Direkt parse ediliyor...');
            listingData = data;
          }
          
          // Konum bilgilerini kontrol et
          print('📍 Konum Bilgileri (API Response):');
          print('📍 province_name: ${listingData['province_name']}');
          print('📍 district_name: ${listingData['district_name']}');
          print('📍 quarter_name: ${listingData['quarter_name']}');
          print('📍 province_code: ${listingData['province_code']}');
          print('📍 district_code: ${listingData['district_code']}');
          
          return right(ListingModel.fromJson(listingData));
        } else {
          print('❌ Response Map değil: ${response.data}');
          return left(ServerFailure(
            message: "Geçersiz response formatı",
            statusCode: response.statusCode,
          ));
        }
      } else {
        return left(ServerFailure(
          message: "İlan detayı alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ API Hatası: ${e.message}');
      return left(NetworkFailure(
        message: "İlan detayı yüklenemedi: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Hata: $e');
      return left(UnknownFailure(message: "Hata: $e"));
    }
  }

  /// Web endpoint'ini kullanarak ilan detayını getir (pageProps.data.detail formatı)
  /// Önce backend API'yi dener, başarısız olursa web endpoint'lerini dener
  Future<Either<Failure, Map<String, dynamic>>> getListingDetailFromWeb(String listingId) async {
    try {
      print('🌐 İlan detayı çekiliyor: $listingId');
      
      final apiKey = dotenv.env["X_API_KEY"] ?? 'ed017c68-24ca-4239-ae68-0fa041391855';
      final appId = dotenv.env["X_APP_ID"] ?? 'zecorner';
      
      // Önce backend API'yi dene (daha güvenilir)
      final backendBaseUrl = dotenv.env['BAMMA_APP_URL'] ?? '${EnvApi.origin}/api/zecorner';
      final backendEndpoints = [
        '$backendBaseUrl/listing/$listingId',
        '$backendBaseUrl/listing-detail/$listingId',
        '$backendBaseUrl/property/$listingId',
      ];
      
      // Web endpoint'leri (fallback)
      final baseUrl = dotenv.env['NEXT_PUBLIC_HOST'] ?? 'https://zecorner.com';
      final possibleEndpoints = [
        '/api/get-listing/$listingId/',
        '/api/get-listing/$listingId',
        '/api/get-listing-detail/$listingId/',
        '/api/get-listing-detail/$listingId',
        '/api/listing-detail/$listingId/',
        '/api/listing-detail/$listingId',
        '/api/listing/$listingId/',
        '/api/listing/$listingId',
      ];
      
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ));

      // Önce backend API'yi dene, sonra web endpoint'lerini dene
      String? lastError;
      
      // Backend API'yi dene (auth gerektirebilir)
      print('🔄 Backend API deneniyor...');
      final backendHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
      };
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      if (token != null) {
        backendHeaders['X-SESSION'] = token;
      }
      
      for (final endpoint in backendEndpoints) {
        print('🌐 Denenen Backend Endpoint: $endpoint');
        
        try {
          final response = await dio.get(
            endpoint,
            options: Options(
              headers: backendHeaders,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          print('✅ Backend API Response Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = response.data;
            print('✅ İlan detayı başarıyla getirildi (Backend)');
            print('📦 Response Data Keys: ${data is Map ? (data as Map).keys.toList() : 'Not a Map'}');
            
            Map<String, dynamic>? listingData;
            if (data is Map) {
              // Backend API genellikle { detail: {...} } formatında döner
              if (data['detail'] != null) {
                listingData = data['detail'] as Map<String, dynamic>;
                print('📦 Backend detail formatı bulundu');
              } else {
                listingData = Map<String, dynamic>.from(data);
                print('📦 Backend direkt data formatı kullanılıyor');
              }
            }
            
            if (listingData != null && listingData.isNotEmpty) {
              print('✅ Listing data parse edildi: ${listingData.keys.toList()}');
              return right(listingData);
            }
          }
        } on DioException catch (e) {
          print('❌ DioException - Backend Endpoint: $endpoint, Hata: ${e.response?.statusCode}');
          lastError = e.message ?? 'Backend API hatası';
          continue;
        }
      }
      
      // Backend API başarısız oldu, web endpoint'lerini dene
      print('🔄 Backend API başarısız, web endpoint\'leri deneniyor...');
      final webHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
      };
      
      if (token != null) {
        webHeaders['X-SESSION'] = token;
      }
      
      // Web endpoint'lerini dene
      for (final endpoint in possibleEndpoints) {
        final url = '$baseUrl$endpoint';
        print('🌐 Denenen Web Endpoint: $url');
        
        try {
          final response = await dio.get(
            url,
            options: Options(
              headers: webHeaders,
              validateStatus: (status) => status != null && status < 500, // 4xx hatalarını da yakala
            ),
          );

          print('✅ API Response Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = response.data;
            print('✅ İlan detayı başarıyla getirildi (Web)');
            print('📦 Response Data Keys: ${data is Map ? (data as Map).keys.toList() : 'Not a Map'}');
            
            // Web'den gelen format: pageProps.data.detail
            Map<String, dynamic>? listingData;
            if (data is Map) {
              if (data['pageProps'] != null && 
                  data['pageProps']['data'] != null && 
                  data['pageProps']['data']['detail'] != null) {
                listingData = data['pageProps']['data']['detail'] as Map<String, dynamic>;
                print('📦 pageProps.data.detail formatı bulundu');
              } else if (data['detail'] != null) {
                listingData = data['detail'] as Map<String, dynamic>;
                print('📦 detail formatı bulundu');
              } else if (data['data'] != null && data['data']['detail'] != null) {
                listingData = data['data']['detail'] as Map<String, dynamic>;
                print('📦 data.detail formatı bulundu');
              } else {
                listingData = Map<String, dynamic>.from(data);
                print('📦 Direkt data formatı kullanılıyor');
              }
            } else {
              continue; // Bir sonraki endpoint'i dene
            }
            
            if (listingData != null && listingData.isNotEmpty) {
              print('✅ Listing data parse edildi: ${listingData.keys.toList()}');
              return right(listingData);
            }
          } else {
            lastError = "İlan detayı getirilemedi: ${response.statusCode}";
            print('❌ $lastError');
          }
        } on DioException catch (e) {
          lastError = e.message ?? 'Bilinmeyen hata';
          print('❌ DioException - Web Endpoint: $endpoint, Hata: ${e.response?.statusCode}');
          if (e.response?.statusCode == 200) {
            // 200 döndüyse ama exception varsa, response'u kontrol et
            try {
              final data = e.response?.data;
              if (data is Map) {
                Map<String, dynamic>? listingData;
                if (data['pageProps'] != null && 
                    data['pageProps']['data'] != null && 
                    data['pageProps']['data']['detail'] != null) {
                  listingData = data['pageProps']['data']['detail'] as Map<String, dynamic>;
                } else if (data['detail'] != null) {
                  listingData = data['detail'] as Map<String, dynamic>;
                } else {
                  listingData = data as Map<String, dynamic>;
                }
                if (listingData != null && listingData.isNotEmpty) {
                  return right(listingData);
                }
              }
            } catch (_) {}
          }
          // 4xx hataları için bir sonraki endpoint'i dene
          continue;
        }
      }
      
      
      // Tüm endpoint'ler başarısız oldu
      return left(ServerFailure(message: lastError ?? "İlan detayı getirilemedi"));
    } on DioException catch (e) {
      print('❌ DioException - İlan detay: ${e.message}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(NetworkFailure(message: "İnternet bağlantısı hatası: ${e.message}"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      if (e.response?.statusCode == 404) {
        return left(ServerFailure(message: "İlan bulunamadı (404)"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - İlan detay: $e');
      return left(UnknownFailure(message: "İlan detayı getirilemedi: $e"));
    }
  }
}