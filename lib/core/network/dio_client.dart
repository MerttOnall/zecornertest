import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_session_storage.dart';
import '../config/api_config.dart';
import '../config/env_api.dart';
import '../error/failures.dart';
import '../utils/either.dart';
// import 'api_network_inspector.dart';

const _kProxymanHost = 'localhost';
const _kProxymanPort = 9090;

/// Debug-only Proxyman proxy. Off unless `.env` has `USE_PROXYMAN=true`.
/// Forced proxy breaks login on device/simulator when Proxyman is not running.
void configureDebugProxy(Dio dio) {
  if (!kDebugMode || kIsWeb) return;

  final enabled = dotenv.env['USE_PROXYMAN']?.trim().toLowerCase() == 'true';
  if (!enabled) return;

  const proxy = '$_kProxymanHost:$_kProxymanPort';

  // Covers stray `Dio()` / `package:http` clients that do not go through [DioClient].
  HttpOverrides.global = _ProxymanHttpOverrides(proxy);

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) => 'PROXY $proxy';
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    },
  );

  debugPrint('Proxyman proxy enabled: $proxy');
}

class _ProxymanHttpOverrides extends HttpOverrides {
  _ProxymanHttpOverrides(this._proxy);

  final String _proxy;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY $_proxy';
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late Dio _dio;

