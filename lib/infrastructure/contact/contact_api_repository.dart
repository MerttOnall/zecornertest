import 'dart:io';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/mixins/update_mixin.dart';
import '../../models/contact/contact_api_model.dart';
import '../../models/contact/refcontact_type_model.dart';
import '../../models/contact/ref_education_model.dart';
import '../../models/contact/ref_profession_model.dart';
import '../../models/contact/ref_city_model.dart';
import '../../models/contact/ref_country_model.dart';
import '../../models/province/provinces_model.dart';
import '../../models/province/provinces_detail_model.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/contact_update_payload.dart'
    show
        applyWebSaveContactAuth,
        contactUpdateRequestUri,
        isContactMutationAckOnly,
        unwrapContactUpdatePayload,
        webSaveContactOrigin;
import 'package:zecorner/core/config/env_api.dart';

class ContactApiRepository with UpdateMixin {
  static final ContactApiRepository _instance = ContactApiRepository._internal();
  factory ContactApiRepository() => _instance;
  ContactApiRepository._internal();

  final DioClient _client = DioClient();
  
  @override
  DioClient get dioClient => _client;

  // GET - Sayfalama ile contactları getir (users_screen.dart mantığına uygun)
  Future<Either<Failure, ContactApiResponse>> getContacts({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
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
        'X-SESSION': token, // Authorization: Bearer yerine X-SESSION kullanıyoruz
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
        queryParams['name'] = search;
        print('🔍 API arama (name): "$search"');
      }

      if (status != null && status.isNotEmpty && status != 'Tümü') {
        if (status == 'Aktif') {
          queryParams['status'] = 1;
        } else if (status == 'Pasif') {
          queryParams['status'] = 0;
        }
      }

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: ${EnvApi.origin}/api/zecorner/contact');
      print('📋 Query Parameters: $queryParams');
      print('📋 Headers: {X-SESSION: ${token.substring(0, 20)}..., X-API-KEY: $apiKey, X-APP-ID: $appId}');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contact",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('✅ API Response Status: ${response.statusCode}');
      print('📦 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // JSON yapısına göre parse et
        final List<dynamic> contactsData = data['contacts'] ?? data['data'] ?? [];
        final contacts = contactsData.map((json) => ContactApiModel.fromJson(json)).toList();
        
        return Right(ContactApiResponse(
          contacts: contacts,
          totalCount: data['totalCount'] ?? data['total'] ?? 0,
          totalPages: data['totalPages'] ?? data['total_pages'] ?? 0,
          page: data['page'] ?? page,
        ));
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contactlar getirilemedi'));
      }
    } on DioException catch (e) {
      print('❌ Contact API Error: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'API endpoint bulunamadı'));
      } else {
        return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ Contact Repository Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  // GET - ID'ye göre contact getir
  Future<Either<Failure, ContactApiModel>> getContactById(int contactId) async {
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
        'X-SESSION': token, // Authorization: Bearer yerine X-SESSION kullanıyoruz
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/contact/$contactId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final primary = _asContactMap(response.data);
        final found = ContactApiModel.collectAttachmentMaps(response.data);
        if (found.isNotEmpty) primary['attachments'] = found;
        final webMap = await _fetchWebContactMap(contactId, headers);
        final merged =
            webMap == null ? primary : _mergeContactMaps(primary, webMap);
        if (webMap != null) {
          final webFound = ContactApiModel.collectAttachmentMaps(webMap);
          if (webFound.isNotEmpty) {
            final current = ContactApiModel.collectAttachmentMaps(merged);
            merged['attachments'] = [...current, ...webFound];
          }
        }
        try {
          return Right(ContactApiModel.fromJson(merged));
        } catch (_) {
          return Right(ContactApiModel.fromJson({
            'contact_no': contactId,
            'name': merged['name'],
            'surname': merged['surname'],
            'e_mail': merged['e_mail'],
            'tel': merged['tel'],
            'detail': merged['detail'] is Map
                ? merged['detail']
                : <String, dynamic>{},
            'attachments': merged['attachments'],
          }));
        }
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact bulunamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  bool _looksLikeContact(Map<String, dynamic> map) {
    return map['contact_no'] != null ||
        map['contactNo'] != null ||
        map['detail'] != null ||
        map['attachments'] != null ||
        (map['name'] != null &&
            (map['surname'] != null ||
                map['e_mail'] != null ||
                map['eMail'] != null));
  }

  Map<String, dynamic>? _pickContact(dynamic node, [int depth = 0]) {
    if (node is! Map || depth > 4) return null;
    final map = Map<String, dynamic>.from(node);
    if (_looksLikeContact(map)) return map;
    for (final key in ['data', 'contact', 'result', 'payload']) {
      final found = _pickContact(map[key], depth + 1);
      if (found != null) return found;
    }
    return null;
  }

  Map<String, dynamic> _asContactMap(dynamic raw) {
    if (raw is String) {
      final text = raw.trim();
      if (text.startsWith('{') || text.startsWith('[')) {
        try {
          return _asContactMap(jsonDecode(text));
        } catch (_) {}
      }
      return {};
    }
    if (raw is List) {
      for (final item in raw) {
        final picked = _asContactMap(item);
        if (picked.isNotEmpty) return picked;
      }
      return {};
    }
    if (raw is! Map) return {};
    final body = Map<String, dynamic>.from(raw);
    final contact = _pickContact(body) ?? body;
    if (contact['attachments'] == null && body['attachments'] != null) {
      contact['attachments'] = body['attachments'];
    }
    if (contact['files'] == null && body['files'] != null) {
      contact['files'] = body['files'];
    }
    final data = body['data'];
    if (data is Map) {
      if (contact['attachments'] == null && data['attachments'] != null) {
        contact['attachments'] = data['attachments'];
      }
      if (contact['detail'] == null && data['detail'] != null) {
        contact['detail'] = data['detail'];
      }
    }
    return contact;
  }

  Map<String, dynamic> _mergeContactMaps(
    Map<String, dynamic> primary,
    Map<String, dynamic> extra,
  ) {
    final merged = Map<String, dynamic>.from(primary);
    for (final key in ['attachments', 'files']) {
      final combined = _concatAttachmentLists(primary[key], extra[key]);
      if (combined != null) merged[key] = combined;
    }
    if (extra['detail'] is Map) {
      final current = merged['detail'] is Map
          ? Map<String, dynamic>.from(merged['detail'] as Map)
          : <String, dynamic>{};
      final incoming = Map<String, dynamic>.from(extra['detail'] as Map);
      incoming.forEach((key, value) {
        if (key == 'attachments' || key == 'files') {
          final combined = _concatAttachmentLists(current[key], value);
          if (combined != null) current[key] = combined;
        } else if (current[key] == null) {
          current[key] = value;
        }
      });
      merged['detail'] = current;
    }
    if ((merged['name'] == null || merged['name'].toString().isEmpty) &&
        extra['name'] != null) {
      extra.forEach((key, value) {
        merged.putIfAbsent(key, () => value);
      });
    }
    return merged;
  }

  dynamic _decodeAttachmentSource(dynamic value) {
    if (value is! String) return value;
    final text = value.trim();
    if (!text.startsWith('[') && !text.startsWith('{')) return value;
    try {
      return jsonDecode(text);
    } catch (_) {
      return value;
    }
  }

  List<dynamic>? _concatAttachmentLists(dynamic primary, dynamic extra) {
    final out = <dynamic>[];
    void take(dynamic value) {
      final decoded = _decodeAttachmentSource(value);
      if (decoded is List) out.addAll(decoded);
      if (decoded is Map) out.add(decoded);
    }

    take(primary);
    take(extra);
    return out.isEmpty ? null : out;
  }

  /// Web düzenleme ekranı `GET /api/get-contact?no=` ile belgeleri de alır.
  Future<Map<String, dynamic>?> _fetchWebContactMap(
    int contactId,
    Map<String, String> headers,
  ) async {
    final origin = EnvApi.webNextApiOrigin;
    if (origin == null || origin.isEmpty) return null;
    final url = EnvApi.amplifyStyleTrailingSlash('$origin/api/get-contact') ??
        '$origin/api/get-contact/';
    try {
      final response = await _client.dio.get<dynamic>(
        url,
        queryParameters: {'no': contactId},
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return _asContactMap(response.data);
      }
    } catch (_) {}
    return null;
  }

  // POST - Contact durumunu güncelle (çalışan endpoint kullanarak)
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

      // Environment variable'ı kullan ve contact ID'yi ekle
      final setUserStatusEndpoint = dotenv.env["SETUSERSTATUS"] ?? "/api/zecorner/setUserStatus";
      final baseUrl = "${EnvApi.origin}$setUserStatusEndpoint";
      final endpoint = baseUrl.replaceAll('/id', '/$contactId');

      final response = await _client.dio.post(
        endpoint,
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
  Future<Either<Failure, ContactApiModel>> createContact(ContactApiModel contact) async {
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
        'X-SESSION': token, // Authorization: Bearer yerine X-SESSION kullanıyoruz
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print('🔄 Contact Create Request:');
      print('📋 Contact Data: ${contact.toJson()}');
      print('🚀 REQUEST: POST ${EnvApi.origin}/api/zecorner/contact');
      print('📤 Headers: $headers');
      print('📤 Data: ${contact.toJson()}');

      final baseUrl = (dotenv.env["BASE_URL"] ?? "${EnvApi.origin}").trim();
      final contactPath =
          (dotenv.env["PCONTACTS"] ?? "/api/zecorner/contact").trim();
      final createUrl = Uri.parse("$baseUrl$contactPath")
          .replace(queryParameters: const {"type": "save"})
          .toString();

      final response = await _client.dio.post(
        createUrl,
        data: contact.toJson(),
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} $createUrl');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdContact = ContactApiModel.fromJson(response.data['data'] ?? response.data);
        return Right(createdContact);
      } else {
        print('❌ ERROR: ${response.statusCode} - ${response.data}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact oluşturulamadı'));
      }
    } catch (e) {
      print('❌ ERROR: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // PUT - Contact güncelle
  Future<Either<Failure, ContactApiModel>> updateContact(int contactId, ContactApiModel contact) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT') ?? pref.getString('auth_token');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = <String, String>{
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      applyWebSaveContactAuth(headers, token);

      // Debug: Request payload'ı göster (Update için özel JSON metodu kullan)
      final requestData = contact.toUpdateJson();
      final uri = contactUpdateRequestUri(contactId);

      print('🔄 Update Contact Request (ID: $contactId):');
      print('📋 Contact Data: $requestData');
      print(
        '📋 POST $uri (${webSaveContactOrigin() != null ? "Next save-contact (web)" : "doğrudan BAMMA"})',
      );

      final response = await _client.dio.postUri(
        uri,
        data: requestData,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Contact başarıyla güncellendi (ID: $contactId)');
        final payload = unwrapContactUpdatePayload(response.data);
        if (payload == null) {
          return Left(ServerFailure(message: 'Geçersiz API yanıtı'));
        }
        if (isContactMutationAckOnly(payload)) {
          return Right(contact);
        }
        try {
          return Right(ContactApiModel.fromJson(payload));
        } catch (_) {
          return Right(contact);
        }
      } else {
        print('❌ Contact güncellenemedi: ${response.statusCode}');
        final d = response.data;
        String? msg;
        if (d is Map) {
          msg = d['DESCRIPTION']?.toString() ?? d['description']?.toString();
          msg ??= d['message']?.toString();
        }
        return Left(ServerFailure(message: msg ?? 'Contact güncellenemedi'));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Message: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      }
      return Left(ServerFailure(message: 'Bağlantı hatası: ${e.message}'));
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Contact güncelle (Web save-contact ile aynı: POST /contact/{id})
  Future<Either<Failure, ContactApiModel>> updateContactWithBody(
    int contactId,
    Map<String, dynamic> requestBody,
  ) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];
      final baseUrl = (dotenv.env["BASE_URL"] ?? "${EnvApi.origin}").trim();
      final contactEndpoint = (dotenv.env["PCONTACTS"] ?? "/api/zecorner/contact").trim();

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

      // Web save-contact: POST /contact/{no} (ID path'te, query yok)
      final url = "$baseUrl$contactEndpoint/$contactId";
      print('📤 updateContactWithBody: $url');

      final response = await _client.dio.post(
        url,
        data: requestBody,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        final contactData = data['data'] ?? data['result'];
        if (contactData is Map<String, dynamic>) {
          try {
            return Right(ContactApiModel.fromJson(contactData));
          } catch (_) {}
        }
        if (data['result']?['code'] == 'CONTACT_UPDATED') {
          return Right(ContactApiModel.fromJson({
            'contact_no': contactId,
            'name': requestBody['name'],
            'surname': requestBody['surname'],
            'e_mail': requestBody['eMail'],
            'tel': requestBody['tel'],
            'status': requestBody['status'],
            'title': '${requestBody['name']} ${requestBody['surname']}',
            'type': '11',
            'type_description': 'Gayrimenkul Danışmanı',
            'is_company': false,
            'is_employee': true,
            'is_agency': false,
            'is_customer': false,
            'nationality': 'TR',
            'created_at': DateTime.now().toIso8601String(),
            'marketing_communication_permission': requestBody['marketingCommunicationPermission'] ?? true,
            'slug': '',
          }));
        }
        return Right(ContactApiModel.fromJson({
          'contact_no': contactId,
          'title': '',
          'name': requestBody['name'],
          'surname': requestBody['surname'],
          'type': '11',
          'type_description': '',
          'e_mail': requestBody['eMail'],
          'tel': requestBody['tel'],
          'status': requestBody['status'],
          'created_at': DateTime.now().toIso8601String(),
          'marketing_communication_permission': requestBody['marketingCommunicationPermission'] ?? true,
          'slug': '',
        }));
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact güncellenemedi'));
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final apiMessage = e.response?.data?['message']?.toString();
        if (apiMessage != null && apiMessage.isNotEmpty) {
          return Left(ServerFailure(message: apiMessage));
        }
      }
      return Left(ServerFailure(message: 'Bağlantı hatası: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Mevcut rolleri getir
  Future<Either<Failure, List<String>>> getAvailableRoles() async {
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

      print('🔄 Getting Available Roles...');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/roles",
        options: Options(headers: headers),
      );

      print('✅ Available Roles Response: ${response.statusCode}');
      print('📦 Roles Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> roles = [];
        
        if (data is List) {
          // Her item'dan sadece "name" alanını al
          roles = data.map((item) {
            if (item is Map<String, dynamic> && item['name'] != null) {
              return item['name'].toString();
            }
            return item.toString();
          }).toList();
        } else if (data['roles'] != null) {
          final rolesData = data['roles'];
          if (rolesData is List) {
            roles = rolesData.map((item) {
              if (item is Map<String, dynamic> && item['name'] != null) {
                return item['name'].toString();
              }
              return item.toString();
            }).toList();
          } else {
            roles = List<String>.from(rolesData);
          }
        } else if (data['data'] != null) {
          final dataList = data['data'];
          if (dataList is List) {
            roles = dataList.map((item) {
              if (item is Map<String, dynamic> && item['name'] != null) {
                return item['name'].toString();
              }
              return item.toString();
            }).toList();
          } else {
            roles = List<String>.from(dataList);
          }
        }
        
        print('📋 Extracted Role Names: $roles');
        return Right(roles);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Roller getirilemedi'));
      }
    } catch (e) {
      print('❌ Get Roles Error: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Contact rollerini güncelle (oluşturma mantığı)
  Future<Either<Failure, bool>> updateContactRoles({
    required int contactId,
    required List<String> roles,
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

      // Environment variable'ı kullan
      final setRoleEndpoint = dotenv.env["SETROLE"] ?? "/api/zecorner/setUserRoles/id";
      final baseUrl = "${EnvApi.origin}$setRoleEndpoint";
      final endpoint = baseUrl.replaceAll('/id', '/$contactId');
      
      // Role mapping'i düzelt - API'den gelen gerçek role code'ları
      final roleMapping = {
        'Admin': 'role_admin',
        'İlan Onaylama': 'role_approve_listing',
        'Dosya Yönetimi': 'role_file_manager',
        'Duyuru İşlemleri': 'role_announcements',
        'Seminer İşlemleri': 'role_seminars',
        'Başvuru Form İşlemleri': 'role_form_applications',
        'Başvuru Form Yönetici': 'role_form_applications_admin',
        'Satış Başvuru Form Yönetici': 'role_sale_applications_admin',
        'Satış Başvuru Form İşlemleri': 'role_sale_applications',
        'Haber İşlemleri': 'role_news',
        'Sıkça Sorulan Sorular İşlemleri': 'role_faq',
        'Blog İşlemleri': 'role_blog',
        'Kampanya İşlemleri': 'role_promo',
        'Gayrimenkul Danışmanı': 'role_advisor',
        'Ofis Broker': 'role_office_broker',
        'Ofis Asistanı': 'role_office_assistant',
        'Takım Lideri': 'role_team_lead',
      };
      
      final roleObjects = roles.map((role) => {
        'code': roleMapping[role] ?? 'role_advisor'
      }).toList();
      
      final requestData = {
        'roles': roleObjects,
      };

      print('🔄 Contact Roles Update Request:');
      print('📋 Contact ID: $contactId');
      print('📋 Selected Roles: $roles');
      print('📋 Mapped Role Codes: ${roleObjects.map((r) => r['code']).toList()}');
      print('📋 Endpoint: $endpoint');
      print('📋 Request Data: $requestData');

      final response = await _client.dio.post(
        endpoint,
        data: requestData,
        options: Options(headers: headers),
      );

      print('✅ Contact Roles Update Response: ${response.statusCode}');
      print('📦 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact rolleri güncellenemedi'));
      }
    } catch (e) {
      print('❌ Contact Roles Update Error: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Contact'tan kullanıcı oluştur
  Future<Either<Failure, Map<String, dynamic>>> createUserFromContact({
    required int contactId,
    required List<String> roles,
  }) async {
    try {
      // Input validation - Edit screen'deki gibi
      if (contactId <= 0) {
        return Left(ServerFailure(message: "Geçersiz contact ID: $contactId"));
      }

      if (roles.isEmpty) {
        return Left(ServerFailure(message: "En az bir rol seçilmelidir"));
      }

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

      // Rol isimlerini role code'lara çevir
      final roleMapping = {
        'Admin': 'role_admin',
        'İlan Onaylama': 'role_approve_listing',
        'Dosya Yönetimi': 'role_file_manager',
        'Duyuru İşlemleri': 'role_announcements',
        'Seminer İşlemleri': 'role_seminars',
        'Başvuru Form İşlemleri': 'role_form_applications',
        'Başvuru Form Yönetici': 'role_form_applications_admin',
        'Satış Başvuru Form Yönetici': 'role_sale_applications_admin',
        'Satış Başvuru Form İşlemleri': 'role_sale_applications',
        'Haber İşlemleri': 'role_news',
        'Sıkça Sorulan Sorular İşlemleri': 'role_faq',
        'Blog İşlemleri': 'role_blog',
        'Kampanya İşlemleri': 'role_promo',
        'Gayrimenkul Danışmanı': 'role_advisor',
        'Ofis Broker': 'role_office_broker',
        'Ofis Asistanı': 'role_office_assistant',
        'Takım Lideri': 'role_team_lead',
      };
      
      // Rol isimlerini role code'lara çevir
      final roleCodes = roles.map((role) => roleMapping[role] ?? 'role_advisor').toList();
      
      // API'nin beklediği format - role code'ları gönder
      final requestData = {
        'no': contactId,  // API "no" alanını bekliyor
        'roles': roleCodes,  // API role code'ları bekliyor
      };

      // Next.js koduna göre doğru endpoint
      final createUserEndpoint = dotenv.env["CREATEUFCONTACT"] ?? "/api/zecorner/createUserFromContact";
      final baseUrl = "${EnvApi.origin}$createUserEndpoint";

      // API request - debug logları temizlendi

      final response = await _client.dio.post(
        baseUrl,
        data: requestData,
        options: Options(headers: headers),
      );

      // DEBUG: Response detaylarını kontrol et
      print('🔍 DEBUG: API Response Status: ${response.statusCode}');
      print('🔍 DEBUG: API Response Data: ${response.data}');
      print('🔍 DEBUG: Is Success: ${response.statusCode == 201 || response.statusCode == 200}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ DEBUG: Kullanıcı başarıyla oluşturuldu!');
        return Right(response.data);
      } else {
        // Error handling - debug logları temizlendi
        
        // USER_EXISTS durumunu özel olarak handle et
        if (response.statusCode == 400 && response.data['code'] == 'USER_EXISTS') {
          return Left(ServerFailure(message: 'Bu kişi zaten sistemde kayıtlı. Farklı bir kişi seçin.'));
        }
        
        return Left(ServerFailure(message: response.data['message'] ?? 'Kullanıcı oluşturulamadı (${response.statusCode})'));
      }
    } catch (e) {
      if (e is DioException) {
        return Left(ServerFailure(message: 'API Hatası: ${e.response?.data?['message'] ?? e.message}'));
      }
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
        'X-SESSION': token, // Authorization: Bearer yerine X-SESSION kullanıyoruz
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.delete(
        "${EnvApi.origin}/api/zecorner/contact/$contactId",
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

  // GET - Contact türlerini getir
  Future<Either<Failure, RefContactTypeResponseModel>> getContactTypes() async {
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

      final headers = AppConfig.getHeaders(token);
      final url = AppConfig.contactTypesEndpoint;
      print('📋 getContactTypes: $url');

      final response = await _client.dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> typesData = [];

        // Web/backend farklı formatlarda dönebilir: result, data, contactTypes veya doğrudan liste
        if (data is List) {
          typesData = data;
        } else if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          dynamic pickList(dynamic v) => v is List ? v : null;
          typesData = pickList(map['result']) ??
              pickList(map['data']) ??
              pickList(map['contactTypes']) ??
              pickList(map['types']) ??
              pickList(map['items']) ??
              <dynamic>[];
          if (typesData.isEmpty && map['result'] is Map) {
            final result = Map<String, dynamic>.from(map['result'] as Map);
            typesData = pickList(result['contactTypes']) ??
                pickList(result['data']) ??
                pickList(result['types']) ??
                <dynamic>[];
          }
        }

        if (typesData.isNotEmpty) {
          final contactTypes = RefContactTypeResponseModel.fromJson(typesData);
          return Right(contactTypes);
        }
        // Boş liste ile model döndür (dropdown en azından boş açılır, hata vermez)
        return Right(RefContactTypeResponseModel(contactTypes: []));
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact türleri getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Meslekleri getir
  Future<Either<Failure, RefProfessionResponseModel>> getProfessions() async {
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

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/refProfessions",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> professionsData = [];
        
        if (data is List) {
          professionsData = data;
        } else if (data['data'] != null) {
          professionsData = data['data'];
        } else if (data['professions'] != null) {
          professionsData = data['professions'];
        }

        final professions = RefProfessionResponseModel.fromJson(professionsData);
        ProfessionCatalog.remember(professions.professions);
        return Right(professions);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Meslekler getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Eğitim durumlarını getir
  Future<Either<Failure, RefEducationResponseModel>> getEducations() async {
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

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/refEducations",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> educationsData = [];
        
        if (data is List) {
          educationsData = data;
        } else if (data['data'] != null) {
          educationsData = data['data'];
        } else if (data['educations'] != null) {
          educationsData = data['educations'];
        }

        final educations = RefEducationResponseModel.fromJson(educationsData);
        return Right(educations);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Eğitim durumları getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - İlleri getir (refProvinces endpoint'i)
  // country_code zorunlu (TR / CT). Yoksa BAMMA boş PROVINCES döner.
  // Yanıt formatları:
  // 1) düz liste: [{code, name, ...}]
  // 2) dump: { type, data: { PROVINCES: [...] } }
  Future<Either<Failure, ProvincesResponseModel>> getProvinces({
    String? countryCode,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token =
          pref.getString('userJWT') ?? pref.getString('auth_token');
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

      final resolvedCountry =
          (countryCode == null || countryCode.trim().isEmpty) ? 'TR' : countryCode.trim();

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/refProvinces",
        queryParameters: {'country_code': resolvedCountry},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final provincesData = _extractProvincesList(response.data);
        final provinces = ProvincesResponseModel.fromJson(
          provincesData
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
        return Right(provinces);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'İller getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  /// refProvinces gövdesinden il listesini çıkarır (liste / dump.PROVINCES / data / cities).
  List<dynamic> _extractProvincesList(dynamic data) {
    if (data is List) return data;
    if (data is! Map) return const [];

    final map = Map<String, dynamic>.from(data);

    // BAMMA dump: { type: 'dump', data: { PROVINCES: [...] } }
    final nested = map['data'];
    if (nested is Map) {
      final nestedMap = Map<String, dynamic>.from(nested);
      for (final key in ['PROVINCES', 'provinces', 'cities', 'Response']) {
        final value = nestedMap[key];
        if (value is List && value.isNotEmpty) return value;
        if (value is List) return value;
      }
    }

    for (final key in ['PROVINCES', 'provinces', 'data', 'cities']) {
      final value = map[key];
      if (value is List) return value;
    }

    return const [];
  }

  // GET - İlleri getir (eski method - geriye uyumluluk için)
  Future<Either<Failure, RefCityResponseModel>> getCities() async {
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

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/refProvinces",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> citiesData = [];
        
        if (data is List) {
          citiesData = data;
        } else if (data['data'] != null) {
          citiesData = data['data'];
        } else if (data['cities'] != null) {
          citiesData = data['cities'];
        }

        final cities = RefCityResponseModel.fromJson(citiesData);
        return Right(cities);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'İller getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Ülkeleri getir
  Future<Either<Failure, RefCountryResponseModel>> getCountries() async {
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

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/refCountries",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> countriesData = [];
        
        if (data is List) {
          countriesData = data;
        } else if (data['data'] != null) {
          countriesData = data['data'];
        } else if (data['countries'] != null) {
          countriesData = data['countries'];
        }

        final countries = RefCountryResponseModel.fromJson(countriesData);
        return Right(countries);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Ülkeler getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - İlçeler + mahalleler (il plaka/kod ile)
  //
  // Postman: GET `/api/zecorner/refProvince/{provinceCode}` (örn. 34 = İstanbul)
  // Opsiyonel [countryCode]: TR / CT (web getDistricts ile uyumlu)
  // Gövde: kök düzeyde JSON dizi — `[{ "code", "name", "quarters": [{ "code", "name" }] }, ...]`
  // `ProvincesDetailResponseModel` / `DistrictModel` / `QuarterModel` bu şemayı parse eder.
  Future<Either<Failure, ProvincesDetailResponseModel>> getDistrictsByProvince(
    int provinceCode, {
    String? countryCode,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT') ?? pref.getString('auth_token');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = <String, String>{
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null) headers['X-SESSION'] = token;

      final baseUrl = dotenv.env["BASE_URL"] ?? "${EnvApi.origin}";
      final opts = Options(
        headers: headers,
        validateStatus: (s) => s != null && s < 500,
      );

      final queryParameters = <String, dynamic>{};
      if (countryCode != null && countryCode.trim().isNotEmpty) {
        queryParameters['country_code'] = countryCode.trim();
      }

      // Web API: /refProvince/{code} (web'deki getDistricts gibi)
      var url = "$baseUrl/api/zecorner/refProvince/$provinceCode";
      var response = await _client.dio.get(
        url,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        options: opts,
      );

      // Fallback: eski path /refProvinces/{code}/districts
      if (response.statusCode == 404 || response.statusCode == 401) {
        url = "$baseUrl/api/zecorner/refProvinces/$provinceCode/districts";
        response = await _client.dio.get(
          url,
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
          options: opts,
        );
      }

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> districtsData = [];
        
        if (data is List) {
          districtsData = data;
        } else if (data['data'] != null) {
          districtsData = data['data'];
        } else if (data['districts'] != null) {
          districtsData = data['districts'];
        }

        final districts = ProvincesDetailResponseModel.fromJson(districtsData);
        return Right(districts);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'İlçeler getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Mahalleleri getir (ilçe kodu ile)
  Future<Either<Failure, List<QuarterModel>>> getQuartersByDistrict(int districtCode) async {
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

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/refDistricts/$districtCode/quarters",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> quartersData = [];
        
        if (data is List) {
          quartersData = data;
        } else if (data['data'] != null) {
          quartersData = data['data'];
        } else if (data['quarters'] != null) {
          quartersData = data['quarters'];
        }

        final quarters = quartersData.map((e) => QuarterModel.fromJson(e as Map<String, dynamic>)).toList();
        return Right(quarters);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Mahalleler getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  /// Yanıt objesinden dosya ID'sini çıkarır (düz map, nested data, JSON string veya web API gibi düz S3 key string).
  static String? _extractFileIdFromResponse(dynamic data) {
    if (data == null) return null;
    
    // Web uploadFileToAWS / api/upload-file bazen doğrudan S3 key (uuid string) döner
    if (data is String) {
      final s = data.trim();
      // UUID veya S3 key formatı kontrolü (en az 10 karakter, JSON değil)
      if (s.isNotEmpty && s.length >= 10 && !s.startsWith('{') && !s.startsWith('[') && !s.startsWith('<')) {
        return s;
      }
      try {
        final decoded = jsonDecode(data);
        return _extractFileIdFromResponse(decoded);
      } catch (_) {}
      return null;
    }
    
    Map<String, dynamic>? map;
    if (data is Map<String, dynamic>) {
      map = data;
    } else if (data is Map) {
      try {
        map = Map<String, dynamic>.from(data);
      } catch (_) {
        return null;
      }
    }
    
    if (map == null) return null;
    
    // Önce üst seviye field'ları kontrol et
    final topLevelFields = ['fileId', 'id', 'file_id', 's3Id', 's3_id', 'key', 'filename', 
                            'file', 'url', 'path', 'location', 'hd', 'standart', 'thumbnail',
                            'uuid', 's3Key', 's3_key', 'fileKey', 'file_key'];
    for (final field in topLevelFields) {
      final value = map[field];
      if (value != null) {
        final strValue = value.toString().trim();
        if (strValue.isNotEmpty && strValue.length >= 10) {
          return strValue;
        }
      }
    }
    
    // Nested data kontrolü
    final nestedFields = ['data', 'result', 'response', 'body', 'payload', 'content'];
    for (final field in nestedFields) {
      final nested = map[field];
      if (nested != null) {
        final nestedId = _extractFileIdFromResponse(nested);
        if (nestedId != null && nestedId.isNotEmpty) {
          return nestedId;
        }
      }
    }
    
    return null;
  }

  /// Yükleme istekleri: global [DioClient] interceptor/token davranışından tamamen bağımsız.
  static Dio _plainUploadDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(minutes: 3),
        validateStatus: (s) => s != null && s < 500,
        followRedirects: false,
      ),
    );
  }

  static String? _presignedUrlFromJson(Map<String, dynamic> m) {
    for (final k in ['url', 'uploadUrl', 'presignedUrl', 'signedUrl']) {
      final v = m[k]?.toString();
      if (v != null && v.isNotEmpty && v.startsWith('http')) return v;
    }
    return null;
  }

  static String? _s3KeyFromJson(Map<String, dynamic> m) {
    for (final k in ['key', 'fileKey', 's3Key', 'objectKey']) {
      final v = m[k]?.toString();
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// Uzantı yoksa veya path tek parçalıysa [split('.').last] tüm yolu verir; güvenilir değil.
  static String? _extensionFromPath(String path) {
    final idx = path.lastIndexOf('.');
    if (idx <= 0 || idx >= path.length - 1) return null;
    return path.substring(idx + 1).toLowerCase();
  }

  /// Profil / galeri: iOS image_picker çoğu zaman uzantısız dosya verir; presign Content-Type imzaya girer.
  static String? _sniffImageMimeFromBytes(List<int> b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (b.length >= 8 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47 &&
        b[4] == 0x0D &&
        b[5] == 0x0A &&
        b[6] == 0x1A &&
        b[7] == 0x0A) {
      return 'image/png';
    }
    if (b.length >= 6 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) {
      return 'image/gif';
    }
    if (b.length >= 12 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 &&
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50) {
      return 'image/webp';
    }
    // HEIC/HEIF (iOS fotoğraf)
    if (b.length >= 12 &&
        b[4] == 0x66 &&
        b[5] == 0x74 &&
        b[6] == 0x79 &&
        b[7] == 0x70) {
      return 'image/heic';
    }
    return null;
  }

  /// [fileType] == profile_image ise asla PDF varsayımı yok; önce imza, sonra uzantı, son çare image/jpeg.
  static String _mimeTypeForUpload(String path, String fileType, List<int> bytes) {
    if (fileType == 'profile_image') {
      final sniffed = _sniffImageMimeFromBytes(bytes);
      if (sniffed != null) return sniffed;
      final ext = _extensionFromPath(path);
      switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'jpe':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'gif':
          return 'image/gif';
        case 'webp':
          return 'image/webp';
        case 'heic':
        case 'heif':
          return 'image/heic';
        default:
          return 'image/jpeg';
      }
    }

    final ext = _extensionFromPath(path);
    if (ext != null) {
      switch (ext) {
        case 'pdf':
          return 'application/pdf';
        case 'doc':
          return 'application/msword';
        case 'docx':
          return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        case 'jpg':
        case 'jpeg':
        case 'jpe':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'gif':
          return 'image/gif';
        case 'webp':
          return 'image/webp';
      }
    }
    final sniffed = _sniffImageMimeFromBytes(bytes);
    if (sniffed != null) return sniffed;
    return 'application/octet-stream';
  }

  /// Next.js GET /api/get-upload-url?contentType=... → { url, key }; sonra doğrudan S3 PUT.
  /// [DioClient] interceptor S3 imzasını bozmasın diye PUT ayrı [Dio] ile yapılır.
  /// Önce X-SESSION (+ X-UR-ID), olmazsa sadece X-API-KEY / X-APP-ID (auth'sız presign route'ları için).
  Future<Either<Failure, String>?> _tryPresignedS3Upload({
    required List<int> bytes,
    required String mimeType,
    required String apiKey,
    required String appId,
    required SharedPreferences pref,
    String? sessionToken,
  }) async {
    final bammaBase =
        (dotenv.env["BASE_URL"] ?? "${EnvApi.origin}").replaceAll(RegExp(r'/$'), '');
    final envFull = dotenv.env["GET_UPLOAD_URL"]?.trim();

    // Web ile aynı host: UPLOAD_FILE_API_URL genelde Amplify; presign de orada (BAMMA IP'de yok)
    final uploadFileApi = EnvApi.webUploadFileAbsoluteUrl;
    final amplifyFromUploadFile = uploadFileApi.contains('upload-file')
        ? uploadFileApi
            .replaceAll(RegExp(r'/upload-file/?$'), '/get-upload-url')
            .replaceAll(RegExp(r'/+$'), '')
        : '';

    final candidates = <String>[
      if (envFull != null && envFull.isNotEmpty) envFull,
      if (amplifyFromUploadFile.isNotEmpty) ...[
        amplifyFromUploadFile,
        '$amplifyFromUploadFile/',
      ],
      '$bammaBase/api/zecorner/get-upload-url',
      '$bammaBase/api/get-upload-url',
    ];
    final seen = <String>{};
    final bases = <String>[];
    for (final u in candidates) {
      if (seen.add(u)) bases.add(u);
    }

    final headerVariants = <Map<String, String>>[];
    if (sessionToken != null && sessionToken.isNotEmpty) {
      final h = <String, String>{
        'X-SESSION': sessionToken,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Accept': 'application/json',
      };
      final userId = pref.getString('userID');
      if (userId != null && userId.isNotEmpty) {
        h['X-UR-ID'] = userId;
      }
      headerVariants.add(h);
    }
    headerVariants.add(<String, String>{
      'X-API-KEY': apiKey,
      'X-APP-ID': appId,
      'Accept': 'application/json',
    });
    // Next.js örneğinizde auth yoksa fazla header 401 üretebilir
    headerVariants.add(<String, String>{
      'Accept': 'application/json',
    });

    String? putUrl;
    String? objectKey;

    outer:
    for (final base in bases) {
      for (final getHeaders in headerVariants) {
        final uri =
            Uri.parse(base).replace(queryParameters: {'contentType': mimeType});
        final plain = _plainUploadDio();
        final getOptions = Options(
          headers: getHeaders,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        );
        Response getResp;
        try {
          getResp = await plain.getUri(uri, options: getOptions);
        } catch (_) {
          continue;
        }

        var g = getResp;
        for (var hop = 0;
            hop < 3 &&
                g.statusCode != null &&
                g.statusCode! >= 300 &&
                g.statusCode! < 400;
            hop++) {
          final loc = g.headers.value('location') ?? g.headers.value('Location');
          if (loc == null || loc.isEmpty) break;
          final next = loc.startsWith('http')
              ? loc
              : Uri.parse(g.requestOptions.uri.toString()).resolve(loc).toString();
          try {
            g = await plain.get(
              next,
              options: getOptions,
            );
          } catch (_) {
            break;
          }
        }

        if (g.statusCode != 200) continue;

        dynamic data = g.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {
            continue;
          }
        }
        if (data is! Map) continue;
        final m = Map<String, dynamic>.from(data);
        final u = _presignedUrlFromJson(m);
        final k = _s3KeyFromJson(m);
        if (u == null || k == null) continue;
        putUrl = u;
        objectKey = k;
        break outer;
      }
    }

    if (putUrl == null || objectKey == null) return null;

    try {
      final s3Dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(minutes: 3),
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );
      final putResp = await s3Dio.put(
        putUrl,
        data: bytes,
        options: Options(
          headers: <String, String>{'Content-Type': mimeType},
        ),
      );
      if (putResp.statusCode == 200 || putResp.statusCode == 204) {
        return Right(objectKey);
      }
      return Left(
        ServerFailure(
          message:
              'Dosya depoya yüklenemedi (HTTP ${putResp.statusCode}). Lütfen tekrar deneyin.',
        ),
      );
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          message:
              'Dosya depoya yüklenemedi: ${e.response?.statusCode ?? ''} ${e.message ?? e.toString()}'
                  .trim(),
        ),
      );
    }
  }

  /// Portföy / genel: Next `get-upload-url` + doğrudan S3 PUT. Olmazsa `null` (base64 fallback).
  Future<String?> tryPresignedS3UploadBytes({
    required List<int> bytes,
    required String mimeType,
  }) async {
    final pref = await SharedPreferences.getInstance();
    final token = pref.getString('userJWT') ?? pref.getString('auth_token');
    final apiKey = dotenv.env['X_API_KEY'];
    final appId = dotenv.env['X_APP_ID'];
    if (apiKey == null || appId == null) return null;
    final result = await _tryPresignedS3Upload(
      bytes: bytes,
      mimeType: mimeType,
      apiKey: apiKey,
      appId: appId,
      pref: pref,
      sessionToken: token,
    );
    if (result == null) return null;
    return result.fold((_) => null, (key) => key);
  }

  // POST - Dosya yükle (önce presigned S3; olmazsa base64 + legacy API)
  Future<Either<Failure, String>> uploadFile(File file, String fileType) async {
    try {
      final pref = await SharedPreferences.getInstance();
      // userJWT (login) veya auth_token (bazı repolar) fallback
      final token = pref.getString('userJWT') ?? pref.getString('auth_token');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final bytes = await file.readAsBytes();
      final mimeType = _mimeTypeForUpload(file.path, fileType, bytes);

      final presigned = await _tryPresignedS3Upload(
        bytes: bytes,
        mimeType: mimeType,
        apiKey: apiKey,
        appId: appId,
        pref: pref,
        sessionToken: token,
      );
      if (presigned != null) {
        return presigned;
      }

      // Convert to base64 with data URI prefix (web'deki gibi)
      final base64String = base64Encode(bytes);
      final base64DataUri = 'data:$mimeType;base64,$base64String';
      
      // Prepare request body (web'deki gibi)
      final requestBody = {
        'base64': base64DataUri,
      };

      final headersNoAuth = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      Map<String, String> buildAuthHeaders(String sessionToken) {
        final h = <String, String>{
          'X-SESSION': sessionToken,
          'X-API-KEY': apiKey,
          'X-APP-ID': appId,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        final userId = pref.getString('userID');
        if (userId != null && userId.isNotEmpty) {
          h['X-UR-ID'] = userId;
        }
        return h;
      }

      // Web'deki Next.js API: /api/upload-file/ (308 → tarayıcıda çift istek; mobilde doğrudan slash'lı)
      final uploadUrl = EnvApi.webUploadFileAbsoluteUrl;
      final bammaBase = (dotenv.env["BASE_URL"] ?? "${EnvApi.origin}").toString().replaceAll(RegExp(r'/$'), '');
      final bammaUpload = "$bammaBase/api/zecorner/upload-file";
      final bammaUploadImage = "$bammaBase/api/zecorner/upload-image";

      print('📤 Uploading file: ${file.path}, type: $fileType');

      final plain = _plainUploadDio();
      final opts = (Map<String, String> h) => Options(
        headers: h,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      );

      bool isSuccess(int? code) => code != null && code >= 200 && code < 300;

      Response response;
      if (token != null && token.isNotEmpty) {
        final headersWithAuth = buildAuthHeaders(token);
        // 1) Token varsa önce BAMMA upload-file dene
        response = await plain.post(
          bammaUpload,
          data: requestBody,
          options: opts(headersWithAuth),
        );
        if (!isSuccess(response.statusCode) && (response.statusCode == 401 || response.statusCode == 404)) {
          // 2) upload-file 404 ise upload-image dene (bazı backend'ler farklı path kullanır)
          print('🔄 BAMMA upload-file ${response.statusCode}, upload-image deneniyor');
          response = await plain.post(
            bammaUploadImage,
            data: requestBody,
            options: opts(headersWithAuth),
          );
        }
        if (!isSuccess(response.statusCode) && (response.statusCode == 401 || response.statusCode == 404)) {
          print('🔄 BAMMA yanıt vermedi, Amplify deneniyor');
          response = await plain.post(
            uploadUrl,
            data: requestBody,
            options: opts(headersNoAuth),
          );
          if (!isSuccess(response.statusCode) && (response.statusCode == 401 || response.statusCode == 404)) {
            response = await plain.post(
              uploadUrl,
              data: requestBody,
              options: opts(headersWithAuth),
            );
          }
        }
      } else {
        // 2) Token yoksa doğrudan Amplify (auth olmadan)
        print('🔄 Token yok, Amplify auth olmadan deneniyor');
        response = await plain.post(
          uploadUrl,
          data: requestBody,
          options: opts(headersNoAuth),
        );
        if (response.statusCode == 401 || response.statusCode == 404) {
          return Left(AuthFailure(
            message: 'Token bulunamadı. Lütfen tekrar giriş yapın.',
          ));
        }
      }

      // 30x: yönlendirme sonrası header kaybı olmasın
      for (var hop = 0;
          hop < 5 &&
              response.statusCode != null &&
              response.statusCode! >= 300 &&
              response.statusCode! < 400;
          hop++) {
        final location =
            response.headers.value('location') ?? response.headers.value('Location');
        if (location == null || location.isEmpty) {
          return Left(ServerFailure(
            message: 'Sunucu yönlendirme döndürdü ancak hedef adres bulunamadı',
          ));
        }
        final base = response.requestOptions.uri.toString();
        final redirectUrl = location.startsWith('http')
            ? location
            : Uri.parse(base).resolve(location).toString();
        print('🔄 Yönlendirme ${hop + 1}: $redirectUrl');
        final headersForRedirect = (token != null && token.isNotEmpty)
            ? buildAuthHeaders(token)
            : headersNoAuth;
        response = await plain.post(
          redirectUrl,
          data: requestBody,
          options: Options(
            headers: headersForRedirect,
            followRedirects: false,
            validateStatus: (status) => status != null && status < 500,
          ),
        );
      }

      if (response.statusCode != null &&
          response.statusCode! >= 300 &&
          response.statusCode! < 400) {
        return Left(ServerFailure(
          message:
              'Çok fazla yönlendirme (Status: ${response.statusCode}). Lütfen daha sonra tekrar deneyin.',
        ));
      }

      print('✅ Upload response: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final fileId = _extractFileIdFromResponse(response.data);
        if (fileId != null && fileId.isNotEmpty) {
          return Right(fileId);
        }
        if (response.data is String && (response.data as String).trim().isNotEmpty) {
          final s = (response.data as String).trim();
          if (s.length >= 5 && !s.startsWith('{') && !s.startsWith('[')) {
            return Right(s);
          }
        }
        return Left(ServerFailure(message: 'Dosya yüklendi ama ID alınamadı. Yanıt: ${response.data}'));
      } else if (response.statusCode == 401) {
        return Left(ServerFailure(
          message:
              'Dosya yüklenemedi (oturum doğrulanamadı). Lütfen tekrar giriş yapıp yeniden deneyin.',
        ));
      } else if (response.statusCode == 404) {
        return Left(ServerFailure(message: 'Dosya yükleme API\'si bulunamadı. Lütfen UPLOAD_FILE_API_URL ayarını kontrol edin.'));
      } else {
        final msg = response.data is Map
            ? (response.data['message'] ?? response.data['error'] ?? 'Dosya yüklenemedi')
            : 'Dosya yüklenemedi';
        return Left(ServerFailure(message: msg.toString()));
      }
    } on DioException catch (e) {
      print('❌ Upload DioException: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(ServerFailure(message: 'Dosya yüklenemedi. Lütfen tekrar deneyin.'));
      }
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? e.message)
          : e.message;
      return Left(ServerFailure(message: 'Dosya yükleme hatası: $msg'));
    } catch (e) {
      print('❌ Upload error: $e');
      return Left(ServerFailure(message: 'Dosya yükleme hatası: $e'));
    }
  }

  // GET - Kişi arama (bağlı kişi/ofis için) - Web API'ye uygun
  Future<Either<Failure, List<Map<String, dynamic>>>> searchContacts(
    String query, {
    int size = 10,
    List<int>? typeCodes,
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

      // Web'deki gibi query string oluştur (birden fazla type parametresi için)
      final queryString = StringBuffer();
      queryString.write('q=${Uri.encodeComponent(query)}');
      queryString.write('&size=$size');
      
      // Type kodlarını ekle (birden fazla type parametresi: type=100&type=101&type=102)
      if (typeCodes != null && typeCodes.isNotEmpty) {
        for (final typeCode in typeCodes) {
          queryString.write('&type=$typeCode');
        }
      }

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/search/contacts/?${queryString.toString()}",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> contactsData = [];
        
        // Web API direkt array döndürüyor
        if (data is List) {
          contactsData = data;
        } else if (data['data'] != null) {
          contactsData = data['data'];
        } else if (data['contacts'] != null) {
          contactsData = data['contacts'];
        }

        final contacts = contactsData.map((e) => e as Map<String, dynamic>).toList();
        return Right(contacts);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Kişiler aranamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Arama hatası: $e'));
    }
  }

  /// GET - Simple contact list for dropdown (no pagination)
  Future<Either<Failure, List<Map<String, dynamic>>>> getContactList() async {
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

      final baseUrl = "${AppConfig.baseUrl}/api/zecorner/contacts";
      print('📞 GET Contact List Endpoint: $baseUrl');

      final response = await _client.dio.get(
        baseUrl,
        options: Options(
          headers: {
            'X-SESSION': token,
            'X-API-KEY': apiKey,
            'X-APP-ID': appId,
            'X-HB-USER-AGENT': 'flutter-app',
            'X-HB-IP': '::1',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ Contact List Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> contactsData = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        
        final contacts = contactsData
            .map((e) => e as Map<String, dynamic>)
            .toList();
        
        print('✅ Found ${contacts.length} contacts');
        return Right(contacts);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Danışmanlar getirilemedi'));
      }
    } on DioException catch (e) {
      print('❌ Get Contact List DioException: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      }
      return Left(ServerFailure(message: 'Danışmanlar getirilemedi: ${e.message}'));
    } catch (e) {
      print('❌ Get Contact List Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// GET - Advisor list for dropdown using search endpoint
  Future<Either<Failure, List<Map<String, dynamic>>>> getAdvisorList({String? searchQuery}) async {
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

      // Backend uses /search/contacts endpoint with query parameters
      final baseUrl = "${AppConfig.baseUrl}/api/zecorner/search/contacts";
      final queryParams = searchQuery != null && searchQuery.isNotEmpty
          ? {'q': searchQuery}
          : <String, dynamic>{};

      final response = await _client.dio.get(
        baseUrl,
        queryParameters: queryParams,
        options: Options(
          headers: {
            'X-SESSION': token,
            'X-API-KEY': apiKey,
            'X-APP-ID': appId,
            'X-HB-USER-AGENT': 'flutter-app',
            'X-HB-IP': '::1',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> advisorsData = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        
        final advisors = advisorsData
            .map((e) => e as Map<String, dynamic>)
            .toList();
        
        return Right(advisors);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Danışmanlar getirilemedi'));
      }
    } on DioException catch (e) {
      print('❌ Get Advisor List DioException: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      }
      return Left(ServerFailure(message: 'Danışmanlar getirilemedi: ${e.message}'));
    } catch (e) {
      print('❌ Get Advisor List Unexpected Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }
}
