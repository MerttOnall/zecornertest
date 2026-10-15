import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/office/office_model.dart';
import '../../models/list/listings_response_model.dart';
import '../../models/list/listing_model.dart';

class OfficeRepository with BaseRepository {
  static final OfficeRepository _instance = OfficeRepository._internal();
  factory OfficeRepository() => _instance;
  OfficeRepository._internal();

  final DioClient _client = DioClient();
  
  // Public mode - Office sayfası login gerektirmez (artık gerçek API kullanıyoruz)
  static const bool isPublicPage = false;

  /// Tüm ofisleri getir - sayfalama ile
  Future<Either<Failure, OfficeResponseModel>> getAllOffices({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🏢 Ofisler getiriliyor... (Sayfa: $page, Limit: $limit)');
      
      final apiKey = dotenv.env['X_API_KEY'] ?? 'ed017c68-24ca-4239-ae68-0fa041391855';
      final appId = dotenv.env['X_APP_ID'] ?? 'zecorner';
      // Web'deki endpoint'i kullanıyoruz - public endpoint
      final baseUrl = dotenv.env['NEXT_PUBLIC_HOST'] ?? 'https://zecorner.com';
      
      // Public endpoint - login gerektirmez
      // Web'deki Next.js API route'unu kullanıyoruz
      final endpoint = '/api/get-offices';
      final url = '$baseUrl$endpoint';
      
      // Web'deki sırayla: pageSize önce, page sonra
      final queryParams = <String, dynamic>{
        'pageSize': limit,
        'page': page,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-API-Version': '1.0',
        'X-Client': 'flutter-app',
      };

      // Yeni bir Dio instance oluştur (base URL olmadan)
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ));

