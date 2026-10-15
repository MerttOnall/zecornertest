import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/config/api_config.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/reports/cari_report_model.dart';
import 'package:zecorner/models/reports/yearly_sales_report_model.dart';

class ReportsApiRepository {
  Future<YearlySalesReportModel> getYearlySalesReport({
    required int year,
  }) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);
    final data = await _get(
      urls: _yearlyUrls(),
      query: {
        'year': year.toString(),
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      },
      errorLabel: 'Yıllık satış raporu',
    );
    return YearlySalesReportModel.fromJson(data, year: year);
  }

  Future<CariReportModel> getOfficeCurrentAccount({
    String? search,
  }) async {
    final year = DateTime.now().year;
    final start = DateTime.utc(year, 1, 1);
    final end = DateTime.utc(year, 12, 31, 23, 59, 59);
    final query = <String, String>{
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    bool hasRows(dynamic data) =>
        CariReportModel.fromJson(data).accounts.isNotEmpty;

    final dated = await _get(
      urls: _cariUrls(),
      query: query,
      errorLabel: 'Cari rapor',
      accept: hasRows,
    );
    final datedModel = CariReportModel.fromJson(dated);
    if (datedModel.accounts.isNotEmpty) return datedModel;

    final open = await _get(
      urls: _cariUrls(),
      query: const {},
      errorLabel: 'Cari rapor',
      accept: hasRows,
    );
    final openModel = CariReportModel.fromJson(open);
    if (openModel.accounts.isNotEmpty) return openModel;
    return datedModel.accounts.isNotEmpty ? datedModel : openModel;
  }

  List<String> _yearlyUrls() {
    return _reportUrls(
      envKey: 'YEARLY_SALES_REPORT',
      bammaPath: '/report/yearly-sales-report',
      extraBammaPaths: const ['/report/get-yearly-sales-report'],
      nextPaths: const [
        '/api/get-yearly-sales-report',
        '/api/yearly-sales-report',
      ],
    );
  }

  List<String> _cariUrls() {
    return _reportUrls(
      envKey: 'OFFICE_CURRENT_ACCOUNT',
      bammaPath: '/report/office-current-account',
      extraBammaPaths: const ['/report/get-office-current-account'],
      nextPaths: const [
        '/api/get-office-current-account',
        '/api/office-current-account',
      ],
    );
  }

  List<String> _reportUrls({
    required String envKey,
    required String bammaPath,
    List<String> extraBammaPaths = const [],
    List<String> nextPaths = const [],
  }) {
    final urls = <String>[];
    final seen = <String>{};

    void add(String? raw, {bool trailingSlash = true}) {
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

    add(dotenv.env[envKey]?.trim());

    final bamma = (dotenv.env['BAMMA_APP_URL']?.trim().isNotEmpty == true)
        ? dotenv.env['BAMMA_APP_URL']!.trim().replaceAll(RegExp(r'/$'), '')
        : EnvApi.zecornerBase;
    add('$bamma$bammaPath');
    add('${EnvApi.zecornerBase}$bammaPath');
    for (final extra in extraBammaPaths) {
      add('$bamma$extra');
      add('${EnvApi.zecornerBase}$extra');
    }

    final webOrigin = EnvApi.webNextApiOrigin;
    if (webOrigin != null && webOrigin.isNotEmpty) {
      for (final path in nextPaths) {
        add('$webOrigin$path');
      }
    }

    return urls;
  }

  dynamic _decodeBody(dynamic data) {
    if (data is String) {
      final text = data.trim();
      if (text.startsWith('[') || text.startsWith('{')) {
        try {
          return jsonDecode(text);
        } catch (_) {}
      }
    }
    return data;
  }

  Future<dynamic> _get({
    required List<String> urls,
    required Map<String, String> query,
    required String errorLabel,
    bool Function(dynamic data)? accept,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT');
    if (token == null || token.isEmpty) {
      throw AuthFailure(message: 'Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'X-SESSION': token,
      'X-API-KEY': dotenv.env['X_API_KEY'] ?? ApiConfig.apiKey,
      'X-APP-ID': dotenv.env['X_APP_ID'] ?? ApiConfig.appId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    int? lastStatus;
    String? lastMessage;
    dynamic lastBody;

    for (final url in urls) {
      try {
        final response = await Dio().get<dynamic>(
          url,
          queryParameters: query,
          options: Options(
            headers: headers,
            responseType: ResponseType.json,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final body = _decodeBody(response.data);
          lastBody = body;
          if (accept == null || accept(body)) return body;
          continue;
        }

        lastStatus = response.statusCode;
        final data = response.data;
        if (data is Map && data['message'] != null) {
          lastMessage = data['message'].toString();
        }
        if (_shouldTryNext(response.statusCode)) continue;

        throw NetworkFailure(
          message: lastMessage ??
              '$errorLabel alınamadı (${response.statusCode})',
          statusCode: response.statusCode,
        );
      } on DioException catch (e) {
        lastStatus = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          lastMessage = data['message'].toString();
        }
        if (_shouldTryNext(e.response?.statusCode)) continue;
        throw NetworkFailure(
          message: lastMessage ?? '$errorLabel yüklenemedi',
          statusCode: lastStatus,
        );
      }
    }

    if (lastStatus == 401) {
      throw AuthFailure(
        message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.',
      );
    }

    if (lastBody != null) return lastBody;

    throw NetworkFailure(
      message: lastMessage ??
          '$errorLabel yüklenemedi${lastStatus != null ? ' ($lastStatus)' : ''}',
      statusCode: lastStatus,
    );
  }

  bool _shouldTryNext(int? statusCode) {
    return statusCode == null ||
        statusCode == 401 ||
        statusCode == 404 ||
        statusCode == 405;
  }
}
