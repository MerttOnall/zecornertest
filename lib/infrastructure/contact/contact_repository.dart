import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../models/contact/contact_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class ContactRepository {
  static final ContactRepository _instance = ContactRepository._internal();
  factory ContactRepository() => _instance;
  ContactRepository._internal();

  final DioClient _client = DioClient();

  // GET - Tüm contactları getir
  Future<Either<Failure, List<ContactModel>>> getAllContacts() async {
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final contacts = data.map((json) => ContactModel.fromJson(json)).toList();
        return Right(contacts);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contactlar getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - ID'ye göre contact getir
  Future<Either<Failure, ContactModel>> getContactById(int contactId) async {
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts/$contactId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final contact = ContactModel.fromJson(response.data['data'] ?? response.data);
        return Right(contact);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact bulunamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Tip'e göre contactları getir
  Future<Either<Failure, List<ContactModel>>> getContactsByType(int typeCode) async {
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts",
        queryParameters: {'type': typeCode},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final contacts = data.map((json) => ContactModel.fromJson(json)).toList();
        return Right(contacts);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contactlar getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Yeni contact oluştur
  Future<Either<Failure, ContactModel>> createContact(ContactModel contact) async {
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/contacts",
        data: contact.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdContact = ContactModel.fromJson(response.data['data'] ?? response.data);
        return Right(createdContact);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact oluşturulamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // PUT - Contact güncelle
  Future<Either<Failure, ContactModel>> updateContact(int contactId, ContactModel contact) async {
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.put(
        "${EnvApi.origin}/api/zecorner/contacts/$contactId",
        data: contact.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final updatedContact = ContactModel.fromJson(response.data['data'] ?? response.data);
        return Right(updatedContact);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact güncellenemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // DELETE - Contact sil
  Future<Either<Failure, bool>> deleteContact(int contactId) async {
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.delete(
        "${EnvApi.origin}/api/zecorner/contacts/$contactId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact silinemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Toplu contact silme
  Future<Either<Failure, bool>> deleteMultipleContacts(List<int> contactIds) async {
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/contacts/bulk-delete",
        data: {'contact_ids': contactIds},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contactlar silinemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Arama yap
  Future<Either<Failure, List<ContactModel>>> searchContacts(String query) async {
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
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts/search",
        queryParameters: {'q': query},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final contacts = data.map((json) => ContactModel.fromJson(json)).toList();
        return Right(contacts);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Arama yapılamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Sayfalama ile contactları getir
  Future<Either<Failure, Map<String, dynamic>>> getContactsWithPagination({
    int page = 1,
    int limit = 20,
    String? search,
    int? typeCode,
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

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contacts",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> contactsData = data['data'] ?? [];
        final contacts = contactsData.map((json) => ContactModel.fromJson(json)).toList();
        
        return Right({
          'contacts': contacts,
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
          'totalPages': data['total_pages'] ?? 0,
        });
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contactlar getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }
}
