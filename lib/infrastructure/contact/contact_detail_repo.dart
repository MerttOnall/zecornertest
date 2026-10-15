import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../models/contact/contact_detail_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class ContactDetailRepository {
  static final ContactDetailRepository _instance = ContactDetailRepository._internal();
  factory ContactDetailRepository() => _instance;
  ContactDetailRepository._internal();

  final DioClient _client = DioClient();

  // GET - ID'ye göre contact detail getir
  Future<Either<Failure, ContactDetailModel>> getContactDetail(int contactId) async {
    try {
      print('📞 Contact detail getiriliyor: $contactId');
      
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        print('❌ Token bulunamadı');
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        print('❌ API anahtarları bulunamadı');
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts/$contactId/detail",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Contact detail başarıyla getirildi');
        final contactDetail = ContactDetailModel.fromJson(response.data['data'] ?? response.data);
        return Right(contactDetail);
      } else {
        print('❌ Contact detail getirilemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact detail bulunamadı'));
      }
    } catch (e) {
      print('❌ Contact detail getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Tüm contact detailları getir
  Future<Either<Failure, List<ContactDetailModel>>> getAllContactDetails() async {
    try {
      print('📞 Tüm contact detayları getiriliyor...');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts/details",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Contact detaylar başarıyla getirildi');
        final List<dynamic> data = response.data['data'] ?? response.data;
        final contactDetails = data.map((json) => ContactDetailModel.fromJson(json)).toList();
        return Right(contactDetails);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact detayları getirilemedi'));
      }
    } catch (e) {
      print('❌ Contact detayları getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Sayfalama ile contact detailları getir
  Future<Either<Failure, Map<String, dynamic>>> getContactDetailsWithPagination({
    int page = 1,
    int limit = 20,
    String? search,
    int? typeCode,
    bool? isActive,
  }) async {
    try {
      print('📞 Contact detayları sayfalama ile getiriliyor: page=$page, limit=$limit');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (typeCode != null) {
        queryParams['type'] = typeCode;
      }

      if (isActive != null) {
        queryParams['status'] = isActive ? 1 : 0;
      }

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts/details",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Contact detayları sayfalama ile getirildi');
        final data = response.data;
        final List<dynamic> contactsData = data['data'] ?? [];
        final contactDetails = contactsData.map((json) => ContactDetailModel.fromJson(json)).toList();
        
        return Right({
          'contactDetails': contactDetails,
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
          'totalPages': data['total_pages'] ?? 0,
        });
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact detayları getirilemedi'));
      }
    } catch (e) {
      print('❌ Contact detayları sayfalama hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Arama yap
  Future<Either<Failure, List<ContactDetailModel>>> searchContactDetails(String query) async {
    try {
      print('🔍 Contact detayları aranıyor: $query');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts/details/search",
        queryParameters: {'q': query},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Contact detayları arama tamamlandı');
        final List<dynamic> data = response.data['data'] ?? response.data;
        final contactDetails = data.map((json) => ContactDetailModel.fromJson(json)).toList();
        return Right(contactDetails);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Arama yapılamadı'));
      }
    } catch (e) {
      print('❌ Contact detayları arama hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Tip'e göre contact detailları getir
  Future<Either<Failure, List<ContactDetailModel>>> getContactDetailsByType(int typeCode) async {
    try {
      print('📞 Tip göre contact detayları getiriliyor: $typeCode');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts/details/type/$typeCode",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Tip göre contact detayları getirildi');
        final List<dynamic> data = response.data['data'] ?? response.data;
        final contactDetails = data.map((json) => ContactDetailModel.fromJson(json)).toList();
        return Right(contactDetails);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact detayları getirilemedi'));
      }
    } catch (e) {
      print('❌ Tip göre contact detayları getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Yeni contact detail oluştur
  Future<Either<Failure, ContactDetailModel>> createContactDetail(ContactDetailModel contactDetail) async {
    try {
      print('💾 Yeni contact detail oluşturuluyor...');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/contacts/details",
        data: contactDetail.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Contact detail başarıyla oluşturuldu');
        final createdContactDetail = ContactDetailModel.fromJson(response.data['data'] ?? response.data);
        return Right(createdContactDetail);
      } else {
        print('❌ Contact detail oluşturulamadı: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact detail oluşturulamadı'));
      }
    } catch (e) {
      print('❌ Contact detail oluşturma hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Contact detail güncelle
  Future<Either<Failure, ContactDetailModel>> updateContactDetail(int contactId, ContactDetailModel contactDetail) async {
    try {
      print('🔄 Contact detail güncelleniyor: $contactId');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.put(
        "${EnvApi.origin}/api/zecorner/contacts/$contactId/detail",
        data: contactDetail.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Contact detail başarıyla güncellendi');
        final updatedContactDetail = ContactDetailModel.fromJson(response.data['data'] ?? response.data);
        return Right(updatedContactDetail);
      } else {
        print('❌ Contact detail güncellenemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact detail güncellenemedi'));
      }
    } catch (e) {
      print('❌ Contact detail güncelleme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Contact detail kısmi güncelleme (PATCH)
  Future<Either<Failure, ContactDetailModel>> updateContactDetailPartial(int contactId, Map<String, dynamic> updates) async {
    try {
      print('🔄 Contact detail kısmi güncelleme: $contactId');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.patch(
        "${EnvApi.origin}/api/zecorner/contacts/$contactId/detail",
        data: updates,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Contact detail kısmi güncelleme tamamlandı');
        final updatedContactDetail = ContactDetailModel.fromJson(response.data['data'] ?? response.data);
        return Right(updatedContactDetail);
      } else {
        print('❌ Contact detail kısmi güncelleme başarısız: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact detail güncellenemedi'));
      }
    } catch (e) {
      print('❌ Contact detail kısmi güncelleme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // DELETE - Contact detail sil
  Future<Either<Failure, bool>> deleteContactDetail(int contactId) async {
    try {
      print('🗑️ Contact detail siliniyor: $contactId');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.delete(
        "${EnvApi.origin}/api/zecorner/contacts/$contactId/detail",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Contact detail başarıyla silindi');
        return const Right(true);
      } else {
        print('❌ Contact detail silinemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact detail silinemedi'));
      }
    } catch (e) {
      print('❌ Contact detail silme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // DELETE - Çoklu contact detail sil
  Future<Either<Failure, bool>> deleteMultipleContactDetails(List<int> contactIds) async {
    try {
      print('🗑️ Çoklu contact detail siliniyor: ${contactIds.length} adet');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.delete(
        "${EnvApi.origin}/api/zecorner/contacts/details/bulk",
        data: {'contact_ids': contactIds},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Çoklu contact detail başarıyla silindi');
        return const Right(true);
      } else {
        print('❌ Çoklu contact detail silinemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact detayları silinemedi'));
      }
    } catch (e) {
      print('❌ Çoklu contact detail silme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Contact durumunu değiştir (aktif/pasif)
  Future<Either<Failure, ContactDetailModel>> toggleContactStatus(int contactId) async {
    try {
      print('🔄 Contact durumu değiştiriliyor: $contactId');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/contacts/$contactId/toggle-status",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Contact durumu başarıyla değiştirildi');
        final updatedContactDetail = ContactDetailModel.fromJson(response.data['data'] ?? response.data);
        return Right(updatedContactDetail);
      } else {
        print('❌ Contact durumu değiştirilemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact durumu değiştirilemedi'));
      }
    } catch (e) {
      print('❌ Contact durumu değiştirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Aktif contact detailları getir
  Future<Either<Failure, List<ContactDetailModel>>> getActiveContactDetails() async {
    try {
      print('📞 Aktif contact detayları getiriliyor...');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts/details/active",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Aktif contact detayları getirildi');
        final List<dynamic> data = response.data['data'] ?? response.data;
        final contactDetails = data.map((json) => ContactDetailModel.fromJson(json)).toList();
        return Right(contactDetails);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Aktif contact detayları getirilemedi'));
      }
    } catch (e) {
      print('❌ Aktif contact detayları getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - İnaktif contact detailları getir
  Future<Either<Failure, List<ContactDetailModel>>> getInactiveContactDetails() async {
    try {
      print('📞 İnaktif contact detayları getiriliyor...');
      
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts/details/inactive",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ İnaktif contact detayları getirildi');
        final List<dynamic> data = response.data['data'] ?? response.data;
        final contactDetails = data.map((json) => ContactDetailModel.fromJson(json)).toList();
        return Right(contactDetails);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'İnaktif contact detayları getirilemedi'));
      }
    } catch (e) {
      print('❌ İnaktif contact detayları getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }
}
