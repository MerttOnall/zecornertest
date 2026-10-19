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
import '../../models/contact/ref_profession_model.dart';
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
        if (!ProfessionCatalog.isReady) {
          final professions = await ContactApiRepository().getProfessions();
          professions.fold((_) {}, (result) {
            ProfessionCatalog.remember(result.professions);
          });
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

  // POST - Web update-customer'ın BAMMA'ya yazdığı iç içe gövde.
  // Next/CloudFront boş cevap verirse kayıt yine sunucuya gider.
  Future<Either<Failure, CustomerApiModel>> updateCustomer(
    int customerId,
    CustomerApiModel customer, {
    String? pictureDataUri,
  }) async {
    try {
      final headers = await _customerHeaders();
      if (headers == null) {
        return const Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      final nested = _withoutEmpty(_nestedCustomerUpdate(customerId, customer));
      final bamma = await _postCustomer(
        '${EnvApi.origin}/api/zecorner/customer',
        nested,
        headers,
        customer,
      );
      if (bamma != null) {
        final bammaMessage = bamma.fold((failure) => failure.message, (_) => '');
        final emptyBody = bamma.isLeft() &&
            bammaMessage == 'Müşteri kaydedilemedi. Tekrar deneyin.';
        if (!emptyBody) return bamma;
      }

      final flat = _withoutEmpty(
        _flatCustomerUpdate(customerId, customer, pictureDataUri: pictureDataUri),
      );
      Either<Failure, CustomerApiModel>? webFailure;
      for (final url in _customerWebUrls('/api/update-customer')) {
        final result = await _postCustomer(url, flat, headers, customer);
        if (result == null) continue;
        if (result.isRight()) return result;
        final message = result.fold((failure) => failure.message, (_) => '');
        if (message == 'Müşteri kaydedilemedi. Tekrar deneyin.' ||
            message == 'Oturum süresi dolmuş') {
          webFailure ??= result;
          continue;
        }
        return result;
      }

      return bamma ??
          webFailure ??
          const Left(ServerFailure(message: 'Müşteri güncellenemedi'));
    } catch (e) {
      return Left(ServerFailure(message: _customerErrorMessage(e)));
    }
  }

  /// Düzenleme ekranı liste satırından daha dolu kayıt ister (web get-customer).
  Future<Either<Failure, CustomerApiModel>> getCustomer(int contactNo) async {
    try {
      final headers = await _customerHeaders();
      if (headers == null) {
        return const Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      final urls = <String>[
        ..._customerWebUrls('/api/get-customer/$contactNo'),
        '${EnvApi.origin}/api/zecorner/customer/$contactNo',
      ];
      for (final url in urls) {
        try {
          final response = await _client.dio.get(
            url,
            options: Options(
              headers: headers,
              validateStatus: (status) => status != null && status < 500,
            ),
          );
          final code = response.statusCode ?? 0;
          if (code == 401 || code == 403 || code == 404 || code == 308) continue;
          if (code != 200 || response.data is! Map) continue;
          final map = Map<String, dynamic>.from(response.data as Map);
          final raw = map['customer'] ?? map['data'] ?? map;
          if (raw is! Map) continue;
          if (!raw.containsKey('contact_no') &&
              !raw.containsKey('name') &&
              !raw.containsKey('tel') &&
              !raw.containsKey('title')) {
            continue;
          }
          final customer = CustomerApiModel.fromJson(Map<String, dynamic>.from(raw));
          if (customer.contactNo == contactNo || customer.name.isNotEmpty || customer.tel.isNotEmpty) {
            return Right(customer);
          }
        } catch (_) {
          continue;
        }
      }
      return const Left(ServerFailure(message: 'Müşteri getirilemedi'));
    } catch (_) {
      return const Left(ServerFailure(message: 'Müşteri getirilemedi'));
    }
  }

  Future<Map<String, String>?> _customerHeaders() async {
    final pref = await SharedPreferences.getInstance();
    final token = pref.getString('userJWT');
    final apiKey = dotenv.env['X_API_KEY'];
    final appId = dotenv.env['X_APP_ID'];
    if (token == null || token.isEmpty) return null;
    if (apiKey == null || appId == null) return null;
    final headers = <String, String>{
      'X-SESSION': token,
      'Authorization': 'Bearer $token',
      'X-API-KEY': apiKey,
      'X-APP-ID': appId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final userId = pref.getString('userID');
    if (userId != null && userId.isNotEmpty) {
      headers['X-UR-ID'] = userId;
    }
    return headers;
  }

  List<String> _customerWebUrls(String path) {
    final urls = <String>[];
    void add(String? origin) {
      if (origin == null || origin.trim().isEmpty) return;
      final url = EnvApi.amplifyStyleTrailingSlash(
        '${origin.replaceAll(RegExp(r'/$'), '')}$path',
      );
      if (url != null && url.isNotEmpty && !urls.contains(url)) urls.add(url);
    }

    add(EnvApi.webNextApiOrigin);
    add('https://zecorner.com');
    add('https://www.zecorner.com');
    return urls;
  }

  Map<String, dynamic> _flatCustomerUpdate(
    int customerId,
    CustomerApiModel customer, {
    String? pictureDataUri,
  }) {
    final social = customer.detail.socialMedia;
    final picture = pictureDataUri?.trim();
    return {
      'contact_no': customerId,
      'status': customer.status,
      'title': customer.title,
      'name': customer.name,
      'surname': customer.surname,
      'type': customer.type,
      'type_description': customer.typeDescription,
      'tc_id_number': customer.tcIdNumber,
      'tax_no': customer.taxNo,
      'tax_office': customer.taxOffice,
      'nationality': customer.nationality,
      'sex': customer.sex,
      'e_mail': customer.eMail,
      'tel': customer.tel,
      'birthday': customer.detail.birthday,
      'profession': _catalogRef(
        customer.detail.profession?.id,
        customer.detail.profession?.code,
      ),
      'education': _catalogRef(
        customer.detail.education?.id,
        customer.detail.education?.code,
      ),
      'social_media': {
        'instagram': social?.instagram,
        'facebook': social?.facebook,
        'x': social?.x,
        'linkedin': social?.linkedin,
      },
      'where_you_heard_us': customer.detail.whereYouHeardUs,
      'cover_letter': customer.detail.coverLetter,
      if (picture != null && picture.startsWith('data:image/')) 'picture': picture,
      'listings': customer.listings.map((item) => item.id).where((id) => id.isNotEmpty).toList(),
      'real_estates': customer.realEstates.map((item) => item.id).where((id) => id.isNotEmpty).toList(),
      'tags': customer.detail.detail?.tags ?? [],
      'children_amount': customer.detail.detail?.childrenAmount ?? 0,
      'monthly_salary': customer.detail.detail?.monthlySalary,
      'marital_status': customer.detail.detail?.maritalStatus,
    };
  }

  Map<String, dynamic> _nestedCustomerUpdate(int customerId, CustomerApiModel customer) {
    final social = customer.detail.socialMedia;
    final picture = customer.detail.picture?.trim();
    final keepPicture = picture != null &&
        picture.isNotEmpty &&
        !picture.startsWith('http') &&
        !picture.startsWith('data:');
    return {
      'status': customer.status,
      'contact_no': customerId,
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
      'listings': customer.listings.map((item) => item.id).where((id) => id.isNotEmpty).toList(),
      'real_estates': customer.realEstates.map((item) => item.id).where((id) => id.isNotEmpty).toList(),
      'detail': {
        'birthday': customer.detail.birthday,
        'profession': _catalogRef(
          customer.detail.profession?.id,
          customer.detail.profession?.code,
        ),
        'education': _catalogRef(
          customer.detail.education?.id,
          customer.detail.education?.code,
        ),
        'social_media': {
          'instagram': social?.instagram,
          'facebook': social?.facebook,
          'x': social?.x,
          'linkedin': social?.linkedin,
        },
        'where_you_heard_us': customer.detail.whereYouHeardUs,
        'cover_letter': customer.detail.coverLetter,
        if (keepPicture) 'picture': picture,
        'detail': {
          'tags': customer.detail.detail?.tags ?? [],
          'children_amount': customer.detail.detail?.childrenAmount ?? 0,
          'monthly_salary': customer.detail.detail?.monthlySalary,
          'marital_status': customer.detail.detail?.maritalStatus,
        },
      },
    };
  }

  Map<String, dynamic> _withoutEmpty(Map<String, dynamic> source) {
    final out = <String, dynamic>{};
    source.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is Map) {
        final nested = _withoutEmpty(Map<String, dynamic>.from(value));
        if (nested.isEmpty) return;
        out[key] = nested;
        return;
      }
      out[key] = value;
    });
    return out;
  }

  String? _catalogRef(String? id, String? code) {
    for (final value in [id, code]) {
      final text = value?.trim() ?? '';
      if (text.isEmpty || text.contains(' ')) continue;
      return text;
    }
    return null;
  }

  /// `null`: sonraki adres denensin (401 / 404 / ağ).
  Future<Either<Failure, CustomerApiModel>?> _postCustomer(
    String url,
    Map<String, dynamic> body,
    Map<String, String> headers,
    CustomerApiModel customer,
  ) async {
    try {
      final response = await _client.dio.post(
        url,
        data: body,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final code = response.statusCode ?? 0;
      if (code == 404 || code == 405 || code == 308 || (code >= 300 && code < 400)) {
        return null;
      }
      if (code == 401 || code == 403) {
        return const Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      }
      if (code == 200 || code == 201) {
        final data = response.data;
        if (data is String && data.trim().isEmpty) return null;
        if (data is Map && (data['success'] == false || data['STATUS'] == 401)) {
          return Left(ServerFailure(message: _customerErrorMessage(data, code)));
        }
        if (data != null && data is! Map && data is! String) return null;
        return Right(customer);
      }
      final message = _customerErrorMessage(response.data, code).toLowerCase();
      if (message.contains('not found') || message.contains('bulunamadı')) return null;
      return Left(ServerFailure(message: _customerErrorMessage(response.data, code)));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == null || code == 404 || code == 405 || code >= 500) return null;
      if (code == 401 || code == 403) {
        return const Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      }
      return Left(ServerFailure(message: _customerErrorMessage(e.response?.data, code)));
    } catch (_) {
      return null;
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
    final raw = data['message'] ??
        data['MESSAGE'] ??
        data['DESCRIPTION'] ??
        data['description'] ??
        data['error'] ??
        data['detail'];
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