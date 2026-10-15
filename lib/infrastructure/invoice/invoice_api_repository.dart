import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/mixins/update_mixin.dart';
import '../../models/invoice/invoice_model.dart';
import 'package:zecorner/core/config/env_api.dart';

/// Invoice API Repository
/// Endpoint: GET /api/zecorner/pay/invoices
class InvoiceApiRepository with UpdateMixin {
  static final InvoiceApiRepository _instance = InvoiceApiRepository._internal();
  factory InvoiceApiRepository() => _instance;
  InvoiceApiRepository._internal();

  final DioClient _client = DioClient();
  
  @override
  DioClient get dioClient => _client;

  /// Faturaları getir
  /// [page] - Sayfa numarası (default: 1)
  /// [limit] - Sayfa başına kayıt sayısı (default: 20)
  /// [state] - Filtre: PAID, PENDING, CANCELLED
  /// [type] - Filtre: training, advisor, monthly, franchise
  /// [search] - Arama metni
  /// [startDate] / [endDate] - Tarih aralığı
  /// [all] - Tüm faturaları getir (true ise, false ise sadece kullanıcının faturaları)
  Future<Either<Failure, InvoiceResponse>> getInvoices({
    int page = 1,
    int limit = 20,
    String? state,
    String? type,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    bool all = false,
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

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (all) {
        queryParams['all'] = 'true';
      }

      if (state != null && state.isNotEmpty && state != 'Tümü') {
        queryParams['state'] = state;
      }

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        queryParams['q'] = search;
      }

      if (startDate != null) {
        final startIso = DateTime(startDate.year, startDate.month, startDate.day)
            .toIso8601String();
        queryParams['startDate'] = startIso;
        queryParams['start_date'] = startIso;
      }

      if (endDate != null) {
        final endIso = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
            .toIso8601String();
        queryParams['endDate'] = endIso;
        queryParams['end_date'] = endIso;
      }

      final urls = _invoiceCollectionUrls();
      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('📋 Query Parameters: $queryParams');
      print('🌐 Invoice URLs: $urls');

      InvoiceResponse? lastEmpty;
      int? lastStatus;
      String? lastMessage;

      for (final fullUrl in urls) {
        try {
          final response = await dioClient.dio.get(
            fullUrl,
            queryParameters: queryParams,
            options: Options(
              headers: headers,
              responseType: ResponseType.json,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          print('📥 Data: ${response.data}');

          lastStatus = response.statusCode;
          if (response.statusCode == 200) {
            final payload = extractInvoiceResponseJson(response.data);
            if (payload == null) {
              continue;
            }
            final invoiceResponse = InvoiceResponse.fromJson(payload);
            if (invoiceResponse.invoices.isNotEmpty ||
                invoiceResponse.totalCount > 0) {
              return Right(invoiceResponse);
            }
            lastEmpty = invoiceResponse;
            continue;
          }

          final data = response.data;
          if (data is Map && data['message'] != null) {
            lastMessage = data['message'].toString();
          }
          if (_shouldTryNextInvoiceUrl(response.statusCode)) {
            continue;
          }
          return Left(ServerFailure(
            message: lastMessage ?? 'Sunucu hatası oluştu',
            statusCode: response.statusCode,
          ));
        } on DioException catch (e) {
          lastStatus = e.response?.statusCode;
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            lastMessage = data['message'].toString();
          }
          if (_shouldTryNextInvoiceUrl(e.response?.statusCode)) {
            continue;
          }
          rethrow;
        }
      }

      if (lastEmpty != null) {
        return Right(lastEmpty);
      }

      return Left(ServerFailure(
        message: lastMessage ?? 'Faturalar yüklenemedi',
        statusCode: lastStatus,
      ));
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz yok."));
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        return Left(NetworkFailure(message: "Bağlantı zaman aşımına uğradı."));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(NetworkFailure(message: "İnternet bağlantınızı kontrol edin."));
      }

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Tek fatura detayı getir
  Future<Either<Failure, InvoiceModel>> getInvoiceDetail(String invoiceId) async {
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

      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl/api/zecorner/pay/invoices/$invoiceId";

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');

      final response = await dioClient.dio.get(
        fullUrl,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final raw = response.data;
        Map<String, dynamic>? map;
        if (raw is Map && raw['id'] != null) {
          map = Map<String, dynamic>.from(raw);
        } else {
          final extracted = extractInvoiceResponseJson(raw);
          final list = extracted?['invoices'];
          if (list is List && list.isNotEmpty && list.first is Map) {
            map = Map<String, dynamic>.from(list.first as Map);
          }
        }
        if (map == null) {
          return Left(ServerFailure(message: 'Fatura yanıtı okunamadı'));
        }
        return Right(InvoiceModel.fromJson(map));
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Sunucu hatası oluştu',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz yok."));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: "Fatura bulunamadı."));
      }

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Fatura PDF indirme URL'i al
  Future<Either<Failure, String>> getInvoicePdfUrl(String invoiceId) async {
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

      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl/api/zecorner/pay/invoices/$invoiceId/pdf";

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');

      final response = await dioClient.dio.get(
        fullUrl,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final pdfUrl = response.data['url'] ?? response.data['pdf_url'] ?? '';
        return Right(pdfUrl);
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Sunucu hatası oluştu',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Faturayı onayla (AWAITING_PAYMENT -> PAID)
  Future<Either<Failure, bool>> approveInvoice(String invoiceId) async {
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

      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl/api/zecorner/pay/invoices/$invoiceId/approve";

      // Body'de status gönder
      final body = {
        'status': 'PAID',
      };

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');
      print('📤 Request Body: $body');

      final response = await dioClient.dio.post(
        fullUrl,
        data: body,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Fatura onaylanamadı',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  bool _shouldTryNextInvoiceUrl(int? statusCode) {
    return statusCode == null ||
        statusCode == 401 ||
        statusCode == 404 ||
        statusCode == 405;
  }

  /// Next.js BAMMA'ya `GET {BAMMA_APP_URL}/pay/invoices` atar.
  /// Mobil hem BAMMA yolunu hem Next `/api/get-invoices/` proxy'sini dener.
  List<String> _invoiceCollectionUrls() {
    final urls = <String>[];
    final seen = <String>{};

    void add(String? raw, {bool trailingSlash = false}) {
      if (raw == null || raw.trim().isEmpty) return;
      var url = raw.trim();
      if (!url.startsWith('http')) {
        url = '${EnvApi.origin}${url.startsWith('/') ? url : '/$url'}';
      }
      if (trailingSlash) {
        url = EnvApi.amplifyStyleTrailingSlash(url) ?? url;
      } else {
        url = url.replaceAll(RegExp(r'/$'), '');
      }
      if (seen.add(url)) urls.add(url);
    }

    add(dotenv.env['INVOICES']?.trim());
    add('${EnvApi.origin}/pay/invoices');
    add('${EnvApi.zecornerBase}/pay/invoices');

    final web = EnvApi.webNextApiOrigin;
    if (web != null && web.isNotEmpty) {
      add('$web/api/get-invoices', trailingSlash: true);
      add('$web/api/zecorner/pay/invoices', trailingSlash: true);
      add('$web/api/pay/invoices', trailingSlash: true);
    }

    return urls;
  }
}

