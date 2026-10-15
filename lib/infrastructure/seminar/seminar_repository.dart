import 'package:dartz/dartz.dart' hide Task;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/env_api.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../core/utils/image_utils.dart';
import '../../models/seminar/seminar_model.dart';

class SeminarRepository with BaseRepository {
  static final SeminarRepository _instance = SeminarRepository._internal();
  factory SeminarRepository() => _instance;
  SeminarRepository._internal();

  final DioClient _client = DioClient();

  Future<Either<Failure, Map<String, String>>> _authHeaders({
    required bool forNextProxy,
    required String token,
  }) async {
    final apiKey = dotenv.env['X_API_KEY'];
    final appId = dotenv.env['X_APP_ID'];

    if (apiKey == null || appId == null) {
      return left(ServerFailure(
        message: 'Uygulama yapılandırması eksik. Lütfen yöneticiye başvurun.',
        statusCode: 500,
      ));
    }

    final headers = <String, String>{
      'X-SESSION': token,
      'X-API-KEY': apiKey,
      'X-APP-ID': appId,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (forNextProxy) {
      headers['Cookie'] = 'X-SESSION=$token';
    }
    return right(headers);
  }

  Future<Either<Failure, String>> _requireToken() async {
    final pref = await SharedPreferences.getInstance();
    final token = pref.getString('userJWT');
    if (token == null || token.isEmpty) {
      return left(AuthFailure(message: 'Token bulunamadı. Lütfen tekrar giriş yapın.'));
    }
    return right(token);
  }

  /// Web: `GET /api/get-seminars/?pageSize=&page=&type=education|event&searchText=`
  /// Next.js proxy → BAMMA `{BAMMA_APP_URL}/seminar`
  List<String> _listUrls() {
    final urls = <String>[];
    final seen = <String>{};

    void addUrl(String? raw) {
      if (raw == null || raw.trim().isEmpty) return;
      var url = raw.trim();
      if (!url.startsWith('http')) {
        url = '${EnvApi.origin}${url.startsWith('/') ? url : '/$url'}';
      }
      url = url.replaceAll(RegExp(r'/$'), '');
      if (seen.add(url)) urls.add(url);
    }

    final webHosts = <String>{
      dotenv.env['NEXT_PUBLIC_HOST']?.trim() ?? '',
      ImageUtils.imageHost,
      'https://zecorner.com',
    };

    for (final host in webHosts) {
      if (host.isEmpty || host.contains('amplifyapp.com')) continue;
      final normalized = host.startsWith('http')
          ? host.replaceAll(RegExp(r'/$'), '')
          : 'https://${host.replaceAll(RegExp(r'/$'), '')}';
      final withSlash = EnvApi.amplifyStyleTrailingSlash('$normalized/api/get-seminars');
      if (withSlash != null && seen.add(withSlash)) urls.add(withSlash);
    }

    final bamma = dotenv.env['BAMMA_APP_URL']?.trim();
    if (bamma != null && bamma.isNotEmpty) {
      addUrl('${bamma.replaceAll(RegExp(r'/$'), '')}/seminar');
    }

    addUrl('${EnvApi.origin}/seminar');
    addUrl(dotenv.env['SEMINAR']);
    addUrl('${EnvApi.origin}/api/zecorner/seminar');

    return urls;
  }

  List<String> _detailUrls(int id) {
    return _listUrls()
        .where((url) => !url.contains('get-seminars'))
        .map((url) => '${url.replaceAll(RegExp(r'/$'), '')}/$id')
        .toList();
  }

  Future<Either<Failure, SeminarResponse>> getSeminars({
    int page = 1,
    int pageSize = 10,
    String? type,
    String? search,
    String? searchText,
  }) async {
    final tokenResult = await _requireToken();
    return tokenResult.fold(left, (token) async {
      final query = (searchText ?? search)?.trim() ?? '';
      final queryParams = <String, dynamic>{
        'pageSize': pageSize,
        'page': page,
        'searchText': query,
      };
      if (type == 'event' || type == 'education') {
        queryParams['type'] = type;
      }

      Either<Failure, SeminarResponse>? lastFailure;
      for (final url in _listUrls()) {
        final forNext = url.contains('get-seminars');
        final headersResult = await _authHeaders(forNextProxy: forNext, token: token);
        final headers = headersResult.fold((l) => null, (r) => r);
        if (headers == null) {
          return headersResult.fold(left, (_) => left(UnknownFailure(message: 'Header hatası')));
        }

        try {
          print('🎯 Seminar GET: $url');
          print('📋 Query Params: $queryParams');
          final response = await _client.dio.get(
            url,
            options: Options(headers: headers),
            queryParameters: queryParams,
          );

          if (response.statusCode == 401) {
            lastFailure = left(AuthFailure(
              message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.',
              statusCode: 401,
            ));
            continue;
          }
          if (response.statusCode != 200) {
            lastFailure = left(ServerFailure(
              message: 'Seminer verisi alınamadı (${response.statusCode})',
              statusCode: response.statusCode,
            ));
            continue;
          }

          final payload = _asJsonMap(response.data);
          if (payload == null) {
            lastFailure = left(ServerFailure(
              message: 'Seminer yanıtı beklenen formatta değil.',
              statusCode: response.statusCode,
            ));
            continue;
          }

          print('📦 Seminar keys: ${payload.keys.toList()}');
          final seminarResponse = SeminarResponse.fromJson(
            payload,
            fallbackType: type,
          );
          final looksLikeSeminar = payload.containsKey('seminar') ||
              payload.containsKey('seminars') ||
              payload.containsKey('totalCount') ||
              payload.containsKey('totalPages');
          if (!looksLikeSeminar && seminarResponse.data.isEmpty) {
            continue;
          }
          print('✅ ${seminarResponse.data.length} seminar parse edildi ($url)');
          return right(seminarResponse);
        } on DioException catch (e) {
          print('❌ Seminar DioException ($url): ${e.message}');
          print('📦 Response: ${e.response?.data}');
          if (e.response?.statusCode == 401) {
            lastFailure = left(AuthFailure(
              message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.',
              statusCode: 401,
            ));
            continue;
          }
          lastFailure = left(NetworkFailure(
            message: 'Seminer verisi çekilirken hata: ${e.message}',
            statusCode: e.response?.statusCode,
          ));
        } catch (e) {
          print('❌ Seminar hatası ($url): $e');
          lastFailure = left(UnknownFailure(message: 'Seminer hatası: $e'));
        }
      }

      return lastFailure ??
          left(ServerFailure(message: 'Seminer verisi alınamadı.'));
    });
  }

  Future<Either<Failure, Seminar>> getSeminarById(int id) async {
    final tokenResult = await _requireToken();
    return tokenResult.fold(left, (token) async {
      Either<Failure, Seminar>? lastFailure;
      for (final url in _detailUrls(id)) {
        final headersResult = await _authHeaders(forNextProxy: false, token: token);
        final headers = headersResult.fold((l) => null, (r) => r);
        if (headers == null) {
          return headersResult.fold(left, (_) => left(UnknownFailure(message: 'Header hatası')));
        }

        try {
          print('🌐 Get Seminar by ID: $url');
          final response = await _client.dio.get(
            url,
            options: Options(headers: headers),
          );

          if (response.statusCode == 401) {
            lastFailure = left(AuthFailure(
              message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.',
              statusCode: 401,
            ));
            continue;
          }
          if (response.statusCode != 200) {
            lastFailure = left(ServerFailure(
              message: 'Seminer detayı alınamadı (${response.statusCode})',
              statusCode: response.statusCode,
            ));
            continue;
          }

          final payload = _asJsonMap(response.data);
          if (payload == null) {
            lastFailure = left(ServerFailure(
              message: 'Seminer detayı beklenen formatta değil.',
              statusCode: response.statusCode,
            ));
            continue;
          }
          final seminarJson = _unwrapSeminar(payload);
          if (seminarJson == null) {
            lastFailure = left(ServerFailure(message: 'Seminer detayı bulunamadı.'));
            continue;
          }
          return right(Seminar.fromJson(seminarJson));
        } on DioException catch (e) {
          if (e.response?.statusCode == 401) {
            lastFailure = left(AuthFailure(
              message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.',
              statusCode: 401,
            ));
            continue;
          }
          lastFailure = left(NetworkFailure(
            message: 'Seminer detayı çekilirken hata: ${e.message}',
            statusCode: e.response?.statusCode,
          ));
        } catch (e) {
          lastFailure = left(UnknownFailure(message: 'Seminer detail hatası: $e'));
        }
      }

      return lastFailure ??
          left(ServerFailure(message: 'Seminer detayı alınamadı.'));
    });
  }

  Map<String, dynamic>? _unwrapSeminar(Map<String, dynamic> payload) {
    final seminar = payload['seminar'] ?? payload['data'];
    if (seminar is Map) {
      return Map<String, dynamic>.from(seminar);
    }
    if (seminar is List && seminar.isNotEmpty && seminar.first is Map) {
      return Map<String, dynamic>.from(seminar.first as Map);
    }
    if (payload.containsKey('seminar_id') || payload.containsKey('title')) {
      return payload;
    }
    return null;
  }

  Map<String, dynamic>? _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}
