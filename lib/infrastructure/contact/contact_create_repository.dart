import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/network/network_info.dart';
import 'package:zecorner/infrastructure/contact/contact_api_client.dart';
import 'package:zecorner/models/contact/contact_create_model.dart';
import 'package:dartz/dartz.dart';
import 'package:zecorner/core/config/env_api.dart';

class ContactCreateRepository {
  final ContactApiClient _client;
  final NetworkInfo _networkInfo;

  ContactCreateRepository({
    required ContactApiClient client,
    required NetworkInfo networkInfo,
  })  : _client = client,
        _networkInfo = networkInfo;

  // POST - Contact oluştur
  Future<Either<Failure, Map<String, dynamic>>> createContact({
    required ContactCreateModel contactData,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        return Left(ServerFailure(message: 'İnternet bağlantısı yok'));
      }

      final token = await _client.getStoredToken();
      final apiKey = await _client.getStoredApiKey();
      final appId = await _client.getStoredAppId();

      if (token == null || apiKey == null || appId == null) {
        return Left(ServerFailure(message: 'Oturum bilgileri bulunamadı'));
      }

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Contact data'yı API formatına çevir
      final requestData = _buildContactRequestData(contactData);

      final createContactEndpoint = "/api/zecorner/contact";
      // Next.js handler: type=save olmadan istek /contact/undefined gibi yanlış path'e gider
      final baseUrl = Uri.parse("${EnvApi.origin}$createContactEndpoint")
          .replace(queryParameters: const {'type': 'save'})
          .toString();

      print('🔄 Create Contact Request:');
      print('📋 Contact Data: ${jsonEncode(requestData)}');
      print('📋 Endpoint: $baseUrl');
      print('🔍 DEBUG: Person Type: ${contactData.personType}');
      print('🔍 DEBUG: Type Code: ${_getContactTypeCode(contactData.personType)}');
      print('🔍 DEBUG: Profession: ${contactData.profession}');
      print('🔍 DEBUG: Education: ${contactData.education}');

      final response = await _client.dio.post(
        baseUrl,
        data: requestData,
        options: Options(headers: headers),
      );

      print('🔍 DEBUG: API Response Status: ${response.statusCode}');
      print('🔍 DEBUG: API Response Data: ${response.data}');
      print('🔍 DEBUG: Is Success: ${response.statusCode == 201 || response.statusCode == 200}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ DEBUG: Contact başarıyla oluşturuldu!');
        return Right(response.data);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Contact oluşturulamadı (${response.statusCode})'));
      }
    } catch (e) {
      if (e is DioException) {
        return Left(ServerFailure(message: 'API Hatası: ${e.response?.data?['message'] ?? e.message}'));
      }
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // Contact data'yı API formatına çevir (Next.js API'ye uygun - camelCase)
  Map<String, dynamic> _buildContactRequestData(ContactCreateModel contact) {
    // Ana request objesi (minimal - sadece zorunlu alanlar)
    final requestData = <String, dynamic>{
      'name': contact.name,
      'surname': contact.surname,
      'tel': contact.phone,
      'eMail': contact.email,
      'nationality': 'TR',
      'sex': 1, // 1: Erkek, 2: Kadın
      'type': {
        'code': _getContactTypeCode(contact.personType),
      },
      'status': 1,
    };
    
    // TC Kimlik (opsiyonel)
    if (contact.tcId != null && contact.tcId!.isNotEmpty) {
      requestData['tcIdNumber'] = contact.tcId;
    }
    
    // Detail objesi (opsiyonel)
    final detailObj = <String, dynamic>{};
    
    if (contact.birthDate != null && contact.birthDate!.isNotEmpty) {
      detailObj['birthday'] = contact.birthDate;
    }
    
    if (contact.profession != null && contact.profession!.isNotEmpty) {
      detailObj['profession'] = {
        'code': _getProfessionCode(contact.profession),
        'description': contact.profession!,
      };
    }
    
    if (contact.education != null && contact.education!.isNotEmpty) {
      detailObj['education'] = {
        'code': _getEducationCode(contact.education),
        'description': contact.education!,
      };
    }
    
    // Social Media
    final socialMediaObj = <String, dynamic>{};
    if (contact.linkedin != null && contact.linkedin!.isNotEmpty) {
      socialMediaObj['linkedin'] = contact.linkedin!;
    }
    if (contact.twitter != null && contact.twitter!.isNotEmpty) {
      socialMediaObj['x'] = contact.twitter!;
    }
    if (contact.instagram != null && contact.instagram!.isNotEmpty) {
      socialMediaObj['instagram'] = contact.instagram!;
    }
    if (contact.facebook != null && contact.facebook!.isNotEmpty) {
      socialMediaObj['facebook'] = contact.facebook!;
    }
    if (socialMediaObj.isNotEmpty) {
      detailObj['socialMedia'] = socialMediaObj;
    }
    
    if (contact.whereYouHeardUs != null && contact.whereYouHeardUs!.isNotEmpty) {
      detailObj['whereYouHeardUs'] = contact.whereYouHeardUs!;
    }
    if (contact.coverLetter != null && contact.coverLetter!.isNotEmpty) {
      detailObj['coverLetter'] = contact.coverLetter!;
    }
    if (contact.experience != null && contact.experience!.isNotEmpty) {
      detailObj['sectoralExperience'] = int.tryParse(contact.experience!) ?? 0;
    }
    if (contact.references != null && contact.references!.isNotEmpty) {
      detailObj['references'] = contact.references!;
    }
    
    // Attachments (boş array bile olabilir)
    if (contact.attachments != null && contact.attachments!.isNotEmpty) {
      detailObj['attachments'] = contact.attachments!;
    }
    
    // Detail objesini ekle (sadece boş değilse)
    if (detailObj.isNotEmpty) {
      requestData['detail'] = detailObj;
    }
    
    // Address objesi (opsiyonel)
    final addressObj = <String, dynamic>{};
    if (contact.city != null && contact.city!.isNotEmpty) {
      addressObj['city'] = contact.city!;
    }
    if (contact.district != null && contact.district!.isNotEmpty) {
      addressObj['district'] = contact.district!;
    }
    if (contact.address != null && contact.address!.isNotEmpty) {
      addressObj['address'] = contact.address!;
    }
    if (addressObj.isNotEmpty) {
      requestData['address'] = addressObj;
    }
    
    return requestData;
  }

  // Contact type kodunu al (API'den gelen type_description'a göre)
  String _getContactTypeCode(String? personType) {
    if (personType == null) return '13'; // Default: Takım Lideri
    
    // API'den gelen type_description değerlerine göre type kodları
    // Fotoğraflardaki sırayla eşleştirme
    switch (personType) {
      case 'Super Admin':
        return '301';
      case 'Admin':
        return '3';
      case 'Broker':
        return '10';
      case 'Gayrimenkul Danışmanı':
        return '11';
      case 'Takım Lideri':
        return '13';
      case 'Franchise Satış ve Geliştirme Bölge Müdürü':
        return '306';
      case 'Ofis Asistanı':
        return '12';
      case 'Franchise Geliştime Uzmanı':
        return '305';
      case 'Franchise Satış Destek Uzmanı':
        return '303';
      case 'Franchise Satış Ve Geliştirme Direktörü':
        return '306';
      case 'Franchise Satış Yöneticisi':
        return '304';
      case 'Müdür':
        return '307';
      case 'Saha Satış Asistanı':
        return '309';
      case 'Saha Satış Uzmanı':
        return '308';
      // Eski kodlar (geriye dönük uyumluluk)
      case 'Broker Aday':
        return '14';
      case 'Gayrimenkul Danışman Adayı':
        return '15';
      default:
        print('⚠️ WARNING: Unknown person type: $personType, using default (13)');
        return '13'; // Default: Takım Lideri
    }
  }

  // Profession kodunu al (API'ye uygun)
  String _getProfessionCode(String? profession) {
    switch (profession) {
      case 'Mühendis':
        return 'ENGINEER';
      case 'Doktor':
        return 'DOCTOR';
      case 'Avukat':
        return 'LAWYER';
      case 'Öğretmen':
        return 'TEACHER';
      case 'Emlak Uzmanı':
        return 'REAL_ESTATE_EXPERT';
      case 'Diğer':
        return 'OTHER';
      default:
        return 'OTHER';
    }
  }

  // Education kodunu al (API'ye uygun)
  String _getEducationCode(String? education) {
    switch (education) {
      case 'İlkokul':
        return 'PRIMARY_SCHOOL';
      case 'Ortaokul':
        return 'MIDDLE_SCHOOL';
      case 'Lise':
        return 'HIGH_SCHOOL';
      case 'Üniversite':
        return 'UNIVERSITY';
      case 'Yüksek Lisans':
        return 'MASTER';
      case 'Doktora':
        return 'POST_GRADUATE';
      default:
        return 'UNIVERSITY';
    }
  }
}
