import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/realestate/refrealestate_category_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class ReferenceRealEstateCategoryRepository with BaseRepository {
  static final ReferenceRealEstateCategoryRepository _instance = ReferenceRealEstateCategoryRepository._internal();
  factory ReferenceRealEstateCategoryRepository() => _instance;
  ReferenceRealEstateCategoryRepository._internal();

  final DioClient _client = DioClient();

  /// Tüm emlak kategorilerini getir
  Future<Either<Failure, PropertyTypeResponseModel>> getAllPropertyTypes() async {
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

      print('🏠 Emlak kategorileri çekiliyor...');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zonnin/property-types",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Emlak kategorileri başarıyla alındı');
        return right(PropertyTypeResponseModel.fromJson(response.data as List<dynamic>));
      } else {
        return left(ServerFailure(
          message: "Emlak kategorileri alınamadı",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Emlak kategorileri API hatası: ${e.message}');
      return left(NetworkFailure(
        message: "Emlak kategorileri çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel emlak kategorileri hatası: $e');
      return left(UnknownFailure(message: "Emlak kategorileri hatası: $e"));
    }
  }

  /// Sadece konut türlerini getir
  Future<Either<Failure, PropertyTypeModel?>> getHousingTypes() async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final housingCategory = response.findCategory('konut');
          if (housingCategory != null) {
            print('✅ Konut türleri başarıyla alındı: ${housingCategory.children.length} tür');
            return right(housingCategory);
          } else {
            return left(ValidationFailure(message: "Konut kategorisi bulunamadı"));
          }
        },
      );
    } catch (e) {
      print('❌ Konut türleri hatası: $e');
      return left(UnknownFailure(message: "Konut türleri hatası: $e"));
    }
  }

  /// Sadece iş yeri türlerini getir
  Future<Either<Failure, PropertyTypeModel?>> getCommercialTypes() async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final commercialCategory = response.findCategory('is-yeri');
          if (commercialCategory != null) {
            print('✅ İş yeri türleri başarıyla alındı: ${commercialCategory.children.length} tür');
            return right(commercialCategory);
          } else {
            return left(ValidationFailure(message: "İş yeri kategorisi bulunamadı"));
          }
        },
      );
    } catch (e) {
      print('❌ İş yeri türleri hatası: $e');
      return left(UnknownFailure(message: "İş yeri türleri hatası: $e"));
    }
  }

  /// Sadece arsa türlerini getir
  Future<Either<Failure, PropertyTypeModel?>> getLandTypes() async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final landCategory = response.findCategory('arsa');
          if (landCategory != null) {
            print('✅ Arsa türleri başarıyla alındı: ${landCategory.children.length} tür');
            return right(landCategory);
          } else {
            return left(ValidationFailure(message: "Arsa kategorisi bulunamadı"));
          }
        },
      );
    } catch (e) {
      print('❌ Arsa türleri hatası: $e');
      return left(UnknownFailure(message: "Arsa türleri hatası: $e"));
    }
  }

  /// Belirli kategoriye ait alt türleri getir
  Future<Either<Failure, List<PropertyTypeChildModel>>> getCategorySubTypes(String categoryCode) async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final category = response.findCategory(categoryCode);
          if (category != null) {
            print('✅ $categoryCode kategorisi alt türleri alındı: ${category.children.length} tür');
            return right(category.children);
          } else {
            return left(ValidationFailure(message: "$categoryCode kategorisi bulunamadı"));
          }
        },
      );
    } catch (e) {
      print('❌ Kategori alt türleri hatası: $e');
      return left(UnknownFailure(message: "Kategori alt türleri hatası: $e"));
    }
  }

  /// Popüler emlak türlerini getir (dropdown/seçim için)
  Future<Either<Failure, List<PropertyTypeChildModel>>> getPopularTypes({int limit = 10}) async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final popularTypes = response.popularTypes.take(limit).toList();
          print('✅ Popüler emlak türleri alındı: ${popularTypes.length} tür');
          return right(popularTypes);
        },
      );
    } catch (e) {
      print('❌ Popüler türler hatası: $e');
      return left(UnknownFailure(message: "Popüler türler hatası: $e"));
    }
  }

  /// Tüm alt türleri flat liste olarak getir (arama için)
  Future<Either<Failure, List<PropertyTypeChildModel>>> getAllSubTypes() async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final allSubTypes = response.allChildren;
          print('✅ Tüm alt türler alındı: ${allSubTypes.length} tür');
          return right(allSubTypes);
        },
      );
    } catch (e) {
      print('❌ Alt türler hatası: $e');
      return left(UnknownFailure(message: "Alt türler hatası: $e"));
    }
  }

  /// Belirli kod ile emlak türü bilgisini getir
  Future<Either<Failure, PropertyTypeChildModel?>> getPropertyTypeByCode(String code) async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final propertyType = response.findChildByCode(code);
          if (propertyType != null) {
            print('✅ Emlak türü bulundu: ${propertyType.displayName}');
            return right(propertyType);
          } else {
            print('⚠️ Emlak türü bulunamadı: $code');
            return right(null);
          }
        },
      );
    } catch (e) {
      print('❌ Emlak türü arama hatası: $e');
      return left(UnknownFailure(message: "Emlak türü arama hatası: $e"));
    }
  }

  /// Dropdown/seçim listesi için kategori seçeneklerini getir
  Future<Either<Failure, List<Map<String, dynamic>>>> getCategoryOptions() async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final options = response.categoryOptions;
          print('✅ Kategori seçenekleri alındı: ${options.length} kategori');
          return right(options);
        },
      );
    } catch (e) {
      print('❌ Kategori seçenekleri hatası: $e');
      return left(UnknownFailure(message: "Kategori seçenekleri hatası: $e"));
    }
  }

  /// Arama filtresi için tüm seçenekleri getir
  Future<Either<Failure, List<Map<String, dynamic>>>> getSearchFilterOptions() async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final options = response.searchFilterOptions;
          print('✅ Arama filtre seçenekleri alındı: ${options.length} seçenek');
          return right(options);
        },
      );
    } catch (e) {
      print('❌ Arama filtre seçenekleri hatası: $e');
      return left(UnknownFailure(message: "Arama filtre seçenekleri hatası: $e"));
    }
  }

  /// Kategori bazlı gruplama yaparak getir
  Future<Either<Failure, Map<String, List<PropertyTypeChildModel>>>> getGroupedByCategory() async {
    try {
      final allTypesResult = await getAllPropertyTypes();
      
      return allTypesResult.fold(
        (failure) => left(failure),
        (response) {
          final grouped = response.groupedByCategory;
          print('✅ Kategori bazlı gruplama alındı: ${grouped.length} kategori');
          return right(grouped);
        },
      );
    } catch (e) {
      print('❌ Kategori gruplama hatası: $e');
      return left(UnknownFailure(message: "Kategori gruplama hatası: $e"));
    }
  }

  /// Cache'lenmiş verileri temizle ve yeniden getir
  Future<Either<Failure, PropertyTypeResponseModel>> refreshPropertyTypes() async {
    try {
      // Cache temizleme işlemi burada olabilir
      print('🔄 Emlak kategorileri cache temizleniyor ve yeniden getiriliyor...');
      
      return await getAllPropertyTypes();
    } catch (e) {
      print('❌ Emlak kategorileri yenileme hatası: $e');
      return left(UnknownFailure(message: "Emlak kategorileri yenileme hatası: $e"));
    }
  }
}
