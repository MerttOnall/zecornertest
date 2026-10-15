import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/models/myfiles/my_file_model.dart';

/// Kişinin kendi dosyaları — Next `/myFiles` ve `/myFile/{id}`.
/// ZeDosya (`/files`) ile karıştırılmaz.
class MyFilesRepository {
  final Dio _dio;

  MyFilesRepository({required Dio dio}) : _dio = dio;

  String get _baseUrl => EnvApi.origin;

  Future<Map<String, String>?> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT');
    final apiKey = dotenv.env['X_API_KEY'];
    final appId = dotenv.env['X_APP_ID'];

    if (token == null || token.isEmpty) return null;
    if (apiKey == null || appId == null) return null;

    return {
      'X-SESSION': token,
      'X-API-KEY': apiKey,
      'X-APP-ID': appId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Map<String, String> _withNextProxyHeaders(Map<String, String> headers) {
    final requestHeaders = Map<String, String>.from(headers);
    final token = requestHeaders['X-SESSION'];
    if (token != null && token.isNotEmpty) {
      requestHeaders['Cookie'] = 'X-SESSION=$token';
      requestHeaders['Authorization'] = 'Bearer $token';
    }
    return requestHeaders;
  }

  bool _isNextUrl(String url) {
    return url.contains('/api/get-my-files') ||
        url.contains('/api/myFiles') ||
        url.contains('/api/myFile') ||
        url.contains('/api/save-my-file') ||
        url.contains('/api/add-my-file') ||
        url.contains('/api/delete-my-file');
  }

  void _collectUrl(List<String> urls, Set<String> seen, String? raw) {
    if (raw == null || raw.trim().isEmpty) return;
    var url = raw.trim();
    if (!url.startsWith('http')) {
      url = '$_baseUrl${url.startsWith('/') ? url : '/$url'}';
    }
    url = url.replaceAll(RegExp(r'/$'), '');
    if (seen.add(url)) urls.add(url);
  }

  Iterable<String> get _webHosts {
    return <String>{
      dotenv.env['NEXT_PUBLIC_HOST']?.trim() ?? '',
      dotenv.env['WEB_NEXT_API_ORIGIN']?.trim() ?? '',
      'https://zecorner.com',
    }.where((host) => host.isNotEmpty && !host.contains('amplifyapp.com'));
  }

  String _normalizeHost(String host) {
    return host.startsWith('http')
        ? host.replaceAll(RegExp(r'/$'), '')
        : 'https://${host.replaceAll(RegExp(r'/$'), '')}';
  }

  List<String> _listUrls() {
    final urls = <String>[];
    final seen = <String>{};

    // Önce gateway path (diğer zecorner endpoint’leriyle aynı)
    _collectUrl(urls, seen, dotenv.env['MYFILES']);
    _collectUrl(urls, seen, '$_baseUrl/api/zecorner/myFiles');

    final bamma = dotenv.env['BAMMA_APP_URL']?.trim();
    if (bamma != null && bamma.isNotEmpty) {
      _collectUrl(urls, seen, '${bamma.replaceAll(RegExp(r'/$'), '')}/myFiles');
    }
    _collectUrl(urls, seen, '$_baseUrl/myFiles');
    _collectUrl(urls, seen, dotenv.env['GET_MY_FILES']);

    for (final host in _webHosts) {
      final normalized = _normalizeHost(host);
      for (final path in ['/api/get-my-files', '/api/myFiles']) {
        final withSlash = EnvApi.amplifyStyleTrailingSlash('$normalized$path');
        if (withSlash != null && seen.add(withSlash)) urls.add(withSlash);
      }
    }
    return urls;
  }

  List<String> _writeUrls() {
    final urls = <String>[];
    final seen = <String>{};

    _collectUrl(urls, seen, dotenv.env['MYFILES']);
    _collectUrl(urls, seen, '$_baseUrl/api/zecorner/myFiles');

    final bamma = dotenv.env['BAMMA_APP_URL']?.trim();
    if (bamma != null && bamma.isNotEmpty) {
      _collectUrl(urls, seen, '${bamma.replaceAll(RegExp(r'/$'), '')}/myFiles');
    }
    _collectUrl(urls, seen, '$_baseUrl/myFiles');

    for (final host in _webHosts) {
      final normalized = _normalizeHost(host);
      for (final path in ['/api/myFiles', '/api/save-my-file', '/api/add-my-file']) {
        final withSlash = EnvApi.amplifyStyleTrailingSlash('$normalized$path');
        if (withSlash != null && seen.add(withSlash)) urls.add(withSlash);
      }
    }
    return urls;
  }

  List<String> _deleteUrls(int id) {
    final urls = <String>[];
    final seen = <String>{};

    final configured = dotenv.env['MYFILE']?.trim();
    if (configured != null && configured.isNotEmpty) {
      final path = configured.contains('{id}')
          ? configured.replaceAll('{id}', '$id')
          : '${configured.replaceAll(RegExp(r'/$'), '')}/$id';
      _collectUrl(urls, seen, path);
    }
    _collectUrl(urls, seen, '$_baseUrl/api/zecorner/myFile/$id');

    final bamma = dotenv.env['BAMMA_APP_URL']?.trim();
    if (bamma != null && bamma.isNotEmpty) {
      _collectUrl(urls, seen, '${bamma.replaceAll(RegExp(r'/$'), '')}/myFile/$id');
    }
    _collectUrl(urls, seen, '$_baseUrl/myFile/$id');

    for (final host in _webHosts) {
      final normalized = _normalizeHost(host);
      for (final path in ['/api/myFile/$id', '/api/delete-my-file/$id']) {
        final withSlash = EnvApi.amplifyStyleTrailingSlash('$normalized$path');
        if (withSlash != null && seen.add(withSlash)) urls.add(withSlash);
      }
    }
    return urls;
  }

  String? _messageFromResponse(dynamic data) {
    if (data is Map) {
      final msg = data['message'] ?? data['error'] ?? data['DESCRIPTION'];
      if (msg != null) return msg.toString();
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return null;
  }

  Failure _fromDio(DioException e) {
    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final message = _messageFromResponse(e.response?.data) ?? 'Server error';
      if (statusCode == 401) {
        return AuthFailure(message: message);
      }
      return ServerFailure(message: message);
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(message: 'İnternet bağlantısı yok.');
    }
    return ServerFailure(message: e.message ?? 'Bilinmeyen hata.');
  }

  MyFileModel? _extractFile(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map.containsKey('id') && map.containsKey('uuid')) {
        return MyFileModel.fromJson(map);
      }
      if (map['data'] is Map) {
        return MyFileModel.fromJson(Map<String, dynamic>.from(map['data'] as Map));
      }
    }
    return null;
  }

  Future<Either<Failure, MyFileResponse>> getMyFiles({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final headers = await _authHeaders();
    if (headers == null) {
      return Left(AuthFailure(message: 'Oturum bilgisi bulunamadı.'));
    }

    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'limit': pageSize,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
      queryParams['searchText'] = search;
    }

    Failure? lastFailure;
    for (final url in _listUrls()) {
      final requestHeaders = _isNextUrl(url) ? _withNextProxyHeaders(headers) : headers;
      try {
        final response = await _dio.get(
          url,
          queryParameters: queryParams,
          options: Options(headers: requestHeaders),
        );
        if (response.statusCode != 200 || response.data is! Map) {
          lastFailure = ServerFailure(
            message: 'Dosyalar yüklenemedi (${response.statusCode})',
          );
          continue;
        }
        final payload = Map<String, dynamic>.from(response.data as Map);
        if (!payload.containsKey('data') && !payload.containsKey('totalCount')) {
          lastFailure = ServerFailure(message: 'Dosya listesi bulunamadı.');
          continue;
        }
        return Right(MyFileResponse.fromJson(payload));
      } on DioException catch (e) {
        lastFailure = _fromDio(e);
      } catch (e) {
        lastFailure = ServerFailure(message: 'Dosyalar yüklenirken hata: $e');
      }
    }

    return Left(lastFailure ?? ServerFailure(message: 'Dosyalar yüklenemedi.'));
  }

  /// Next POST `/myFiles` → BAMMA `/myFiles`
  Future<Either<Failure, MyFileModel>> createMyFile({
    required String title,
    required String subTitle,
    required String fileName,
    required String uuid,
    String? thumbnail,
  }) async {
    final headers = await _authHeaders();
    if (headers == null) {
      return Left(AuthFailure(message: 'Oturum bilgisi bulunamadı.'));
    }

    // Web/BAMMA body — category UI yok; API örneklerinde 1
    final data = <String, dynamic>{
      'title': title,
      'sub_title': subTitle,
      'file_name': fileName,
      'uuid': uuid,
      'category': 1,
      'status': 1,
      'detail': null,
      'thumbnail': (thumbnail != null && thumbnail.isNotEmpty) ? thumbnail : null,
    };

    Failure? lastFailure;
    for (final url in _writeUrls()) {
      final requestHeaders = _isNextUrl(url) ? _withNextProxyHeaders(headers) : headers;
      try {
        debugPrint('📤 MyFiles POST: $url');
        debugPrint('📋 Body: $data');
        final response = await _dio.post(
          url,
          data: data,
          options: Options(
            headers: requestHeaders,
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        debugPrint('📥 MyFiles POST status: ${response.statusCode}');
        debugPrint('📥 MyFiles POST data: ${response.data}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final parsed = _extractFile(response.data);
          if (parsed != null) return Right(parsed);
          // 200 ama gövde farklı format — kayıt kabul edildi say
          return Right(
            MyFileModel(
              id: 0,
              title: title,
              subTitle: subTitle,
              fileName: fileName,
              uuid: uuid,
              category: 1,
              thumbnail: thumbnail,
              status: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }

        lastFailure = ServerFailure(
          message: _messageFromResponse(response.data) ??
              'Dosya kaydedilemedi (${response.statusCode})',
        );
      } on DioException catch (e) {
        debugPrint('❌ MyFiles POST DioException ($url): ${e.message}');
        debugPrint('📦 Response: ${e.response?.data}');
        lastFailure = _fromDio(e);
      } catch (e) {
        lastFailure = ServerFailure(message: 'Dosya kaydetme hatası: $e');
      }
    }

    return Left(lastFailure ?? ServerFailure(message: 'Dosya kaydedilemedi.'));
  }

  /// Next DELETE `/myFile/{id}` → BAMMA `/myFile/{id}`
  Future<Either<Failure, bool>> deleteMyFile(int id) async {
    final headers = await _authHeaders();
    if (headers == null) {
      return Left(AuthFailure(message: 'Oturum bilgisi bulunamadı.'));
    }

    Failure? lastFailure;
    for (final url in _deleteUrls(id)) {
      final requestHeaders = _isNextUrl(url) ? _withNextProxyHeaders(headers) : headers;
      try {
        final response = await _dio.delete(
          url,
          options: Options(headers: requestHeaders),
        );
        if (response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 204) {
          return const Right(true);
        }
        lastFailure = ServerFailure(
          message: _messageFromResponse(response.data) ??
              'Dosya silinemedi (${response.statusCode})',
        );
      } on DioException catch (e) {
        lastFailure = _fromDio(e);
      } catch (e) {
        lastFailure = ServerFailure(message: 'Dosya silme hatası: $e');
      }
    }

    return Left(lastFailure ?? ServerFailure(message: 'Dosya silinemedi.'));
  }

  Future<Either<Failure, String>> downloadFile(MyFileModel file) async {
    try {
      final headers = await _authHeaders();
      if (headers == null) {
        return Left(AuthFailure(message: 'Oturum bilgisi bulunamadı.'));
      }

      final endpoints = <String>{
        ...ImageUtils.getAlternativeImageUrls(file.uuid),
        ImageUtils.getS3FileUrl(file.uuid),
        if (file.fileName.isNotEmpty) ImageUtils.getS3FileUrl(file.fileName),
        '$_baseUrl/api/retrieve-file?name=${file.uuid}',
      }.where((url) => url.isNotEmpty).toList();

      for (final endpoint in endpoints) {
        if (endpoint.isEmpty) continue;
        try {
          final response = await _dio.get(
            endpoint,
            options: Options(
              headers: headers,
              responseType: ResponseType.bytes,
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
            ),
          );
          if (response.statusCode != 200 || response.data is! List<int>) continue;
          final bytes = response.data as List<int>;
          if (bytes.isEmpty) continue;

          final directory = await _downloadDirectory();
          final safeName = file.fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
          final path = '${directory.path}/$safeName';
          await File(path).writeAsBytes(bytes);
          if (await File(path).length() == 0) continue;
          return Right(path);
        } catch (_) {
          continue;
        }
      }

      return Left(ServerFailure(message: 'Dosya indirilemedi.'));
    } on DioException catch (e) {
      return Left(_fromDio(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Dosya indirme hatası: $e'));
    }
  }

  Future<Directory> _downloadDirectory() async {
    if (Platform.isIOS) {
      final doc = await getApplicationDocumentsDirectory();
      final sub = Directory('${doc.path}/Downloads');
      if (!await sub.exists()) await sub.create(recursive: true);
      return sub;
    }
    if (Platform.isAndroid) {
      try {
        final pub = await getDownloadsDirectory();
        if (pub != null) {
          final sub = Directory('${pub.path}/Zecorner');
          if (!await sub.exists()) await sub.create(recursive: true);
          return sub;
        }
      } catch (_) {}
    }
    final fallback = await getApplicationDocumentsDirectory();
    final sub = Directory('${fallback.path}/Downloads');
    if (!await sub.exists()) await sub.create(recursive: true);
    return sub;
  }
}
