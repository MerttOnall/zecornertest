import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/mixins/update_mixin.dart';
import 'package:zecorner/core/auth/advisor_office_scope.dart';
import '../../models/customer/customer_api_model.dart';
import '../../core/config/app_config.dart';
import '../contact/contact_api_repository.dart';
import 'package:zecorner/core/config/env_api.dart';

class CustomerApiRepository with UpdateMixin {
  static final CustomerApiRepository _instance = CustomerApiRepository._internal();
  factory CustomerApiRepository() => _instance;
  CustomerApiRepository._internal();

  final DioClient _client = DioClient();
  
  @override
  DioClient get dioClient => _client;

  // GET - Web ile aynı: ?type=201&page=1&searchText=&pageSize=10
  Future<Either<Failure, CustomerApiResponse>> getCustomers({
    int page = 1,
    int limit = 10,
    String? search,
    String? searchText,
    String? status,
    int? type, // 201 Alıcı, 202 Satıcı, 203 Potansiyel
    List<int>? types,
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

      final headers = AppConfig.getHeaders(token);

      final scope = await AdvisorOfficeScope.load();
      final queryParams = <String, dynamic>{
        'page': scope.restricted ? 1 : page,
        'pageSize': scope.restricted ? 500 : limit,
        'searchText': (searchText ?? search)?.trim() ?? '',
      };

      final typeToSend = type ??
          (types != null && types.isNotEmpty ? types.first : null);
      if (typeToSend != null) {
        queryParams['type'] = typeToSend;
      }

      if (status != null && status.isNotEmpty && status != 'Tümü') {
        if (status == 'Aktif') {
          queryParams['status'] = 1;
        } else if (status == 'Pasif') {
          queryParams['status'] = 0;
        }
      }

      final response = await _client.dio.get(
        AppConfig.customersEndpoint,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map) {
          return Left(ServerFailure(message: 'Müşteriler getirilemedi'));
        }
        final parsed = CustomerApiResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
        final customers = scope.restricted
            ? parsed.customers
                .where(
                  (customer) => scope.allows(
                    officeId: customer.connectedContact,
                  ),
                )
                .toList()
            : parsed.customers;
        return Right(
          CustomerApiResponse(
            customers: customers,
            totalCount: scope.restricted ? customers.length : parsed.totalCount,
            totalPages: scope.restricted ? 1 : parsed.totalPages,
            page: scope.restricted
                ? 1
                : (parsed.page > 0 ? parsed.page : page),
          ),
        );
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Müşteriler getirilemedi'));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'API endpoint bulunamadı'));
      } else {
        return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  // GET - ID'ye göre customer getir
  Future<Either<Failure, CustomerApiModel>> getCustomerById(int customerId) async {
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

      final response = await _client.dio.get(
        "${AppConfig.customersEndpoint}/$customerId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final customer = CustomerApiModel.fromJson(response.data['data'] ?? response.data);
        return Right(customer);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Müşteri bulunamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Customer durumunu güncelle
  Future<Either<Failure, bool>> updateCustomerStatus({
    required int customerId,
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

      final headers = AppConfig.getHeaders(token);

      final response = await _client.dio.post(
        "${AppConfig.customersEndpoint}/$customerId/status",
        data: {'status': isActive ? 1 : 0},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Müşteri durumu güncellenemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Yeni customer oluştur
  Future<Either<Failure, CustomerApiModel>> createCustomer(CustomerApiModel customer) async {
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

      print('🔄 Create Customer Request:');
      print('📋 Customer Data: ${customer.toCreateJson()}');
      print('📋 Endpoint: ${AppConfig.customersEndpoint}');

      final response = await _client.dio.post(
        AppConfig.customersEndpoint,
        data: customer.toCreateJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Customer başarıyla oluşturuldu');
        // Backend sadece success message dönüyor (CUSTOMER_CREATED), full data yok
        // Oluşturulan customer'ı geri döndür (backend'den gelen pk ile)
        return Right(customer);
      } else {
        return Left(ServerFailure(message: _customerErrorMessage(response.data)));
      }
    } on DioException catch (e) {
      print('❌ Create Customer Error: ${e.response?.statusCode} ${e.response?.data}');
      return Left(ServerFailure(message: _customerErrorMessage(e.response?.data, e.response?.statusCode)));
    } catch (e) {
      print('❌ Create Customer Error: $e');
      return Left(const ServerFailure(message: 'Müşteri kaydedilemedi. Tekrar deneyin.'));
    }
  }

  // POST - Customer güncelle (Backend: POST /customer with snake_case)
  Future<Either<Failure, CustomerApiModel>> updateCustomer(int customerId, CustomerApiModel customer) async {
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

      // Backend'in beklediği format (snake_case)
      final updateData = {
        'contact_no': customerId,
        'status': customer.status,
        'name': customer.name,
        'surname': customer.surname,
        'type': customer.type,
        'tc_id_number': customer.tcIdNumber,
        'tax_no': customer.taxNo,
        'tax_office': customer.taxOffice,
        'nationality': customer.nationality,
        'sex': customer.sex,
        'e_mail': customer.eMail,
        'tel': customer.tel,
        'listings': [], // Backend expects this
        'real_estates': [], // Backend expects this
        'detail': {
          // birthday boş ise null gönder (timestamp hatası önlemek için)
          if (customer.detail.birthday != null && customer.detail.birthday!.isNotEmpty)
            'birthday': customer.detail.birthday,
          // Backend UUID bekliyor (sadece id)
          'profession': customer.detail.profession?.id,
          'education': customer.detail.education?.id,
          'social_media': {
            'instagram': customer.detail.socialMedia?.instagram,
            'facebook': customer.detail.socialMedia?.facebook,
            'x': customer.detail.socialMedia?.x,
            'linkedin': customer.detail.socialMedia?.linkedin,
          },
          // Boş stringleri conditional olarak gönder
          if (customer.detail.whereYouHeardUs.isNotEmpty)
            'where_you_heard_us': customer.detail.whereYouHeardUs,
          if (customer.detail.coverLetter.isNotEmpty)
            'cover_letter': customer.detail.coverLetter,
          // Profil fotoğrafı (web'deki gibi)
          if (customer.detail.picture != null && customer.detail.picture!.isNotEmpty)
            'picture': customer.detail.picture,
          'detail': {
            'tags': customer.detail.detail?.tags ?? [],
            'children_amount': customer.detail.detail?.childrenAmount ?? 0,
            'monthly_salary': customer.detail.detail?.monthlySalary ?? 'N/A',
            'marital_status': customer.detail.detail?.maritalStatus,
          },
        },
      };

      print('🔄 Update Customer Request (ID: $customerId):');
      print('📋 Customer Data: $updateData');
      print('📋 Endpoint: ${EnvApi.origin}/api/zecorner/customer');

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/customer",
        data: updateData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Customer başarıyla güncellendi (ID: $customerId)');
        // Backend sadece success message dönüyor, full data yok
        // Güncellenmiş customer'ı geri döndür
        return Right(customer);
      } else {
        print('❌ Customer güncellenemedi: ${response.statusCode}');
        return Left(ServerFailure(message: response.data['message'] ?? 'Müşteri güncellenemedi'));
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

  // DELETE - Customer sil
  Future<Either<Failure, bool>> deleteCustomer(int customerId) async {
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

      final response = await _client.dio.delete(
        "${AppConfig.customersEndpoint}/$customerId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Müşteri silinemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Customer türlerini getir (Alıcı/Satıcı)
  Future<Either<Failure, List<String>>> getCustomerTypes() async {
    try {
      // Sabit değerler döndür
      return Right(['Alıcı', 'Satıcı']);
    } catch (e) {
      return Left(ServerFailure(message: 'Müşteri türleri getirilemedi: $e'));
    }
  }

  // GET - Medeni durumları getir
  Future<Either<Failure, List<String>>> getMaritalStatuses() async {
    try {
      // Sabit değerler döndür
      return Right(['Bekar', 'Evli', 'Boşanmış']);
    } catch (e) {
      return Left(ServerFailure(message: 'Medeni durumlar getirilemedi: $e'));
    }
  }

  // GET - Uzmanlık alanlarını getir
  Future<Either<Failure, List<String>>> getExpertiseAreas() async {
    try {
      // Sabit değerler döndür
      return Right(['Eğitim', 'Sağlık', 'Teknoloji', 'Hukuk', 'Finans', 'Akademisyen']);
    } catch (e) {
      return Left(ServerFailure(message: 'Uzmanlık alanları getirilemedi: $e'));
    }
  }

  // GET - Eğitim seviyelerini getir
  Future<Either<Failure, List<String>>> getEducationLevels() async {
    try {
      // Sabit değerler döndür
      return Right(['Lise', 'Üniversite', 'Yüksek Lisans', 'Doktora']);
    } catch (e) {
      return Left(ServerFailure(message: 'Eğitim seviyeleri getirilemedi: $e'));
    }
  }

  // Profil fotoğrafı: presigned S3 + legacy (ContactApiRepository.uploadFile)
  Future<Either<Failure, String>> uploadProfilePicture(File imageFile) async {
    return ContactApiRepository().uploadFile(imageFile, 'profile_image');
  }
}

String _customerErrorMessage(dynamic data, [int? statusCode]) {
  if (data is Map) {
    final raw = data['message'] ?? data['error'] ?? data['detail'];
    final text = raw?.toString().trim() ?? '';
    if (text.isNotEmpty &&
        !text.contains('DioException') &&
        !text.contains('validateStatus') &&
        text.length < 220) {
      return text;
    }
  }
  if (statusCode == 500) {
    return 'Sunucu müşteriyi kaydedemedi. Zorunlu alanları kontrol edip tekrar deneyin.';
  }
  return 'Müşteri kaydedilemedi. Tekrar deneyin.';
}