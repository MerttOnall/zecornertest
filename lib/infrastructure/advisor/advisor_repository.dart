import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../models/users/users_model.dart';
import '../../models/list/listing_model.dart';
import '../../models/list/listings_response_model.dart';
import '../../models/advisor/advisor_model.dart';
import 'package:dio/dio.dart';
import 'package:zecorner/core/config/env_api.dart';

class AdvisorRepository {
  final DioClient _client = DioClient();

  /// Danışmanların listesini getir - Users API
  Future<Either<Failure, UsersResponseModel>> getAdvisorsList({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('👥 Danışmanlar listesi yükleniyor (sayfa: $page)');
      
      final baseUrl = "${EnvApi.origin}/api/zecorner";
      final url = "$baseUrl/users";
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      print('📡 Users API çağrısı: $url');
      print('📋 Parametreler: $queryParams');

      final response = await _client.dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      
      print('📦 Status: ${response.statusCode}');
      print('📦 Response type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200 && response.data != null) {
        try {
          final result = UsersResponseModel.fromJson(response.data);
          print('✅ Users parse başarılı: ${result.users.length} kullanıcı');
          
          // Sadece aktif danışmanları filtrele
          final advisors = result.users.where((user) {
            return user.isAdvisor && user.isActive;
          }).toList();
          
          print('🎯 ${advisors.length} aktif danışman filtrelendi');
          
          return right(UsersResponseModel(
            users: advisors,
            totalCount: advisors.length,
            totalPages: result.totalPages,
            page: result.page,
          ));
        } catch (parseError) {
          print('❌ Users parse hatası: $parseError');
          return left(ServerFailure(
            message: "Kullanıcı verisi parse edilemedi: $parseError",
            statusCode: response.statusCode,
          ));
        }
      } else {
        print('❌ Users API Hatası: ${response.statusCode}');
        print('❌ Response: ${response.data}');
        return left(ServerFailure(
          message: "Kullanıcı listesi alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Users Dio Hatası: ${e.message}');
      return left(ServerFailure(
        message: e.message ?? "Bilinmeyen network hatası",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('💥 Users beklenmeyen hata: $e');
      return left(ServerFailure(
        message: e.toString(),
        statusCode: null,
      ));
    }
  }

  /// Danışmanın ilanlarını getir - Ana listing API kullan
  Future<Either<Failure, AdvisorListingsResponseModel>> getAdvisorListings({
    required String advisorId,
    int page = 1,
    int limit = 10,
    String? type, // 'satilik' veya 'kiralik'
  }) async {
    try {
      print('🏘️ Danışman ilanları yükleniyor: $advisorId (sayfa: $page)');
      
      final baseUrl = "${EnvApi.origin}/api/zecorner";
      final url = "$baseUrl/listing"; // Ana listing endpoint'i (çalışıyor)
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Pagination parametreleri
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      print('📡 API çağrısı: $url');
      print('📋 Parametreler: $queryParams');

      final response = await _client.dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      
      print('📦 Status: ${response.statusCode}');
      print('📦 Response type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200 && response.data != null) {
        // Response'u analiz et
        if (response.data is List) {
          final list = response.data as List;
          print('📋 Liste response - ${list.length} elemen var');
          
          if (list.isNotEmpty) {
            print('📋 İlk eleman: ${list.first}');
            
            // Ana listing API'sinden gelen formatı parse et
            try {
              final listingsResponse = ListingsResponseModel.fromJson(response.data);
              print('✅ ListingsResponseModel parse başarılı: ${listingsResponse.listings.length} ilan');
              
              // ListingModel'leri AdvisorListingModel'e çevir
              final advisorListings = listingsResponse.listings.map((listing) {
                return AdvisorListingModel(
                  id: listing.id,
                  type: listing.type.isNotEmpty ? listing.type : 'satilik',
                  realEstate: listing.realEstateType,
                  title: listing.title,
                  description: listing.title, // Description yok, title kullan
                  price: listing.price.toDouble(),
                  currency: listing.currency,
                  properties: listing.properties.entries.map((entry) {
                    return AdvisorPropertyModel(
                      code: entry.key,
                      id: entry.value.valueId,
                      value: entry.value.value ?? (entry.value.numberValue?.toString() ?? 'N/A'),
                    );
                  }).toList(),
                  internal: false, // Varsayılan değer
                  startDate: listing.createdAt ?? '',
                  endDate: listing.updatedAt ?? '',
                  slug: listing.slug,
                );
              }).toList();
              
              print('✅ ${advisorListings.length} ilan AdvisorListingModel formatına çevrildi');
              
              return right(AdvisorListingsResponseModel(
                listings: advisorListings,
                totalCount: advisorListings.length,
                currentPage: page,
                totalPages: (advisorListings.length / limit).ceil(),
              ));
              
            } catch (parseError) {
              print('❌ ListingsResponseModel parse hatası: $parseError');
              
              // Direkt liste parse etmeyi dene
              final manualListings = (response.data as List).map((item) {
                try {
                  final listing = ListingModel.fromJson(item as Map<String, dynamic>);
                  
                  // ListingModel'i AdvisorListingModel'e çevir
                  return AdvisorListingModel(
                    id: listing.id,
                    type: listing.type.isNotEmpty ? listing.type : 'satilik',
                    realEstate: listing.realEstateType,
                    title: listing.title,
                    description: listing.title,
                    price: listing.price.toDouble(),
                    currency: listing.currency,
                    properties: listing.properties.entries.map((entry) {
                      return AdvisorPropertyModel(
                        code: entry.key,
                        id: entry.value.valueId,
                        value: entry.value.value ?? (entry.value.numberValue?.toString() ?? 'N/A'),
                      );
                    }).toList(),
                    internal: false,
                    startDate: listing.createdAt ?? '',
                    endDate: listing.updatedAt ?? '',
                    slug: listing.slug,
                  );
                } catch (e) {
                  print('⚠️ İlan parse edilemedi: $e');
                  return null;
                }
              }).where((listing) => listing != null).cast<AdvisorListingModel>().toList();
              
              if (manualListings.isNotEmpty) {
                print('✅ Manuel parse başarılı: ${manualListings.length} ilan');
                return right(AdvisorListingsResponseModel(
                  listings: manualListings,
                  totalCount: manualListings.length,
                  currentPage: page,
                  totalPages: (manualListings.length / limit).ceil(),
                ));
              }
            }
          }
        } else if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          print('📋 Object response - Keys: ${map.keys}');
          
          try {
            final listingsResponse = ListingsResponseModel.fromJson(response.data);
            print('✅ Map ListingsResponseModel parse başarılı: ${listingsResponse.listings.length} ilan');
            
            // ListingModel'leri AdvisorListingModel'e çevir
            final advisorListings = listingsResponse.listings.map((listing) {
              return AdvisorListingModel(
                id: listing.id,
                type: listing.type.isNotEmpty ? listing.type : 'satilik',
                realEstate: listing.realEstateType,
                title: listing.title,
                description: listing.title,
                price: listing.price.toDouble(),
                currency: listing.currency,
                properties: listing.properties.entries.map((entry) {
                  return AdvisorPropertyModel(
                    code: entry.key,
                    id: entry.value.valueId,
                    value: entry.value.value ?? (entry.value.numberValue?.toString() ?? ''),
                  );
                }).toList(),
                internal: false,
                startDate: listing.createdAt ?? '',
                endDate: listing.updatedAt ?? '',
                slug: listing.slug,
              );
            }).toList();
            
            return right(AdvisorListingsResponseModel(
              listings: advisorListings,
              totalCount: advisorListings.length,
              currentPage: page,
              totalPages: (advisorListings.length / limit).ceil(),
            ));
          } catch (e) {
            print('❌ Map parse hatası: $e');
          }
        }
      } else {
        print('❌ API Hatası: ${response.statusCode}');
        print('❌ Response: ${response.data}');
      }

      return left(ServerFailure(
        message: "İlanlar yüklenemedi",
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      print('❌ Dio Hatası: ${e.message}');
      return left(ServerFailure(
        message: e.message ?? "Bilinmeyen network hatası",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('💥 Beklenmeyen hata: $e');
      return left(ServerFailure(
        message: e.toString(),
        statusCode: null,
      ));
    }
  }

  /// Danışman bilgilerini getir - Users API'sinden contact_no ile
  Future<Either<Failure, UserModel?>> getAdvisorInfo(String advisorIdentifier) async {
    try {
      print('👤 Danışman bilgileri yükleniyor: $advisorIdentifier');
      
      // Önce tüm danışmanları al
      final advisorsResult = await getAdvisorsList();
      
      return advisorsResult.fold(
        (failure) => left(failure),
        (usersResponse) {
          // contact_no, email veya title ile danışmanı bul
          UserModel? foundAdvisor;
          
          // Önce contact_no ile dene
          if (int.tryParse(advisorIdentifier) != null) {
            final contactNo = int.parse(advisorIdentifier);
            try {
              foundAdvisor = usersResponse.users.firstWhere(
                (user) => user.contactNo == contactNo,
              );
            } catch (e) {
              foundAdvisor = null;
            }
          }
          
          // Bulunamazsa email ile dene
          if (foundAdvisor == null) {
            try {
              foundAdvisor = usersResponse.users.firstWhere(
                (user) => user.email.toLowerCase().contains(advisorIdentifier.toLowerCase()),
              );
            } catch (e) {
              foundAdvisor = null;
            }
          }
          
          // Bulunamazsa title ile dene
          if (foundAdvisor == null) {
            try {
              foundAdvisor = usersResponse.users.firstWhere(
                (user) => user.title.toLowerCase().contains(advisorIdentifier.toLowerCase()),
              );
            } catch (e) {
              foundAdvisor = null;
            }
          }
          
          if (foundAdvisor != null) {
            print('✅ Danışman bulundu: ${foundAdvisor.title} (${foundAdvisor.contactNo})');
            return right(foundAdvisor);
          } else {
            print('❌ Danışman bulunamadı: $advisorIdentifier');
            return right(null);
          }
        },
      );
    } catch (e) {
      print('💥 Advisor info beklenmeyen hata: $e');
      return left(ServerFailure(
        message: e.toString(),
        statusCode: null,
      ));
    }
  }
}
