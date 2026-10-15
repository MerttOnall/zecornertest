import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/auth/advisor_office_scope.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../models/contact/contacts_api_model.dart';
import 'package:zecorner/core/config/env_api.dart';

String _extractContactsApiErrorMessage(dynamic data) {
  if (data == null) return 'Kişi listesi alınamadı';
  if (data is String) {
    return data.trim().isNotEmpty ? data.trim() : 'Kişi listesi alınamadı';
  }
  if (data is Map) {
    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    final err = data['error'];
    if (err is String && err.trim().isNotEmpty) return err.trim();
    final detail = data['detail'];
    if (detail is Map) {
      final dm = detail['message'];
      if (dm is String && dm.trim().isNotEmpty) return dm.trim();
    }
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
  }
  return 'Kişi listesi alınamadı';
}

class ContactsApiRepository {
  static final ContactsApiRepository _instance = ContactsApiRepository._internal();
  factory ContactsApiRepository() => _instance;
  ContactsApiRepository._internal();

  final DioClient _client = DioClient();

  // GET - Sayfalama ile contactları getir
  Future<Either<Failure, List<String>>> getPersonTypes() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: 'Token bulunamadı'));
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Version': '1.0',
        'X-Client': 'flutter-app',
        'X-SESSION': token,
        'X-API-KEY': apiKey ?? 'ed017c68-24ca-4239-ae68-0fa041391855',
        'X-APP-ID': appId ?? 'zecorner',
        'Authorization': 'Bearer $token',
      };

      // Tüm contactları çek
      final contactsEndpoint = dotenv.env["DCONTACTS"] ?? "/api/zecorner/contacts";
      final baseUrl = "${EnvApi.origin}$contactsEndpoint";
      
      print('🌐 Person Types API: $baseUrl');
      
      final response = await _client.dio.get(
        baseUrl,
        options: Options(headers: headers),
        queryParameters: {
          'page': 1,
          'limit': 1000, // Tüm verileri çek
        },
      );

      print('✅ Person Types API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('📦 Full Response Data: $data');
        
        final List<dynamic> contactsData = data['contacts'] ?? [];
        print('📋 Contacts Data Length: ${contactsData.length}');
        
        // Tüm type_description değerlerini topla
        final Set<String> personTypes = {};
        for (final contact in contactsData) {
          if (contact['type_description'] != null && contact['type_description'].toString().isNotEmpty) {
            final typeDesc = contact['type_description'].toString();
            personTypes.add(typeDesc);
            print('🔍 Bulunan type_description: "$typeDesc"');
          }
        }
        
        final List<String> sortedTypes = personTypes.toList()..sort();
        print('🔍 Bulunan kullanıcı tipleri: $sortedTypes');
        print('🔍 Toplam benzersiz tip sayısı: ${sortedTypes.length}');
        
        return Right(sortedTypes);
      } else {
        return Left(ServerFailure(message: 'API hatası: ${response.statusCode}'));
      }
    } catch (e) {
      print('❌ Person Types API Error: $e');
      return Left(ServerFailure(message: 'Kullanıcı tipleri yüklenemedi: $e'));
    }
  }

  Future<Either<Failure, ContactsApiResponse>> getContacts({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? personType,
    int? types,
    int? connectedContact,
    /// Web satış raporu: `get-contacts/?office=30`
    int? office,
    /// true: web ile aynı `/api/get-contacts` (ofis kullanıcı listesi)
    bool useGetContacts = false,
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final scope = await AdvisorOfficeScope.load();
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'pageSize': limit,
        'sortOrder': 'asc',
        'sortColumn': 'contact_no',
        // Web ile aynı: her zaman searchText gönder
        'searchText': search?.trim() ?? '',
      };

      final trimmedSearch = search?.trim() ?? '';
      if (trimmedSearch.isNotEmpty) {
        print('🔍 API arama (searchText): "$trimmedSearch"');
        print('🔍 Gönderilen parametreler: $queryParams');
      }

      if (status != null && status.isNotEmpty && status != 'Tümü') {
        if (status == 'Aktif') {
          queryParams['status'] = 1;
          print('🔍 Durum filtresi: Aktif (status=1)');
        } else if (status == 'Pasif') {
          queryParams['status'] = 0;
          print('🔍 Durum filtresi: Pasif (status=0)');
        }
      } else {
        print('🔍 Durum filtresi: Tümü (filtre yok)');
      }

      // types (sayısal tip kodu) - Web API ile uyumlu (get-contacts?types=3)
      if (types != null) {
        queryParams['types'] = types;
        print('🔍 Kişi türü filtresi (types): $types');
      } else if (personType != null && personType.isNotEmpty && personType != 'Tümü') {
        queryParams['type_description'] = personType;
        print('🔍 Kişi türü filtresi (type_description): "$personType"');
      } else {
        print('🔍 Kişi türü filtresi: Tümü (filtre yok)');
      }

      // Web: get-contacts/?office=30 — office ile connected_contact AND edilmemeli
      // (ikisini birden göndermek boş liste döndürebiliyor).
      if (office != null) {
        queryParams['office'] = office;
        print('🔍 Ofis filtresi (office): $office');
      } else if (connectedContact != null) {
        queryParams['connected_contact'] = connectedContact;
        print('🔍 Bağlı ofis filtresi (connected_contact): $connectedContact');
      }

      // Satış raporu / Kişiler: web ile aynı GET_CONTACTS (Amplify/Next).
      // Diğer ekranlar BAMMA DCONTACTS kullanmaya devam eder.
      String contactsEndpoint;
      String resolveBase(String path) {
        if (useGetContacts || office != null) {
          final web = EnvApi.webNextApiOrigin;
          if (web != null && web.isNotEmpty) {
            return '$web$path';
          }
        }
        return '${EnvApi.origin}$path';
      }

      if (useGetContacts || office != null) {
        var getPath =
            (dotenv.env['GET_CONTACTS'] ?? '/api/get-contacts').trim();
        if (getPath.isEmpty) getPath = '/api/get-contacts';
        getPath = getPath.startsWith('/') ? getPath : '/$getPath';
        // Amplify/Next: trailing slash yoksa 308
        if (!getPath.endsWith('/')) getPath = '$getPath/';
        contactsEndpoint = getPath;
      } else {
        final dContactsPath =
            (dotenv.env['DCONTACTS'] ?? '/api/zecorner/contacts').trim();
        contactsEndpoint =
            dContactsPath.startsWith('/') ? dContactsPath : '/$dContactsPath';
      }

      final baseUrl = resolveBase(contactsEndpoint);
      
      print('🌐 API: $baseUrl');
      print('📋 Parametreler: $queryParams');

      Future<Response<dynamic>> doGet(String url) => _client.dio.get(
            url,
            queryParameters: queryParams,
            options: Options(
              headers: headers,
              validateStatus: (status) => status != null && status < 600,
              followRedirects: true,
              maxRedirects: 5,
            ),
          );

      var response = await doGet(baseUrl);

      // GET_CONTACTS 404/405 ise BAMMA DCONTACTS’a düş
      if ((useGetContacts || office != null) &&
          (response.statusCode == 404 ||
              response.statusCode == 405 ||
              response.statusCode == 401)) {
        final dContactsPath =
            (dotenv.env['DCONTACTS'] ?? '/api/zecorner/contacts').trim();
        final fallback = dContactsPath.startsWith('/')
            ? dContactsPath
            : '/$dContactsPath';
        final fallbackUrl = '${EnvApi.origin}$fallback';
        print('🌐 Contacts fallback (DCONTACTS): $fallbackUrl');
        response = await doGet(fallbackUrl);
      }

      print('✅ API Status: ${response.statusCode}');
      print('📦 Full Response: ${response.data}');
      
      if (trimmedSearch.isNotEmpty) {
        final data = response.data;
        final List<dynamic> contactsData = data is Map
            ? (data['contacts'] ?? data['data'] ?? [])
            : <dynamic>[];
        print('🔍 Bulunan: ${contactsData.length} kişi');
        for (int i = 0; i < contactsData.length && i < 3; i++) {
          final contact = contactsData[i];
          print('🔍 ${i + 1}: ${contact['name']} ${contact['surname']} (type_description: ${contact['type_description']})');
        }
      }
      
      if (personType != null && personType.isNotEmpty && personType != 'Tümü') {
        final data = response.data;
        final List<dynamic> contactsData = data is Map
            ? (data['contacts'] ?? data['data'] ?? [])
            : <dynamic>[];
        print('🔍 Kişi türü filtresi sonuçları: ${contactsData.length} kişi');
        for (int i = 0; i < contactsData.length && i < 3; i++) {
          final contact = contactsData[i];
          print('🔍 ${i + 1}: ${contact['name']} ${contact['surname']} (type_description: ${contact['type_description']})');
        }
      }

      if (response.statusCode == 200) {
        final data = response.data;
        print('📦 API Response Data Type: ${data.runtimeType}');

        List<dynamic> contactsData = const [];
        if (data is List) {
          contactsData = data;
        } else if (data is Map) {
          print('📦 API Response Keys: ${data.keys.toList()}');
          final raw = data['contacts'] ?? data['data'] ?? data['results'] ?? [];
          if (raw is List) {
            contactsData = raw;
          } else if (raw is Map) {
            contactsData = [raw];
          }
        }

        final contacts = <ContactsApiModel>[];
        for (final item in contactsData) {
          if (item is! Map) continue;
          try {
            contacts.add(
              ContactsApiModel.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (e) {
            print('⚠️ Contact parse atlandı: $e');
          }
        }
        print('✅ Parse edilen kişi sayısı: ${contacts.length}');

        final visible = contacts.where((contact) {
          if (scope.officeId > 0 && contact.contactNo == scope.officeId) {
            return true;
          }
          return !scope.isForeignOffice(
            officeId: contact.connectedContact,
            officeTitle: contact.connectedContactTitle,
          );
        }).toList();

        final totalCount = data is Map
            ? (data['totalCount'] ?? data['total'] ?? contacts.length)
            : contacts.length;
        final totalPages = data is Map
            ? (data['totalPages'] ?? data['total_pages'] ?? 1)
            : 1;
        final pageNum = data is Map ? (data['page'] ?? page) : page;

        return Right(ContactsApiResponse(
          contacts: visible,
          totalCount: totalCount is int ? totalCount : visible.length,
          totalPages: totalPages is int ? totalPages : 1,
          page: pageNum is int ? pageNum : page,
        ));
      }
      if (response.statusCode == 401) {
        return Left(
          AuthFailure(
            message: _extractContactsApiErrorMessage(response.data),
          ),
        );
      }
      return Left(
        ServerFailure(
          message: _extractContactsApiErrorMessage(response.data),
        ),
      );
    } on DioException catch (e) {
      print('❌ Contacts API Error: ${e.message}');
      final data = e.response?.data;
      final code = e.response?.statusCode;
      if (code == 401) {
        return Left(
          AuthFailure(
            message: data != null
                ? _extractContactsApiErrorMessage(data)
                : 'Oturum süresi dolmuş',
          ),
        );
      }
      if (data != null) {
        return Left(ServerFailure(message: _extractContactsApiErrorMessage(data)));
      }
      return Left(
        ServerFailure(
          message: 'Bağlantı hatası: ${e.message ?? 'Bilinmeyen'}',
        ),
      );
    } catch (e) {
      print('❌ Contacts Repository Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  // GET - ID'ye göre contact getir
  Future<Either<Failure, ContactsApiModel>> getContactById(int contactId) async {
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final contactsEndpoint = dotenv.env["DCONTACTS"] ?? "/api/zecorner/contacts";
      final baseUrl = "${EnvApi.origin}$contactsEndpoint";

      final response = await _client.dio.get(
        "$baseUrl/$contactId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final contact = ContactsApiModel.fromJson(response.data['data'] ?? response.data);
        return Right(contact);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact bulunamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // PUT - Contact durumunu güncelle
  Future<Either<Failure, bool>> updateContactStatus({
    required int contactId,
    required bool isActive,
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final contactsEndpoint = dotenv.env["DCONTACTS"] ?? "/api/zecorner/contacts";
      final baseUrl = "${EnvApi.origin}$contactsEndpoint";

      final response = await _client.dio.put(
        "$baseUrl/$contactId/status",
        data: {'status': isActive ? 1 : 0},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact durumu güncellenemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Yeni contact oluştur
  Future<Either<Failure, ContactsApiModel>> createContact(ContactsApiModel contact) async {
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final contactsEndpoint = dotenv.env["DCONTACTS"] ?? "/api/zecorner/contacts";
      final baseUrl = "${EnvApi.origin}$contactsEndpoint";

      final response = await _client.dio.post(
        baseUrl,
        data: contact.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdContact = ContactsApiModel.fromJson(response.data['data'] ?? response.data);
        return Right(createdContact);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact oluşturulamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // PUT - Contact güncelle
  Future<Either<Failure, ContactsApiModel>> updateContact(int contactId, ContactsApiModel contact) async {
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final contactsEndpoint = dotenv.env["DCONTACTS"] ?? "/api/zecorner/contacts";
      final baseUrl = "${EnvApi.origin}$contactsEndpoint";

      final response = await _client.dio.put(
        "$baseUrl/$contactId",
        data: contact.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final updatedContact = ContactsApiModel.fromJson(response.data['data'] ?? response.data);
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
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final contactsEndpoint = dotenv.env["DCONTACTS"] ?? "/api/zecorner/contacts";
      final baseUrl = "${EnvApi.origin}$contactsEndpoint";

      final response = await _client.dio.delete(
        "$baseUrl/$contactId",
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
}
