import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/bform/web_advisor_model.dart';

class WebAdvisorRepository {
  WebAdvisorRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Yeni sayfalar eski BASE_URL'de yok. Ziyaretlerle aynı sunucu:
  /// test `3.77.159.125` → `63.179.167.252`, canlı → `18.195.239.53`.
  static const _liveBase = 'http://18.195.239.53/api/zecorner';
  static const _testBase = 'http://63.179.167.252/api/zecorner';

  String get _base {
    final host = Uri.tryParse(EnvApi.origin)?.host.toLowerCase() ?? '';
    if (host == '3.77.159.125') return _testBase;
    return _liveBase;
  }

  String get _path => '$_base/forms/web-advisor';

  Future<Either<Failure, WebAdvisorListResponse>> fetchList({
    int page = 1,
    int pageSize = 20,
    String? searchText,
    String? currentStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return const Left(AuthFailure(message: 'Oturum bulunamadı.'));
      }
      final query = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (searchText != null && searchText.trim().isNotEmpty) {
        query['searchText'] = searchText.trim();
      }
      if (currentStatus != null && currentStatus.isNotEmpty) {
        query['current_status'] = currentStatus;
      }
      if (startDate != null) query['start_date'] = _day(startDate);
      if (endDate != null) query['end_date'] = _day(endDate);

      final response = await _dio.get(
        '$_path/',
        queryParameters: query,
        options: Options(headers: headers),
      );
      final data = response.data;
      if (data is! Map) {
        return const Left(ServerFailure(message: 'Başvuru listesi okunamadı.'));
      }
      return Right(
        WebAdvisorListResponse.fromJson(Map<String, dynamic>.from(data)),
      );
    } on DioException catch (e) {
      return Left(_failure(e, 'Başvurular yüklenemedi.'));
    } catch (e) {
      return Left(ServerFailure(message: 'Başvurular yüklenemedi: $e'));
    }
  }

  Future<Either<Failure, WebAdvisorLookups>> fetchLookups() async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return const Left(AuthFailure(message: 'Oturum bulunamadı.'));
      }
      final response = await _dio.get(
        '$_path/lookups',
        options: Options(headers: headers),
      );
      final data = response.data;
      if (data is! Map) return const Right(WebAdvisorLookups(statusTypes: [], contactTypes: []));
      return Right(WebAdvisorLookups.fromJson(Map<String, dynamic>.from(data)));
    } on DioException catch (e) {
      return Left(_failure(e, 'Durum listesi yüklenemedi.'));
    } catch (e) {
      return Left(ServerFailure(message: 'Durum listesi yüklenemedi: $e'));
    }
  }

  Future<Either<Failure, WebAdvisorApplication>> fetchDetail(int id) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return const Left(AuthFailure(message: 'Oturum bulunamadı.'));
      }
      final response = await _dio.get(
        '$_path/$id',
        options: Options(headers: headers),
      );
      return Right(_application(response.data));
    } on DioException catch (e) {
      return Left(_failure(e, 'Başvuru detayı yüklenemedi.'));
    } catch (e) {
      return Left(ServerFailure(message: 'Başvuru detayı yüklenemedi: $e'));
    }
  }

  Future<Either<Failure, WebAdvisorApplication>> createStatus({
    required int id,
    required String statusType,
    required String contactType,
    String? description,
    DateTime? date,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return const Left(AuthFailure(message: 'Oturum bulunamadı.'));
      }
      final body = <String, dynamic>{
        'status_type': statusType,
        'contact_type': contactType,
      };
      final note = description?.trim();
      if (note != null && note.isNotEmpty) body['description'] = note;
      if (date != null) body['date'] = date.toUtc().toIso8601String();

      final response = await _dio.post(
        '$_path/$id/status',
        data: body,
        options: Options(headers: headers),
      );
      return _applicationOrDetail(id, response.data);
    } on DioException catch (e) {
      return Left(_failure(e, 'Durum kaydı eklenemedi.'));
    } catch (e) {
      return Left(ServerFailure(message: 'Durum kaydı eklenemedi: $e'));
    }
  }

  Future<Either<Failure, WebAdvisorApplication>> deleteStatus({
    required int id,
    required int statusId,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return const Left(AuthFailure(message: 'Oturum bulunamadı.'));
      }
      final response = await _dio.delete(
        '$_path/$id/status/$statusId',
        options: Options(headers: headers),
      );
      return _applicationOrDetail(id, response.data);
    } on DioException catch (e) {
      return Left(_failure(e, 'Durum kaydı silinemedi.'));
    } catch (e) {
      return Left(ServerFailure(message: 'Durum kaydı silinemedi: $e'));
    }
  }

  Future<Either<Failure, WebAdvisorApplication>> _applicationOrDetail(
    int id,
    dynamic data,
  ) async {
    try {
      if (data == null || data == '') return fetchDetail(id);
      return Right(_application(data));
    } catch (_) {
      return fetchDetail(id);
    }
  }

  WebAdvisorApplication _application(dynamic data) {
    if (data is Map && data['applications'] is List) {
      final list = data['applications'] as List;
      if (list.isNotEmpty && list.first is Map) {
        return WebAdvisorApplication.fromJson(
          Map<String, dynamic>.from(list.first as Map),
        );
      }
    }
    if (data is Map && data['application'] is Map) {
      return WebAdvisorApplication.fromJson(
        Map<String, dynamic>.from(data['application'] as Map),
      );
    }
    if (data is Map) {
      return WebAdvisorApplication.fromJson(Map<String, dynamic>.from(data));
    }
    throw const FormatException('Başvuru yanıtı okunamadı.');
  }

  Future<Map<String, String>?> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT');
    final apiKey = dotenv.env['X_API_KEY'];
    final appId = dotenv.env['X_APP_ID'];
    if (token == null || token.isEmpty || apiKey == null || appId == null) {
      return null;
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'X-SESSION': token,
      'X-API-KEY': apiKey,
      'X-APP-ID': appId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cookie': 'X-SESSION=$token',
    };
    final userId = prefs.getString('userID');
    if (userId != null && userId.isNotEmpty) {
      headers['X-UR-ID'] = userId;
    }
    final ip = dotenv.env['X_HB_IP']?.trim();
    headers['X-HB-IP'] = (ip != null && ip.isNotEmpty) ? ip : '::1';
    final agent = dotenv.env['X_HB_USER_AGENT']?.trim();
    headers['X-HB-USER-AGENT'] =
        (agent != null && agent.isNotEmpty) ? agent : 'flutter-app';
    return headers;
  }

  Failure _failure(DioException e, String fallback) {
    final data = e.response?.data;
    String? message;
    if (data is Map && data['message'] is String) {
      final text = (data['message'] as String).trim();
      if (text.isNotEmpty) message = text;
    }
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return AuthFailure(
        message: message ?? 'Bu sayfaya erişim izniniz bulunmuyor.',
        statusCode: status,
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(message: 'İnternet bağlantısı yok.');
    }
    return ServerFailure(message: message ?? fallback, statusCode: status);
  }

  String _day(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}
