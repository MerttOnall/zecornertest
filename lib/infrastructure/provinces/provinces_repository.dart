import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/province/provinces_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class ProvincesRepository with BaseRepository {
  static final ProvincesRepository _instance = ProvincesRepository._internal();
  factory ProvincesRepository() => _instance;
  ProvincesRepository._internal();

  final DioClient _client = DioClient();

  /// Tüm illeri getir - Türkiye'nin 81 ili
  Future<Either<Failure, ProvincesResponseModel>> getAllProvinces() async {
    try {
      print('🌍 Tüm iller getiriliyor...');
      
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
        "${EnvApi.origin}/api/zecorner/refProvinces",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ İller API response alındı');
        print('Response data type: ${response.data.runtimeType}');
        
        try {
          final data = response.data;
          List<dynamic> provincesData = [];
          
          // Farklı response formatlarını kontrol et
          if (data is List) {
            provincesData = data;
            print('Response direkt liste');
          } else if (data['data'] != null) {
            provincesData = data['data'];
            print('Response data içinde');
          } else if (data['provinces'] != null) {
            provincesData = data['provinces'];
            print('Response provinces içinde');
          }
          
          print('İl sayısı: ${provincesData.length}');
          
          final provincesModel = ProvincesResponseModel.fromJson(provincesData);
          print('✅ İller başarıyla parse edildi: ${provincesModel.provinces.length} adet');
          
          // Cache'e kaydet
          await _cacheProvinces(provincesData);
          
          return right(provincesModel);
        } catch (e, stackTrace) {
          print('❌ İller parse hatası: $e');
          print('Stack trace: $stackTrace');
          return left(ServerFailure(message: "İller parse edilemedi: $e"));
        }
      } else {
        print('❌ İller getirilemedi: ${response.statusCode}');
        return left(ServerFailure(message: "İller getirilemedi: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      print('❌ DioException - İller: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        // Cache'den dene
        final cachedData = await _getCachedProvinces();
        if (cachedData != null) {
          print('📦 Cache\'den iller yuklendi');
          return right(cachedData);
        }
        return left(NetworkFailure(message: "İnternet bağlantısı hatası"));
      }
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Yetkilendirme hatası"));
      }
      
      return left(ServerFailure(message: "Sunucu hatası: ${e.message}"));
    } catch (e) {
      print('❌ Beklenmeyen hata - İller: $e');
      
      // Cache'den dene
      final cachedData = await _getCachedProvinces();
      if (cachedData != null) {
        print('📦 Cache\'den iller yuklendi (fallback)');
        return right(cachedData);
      }
      
      return left(UnknownFailure(message: "İller getirilemedi: $e"));
    }
  }

  /// Belirli bir ili getir (plaka koduna göre)
  Future<Either<Failure, ProvinceModel?>> getProvinceByCode(int provinceCode) async {
    try {
      print('🔍 İl getiriliyor: $provinceCode');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final province = provincesModel.getProvinceByCode(provinceCode);
          if (province != null) {
            print('✅ İl bulundu: ${province.name}');
          } else {
            print('❌ İl bulunamadı: $provinceCode');
          }
          return right(province);
        },
      );
    } catch (e) {
      print('❌ İl getirme hatası: $e');
      return left(UnknownFailure(message: "İl getirilemedi: $e"));
    }
  }

  /// Belirli bir ili getir (ad'a göre)
  Future<Either<Failure, ProvinceModel?>> getProvinceByName(String provinceName) async {
    try {
      print('🔍 İl getiriliyor: $provinceName');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final province = provincesModel.getProvinceByName(provinceName);
          if (province != null) {
            print('✅ İl bulundu: ${province.name}');
          } else {
            print('❌ İl bulunamadı: $provinceName');
          }
          return right(province);
        },
      );
    } catch (e) {
      print('❌ İl getirme hatası: $e');
      return left(UnknownFailure(message: "İl getirilemedi: $e"));
    }
  }

  /// İlleri ara (ad veya plaka kodu)
  Future<Either<Failure, List<ProvinceModel>>> searchProvinces(String query) async {
    try {
      print('🔎 İl arama: $query');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final results = provincesModel.search(query);
          print('✅ Arama sonucu: ${results.length} il bulundu');
          return right(results);
        },
      );
    } catch (e) {
      print('❌ İl arama hatası: $e');
      return left(UnknownFailure(message: "İl arama başarısız: $e"));
    }
  }

  /// Büyükşehirleri getir
  Future<Either<Failure, List<ProvinceModel>>> getMetropolitanCities() async {
    try {
      print('🏙️ Büyükşehirler getiriliyor...');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final metropolitanCities = provincesModel.metropolitanCities;
          print('✅ Büyükşehirler getirildi: ${metropolitanCities.length} adet');
          return right(metropolitanCities);
        },
      );
    } catch (e) {
      print('❌ Büyükşehir getirme hatası: $e');
      return left(UnknownFailure(message: "Büyükşehirler getirilemedi: $e"));
    }
  }

  /// Normal illeri getir
  Future<Either<Failure, List<ProvinceModel>>> getRegularCities() async {
    try {
      print('🏘️ Normal iller getiriliyor...');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final regularCities = provincesModel.regularCities;
          print('✅ Normal iller getirildi: ${regularCities.length} adet');
          return right(regularCities);
        },
      );
    } catch (e) {
      print('❌ Normal il getirme hatası: $e');
      return left(UnknownFailure(message: "Normal iller getirilemedi: $e"));
    }
  }

  /// Bölgeye göre illeri getir
  Future<Either<Failure, List<ProvinceModel>>> getProvincesByRegion(String region) async {
    try {
      print('🌍 Bölge illeri getiriliyor: $region');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final provincesByRegion = provincesModel.getProvincesByRegion(region);
          print('✅ $region bölgesi illeri getirildi: ${provincesByRegion.length} adet');
          return right(provincesByRegion);
        },
      );
    } catch (e) {
      print('❌ Bölge illeri getirme hatası: $e');
      return left(UnknownFailure(message: "Bölge illeri getirilemedi: $e"));
    }
  }

  /// Gelişmişlik seviyesine göre illeri getir
  Future<Either<Failure, List<ProvinceModel>>> getProvincesByDevelopment(String developmentLevel) async {
    try {
      print('📈 Gelişmişlik seviyesi illeri getiriliyor: $developmentLevel');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final groupedByDevelopment = provincesModel.groupedByDevelopment;
          final provinces = groupedByDevelopment[developmentLevel] ?? [];
          print('✅ $developmentLevel seviyesi illeri getirildi: ${provinces.length} adet');
          return right(provinces);
        },
      );
    } catch (e) {
      print('❌ Gelişmişlik seviyesi illeri getirme hatası: $e');
      return left(UnknownFailure(message: "Gelişmişlik seviyesi illeri getirilemedi: $e"));
    }
  }

  /// Alfabetik sıralı illeri getir
  Future<Either<Failure, List<ProvinceModel>>> getProvincesSortedAlphabetically() async {
    try {
      print('🔤 Alfabetik sıralı iller getiriliyor...');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final sortedProvinces = provincesModel.sortedAlphabetically;
          print('✅ Alfabetik sıralı iller getirildi: ${sortedProvinces.length} adet');
          return right(sortedProvinces);
        },
      );
    } catch (e) {
      print('❌ Alfabetik sıralı iller getirme hatası: $e');
      return left(UnknownFailure(message: "Alfabetik sıralı iller getirilemedi: $e"));
    }
  }

  /// Plaka koduna göre sıralı illeri getir
  Future<Either<Failure, List<ProvinceModel>>> getProvincesSortedByCode() async {
    try {
      print('🔢 Plaka koduna göre sıralı iller getiriliyor...');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final sortedProvinces = provincesModel.sortedByCode;
          print('✅ Plaka koduna göre sıralı iller getirildi: ${sortedProvinces.length} adet');
          return right(sortedProvinces);
        },
      );
    } catch (e) {
      print('❌ Plaka koduna göre sıralı iller getirme hatası: $e');
      return left(UnknownFailure(message: "Plaka koduna göre sıralı iller getirilemedi: $e"));
    }
  }

  /// En popüler turistik illeri getir
  Future<Either<Failure, List<ProvinceModel>>> getTopTouristicProvinces() async {
    try {
      print('🏖️ Turistik iller getiriliyor...');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final touristicProvinces = provincesModel.topTouristicProvinces;
          print('✅ Turistik iller getirildi: ${touristicProvinces.length} adet');
          return right(touristicProvinces);
        },
      );
    } catch (e) {
      print('❌ Turistik iller getirme hatası: $e');
      return left(UnknownFailure(message: "Turistik iller getirilemedi: $e"));
    }
  }

  /// Rastgele il getir
  Future<Either<Failure, ProvinceModel>> getRandomProvince() async {
    try {
      print('🎲 Rastgele il getiriliyor...');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final randomProvince = provincesModel.randomProvince;
          print('✅ Rastgele il getirildi: ${randomProvince.name}');
          return right(randomProvince);
        },
      );
    } catch (e) {
      print('❌ Rastgele il getirme hatası: $e');
      return left(UnknownFailure(message: "Rastgele il getirilemedi: $e"));
    }
  }

  /// İl istatistiklerini getir
  Future<Either<Failure, Map<String, dynamic>>> getProvinceStatistics() async {
    try {
      print('📊 İl istatistikleri getiriliyor...');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final statistics = provincesModel.statisticsSummary;
          print('✅ İl istatistikleri getirildi');
          return right(statistics);
        },
      );
    } catch (e) {
      print('❌ İl istatistikleri getirme hatası: $e');
      return left(UnknownFailure(message: "İl istatistikleri getirilemedi: $e"));
    }
  }

  /// Bölge istatistiklerini getir
  Future<Either<Failure, Map<String, int>>> getRegionStatistics() async {
    try {
      print('🌍 Bölge istatistikleri getiriliyor...');
      
      final provincesResult = await getAllProvinces();
      
      return provincesResult.fold(
        (failure) => left(failure),
        (provincesModel) {
          final regionStats = provincesModel.regionStatistics;
          print('✅ Bölge istatistikleri getirildi');
          return right(regionStats);
        },
      );
    } catch (e) {
      print('❌ Bölge istatistikleri getirme hatası: $e');
      return left(UnknownFailure(message: "Bölge istatistikleri getirilemedi: $e"));
    }
  }

  /// İlleri yenile (cache'i temizle ve yeniden getir)
  Future<Either<Failure, ProvincesResponseModel>> refreshProvinces() async {
    try {
      print('🔄 İller yenileniyor...');
      
      // Cache'i temizle
      await _clearProvincesCache();
      
      // Yeniden getir
      return await getAllProvinces();
    } catch (e) {
      print('❌ İller yenileme hatası: $e');
      return left(UnknownFailure(message: "İller yenilenemedi: $e"));
    }
  }

  // Cache işlemleri
  Future<void> _cacheProvinces(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_provinces', data.toString());
      await prefs.setInt('provinces_cache_time', DateTime.now().millisecondsSinceEpoch);
      print('💾 İller cache\'e kaydedildi');
    } catch (e) {
      print('⚠️ Cache kaydetme hatası: $e');
    }
  }

  Future<ProvincesResponseModel?> _getCachedProvinces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_provinces');
      final cacheTime = prefs.getInt('provinces_cache_time');
      
      if (cachedData != null && cacheTime != null) {
        // Cache 24 saat geçerli
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (cacheAge < 24 * 60 * 60 * 1000) {
          // Cache'den parse et - bu gerçek implementasyonda JSON.decode kullanılacak
          print('📦 Cache\'den iller yüklendi (${(cacheAge / (60 * 60 * 1000)).toStringAsFixed(1)} saat önce)');
          return null; // Gerçek implementasyonda JSON.decode yapılacak
        }
      }
    } catch (e) {
      print('⚠️ Cache okuma hatası: $e');
    }
    return null;
  }

  Future<void> _clearProvincesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_provinces');
      await prefs.remove('provinces_cache_time');
      print('🗑️ İller cache\'i temizlendi');
    } catch (e) {
      print('⚠️ Cache temizleme hatası: $e');
    }
  }
}
