import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/province/provinces_detail_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class ProvincesDetailRepository with BaseRepository {
  static final ProvincesDetailRepository _instance = ProvincesDetailRepository._internal();
  factory ProvincesDetailRepository() => _instance;
  ProvincesDetailRepository._internal();

  final DioClient _client = DioClient();

  /// Belirli bir ilin tüm ilçe ve mahalle/köy detaylarını getir
  Future<Either<Failure, ProvincesDetailResponseModel>> getProvinceDetails(int provinceCode) async {
    try {
      print('🏛️ İl detayları getiriliyor: $provinceCode');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final apiKey = dotenv.env['API_KEY'];
      final appId = dotenv.env['APP_ID'];

      if (token == null || apiKey == null || appId == null) {
        print('❌ Authentication bilgileri eksik');
        return left(AuthFailure(message: "Kimlik doğrulama bilgileri bulunamadı"));
      }

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/refProvinces/$provinceCode/districts",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ İl detayları API response alındı');
        
        try {
          final data = response.data;
          List<dynamic> districtsData = [];
          
          // Farklı response formatlarını kontrol et
          if (data is List) {
            districtsData = data;
            print('Response direkt liste');
          } else if (data['data'] != null) {
            districtsData = data['data'];
            print('Response data içinde');
          } else if (data['districts'] != null) {
            districtsData = data['districts'];
            print('Response districts içinde');
          }
          
          print('İlçe sayısı: ${districtsData.length}');
          
          final detailModel = ProvincesDetailResponseModel.fromJson(districtsData);
          print('✅ İl detayları başarıyla parse edildi: ${detailModel.districts.length} ilçe');
          
          // Cache'e kaydet
          await _cacheProvinceDetails(provinceCode, districtsData);
          
          return right(detailModel);
        } catch (e, stackTrace) {
          print('❌ İl detayları parse hatası: $e');
          print('Stack trace: $stackTrace');
          return left(ServerFailure(message: "İl detayları parse edilemedi: $e"));
        }
      } else {
        print('❌ İl detayları getirilemedi: ${response.statusCode}');
        return left(ServerFailure(message: "İl detayları getirilemedi: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - İl detayları: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        // Cache'den dene
        final cachedData = await _getCachedProvinceDetails(provinceCode);
        if (cachedData != null) {
          print('📦 Cache\'den il detaylari yuklendi');
          return right(cachedData);
        }
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - İl detayları: $e');
      
      // Cache'den dene
      final cachedData = await _getCachedProvinceDetails(provinceCode);
      if (cachedData != null) {
        print('📦 Cache\'den il detaylari yuklendi (fallback)');
        return right(cachedData);
      }
      
      return left(UnknownFailure(message: "İl detayları getirilemedi: $e"));
    }
  }

  /// Belirli bir ilçeyi getir (ilçe koduna göre)
  Future<Either<Failure, DistrictModel?>> getDistrictByCode(int provinceCode, int districtCode) async {
    try {
      print('🏘️ İlçe getiriliyor: $districtCode (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final district = detailModel.getDistrictByCode(districtCode);
          if (district != null) {
            print('✅ İlçe bulundu: ${district.name}');
          } else {
            print('❌ İlçe bulunamadı: $districtCode');
          }
          return right(district);
        },
      );
    } catch (e) {
      print('❌ İlçe getirme hatası: $e');
      return left(UnknownFailure(message: "İlçe getirilemedi: $e"));
    }
  }

  /// Belirli bir ilçeyi getir (ilçe adına göre)
  Future<Either<Failure, DistrictModel?>> getDistrictByName(int provinceCode, String districtName) async {
    try {
      print('🏘️ İlçe getiriliyor: $districtName (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final district = detailModel.getDistrictByName(districtName);
          if (district != null) {
            print('✅ İlçe bulundu: ${district.name}');
          } else {
            print('❌ İlçe bulunamadı: $districtName');
          }
          return right(district);
        },
      );
    } catch (e) {
      print('❌ İlçe getirme hatası: $e');
      return left(UnknownFailure(message: "İlçe getirilemedi: $e"));
    }
  }

  /// Belirli bir mahalle/köyü getir (kod'a göre)
  Future<Either<Failure, Map<String, dynamic>?>> getQuarterByCode(int provinceCode, int quarterCode) async {
    try {
      print('🏘️ Mahalle/köy getiriliyor: $quarterCode (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final quarter = detailModel.getQuarterByCode(quarterCode);
          if (quarter != null) {
            // Hangi ilçede olduğunu da bul
            DistrictModel? parentDistrict;
            for (final district in detailModel.districts) {
              if (district.quarters.any((q) => q.code == quarterCode)) {
                parentDistrict = district;
                break;
              }
            }
            
            final result = {
              'quarter': quarter,
              'district': parentDistrict,
              'full_address': parentDistrict != null 
                  ? '${quarter.name}, ${parentDistrict.name}'
                  : quarter.name,
            };
            
            print('✅ Mahalle/köy bulundu: ${quarter.name}');
            return right(result);
          } else {
            print('❌ Mahalle/köy bulunamadı: $quarterCode');
            return right(null);
          }
        },
      );
    } catch (e) {
      print('❌ Mahalle/köy getirme hatası: $e');
      return left(UnknownFailure(message: "Mahalle/köy getirilemedi: $e"));
    }
  }

  /// İlçeleri ara (il içinde)
  Future<Either<Failure, List<DistrictModel>>> searchDistricts(int provinceCode, String query) async {
    try {
      print('🔎 İlçe arama: $query (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final results = detailModel.searchDistricts(query);
          print('✅ İlçe arama sonucu: ${results.length} ilçe bulundu');
          return right(results);
        },
      );
    } catch (e) {
      print('❌ İlçe arama hatası: $e');
      return left(UnknownFailure(message: "İlçe arama başarısız: $e"));
    }
  }

  /// Mahalle/köy ara (il içinde)
  Future<Either<Failure, List<Map<String, dynamic>>>> searchQuarters(int provinceCode, String query) async {
    try {
      print('🔎 Mahalle/köy arama: $query (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final results = detailModel.searchQuarters(query);
          print('✅ Mahalle/köy arama sonucu: ${results.length} mahalle/köy bulundu');
          return right(results);
        },
      );
    } catch (e) {
      print('❌ Mahalle/köy arama hatası: $e');
      return left(UnknownFailure(message: "Mahalle/köy arama başarısız: $e"));
    }
  }

  /// Merkez ilçeleri getir
  Future<Either<Failure, List<DistrictModel>>> getCentralDistricts(int provinceCode) async {
    try {
      print('🏛️ Merkez ilçeler getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final centralDistricts = detailModel.centralDistricts;
          print('✅ Merkez ilçeler getirildi: ${centralDistricts.length} adet');
          return right(centralDistricts);
        },
      );
    } catch (e) {
      print('❌ Merkez ilçeler getirme hatası: $e');
      return left(UnknownFailure(message: "Merkez ilçeler getirilemedi: $e"));
    }
  }

  /// En büyük ilçeleri getir
  Future<Either<Failure, List<DistrictModel>>> getLargestDistricts(int provinceCode) async {
    try {
      print('🏆 En büyük ilçeler getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final largestDistricts = detailModel.largestDistricts;
          print('✅ En büyük ilçeler getirildi: ${largestDistricts.length} adet');
          return right(largestDistricts);
        },
      );
    } catch (e) {
      print('❌ En büyük ilçeler getirme hatası: $e');
      return left(UnknownFailure(message: "En büyük ilçeler getirilemedi: $e"));
    }
  }

  /// En küçük ilçeleri getir
  Future<Either<Failure, List<DistrictModel>>> getSmallestDistricts(int provinceCode) async {
    try {
      print('🎯 En küçük ilçeler getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final smallestDistricts = detailModel.smallestDistricts;
          print('✅ En küçük ilçeler getirildi: ${smallestDistricts.length} adet');
          return right(smallestDistricts);
        },
      );
    } catch (e) {
      print('❌ En küçük ilçeler getirme hatası: $e');
      return left(UnknownFailure(message: "En küçük ilçeler getirilemedi: $e"));
    }
  }

  /// Büyüklüğe göre ilçeleri grupla
  Future<Either<Failure, Map<String, List<DistrictModel>>>> getDistrictsGroupedBySize(int provinceCode) async {
    try {
      print('📊 İlçeler büyüklüğe göre gruplandırılıyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final groupedBySize = detailModel.groupedBySize;
          print('✅ İlçeler büyüklüğe göre gruplandırıldı');
          return right(groupedBySize);
        },
      );
    } catch (e) {
      print('❌ İlçeleri gruplama hatası: $e');
      return left(UnknownFailure(message: "İlçeler gruplandırılamadı: $e"));
    }
  }

  /// Tipe göre ilçeleri grupla
  Future<Either<Failure, Map<String, List<DistrictModel>>>> getDistrictsGroupedByType(int provinceCode) async {
    try {
      print('📊 İlçeler tipe göre gruplandırılıyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final groupedByType = detailModel.groupedByType;
          print('✅ İlçeler tipe göre gruplandırıldı');
          return right(groupedByType);
        },
      );
    } catch (e) {
      print('❌ İlçeleri gruplama hatası: $e');
      return left(UnknownFailure(message: "İlçeler gruplandırılamadı: $e"));
    }
  }

  /// Belirli tipteki mahalle/köyleri getir
  Future<Either<Failure, List<Map<String, dynamic>>>> getQuartersByType(int provinceCode, String quarterType) async {
    try {
      print('🏘️ $quarterType tipindeki mahalle/köyler getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final quarters = detailModel.getQuartersByType(quarterType);
          print('✅ $quarterType tipindeki mahalle/köyler getirildi: ${quarters.length} adet');
          return right(quarters);
        },
      );
    } catch (e) {
      print('❌ Mahalle/köy getirme hatası: $e');
      return left(UnknownFailure(message: "Mahalle/köyler getirilemedi: $e"));
    }
  }

  /// Alfabetik sıralı ilçeleri getir
  Future<Either<Failure, List<DistrictModel>>> getDistrictsSortedAlphabetically(int provinceCode) async {
    try {
      print('🔤 Alfabetik sıralı ilçeler getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final sortedDistricts = detailModel.sortedDistrictsAlphabetically;
          print('✅ Alfabetik sıralı ilçeler getirildi: ${sortedDistricts.length} adet');
          return right(sortedDistricts);
        },
      );
    } catch (e) {
      print('❌ Alfabetik sıralı ilçeler getirme hatası: $e');
      return left(UnknownFailure(message: "Alfabetik sıralı ilçeler getirilemedi: $e"));
    }
  }

  /// Koda göre sıralı ilçeleri getir
  Future<Either<Failure, List<DistrictModel>>> getDistrictsSortedByCode(int provinceCode) async {
    try {
      print('🔢 Koda göre sıralı ilçeler getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final sortedDistricts = detailModel.sortedDistrictsByCode;
          print('✅ Koda göre sıralı ilçeler getirildi: ${sortedDistricts.length} adet');
          return right(sortedDistricts);
        },
      );
    } catch (e) {
      print('❌ Koda göre sıralı ilçeler getirme hatası: $e');
      return left(UnknownFailure(message: "Koda göre sıralı ilçeler getirilemedi: $e"));
    }
  }

  /// Mahalle/köy tip istatistiklerini getir
  Future<Either<Failure, Map<String, int>>> getQuarterTypeStatistics(int provinceCode) async {
    try {
      print('📊 Mahalle/köy tip istatistikleri getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final typeStats = detailModel.quarterTypeStatistics;
          print('✅ Mahalle/köy tip istatistikleri getirildi');
          return right(typeStats);
        },
      );
    } catch (e) {
      print('❌ Mahalle/köy tip istatistikleri getirme hatası: $e');
      return left(UnknownFailure(message: "Mahalle/köy tip istatistikleri getirilemedi: $e"));
    }
  }

  /// İlçe büyüklük istatistiklerini getir
  Future<Either<Failure, Map<String, int>>> getDistrictSizeStatistics(int provinceCode) async {
    try {
      print('📊 İlçe büyüklük istatistikleri getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final sizeStats = detailModel.districtSizeStatistics;
          print('✅ İlçe büyüklük istatistikleri getirildi');
          return right(sizeStats);
        },
      );
    } catch (e) {
      print('❌ İlçe büyüklük istatistikleri getirme hatası: $e');
      return left(UnknownFailure(message: "İlçe büyüklük istatistikleri getirilemedi: $e"));
    }
  }

  /// Kırsal/kentsel dağılım istatistiklerini getir
  Future<Either<Failure, Map<String, double>>> getRuralUrbanStatistics(int provinceCode) async {
    try {
      print('🌾 Kırsal/kentsel dağılım istatistikleri getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final ruralUrbanStats = detailModel.overallRuralUrbanPercentage;
          print('✅ Kırsal/kentsel dağılım istatistikleri getirildi');
          return right(ruralUrbanStats);
        },
      );
    } catch (e) {
      print('❌ Kırsal/kentsel dağılım istatistikleri getirme hatası: $e');
      return left(UnknownFailure(message: "Kırsal/kentsel dağılım istatistikleri getirilemedi: $e"));
    }
  }

  /// En popüler mahalle/köy isimlerini getir
  Future<Either<Failure, Map<String, int>>> getMostCommonQuarterNames(int provinceCode) async {
    try {
      print('⭐ En popüler mahalle/köy isimleri getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final commonNames = detailModel.mostCommonQuarterNames;
          print('✅ En popüler mahalle/köy isimleri getirildi: ${commonNames.length} adet');
          return right(commonNames);
        },
      );
    } catch (e) {
      print('❌ Popüler mahalle/köy isimleri getirme hatası: $e');
      return left(UnknownFailure(message: "Popüler mahalle/köy isimleri getirilemedi: $e"));
    }
  }

  /// Belirli kelimeyi içeren mahalle/köyleri getir
  Future<Either<Failure, List<Map<String, dynamic>>>> getQuartersContaining(int provinceCode, String keyword) async {
    try {
      print('🔍 "$keyword" kelimesini içeren mahalle/köyler getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final quarters = detailModel.getQuartersContaining(keyword);
          print('✅ "$keyword" kelimesini içeren mahalle/köyler getirildi: ${quarters.length} adet');
          return right(quarters);
        },
      );
    } catch (e) {
      print('❌ Kelime içeren mahalle/köy arama hatası: $e');
      return left(UnknownFailure(message: "Kelime içeren mahalle/köy arama başarısız: $e"));
    }
  }

  /// Rastgele ilçe getir
  Future<Either<Failure, DistrictModel>> getRandomDistrict(int provinceCode) async {
    try {
      print('🎲 Rastgele ilçe getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final randomDistrict = detailModel.randomDistrict;
          print('✅ Rastgele ilçe getirildi: ${randomDistrict.name}');
          return right(randomDistrict);
        },
      );
    } catch (e) {
      print('❌ Rastgele ilçe getirme hatası: $e');
      return left(UnknownFailure(message: "Rastgele ilçe getirilemedi: $e"));
    }
  }

  /// Rastgele mahalle/köy getir
  Future<Either<Failure, Map<String, dynamic>>> getRandomQuarter(int provinceCode) async {
    try {
      print('🎲 Rastgele mahalle/köy getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final randomQuarter = detailModel.randomQuarter;
          print('✅ Rastgele mahalle/köy getirildi: ${randomQuarter['full_address']}');
          return right(randomQuarter);
        },
      );
    } catch (e) {
      print('❌ Rastgele mahalle/köy getirme hatası: $e');
      return left(UnknownFailure(message: "Rastgele mahalle/köy getirilemedi: $e"));
    }
  }

  /// İl detay istatistiklerini getir
  Future<Either<Failure, Map<String, dynamic>>> getProvinceDetailStatistics(int provinceCode) async {
    try {
      print('📊 İl detay istatistikleri getiriliyor (İl: $provinceCode)');
      
      final detailsResult = await getProvinceDetails(provinceCode);
      
      return detailsResult.fold(
        (failure) => left(failure),
        (detailModel) {
          final statistics = detailModel.statisticsSummary;
          print('✅ İl detay istatistikleri getirildi');
          return right(statistics);
        },
      );
    } catch (e) {
      print('❌ İl detay istatistikleri getirme hatası: $e');
      return left(UnknownFailure(message: "İl detay istatistikleri getirilemedi: $e"));
    }
  }

  /// İl detaylarını yenile (cache'i temizle ve yeniden getir)
  Future<Either<Failure, ProvincesDetailResponseModel>> refreshProvinceDetails(int provinceCode) async {
    try {
      print('🔄 İl detayları yenileniyor (İl: $provinceCode)');
      
      // Cache'i temizle
      await _clearProvinceDetailsCache(provinceCode);
      
      // Yeniden getir
      return await getProvinceDetails(provinceCode);
    } catch (e) {
      print('❌ İl detayları yenileme hatası: $e');
      return left(UnknownFailure(message: "İl detayları yenilenemedi: $e"));
    }
  }

  // Cache işlemleri
  Future<void> _cacheProvinceDetails(int provinceCode, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_province_details_$provinceCode', data.toString());
      await prefs.setInt('province_details_cache_time_$provinceCode', DateTime.now().millisecondsSinceEpoch);
      print('💾 İl detayları cache\'e kaydedildi (İl: $provinceCode)');
    } catch (e) {
      print('⚠️ Cache kaydetme hatası: $e');
    }
  }

  Future<ProvincesDetailResponseModel?> _getCachedProvinceDetails(int provinceCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_province_details_$provinceCode');
      final cacheTime = prefs.getInt('province_details_cache_time_$provinceCode');
      
      if (cachedData != null && cacheTime != null) {
        // Cache 12 saat geçerli (daha sık güncellenen veri)
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (cacheAge < 12 * 60 * 60 * 1000) {
          // Cache'den parse et - bu gerçek implementasyonda JSON.decode kullanılacak
          print('📦 Cache\'den il detayları yüklendi (${(cacheAge / (60 * 60 * 1000)).toStringAsFixed(1)} saat önce)');
          return null; // Gerçek implementasyonda JSON.decode yapılacak
        }
      }
    } catch (e) {
      print('⚠️ Cache okuma hatası: $e');
    }
    return null;
  }

  Future<void> _clearProvinceDetailsCache(int provinceCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_province_details_$provinceCode');
      await prefs.remove('province_details_cache_time_$provinceCode');
      print('🗑️ İl detayları cache\'i temizlendi (İl: $provinceCode)');
    } catch (e) {
      print('⚠️ Cache temizleme hatası: $e');
    }
  }

  /// Tüm illerin detay cache'lerini temizle
  Future<void> clearAllDetailCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final detailCacheKeys = keys.where((key) => 
        key.startsWith('cached_province_details_') || 
        key.startsWith('province_details_cache_time_')
      ).toList();
      
      for (final key in detailCacheKeys) {
        await prefs.remove(key);
      }
      
      print('🗑️ Tüm il detay cache\'leri temizlendi (${detailCacheKeys.length} cache)');
    } catch (e) {
      print('⚠️ Tüm cache temizleme hatası: $e');
    }
  }
}