      print('🌐 API Endpoint: $url');
      print('📋 Query Params: $queryParams');
      print('📋 Headers: $headers');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('✅ API Response Status: ${response.statusCode}');
      print('📦 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Web API direkt 'offices' key'ini kullanıyor ve OfficeModel formatında
        print('✅ Ofisler başarıyla getirildi: ${data['offices']?.length ?? 0} adet');
        
        // Response zaten OfficeModel formatında, direkt parse edebiliriz
        final offices = (data['offices'] as List?)
            ?.map((officeJson) => OfficeModel.fromJson(officeJson as Map<String, dynamic>))
            .toList() ?? [];
        
        final officeResponse = OfficeResponseModel(
          offices: offices,
          totalCount: data['totalCount'] ?? 0,
          totalPages: data['totalPages'] ?? 0,
          page: data['page'] ?? page,
        );
        
        // Cache'e kaydet
        await _cacheOffices(data, page);
        
        return right(officeResponse);
      } else {
        print('❌ Ofisler getirilemedi: ${response.statusCode}');
        return left(ServerFailure(message: "Ofisler getirilemedi: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - Ofisler: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        // Cache'den dene
        final cachedData = await _getCachedOffices(page);
        if (cachedData != null) {
          print('📦 Cache\'den ofisler yuklendi');
          return right(cachedData);
        }
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - Ofisler: $e');
      
      // Cache'den dene
      final cachedData = await _getCachedOffices(page);
      if (cachedData != null) {
        print('📦 Cache\'den ofisler yuklendi (fallback)');
        return right(cachedData);
      }
      
      return left(UnknownFailure(message: "Ofisler getirilemedi: $e"));
    }
  }

  /// Belirli bir ofisi getir (ID'ye göre)
  Future<Either<Failure, OfficeModel?>> getOfficeById(int officeId) async {
    try {
      print('🔍 Ofis getiriliyor: $officeId');
      
      // Public mode - ID'ye göre mock data'dan döndür
      if (isPublicPage) {
        final allOffices = _getMockOfficeResponse();
        final office = allOffices.offices.where((o) => o.officeId == officeId).isEmpty 
          ? null 
          : allOffices.offices.where((o) => o.officeId == officeId).first;
        await Future.delayed(const Duration(milliseconds: 300));
        return right(office);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final apiKey = dotenv.env['API_KEY'];
      final appId = dotenv.env['APP_ID'];

      if (token == null || apiKey == null || appId == null) {
        print('❌ Authentication bilgileri eksik');
        return left(AuthFailure(message: "Kimlik doğrulama bilgileri bulunamadı"));
      }

      final response = await _client.dio.get(
        '${dotenv.env['OFFICES_ENDPOINT'] ?? '/offices'}/$officeId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-Key': apiKey,
            'X-App-ID': appId,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final office = OfficeModel.fromJson(response.data);
        print('✅ Ofis bulundu: ${office.officeTitle}');
        return right(office);
      } else if (response.statusCode == 404) {
        print('❌ Ofis bulunamadı: $officeId');
        return right(null);
      } else {
        print('❌ Ofis getirilemedi: ${response.statusCode}');
        return left(ServerFailure(message: "Ofis getirilemedi: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - Ofis detay: ${e.message}');
      
      if (e.response?.statusCode == 404) {
        return right(null);
      }
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - Ofis detay: $e');
      return left(UnknownFailure(message: "Ofis getirilemedi: $e"));
    }
  }

  /// Belirli bir ofisi getir (slug'a göre)
  Future<Either<Failure, OfficeModel?>> getOfficeBySlug(String slug) async {
    try {
      print('🔍 Ofis getiriliyor (slug): $slug');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final apiKey = dotenv.env['API_KEY'];
      final appId = dotenv.env['APP_ID'];

      if (token == null || apiKey == null || appId == null) {
        print('❌ Authentication bilgileri eksik');
        return left(AuthFailure(message: "Kimlik doğrulama bilgileri bulunamadı"));
      }

      final response = await _client.dio.get(
        '${dotenv.env['OFFICES_ENDPOINT'] ?? '/offices'}/slug/$slug',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-Key': apiKey,
            'X-App-ID': appId,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final office = OfficeModel.fromJson(response.data);
        print('✅ Ofis bulundu (slug): ${office.officeTitle}');
        return right(office);
      } else if (response.statusCode == 404) {
        print('❌ Ofis bulunamadı (slug): $slug');
        return right(null);
      } else {
        print('❌ Ofis getirilemedi (slug): ${response.statusCode}');
        return left(ServerFailure(message: "Ofis getirilemedi: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - Ofis slug: ${e.message}');
      
      if (e.response?.statusCode == 404) {
        return right(null);
      }
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - Ofis slug: $e');
      return left(UnknownFailure(message: "Ofis getirilemedi: $e"));
    }
  }

  /// Ofis arama
  Future<Either<Failure, OfficeResponseModel>> searchOffices(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔎 Ofis arama: $query (Sayfa: $page)');
      
      // Public mode - mock data'da arama yap
      if (isPublicPage) {
        final allOffices = _getMockOfficeResponse();
        final filteredOffices = allOffices.offices.where((office) =>
          office.officeTitle.toLowerCase().contains(query.toLowerCase()) ||
          office.officeSlug.toLowerCase().contains(query.toLowerCase()) ||
          office.officeAddress.toLowerCase().contains(query.toLowerCase())
        ).toList();
        
        await Future.delayed(const Duration(milliseconds: 400));
        return right(OfficeResponseModel(
          offices: filteredOffices,
          totalCount: filteredOffices.length,
          totalPages: 1,
          page: 1,
        ));
      }
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final apiKey = dotenv.env['API_KEY'];
      final appId = dotenv.env['APP_ID'];

      if (token == null || apiKey == null || appId == null) {
        print('❌ Authentication bilgileri eksik');
        return left(AuthFailure(message: "Kimlik doğrulama bilgileri bulunamadı"));
      }

      final response = await _client.dio.get(
        '${dotenv.env['OFFICES_ENDPOINT'] ?? '/offices'}/search',
        queryParameters: {
          'q': query,
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-Key': apiKey,
            'X-App-ID': appId,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final searchResponse = OfficeResponseModel.fromJson(response.data);
        print('✅ Ofis arama sonucu: ${searchResponse.offices.length} ofis bulundu');
        return right(searchResponse);
      } else {
        print('❌ Ofis arama başarısız: ${response.statusCode}');
        return left(ServerFailure(message: "Ofis arama başarısız: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - Ofis arama: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - Ofis arama: $e');
      return left(UnknownFailure(message: "Ofis arama başarısız: $e"));
    }
  }

  /// Şehre göre ofisleri getir
  Future<Either<Failure, OfficeResponseModel>> getOfficesByCity(
    String cityCode, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🌍 Şehir ofisleri getiriliyor: $cityCode');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final apiKey = dotenv.env['API_KEY'];
      final appId = dotenv.env['APP_ID'];

      if (token == null || apiKey == null || appId == null) {
        print('❌ Authentication bilgileri eksik');
        return left(AuthFailure(message: "Kimlik doğrulama bilgileri bulunamadı"));
      }

      final response = await _client.dio.get(
        '${dotenv.env['OFFICES_ENDPOINT'] ?? '/offices'}/city/$cityCode',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-Key': apiKey,
            'X-App-ID': appId,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final cityResponse = OfficeResponseModel.fromJson(response.data);
        print('✅ Şehir ofisleri getirildi: ${cityResponse.offices.length} ofis');
        return right(cityResponse);
      } else {
        print('❌ Şehir ofisleri getirilemedi: ${response.statusCode}');
        return left(ServerFailure(message: "Şehir ofisleri getirilemedi: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - Şehir ofisleri: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - Şehir ofisleri: $e');
      return left(UnknownFailure(message: "Şehir ofisleri getirilemedi: $e"));
    }
  }

  /// Ofis tipine göre ofisleri getir
  Future<Either<Failure, OfficeResponseModel>> getOfficesByType(
    String officeType, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🏷️ Tip ofisleri getiriliyor: $officeType');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final apiKey = dotenv.env['API_KEY'];
      final appId = dotenv.env['APP_ID'];

      if (token == null || apiKey == null || appId == null) {
        print('❌ Authentication bilgileri eksik');
        return left(AuthFailure(message: "Kimlik doğrulama bilgileri bulunamadı"));
      }

      final response = await _client.dio.get(
        '${dotenv.env['OFFICES_ENDPOINT'] ?? '/offices'}/type',
        queryParameters: {
          'type': officeType,
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-Key': apiKey,
            'X-App-ID': appId,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final typeResponse = OfficeResponseModel.fromJson(response.data);
        print('✅ Tip ofisleri getirildi: ${typeResponse.offices.length} ofis');
        return right(typeResponse);
      } else {
        print('❌ Tip ofisleri getirilemedi: ${response.statusCode}');
        return left(ServerFailure(message: "Tip ofisleri getirilemedi: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - Tip ofisleri: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - Tip ofisleri: $e');
      return left(UnknownFailure(message: "Tip ofisleri getirilemedi: $e"));
    }
  }

  /// ZeCorner ofislerini getir
  Future<Either<Failure, OfficeResponseModel>> getZeCornerOffices({
    int page = 1,
    int limit = 20,
  }) async {
    return await getOfficesByType('ZeCorner', page: page, limit: limit);
  }

  /// Partner ofislerini getir
  Future<Either<Failure, OfficeResponseModel>> getPartnerOffices({
    int page = 1,
    int limit = 20,
  }) async {
    return await getOfficesByType('Partner', page: page, limit: limit);
  }

  /// Prestige ofislerini getir
  Future<Either<Failure, OfficeResponseModel>> getPrestigeOffices({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('💎 Prestige ofisleri getiriliyor...');
      
      final allOfficesResult = await getAllOffices(page: page, limit: limit);
      
      return allOfficesResult.fold(
        (failure) => left(failure),
        (officeResponse) {
          final prestigeOffices = officeResponse.prestigeOffices;
          final prestigeResponse = OfficeResponseModel(
            offices: prestigeOffices,
            totalCount: prestigeOffices.length,
            totalPages: 1,
            page: 1,
          );
          print('✅ Prestige ofisleri getirildi: ${prestigeOffices.length} ofis');
          return right(prestigeResponse);
        },
      );
    } catch (e) {
      print('❌ Prestige ofisleri getirme hatası: $e');
      return left(UnknownFailure(message: "Prestige ofisleri getirilemedi: $e"));
    }
  }

  /// Büyük ofisleri getir (10+ üye)
  Future<Either<Failure, OfficeResponseModel>> getLargeOffices({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🏢 Büyük ofisler getiriliyor...');
      
      final allOfficesResult = await getAllOffices(page: page, limit: limit);
      
      return allOfficesResult.fold(
        (failure) => left(failure),
        (officeResponse) {
          final largeOffices = officeResponse.offices.where((office) => 
            office.sizeCategory == 'Büyük' || office.sizeCategory == 'Çok Büyük'
          ).toList();
          
          final largeResponse = OfficeResponseModel(
            offices: largeOffices,
            totalCount: largeOffices.length,
            totalPages: 1,
            page: 1,
          );
          print('✅ Büyük ofisler getirildi: ${largeOffices.length} ofis');
          return right(largeResponse);
        },
      );
    } catch (e) {
      print('❌ Büyük ofisler getirme hatası: $e');
      return left(UnknownFailure(message: "Büyük ofisler getirilemedi: $e"));
    }
  }

  /// En kaliteli ofisleri getir
  Future<Either<Failure, OfficeResponseModel>> getHighQualityOffices({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('⭐ Kaliteli ofisler getiriliyor...');
      
      final allOfficesResult = await getAllOffices(page: page, limit: limit);
      
      return allOfficesResult.fold(
        (failure) => left(failure),
        (officeResponse) {
          final qualityOffices = officeResponse.offices.where((office) => 
            office.qualityCategory == 'Mükemmel' || office.qualityCategory == 'İyi'
          ).toList();
          
          // Kalite skoruna göre sırala
          qualityOffices.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
          
          final qualityResponse = OfficeResponseModel(
            offices: qualityOffices,
            totalCount: qualityOffices.length,
            totalPages: 1,
            page: 1,
          );
          print('✅ Kaliteli ofisler getirildi: ${qualityOffices.length} ofis');
          return right(qualityResponse);
        },
      );
    } catch (e) {
      print('❌ Kaliteli ofisler getirme hatası: $e');
      return left(UnknownFailure(message: "Kaliteli ofisler getirilemedi: $e"));
    }
  }

  /// Ofis istatistiklerini getir
  Future<Either<Failure, Map<String, dynamic>>> getOfficeStatistics() async {
    try {
      print('📊 Ofis istatistikleri getiriliyor...');
      
      final allOfficesResult = await getAllOffices(limit: 1000); // Tüm ofisleri al
      
      return allOfficesResult.fold(
        (failure) => left(failure),
        (officeResponse) {
          final statistics = officeResponse.statisticsSummary;
          print('✅ Ofis istatistikleri getirildi');
          return right(statistics);
        },
      );
    } catch (e) {
      print('❌ Ofis istatistikleri getirme hatası: $e');
      return left(UnknownFailure(message: "Ofis istatistikleri getirilemedi: $e"));
    }
  }

  /// Ofisleri yenile (cache'i temizle ve yeniden getir)
  Future<Either<Failure, OfficeResponseModel>> refreshOffices({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔄 Ofisler yenileniyor...');
      
      // Cache'i temizle
      await _clearOfficesCache();
      
      // Yeniden getir
      return await getAllOffices(page: page, limit: limit);
    } catch (e) {
      print('❌ Ofisler yenileme hatası: $e');
      return left(UnknownFailure(message: "Ofisler yenilenemedi: $e"));
    }
  }

  /// Ofis ilanlarını getir
  Future<Either<Failure, ListingsResponseModel>> getOfficeListings({
    required int officeId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      print('📋 Ofis ilanları getiriliyor: Office ID $officeId (Sayfa: $page)');
      
      final apiKey = dotenv.env['X_API_KEY'] ?? 'ed017c68-24ca-4239-ae68-0fa041391855';
      final appId = dotenv.env['X_APP_ID'] ?? 'zecorner';
      final baseUrl = dotenv.env['NEXT_PUBLIC_HOST'] ?? 'https://zecorner.com';
      
      final endpoint = '/api/get-office-listings/$officeId/';
      final url = '$baseUrl$endpoint';
      
      final queryParams = <String, dynamic>{
        'pageSize': pageSize,
        'page': page,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
      };

      // Token varsa ekle
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      if (token != null) {
        headers['X-SESSION'] = token;
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ));

      print('🌐 API Endpoint: $url');
      print('📋 Query Params: $queryParams');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('✅ API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ İlanlar başarıyla getirildi: ${data['listings']?.length ?? 0} adet');
        
        final listings = (data['listings'] as List?)
            ?.map((listingJson) => ListingModel.fromJson(listingJson as Map<String, dynamic>))
            .toList() ?? [];
        
        // Aynı cevapta team_members da gelebilir (web API)
        final teamMembers = (data['team_members'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ?? [];
        if (teamMembers.isNotEmpty) {
          print('✅ Aynı cevaptan ekip: ${teamMembers.length} üye');
        }
        
        final listingsResponse = ListingsResponseModel(
          listings: listings,
          totalCount: data['totalCount'] ?? listings.length,
          totalPages: data['totalPages'] ?? 1,
          page: data['page'] ?? page,
          teamMembers: teamMembers,
        );
        
        return right(listingsResponse);
      } else {
        print('❌ İlanlar getirilemedi: ${response.statusCode}');
        return left(ServerFailure(message: "İlanlar getirilemedi: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - İlanlar: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - İlanlar: $e');
      return left(UnknownFailure(message: "İlanlar getirilemedi: $e"));
    }
  }

  /// Ofis ekibini getir.
  /// Web ile aynı: GET /api/get-office-listings/:id/?page=1&pageSize=10
  /// Cevap: { team_members: [...], totalCount, totalPages, page }
  Future<Either<Failure, List<Map<String, dynamic>>>> getOfficeTeam({
    required int officeId,
  }) async {
    try {
      print('👥 Ofis ekibi getiriliyor: Office ID $officeId');
      
      final apiKey = dotenv.env['X_API_KEY'] ?? 'ed017c68-24ca-4239-ae68-0fa041391855';
      final appId = dotenv.env['X_APP_ID'] ?? 'zecorner';
      final baseUrl = dotenv.env['NEXT_PUBLIC_HOST'] ?? 'https://zecorner.com';
      
      final endpoint = '/api/get-office-listings/$officeId/';
      final url = '$baseUrl$endpoint';

      // Web'deki gibi: page=1&pageSize=10 (type yok)
      final queryParams = <String, dynamic>{
        'page': 1,
        'pageSize': 10,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
      };

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      if (token != null) {
        headers['X-SESSION'] = token;
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ));

      print('🌐 API Endpoint: $url');
      print('📋 Query Params: $queryParams');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('✅ API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        final teamMembers = (data['team_members'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ?? [];
        print('✅ Ekip getirildi: ${teamMembers.length} üye');
        return right(teamMembers);
      } else {
        print('❌ Ekip getirilemedi: ${response.statusCode}');
        return left(ServerFailure(message: "Ekip getirilemedi: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - Ekip: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - Ekip: $e');
      return left(UnknownFailure(message: "Ekip getirilemedi: $e"));
    }
  }

  // Cache işlemleri
  Future<void> _cacheOffices(dynamic data, int page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_offices_page_$page', data.toString());
      await prefs.setInt('offices_cache_time_$page', DateTime.now().millisecondsSinceEpoch);
      print('💾 Ofisler cache\'e kaydedildi (Sayfa: $page)');
    } catch (e) {
      print('⚠️ Cache kaydetme hatası: $e');
    }
  }

  Future<OfficeResponseModel?> _getCachedOffices(int page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_offices_page_$page');
      final cacheTime = prefs.getInt('offices_cache_time_$page');
      
      if (cachedData != null && cacheTime != null) {
        // Cache 2 saat geçerli (ofis verileri sık değişir)
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (cacheAge < 2 * 60 * 60 * 1000) {
          // Cache'den parse et - bu gerçek implementasyonda JSON.decode kullanılacak
          print('📦 Cache\'den ofisler yüklendi (${(cacheAge / (60 * 1000)).toStringAsFixed(1)} dakika önce)');
          return null; // Gerçek implementasyonda JSON.decode yapılacak
        }
      }
    } catch (e) {
      print('⚠️ Cache okuma hatası: $e');
    }
    return null;
  }

  Future<void> _clearOfficesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final officeCacheKeys = keys.where((key) => 
        key.startsWith('cached_offices_page_') || 
        key.startsWith('offices_cache_time_')
      ).toList();
      
      for (final key in officeCacheKeys) {
        await prefs.remove(key);
      }
      
      print('🗑️ Ofisler cache\'i temizlendi (${officeCacheKeys.length} cache)');
    } catch (e) {
      print('⚠️ Cache temizleme hatası: $e');
    }
  }

  /// Public office data - login gerektirmez
  OfficeResponseModel _getMockOfficeResponse() {
    final mockOffices = [
      OfficeModel(
        officeId: 1,
        officeTitle: 'ZeCorner Cadde',
        officeEmail: 'infocadde@zecorner.com',
        officePhone: '+90 (216) 711-2222',
        officeLogo: null,
        officeAddress: 'İstanbul / Kadıköy / Caddebostan Mah.',
        districtCode: 1447,
        officeSlug: 'zecorner-cadde',
        officeMembers: [
          OfficeMemberModel(
            memberId: 1,
            memberSlug: 'ahmet-yilmaz',
            memberTitle: 'Ahmet Yılmaz - Ofis Müdürü',
            memberTypeDescription: 'Ofis Müdürü',
          ),
          OfficeMemberModel(
            memberId: 2,
            memberSlug: 'ayse-demir',
            memberTitle: 'Ayşe Demir - Gayrimenkul Danışmanı',
            memberTypeDescription: 'Gayrimenkul Danışmanı',
          ),
          OfficeMemberModel(
            memberId: 3,
            memberSlug: 'mehmet-oz',
            memberTitle: 'Mehmet Öz - Gayrimenkul Danışmanı',
            memberTypeDescription: 'Gayrimenkul Danışmanı',
          ),
        ],
        city: 'İstanbul',
      ),
      OfficeModel(
        officeId: 2,
        officeTitle: 'ZeCorner Prestige',
        officeEmail: 'infoprestige@zecorner.com',
        officePhone: '+90 (252) 358-5685',
        officeLogo: null,
        officeAddress: 'Muğla / Bodrum / Müskebi Mh.',
        districtCode: 1302,
        officeSlug: 'zecorner-prestige',
        officeMembers: [
          OfficeMemberModel(
            memberId: 4,
            memberSlug: 'zeynep-kaya',
            memberTitle: 'Zeynep Kaya - Bölge Müdürü',
            memberTypeDescription: 'Bölge Müdürü',
          ),
          OfficeMemberModel(
            memberId: 5,
            memberSlug: 'can-gunes',
            memberTitle: 'Can Güneş - Gayrimenkul Uzmanı',
            memberTypeDescription: 'Gayrimenkul Uzmanı',
          ),
        ],
        city: 'Muğla',
      ),
      OfficeModel(
        officeId: 3,
        officeTitle: 'ZeCorner Merkez',
        officeEmail: 'infomerkez@zecorner.com',
        officePhone: '+90 (212) 555-0000',
        officeLogo: null,
        officeAddress: 'İstanbul / Şişli / Mecidiyeköy Mah.',
        districtCode: 1449,
        officeSlug: 'zecorner-merkez',
        officeMembers: [
          OfficeMemberModel(
            memberId: 6,
            memberSlug: 'emre-yildiz',
            memberTitle: 'Emre Yıldız - Genel Müdür',
            memberTypeDescription: 'Genel Müdür',
          ),
          OfficeMemberModel(
            memberId: 7,
            memberSlug: 'selin-ak',
            memberTitle: 'Selin Ak - İnsan Kaynakları',
            memberTypeDescription: 'İnsan Kaynakları',
          ),
          OfficeMemberModel(
            memberId: 8,
            memberSlug: 'burak-celik',
            memberTitle: 'Burak Çelik - IT Uzmanı',
            memberTypeDescription: 'IT Uzmanı',
          ),
          OfficeMemberModel(
            memberId: 9,
            memberSlug: 'elif-dogan',
            memberTitle: 'Elif Doğan - Pazarlama Müdürü',
            memberTypeDescription: 'Pazarlama Müdürü',
          ),
        ],
        city: 'İstanbul',
      ),
      OfficeModel(
        officeId: 4,
        officeTitle: 'Partner Office Antalya',
        officeEmail: 'antalya@partnerestate.com',
        officePhone: '+90 (242) 123-4567',
        officeLogo: null,
        officeAddress: 'Antalya / Kepez / Santral Mah.',
        districtCode: 0700,
        officeSlug: 'partner-antalya',
        officeMembers: [
          OfficeMemberModel(
            memberId: 10,
            memberSlug: 'hasan-demir',
            memberTitle: 'Hasan Demir - Partner Müdürü',
            memberTypeDescription: 'Partner Müdürü',
          ),
        ],
        city: 'Antalya',
      ),
      OfficeModel(
        officeId: 5,
        officeTitle: 'ZeCorner Bağdat Caddesi',
        officeEmail: 'bagdat@zecorner.com',
        officePhone: '+90 (216) 987-6543',
        officeLogo: null,
        officeAddress: 'İstanbul / Kadıköy / Bağdat Caddesi',
        districtCode: 1447,
        officeSlug: 'zecorner-bagdat',
        officeMembers: [
          OfficeMemberModel(
            memberId: 11,
            memberSlug: 'fatma-ozkan',
            memberTitle: 'Fatma Özkan - Bölge Koordinatörü',
            memberTypeDescription: 'Bölge Koordinatörü',
          ),
          OfficeMemberModel(
            memberId: 12,
            memberSlug: 'ali-sahin',
            memberTitle: 'Ali Şahin - Satış Danışmanı',
            memberTypeDescription: 'Satış Danışmanı',
          ),
          OfficeMemberModel(
            memberId: 13,
            memberSlug: 'deniz-kara',
            memberTitle: 'Deniz Kara - Kiralama Uzmanı',
            memberTypeDescription: 'Kiralama Uzmanı',
          ),
        ],
        city: 'İstanbul',
      ),
      OfficeModel(
        officeId: 6,
        officeTitle: 'ZeCorner Ankara',
        officeEmail: 'ankara@zecorner.com',
        officePhone: '+90 (312) 444-5566',
        officeLogo: null,
        officeAddress: 'Ankara / Çankaya / Kızılay Mah.',
        districtCode: 0600,
        officeSlug: 'zecorner-ankara',
        officeMembers: [
          OfficeMemberModel(
            memberId: 14,
            memberSlug: 'mehmet-ankara',
            memberTitle: 'Mehmet Yıldırım - Ankara Müdürü',
            memberTypeDescription: 'Ankara Müdürü',
          ),
          OfficeMemberModel(
            memberId: 15,
            memberSlug: 'ayse-ankara',
            memberTitle: 'Ayşe Kaplan - Satış Uzmanı',
            memberTypeDescription: 'Satış Uzmanı',
          ),
        ],
        city: 'Ankara',
      ),
      OfficeModel(
        officeId: 7,
        officeTitle: 'Partner Office İzmir',
        officeEmail: 'izmir@partnerestate.com',
        officePhone: '+90 (232) 333-4455',
        officeLogo: null,
        officeAddress: 'İzmir / Konak / Alsancak Mah.',
        districtCode: 3500,
        officeSlug: 'partner-izmir',
        officeMembers: [
          OfficeMemberModel(
            memberId: 16,
            memberSlug: 'eren-izmir',
            memberTitle: 'Eren Demir - İzmir Koordinatörü',
            memberTypeDescription: 'İzmir Koordinatörü',
          ),
        ],
        city: 'İzmir',
      ),
      OfficeModel(
        officeId: 8,
        officeTitle: 'ZeCorner Beşiktaş',
        officeEmail: 'besiktas@zecorner.com',
        officePhone: '+90 (212) 555-7788',
        officeLogo: null,
        officeAddress: 'İstanbul / Beşiktaş / Levent Mah.',
        districtCode: 1449,
        officeSlug: 'zecorner-besiktas',
        officeMembers: [
          OfficeMemberModel(
            memberId: 17,
            memberSlug: 'seda-besiktas',
            memberTitle: 'Seda Öztürk - Beşiktaş Müdürü',
            memberTypeDescription: 'Beşiktaş Müdürü',
          ),
          OfficeMemberModel(
            memberId: 18,
            memberSlug: 'kaan-besiktas',
            memberTitle: 'Kaan Arslan - Emlak Uzmanı',
            memberTypeDescription: 'Emlak Uzmanı',
          ),
        ],
        city: 'İstanbul',
      ),
    ];

    return OfficeResponseModel(
      offices: mockOffices,
      totalCount: mockOffices.length,
      totalPages: 1,
      page: 1,
    );
  }
}