  Dio get dio => _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout, // Eksik olan timeout eklendi
      headers: ApiConfig.defaultHeaders,
      // Mobil cihazlar için ek ayarlar
      validateStatus: (status) {
        // 404 dahil 200-404 arası kodları geçerli say (Not/Task yokken backend bazen 404 dönebiliyor)
        return status != null && (status >= 200 && status < 300 || status == 404);
      },
      followRedirects: true,
      maxRedirects: 5,
    ));

    _setupInterceptors();
    configureDebugProxy(_dio);
    // ApiNetworkInspector.attachToDio(_dio); // API debug — geri açmak için yorumu kaldır
  }

  /// Ham `Dio()` kullanan yerler için aynı network kaydını bağlar.
  static void attachInspector(Dio dio) {
    configureDebugProxy(dio);
    // ApiNetworkInspector.attachToDio(dio); // API debug — geri açmak için yorumu kaldır
  }

  /// Postman / BAMMA gateway: `X-HB-IP`, `X-HB-USER-AGENT` (listing_api_repository vb. ile aynı).
  ///
  /// Next (Amplify) uçları `/api/zecorner` içermez; [EnvApi.webNextApiOrigin] ile aynı host’a giden
  /// isteklerde de eklenir — aksi halde `create-real-estate` vb. **401** dönebiliyor.
  static void _applyZecornerHbHeadersIfNeeded(RequestOptions options) {
    final uri = options.uri;
    final path = uri.path;
    final onZecorner = path.contains('/api/zecorner');
    final onPayInvoices = path.contains('/pay/invoices') ||
        path.contains('/pay/transactions') ||
        path.contains('/get-invoices') ||
        path.contains('/get-transactions');
    final web = EnvApi.webNextApiOrigin;
    final webHost = web != null && web.isNotEmpty
        ? Uri.tryParse(web)?.host
        : null;
    final onWebNext =
        webHost != null && webHost.isNotEmpty && uri.host == webHost;
    final onZecornerWeb =
        uri.host == 'zecorner.com' || uri.host == 'www.zecorner.com';
    if (!onZecorner && !onWebNext && !onPayInvoices && !onZecornerWeb) return;
    bool has(Iterable<dynamic> keys, String name) => keys
        .map((k) => k.toString().toLowerCase())
        .contains(name.toLowerCase());
    final h = options.headers;
    if (!has(h.keys, 'X-HB-IP')) {
      final ip = dotenv.env['X_HB_IP']?.trim();
      h['X-HB-IP'] = (ip != null && ip.isNotEmpty) ? ip : '::1';
    }
    if (!has(h.keys, 'X-HB-USER-AGENT')) {
      final ua = dotenv.env['X_HB_USER_AGENT']?.trim();
      h['X-HB-USER-AGENT'] =
          (ua != null && ua.isNotEmpty) ? ua : 'flutter-app';
    }
  }

  /// Debug: giden isteğin nihai header + body (interceptor sonrası).
  static void debugLogOutgoingRequest(RequestOptions options) {
    if (!kDebugMode) return;
    final line = List.filled(72, '─').join();
    debugPrint(line);
    debugPrint('➜ ${options.method} ${options.uri}');
    debugPrint('── Query params ──');
    debugPrint('  ${options.queryParameters}');
    debugPrint('── Headers (${options.headers.length}) ──');
    final names = options.headers.keys.map((k) => k.toString()).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final name in names) {
      debugPrint('  $name: ${options.headers[name]}');
    }
    debugPrint('── Body ──');
    debugPrint(_stringifyRequestBody(options.data));
    debugPrint(line);
  }

  static String _stringifyRequestBody(dynamic data) {
    if (data == null) return '(null)';
    if (data is String) {
      if (data.length > 8000) {
        return '${data.substring(0, 8000)}…\n… (${data.length} chars total)';
      }
      return data;
    }
    try {
      Object? encodable = data;
      if (data is Map) {
        encodable = data.map(
          (k, v) => MapEntry(k.toString(), _jsonEncodable(v)),
        );
      } else if (data is List) {
        encodable = data.map(_jsonEncodable).toList();
      }
      if (encodable is Map || encodable is List) {
        return const JsonEncoder.withIndent('  ').convert(encodable);
      }
    } catch (e) {
      debugPrint('  (JSON encode failed: $e)');
    }
    if (data is FormData) {
      final buf = StringBuffer('FormData(fields: ${data.fields.length}, files: ${data.files.length})\n');
      for (final e in data.fields) {
        buf.writeln('  field ${e.key}: ${e.value}');
      }
      for (final e in data.files) {
        buf.writeln('  file ${e.key}: ${e.value.filename} (${e.value.length} bytes)');
      }
      return buf.toString();
    }
    return data.toString();
  }

  static dynamic _jsonEncodable(dynamic v) {
    if (v == null || v is num || v is String || v is bool) return v;
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _jsonEncodable(val)));
    }
    if (v is List) return v.map(_jsonEncodable).toList();
    return v.toString();
  }

  void _setupInterceptors() {
    // Request/Response logging interceptor (mobil debug için)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        _applyZecornerHbHeadersIfNeeded(options);

        if (options.extra['skipAuthBearer'] == true) {
          debugLogOutgoingRequest(options);
          handler.next(options);
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AuthSessionStorage.keyUserJwt);
        options.extra['authGeneration'] = AuthSessionStorage.sessionGeneration;
        options.extra['authTokenSnapshot'] = token;

        final pathLower = options.uri.path.toLowerCase();
        final isCredentialRequest = pathLower.contains('/signin') ||
            pathLower.contains('/register');

        // Amplify Next / zecorner.com web proxy: `X-UR-ID` gerekebilir.
        final wo = EnvApi.webNextApiOrigin;
        final wh =
            wo != null && wo.isNotEmpty ? Uri.tryParse(wo)?.host : null;
        final host = options.uri.host.toLowerCase();
        final onZeCornerWeb =
            host == 'zecorner.com' || host == 'www.zecorner.com';
        final onWebProxy =
            onZeCornerWeb || (wh != null && wh.isNotEmpty && host == wh);
        if (onWebProxy) {
          final hasUr = options.headers.entries.any(
            (e) =>
                e.key.toLowerCase() == 'x-ur-id' &&
                e.value != null &&
                e.value.toString().trim().isNotEmpty,
          );
          if (!hasUr) {
            final uid = prefs.getString('userID');
            if (uid != null && uid.isNotEmpty) {
              options.headers['X-UR-ID'] = uid;
            }
          }
        }

        if (token != null && !isCredentialRequest) {
          // Oturum: çoğu BAMMA GET'i yalnız `Authorization: Bearer` ile 200 döner.
          // `createPortfolio` vb. `X-SESSION` da gönderir; X-SESSION varken Bearer
          // eklenmeyince `/api/zecorner/realEstate` POST sürekli 401 verebiliyor.
          final hasXSession = options.headers.entries.any(
            (e) =>
                e.key.toLowerCase() == 'x-session' &&
                e.value != null &&
                e.value.toString().trim().isNotEmpty,
          );
          final onWebNext = wh != null &&
              wh.isNotEmpty &&
              options.uri.host == wh;
          final onZecorner = pathLower.contains('/api/zecorner');
          final isWebTransactionsProxy = pathLower.contains('/get-transactions');
          final methodUp = options.method.toUpperCase();
          final isMutating =
              methodUp == 'POST' || methodUp == 'PUT' || methodUp == 'PATCH';
          final needsNextCreateBearer = onWebNext &&
              (pathLower.contains('/api/create-real-estate') ||
                  pathLower.contains('/api/create-listing'));
          bool hasAuthHeader() => options.headers.entries.any(
                (e) =>
                    e.key.toLowerCase() == 'authorization' &&
                    e.value != null &&
                    e.value.toString().trim().isNotEmpty,
              );

          if (!hasAuthHeader()) {
            if (!hasXSession) {
              options.headers['Authorization'] = 'Bearer $token';
            } else if (needsNextCreateBearer ||
                isWebTransactionsProxy ||
                onZeCornerWeb) {
              options.headers['Authorization'] = 'Bearer $token';
            } else if (onZecorner && isMutating) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
        }
        debugLogOutgoingRequest(options);
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
        print('📥 Data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) async {
        print('❌ ERROR: ${error.type} ${error.message}');
        print('❌ Response: ${error.response?.statusCode} - ${error.response?.data}');
        print('❌ Request: ${error.requestOptions.method} ${error.requestOptions.uri}');
        handler.next(error);
      },
    ));

    // Logging interceptor (only in debug mode)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      error: true,
      logPrint: (obj) {
        // Only log in debug mode
        assert(() {
          print(obj);
          return true;
        }());
      },
    ));
  }

  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      if (fromJson != null) {
        return Right(fromJson(response.data));
      }
      return Right(response.data as T);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (fromJson != null) {
        return Right(fromJson(response.data));
      }
      return Right(response.data as T);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (fromJson != null) {
        return Right(fromJson(response.data));
      }
      return Right(response.data as T);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (fromJson != null) {
        return Right(fromJson(response.data));
      }
      return Right(response.data as T);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          message: 'Bağlantı zaman aşımı',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Sunucu hatası';
        
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          if (statusCode == 401) {
            return AuthFailure(message: 'Kimlik doğrulama hatası', statusCode: statusCode);
          }
          return ValidationFailure(message: message);
        }
        
        return ServerFailure(message: message, statusCode: statusCode);

      case DioExceptionType.cancel:
        return NetworkFailure(message: 'İstek iptal edildi');

      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'İnternet bağlantısı hatası');

      case DioExceptionType.badCertificate:
        return NetworkFailure(message: 'Güvenlik sertifikası hatası');

      case DioExceptionType.unknown:
        return UnknownFailure(message: error.message ?? 'Bilinmeyen hata');
    }
  }
} 