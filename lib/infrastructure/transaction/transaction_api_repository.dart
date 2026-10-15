import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/mixins/update_mixin.dart';
import '../../models/transaction/transaction_model.dart';
import 'package:zecorner/core/config/env_api.dart';

/// Havale Onayları — web ile aynı proxy:
/// GET https://zecorner.com/api/get-transactions/?status=&type=&page=&pageSize=
class TransactionApiRepository with UpdateMixin {
  static final TransactionApiRepository _instance =
      TransactionApiRepository._internal();
  factory TransactionApiRepository() => _instance;
  TransactionApiRepository._internal();

  final DioClient _client = DioClient();

  @override
  DioClient get dioClient => _client;

  /// Web query string ile birebir (ek parametre yok).
  Map<String, dynamic> _buildQueryParams({
    required int page,
    required int limit,
    String? state,
    String? source,
    String? search,
  }) {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': limit,
    };

    if (state != null && state.isNotEmpty) {
      queryParams['status'] = state;
    }

    if (source != null && source.isNotEmpty) {
      queryParams['type'] = source;
    }

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    return queryParams;
  }

  Future<Either<Failure, TransactionResponse>> getTransactions({
    int page = 1,
    int limit = 10,
    String? state,
    String? source,
    String? search,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env['X_API_KEY'];
      final appId = dotenv.env['X_APP_ID'];
      final userId = pref.getString('userID');

      if (token == null) {
        return Left(
          AuthFailure(message: 'Token bulunamadı. Lütfen tekrar giriş yapın.'),
        );
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: 'API anahtarları bulunamadı.'));
      }

      final headers = <String, dynamic>{
        'Authorization': 'Bearer $token',
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (userId != null && userId.isNotEmpty) {
        headers['X-UR-ID'] = userId;
      }

      final queryParams = _buildQueryParams(
        page: page,
        limit: limit,
        state: state,
        source: source,
        search: search,
      );

      final urls = _transactionCollectionUrls();
      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('📋 Query Parameters: $queryParams');
      print('🌐 Transaction URLs: $urls');

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
              extra: const {'skipSessionExpire': true},
            ),
          );

          print(
            '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
          );
          print('📥 Data: ${response.data}');

          lastStatus = response.statusCode;
          if (response.statusCode == 200) {
            final payload = extractTransactionResponseJson(response.data);
            if (payload != null) {
              return Right(TransactionResponse.fromJson(payload));
            }
            continue;
          }

          final data = response.data;
          if (data is Map) {
            lastMessage = _readErrorMessage(data);
          }
          if (_shouldTryNextTransactionUrl(response.statusCode)) {
            continue;
          }
          return Left(
            ServerFailure(
              message: lastMessage ?? 'Sunucu hatası oluştu',
              statusCode: response.statusCode,
            ),
          );
        } on DioException catch (e) {
          lastStatus = e.response?.statusCode;
          final data = e.response?.data;
          if (data is Map) {
            lastMessage = _readErrorMessage(data);
          }
          if (_shouldTryNextTransactionUrl(e.response?.statusCode)) {
            continue;
          }
          rethrow;
        }
      }

      return Left(
        ServerFailure(
          message: lastMessage ??
              'Havale işlemleri yüklenemedi (${lastStatus ?? 'bağlantı hatası'}).',
          statusCode: lastStatus,
        ),
      );
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        return Left(
          AuthFailure(
            message: 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.',
          ),
        );
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Bu işlem için yetkiniz yok.'));
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Left(NetworkFailure(message: 'Bağlantı zaman aşımına uğradı.'));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(
          NetworkFailure(message: 'İnternet bağlantınızı kontrol edin.'),
        );
      }

      return Left(
        ServerFailure(
          message: e.response?.data?['message'] ??
              e.message ??
              'Bilinmeyen bir hata oluştu',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(
        ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  String? _readErrorMessage(Map data) {
    final message = data['message'] ?? data['DESCRIPTION'] ?? data['description'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }
    return null;
  }

  bool _shouldTryNextTransactionUrl(int? statusCode) {
    return statusCode == null ||
        statusCode == 401 ||
        statusCode == 404 ||
        statusCode == 405;
  }

  /// Mobil JWT → önce BAMMA; web oturumu → get-transactions proxy.
  /// Her iki yolda da web parametreleri: status, type, page, pageSize.
  List<String> _transactionCollectionUrls() {
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

    // 1) Mobil giriş (signIn) JWT — BAMMA gateway (fatura API ile aynı sıra)
    add('${EnvApi.zecornerBase}/pay/transactions');
    add('${EnvApi.origin}/pay/transactions');

    // 2) Web Next.js proxy (tarayıcıdaki istek)
    add(dotenv.env['GET_TRANSACTIONS']?.trim(), trailingSlash: true);
    add('https://zecorner.com/api/get-transactions', trailingSlash: true);
    add('https://www.zecorner.com/api/get-transactions', trailingSlash: true);

    final web = EnvApi.webNextApiOrigin;
    if (web != null && web.isNotEmpty) {
      add('$web/api/get-transactions', trailingSlash: true);
      add('$web/api/zecorner/pay/transactions', trailingSlash: true);
    }

    return urls;
  }

  Future<Either<Failure, bool>> approveTransaction(int transactionId) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env['X_API_KEY'];
      final appId = dotenv.env['X_APP_ID'];

      if (token == null) {
        return Left(
          AuthFailure(message: 'Token bulunamadı. Lütfen tekrar giriş yapın.'),
        );
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: 'API anahtarları bulunamadı.'));
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final urls = _transactionActionUrls(transactionId, 'approve');
      final body = {'status': 'APPROVED'};

      for (final fullUrl in urls) {
        try {
          final response = await dioClient.dio.post(
            fullUrl,
            data: body,
            options: Options(
              headers: headers,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200) {
            return const Right(true);
          }
          if (_shouldTryNextTransactionUrl(response.statusCode)) {
            continue;
          }
          return Left(
            ServerFailure(
              message: response.data?['message'] ?? 'İşlem onaylanamadı',
              statusCode: response.statusCode,
            ),
          );
        } on DioException catch (e) {
          if (_shouldTryNextTransactionUrl(e.response?.statusCode)) {
            continue;
          }
          rethrow;
        }
      }

      return Left(ServerFailure(message: 'İşlem onaylanamadı'));
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          message: e.response?.data?['message'] ??
              e.message ??
              'Bilinmeyen bir hata oluştu',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  Future<Either<Failure, bool>> rejectTransaction(int transactionId) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env['X_API_KEY'];
      final appId = dotenv.env['X_APP_ID'];

      if (token == null) {
        return Left(
          AuthFailure(message: 'Token bulunamadı. Lütfen tekrar giriş yapın.'),
        );
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: 'API anahtarları bulunamadı.'));
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final urls = _transactionActionUrls(transactionId, 'reject');
      final body = {'status': 'REJECTED'};

      for (final fullUrl in urls) {
        try {
          final response = await dioClient.dio.post(
            fullUrl,
            data: body,
            options: Options(
              headers: headers,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200) {
            return const Right(true);
          }
          if (_shouldTryNextTransactionUrl(response.statusCode)) {
            continue;
          }
          return Left(
            ServerFailure(
              message: response.data?['message'] ?? 'İşlem reddedilemedi',
              statusCode: response.statusCode,
            ),
          );
        } on DioException catch (e) {
          if (_shouldTryNextTransactionUrl(e.response?.statusCode)) {
            continue;
          }
          rethrow;
        }
      }

      return Left(ServerFailure(message: 'İşlem reddedilemedi'));
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          message: e.response?.data?['message'] ??
              e.message ??
              'Bilinmeyen bir hata oluştu',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'),
      );
    }
  }

  List<String> _transactionActionUrls(int transactionId, String action) {
    final urls = <String>[];
    final seen = <String>{};

    void add(String base) {
      final normalized = base.replaceAll(RegExp(r'/$'), '');
      final url = '$normalized/$transactionId/$action';
      if (seen.add(url)) urls.add(url);
    }

    add('${EnvApi.zecornerBase}/pay/transactions');
    add('${EnvApi.origin}/pay/transactions');
    add('https://zecorner.com/api/pay/transactions');

    final web = EnvApi.webNextApiOrigin;
    if (web != null && web.isNotEmpty) {
      add('$web/api/pay/transactions');
    }

    return urls;
  }
}
