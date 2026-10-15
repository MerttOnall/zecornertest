import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../models/contact/contacts_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class ContactsRepository {
  static final ContactsRepository _instance = ContactsRepository._internal();
  factory ContactsRepository() => _instance;
  ContactsRepository._internal();

  final DioClient _client = DioClient();

  // GET - Tüm contactları getir
  Future<Either<Failure, List<ContactModel>>> getAllContacts() async {
    try {
      print('📞 Tüm contactlar getiriliyor...');
      
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
        "${EnvApi.origin}/api/zecorner/contacts",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Contactlar başarıyla getirildi');
        final List<dynamic> data = response.data['data'] ?? response.data;
        final contacts = data.map((json) => ContactModel.fromJson(json)).toList();
        
        // Helper extension kullanımı - log bilgileri
        print('📊 Toplam: ${contacts.length} contact');
        final activeCount = contacts.where((c) => c.isActive).length;
        final employeeCount = contacts.where((c) => c.isEmployee).length;
        final customerCount = contacts.where((c) => c.isCustomer).length;
        print('📈 Aktif: $activeCount, Çalışan: $employeeCount, Müşteri: $customerCount');
        
        return Right(contacts);
      } else {
        print('❌ Contactlar getirilemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contactlar getirilemedi'));
      }
    } catch (e) {
      print('❌ Contactlar getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - ID'ye göre contact getir
  Future<Either<Failure, ContactModel>> getContactById(int contactId) async {
    try {
      print('📞 Contact getiriliyor: $contactId');
      
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
        
        // Helper extension kullanımı - log bilgileri
        print('✅ Contact getirildi: ${contact.fullName}');
        print('🏷️ Tür: ${contact.personType} ${contact.personTypeIcon}');
        print('📊 Tamamlık: %${contact.completenessScore}');
        
        return Right(contact);
      } else {
        print('❌ Contact getirilemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact bulunamadı'));
      }
    } catch (e) {
      print('❌ Contact getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Sayfalama ile contactları getir (ContactsResponseModel döndürür)
  Future<Either<Failure, ContactsResponseModel>> getContactsWithPagination({
    int page = 1,
    int limit = 20,
    String? search,
    int? typeCode,
    bool? isActive,
  }) async {
    try {
      print('📞 Contactlar sayfalama ile getiriliyor: page=$page, limit=$limit');
      
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
        "${EnvApi.origin}/api/zecorner/contacts",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> contactsData = data['contacts'] ?? data['data'] ?? [];
        final contacts = contactsData.map((json) => ContactModel.fromJson(json)).toList();
        
        final contactsResponse = ContactsResponseModel(
          contacts: contacts,
          totalCount: data['totalCount'] ?? data['total'] ?? 0,
          totalPages: data['totalPages'] ?? data['total_pages'] ?? 0,
          page: data['page'] ?? page,
        );

        // Helper extension kullanımı - log bilgileri
        print('✅ Contactlar sayfalama ile getirildi');
        print('📊 İstatistikler: ${contactsResponse.statistics}');
        print('🏙️ Şehirler: ${contactsResponse.groupedByCity.keys.join(", ")}');
        
        return Right(contactsResponse);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contactlar getirilemedi'));
      }
    } catch (e) {
      print('❌ Contactlar sayfalama hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Arama yap (ContactsResponseModel helper kullanarak)
  Future<Either<Failure, List<ContactModel>>> searchContacts(String query) async {
    try {
      print('🔍 Contactlar aranıyor: $query');
      
      // Önce tüm contactları al
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          // ContactsResponseModel helper ile arama yap
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final searchResults = contactsResponse.searchContacts(query);
          print('✅ ${searchResults.length} arama sonucu bulundu');
          
          return Right(searchResults);
        },
      );
    } catch (e) {
      print('❌ Contact arama hatası: $e');
      return Left(ServerFailure(message: 'Arama hatası: $e'));
    }
  }

  // GET - Kategorik listeleme (helper extension metodları kullanarak)
  Future<Either<Failure, List<ContactModel>>> getActiveContacts() async {
    try {
      print('📞 Aktif contactlar getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final activeContacts = contactsResponse.activeContacts;
          print('✅ ${activeContacts.length} aktif contact getirildi');
          
          return Right(activeContacts);
        },
      );
    } catch (e) {
      print('❌ Aktif contactlar getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - İnaktif contactları getir
  Future<Either<Failure, List<ContactModel>>> getInactiveContacts() async {
    try {
      print('📞 İnaktif contactlar getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final inactiveContacts = contactsResponse.inactiveContacts;
          print('✅ ${inactiveContacts.length} inaktif contact getirildi');
          
          return Right(inactiveContacts);
        },
      );
    } catch (e) {
      print('❌ İnaktif contactlar getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Çalışanları getir
  Future<Either<Failure, List<ContactModel>>> getEmployees() async {
    try {
      print('👔 Çalışanlar getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final employees = contactsResponse.employees;
          print('✅ ${employees.length} çalışan getirildi');
          
          return Right(employees);
        },
      );
    } catch (e) {
      print('❌ Çalışanlar getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Müşterileri getir
  Future<Either<Failure, List<ContactModel>>> getCustomers() async {
    try {
      print('👤 Müşteriler getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final customers = contactsResponse.customers;
          print('✅ ${customers.length} müşteri getirildi');
          
          return Right(customers);
        },
      );
    } catch (e) {
      print('❌ Müşteriler getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Acenteleri getir
  Future<Either<Failure, List<ContactModel>>> getAgencies() async {
    try {
      print('🏬 Acenteler getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final agencies = contactsResponse.agencies;
          print('✅ ${agencies.length} acente getirildi');
          
          return Right(agencies);
        },
      );
    } catch (e) {
      print('❌ Acenteler getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Brokerları getir
  Future<Either<Failure, List<ContactModel>>> getBrokers() async {
    try {
      print('🏪 Brokerlar getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final brokers = contactsResponse.brokers;
          print('✅ ${brokers.length} broker getirildi');
          
          return Right(brokers);
        },
      );
    } catch (e) {
      print('❌ Brokerlar getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Şirketleri getir
  Future<Either<Failure, List<ContactModel>>> getCompanies() async {
    try {
      print('🏢 Şirketler getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final companies = contactsResponse.companies;
          print('✅ ${companies.length} şirket getirildi');
          
          return Right(companies);
        },
      );
    } catch (e) {
      print('❌ Şirketler getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Profil fotoğrafı olan contactlar
  Future<Either<Failure, List<ContactModel>>> getContactsWithPhoto() async {
    try {
      print('📸 Profil fotoğrafı olan contactlar getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final contactsWithPhoto = contactsResponse.contactsWithPhoto;
          print('✅ ${contactsWithPhoto.length} fotoğraflı contact getirildi');
          
          return Right(contactsWithPhoto);
        },
      );
    } catch (e) {
      print('❌ Fotoğraflı contactlar getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Marketing izni veren contactlar
  Future<Either<Failure, List<ContactModel>>> getMarketingPermittedContacts() async {
    try {
      print('📢 Marketing izni olan contactlar getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final marketingContacts = contactsResponse.marketingPermittedContacts;
          print('✅ ${marketingContacts.length} marketing izinli contact getirildi');
          
          return Right(marketingContacts);
        },
      );
    } catch (e) {
      print('❌ Marketing izinli contactlar getirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Gruplama metodları
  Future<Either<Failure, Map<String, List<ContactModel>>>> getContactsGroupedByType() async {
    try {
      print('🏷️ Contactlar türe göre gruplandırılıyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final groupedByType = contactsResponse.groupedByType;
          print('✅ ${groupedByType.length} farklı türde gruplama yapıldı');
          
          return Right(groupedByType);
        },
      );
    } catch (e) {
      print('❌ Türe göre gruplama hatası: $e');
      return Left(ServerFailure(message: 'Gruplama hatası: $e'));
    }
  }

  // GET - Şehre göre gruplama
  Future<Either<Failure, Map<String, List<ContactModel>>>> getContactsGroupedByCity() async {
    try {
      print('🏙️ Contactlar şehre göre gruplandırılıyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final groupedByCity = contactsResponse.groupedByCity;
          print('✅ ${groupedByCity.length} farklı şehirde gruplama yapıldı');
          
          return Right(groupedByCity);
        },
      );
    } catch (e) {
      print('❌ Şehre göre gruplama hatası: $e');
      return Left(ServerFailure(message: 'Gruplama hatası: $e'));
    }
  }

  // GET - İstatistikler
  Future<Either<Failure, Map<String, int>>> getContactStatistics() async {
    try {
      print('📊 Contact istatistikleri getiriliyor...');
      
      final allContactsResult = await getAllContacts();
      
      return allContactsResult.fold(
        (failure) => Left(failure),
        (contacts) {
          final contactsResponse = ContactsResponseModel(
            contacts: contacts,
            totalCount: contacts.length,
            totalPages: 1,
            page: 1,
          );
          
          final stats = contactsResponse.statistics;
          print('✅ Contact istatistikleri hazırlandı');
          
          return Right(stats);
        },
      );
    } catch (e) {
      print('❌ İstatistik hesaplama hatası: $e');
      return Left(ServerFailure(message: 'İstatistik hatası: $e'));
    }
  }

  // POST - Yeni contact oluştur
  Future<Either<Failure, ContactModel>> createContact(ContactModel contact) async {
    try {
      print('💾 Yeni contact oluşturuluyor...');
      print('👤 Oluşturulacak: ${contact.fullName} (${contact.personType})');
      
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
        
        print('✅ Contact başarıyla oluşturuldu');
        print('🆔 ID: ${createdContact.contactNo}');
        print('👤 İsim: ${createdContact.fullName}');
        print('📊 Tamamlık: %${createdContact.completenessScore}');
        
        return Right(createdContact);
      } else {
        print('❌ Contact oluşturulamadı: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact oluşturulamadı'));
      }
    } catch (e) {
      print('❌ Contact oluşturma hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Contact güncelle
  Future<Either<Failure, ContactModel>> updateContact(int contactId, ContactModel contact) async {
    try {
      print('🔄 Contact güncelleniyor: $contactId');
      print('👤 Güncellenecek: ${contact.fullName}');
      
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
        
        print('✅ Contact başarıyla güncellendi');
        print('👤 Yeni: ${updatedContact.fullName}');
        print('📊 Tamamlık: %${updatedContact.completenessScore}');
        
        return Right(updatedContact);
      } else {
        print('❌ Contact güncellenemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact güncellenemedi'));
      }
    } catch (e) {
      print('❌ Contact güncelleme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Contact kısmi güncelleme (PATCH)
  Future<Either<Failure, ContactModel>> updateContactPartial(int contactId, Map<String, dynamic> updates) async {
    try {
      print('🔄 Contact kısmi güncelleme: $contactId');
      print('📝 Güncellenen alanlar: ${updates.keys.join(", ")}');
      
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
        "${EnvApi.origin}/api/zecorner/contacts/$contactId",
        data: updates,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final updatedContact = ContactModel.fromJson(response.data['data'] ?? response.data);
        
        print('✅ Contact kısmi güncelleme tamamlandı');
        print('👤 Güncel: ${updatedContact.fullName}');
        print('📊 Yeni tamamlık: %${updatedContact.completenessScore}');
        
        return Right(updatedContact);
      } else {
        print('❌ Contact kısmi güncelleme başarısız: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact güncellenemedi'));
      }
    } catch (e) {
      print('❌ Contact kısmi güncelleme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Contact durumunu değiştir (aktif/pasif)
  Future<Either<Failure, ContactModel>> toggleContactStatus(int contactId) async {
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
        final updatedContact = ContactModel.fromJson(response.data['data'] ?? response.data);
        
        print('✅ Contact durumu başarıyla değiştirildi');
        print('👤 ${updatedContact.fullName}');
        print('📊 Yeni durum: ${updatedContact.statusDisplayName}');
        
        return Right(updatedContact);
      } else {
        print('❌ Contact durumu değiştirilemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact durumu değiştirilemedi'));
      }
    } catch (e) {
      print('❌ Contact durumu değiştirme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // DELETE - Contact sil
  Future<Either<Failure, bool>> deleteContact(int contactId) async {
    try {
      print('🗑️ Contact siliniyor: $contactId');
      
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
        print('✅ Contact başarıyla silindi');
        return const Right(true);
      } else {
        print('❌ Contact silinemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact silinemedi'));
      }
    } catch (e) {
      print('❌ Contact silme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // DELETE - Çoklu contact sil
  Future<Either<Failure, bool>> deleteMultipleContacts(List<int> contactIds) async {
    try {
      print('🗑️ Çoklu contact siliniyor: ${contactIds.length} adet');
      
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
        "${EnvApi.origin}/api/zecorner/contacts/bulk",
        data: {'contact_ids': contactIds},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ ${contactIds.length} contact başarıyla silindi');
        return const Right(true);
      } else {
        print('❌ Çoklu contact silinemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Contactlar silinemedi'));
      }
    } catch (e) {
      print('❌ Çoklu contact silme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }
}