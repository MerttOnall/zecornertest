import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/presentation/screens/franchise_map/franchise_map_data.dart';

class VisitLoadResult {
  final List<FieldVisit> visits;
  final String? error;

  const VisitLoadResult({required this.visits, this.error});
}

/// Franchise haritası, uygulamanın [BASE_URL] değerine dokunmadan
/// o ortamın yeni sunucusuna gider.
///
/// `https://bamma.zecorner.com` → `http://18.195.239.53/api/zecorner`
/// `http://3.77.159.125` → `http://63.179.167.252/api/zecorner`
class VisitRepository {
  static const _liveBase = 'http://18.195.239.53/api/zecorner';
  static const _testBase = 'http://63.179.167.252/api/zecorner';

  String get _base {
    final host = Uri.tryParse(EnvApi.origin)?.host.toLowerCase() ?? '';
    if (host == '3.77.159.125') return _testBase;
    return _liveBase;
  }
  VisitRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
                followRedirects: true,
                maxRedirects: 5,
                responseType: ResponseType.json,
                validateStatus: (status) => status != null && status < 500,
              ),
            );

  final Dio _dio;
  final Map<int, _CityPlaces> _districtCache = {};

  Future<VisitLoadResult> fetchVisits({int? cityCode}) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return const VisitLoadResult(
          visits: [],
          error: 'Oturum bulunamadı. Tekrar giriş yapın.',
        );
      }

      final query = <String, dynamic>{};
      if (cityCode != null) query['city_code'] = cityCode;

      final summaryFuture = _firstOk(
        '/api/visits/summary',
        headers,
        cityCode == null ? const {} : {'city_code': cityCode},
      );
      final districtsFuture = cityCode == null
          ? Future<_CityPlaces?>.value(null)
          : _loadDistricts(cityCode, headers);
      final visitsFuture = _firstList('/api/visits', headers, query);

      final rowsResult = await visitsFuture;
      final places = await districtsFuture;
      await summaryFuture;
      final rows = rowsResult.rows;
      if (rows == null) {
        return VisitLoadResult(
          visits: const [],
          error: rowsResult.error ?? 'Ziyaretler yüklenemedi.',
        );
      }
      final visits = rows.map((row) {
        final city = _asInt(row['city_code']);
        final district = _asInt(row['district_code']);
        final quarter = _asInt(row['quarter_code']);
        final cityPlaces = city == cityCode ? places : null;
        return FieldVisit.fromApi(
          row,
          ilName: _cityName(city),
          ilceName: cityPlaces?.districtName(district),
          mahalleName: cityPlaces?.quarterName(district, quarter),
        );
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return VisitLoadResult(visits: visits);
    } catch (error) {
      final data = error is DioException ? error.response?.data : null;
      return VisitLoadResult(
        visits: const [],
        error: _message(data) ?? 'Ziyaretler yüklenemedi.',
      );
    }
  }

  Future<VisitLoadResult> createVisit({
    required double lat,
    required double lon,
    required int score,
    required int cityCode,
    required String officeName,
    required String metPerson,
    required List<String> notes,
    int? districtCode,
    int? quarterCode,
    String? districtName,
    String? quarterName,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return const VisitLoadResult(
          visits: [],
          error: 'Oturum bulunamadı. Tekrar giriş yapın.',
        );
      }

      final places = await _loadDistricts(cityCode, headers);
      final matched = places?.codesFor(districtName, quarterName);
      final district = districtCode ?? matched?.districtCode;
      final quarter = quarterCode ?? matched?.quarterCode;
      final body = <String, dynamic>{
        'lat': lat,
        'lon': lon,
        'score': score,
        'city_code': cityCode,
        'office_name': officeName.trim().length > 512
            ? officeName.trim().substring(0, 512)
            : officeName.trim(),
        'met_person': metPerson.trim().length > 255
            ? metPerson.trim().substring(0, 255)
            : metPerson.trim(),
        'notes': notes.map((note) => note.trim()).where((note) => note.isNotEmpty).toList(),
        if (district != null) 'district_code': district,
        if (quarter != null) 'quarter_code': quarter,
      };

      final response = await _send('POST', '$_base/visits/', headers, body);
      final status = response?.statusCode ?? 0;
      if (response == null || status < 200 || status >= 300) {
        return VisitLoadResult(
          visits: const [],
          error: _message(response?.data) ?? 'Ziyaret kaydedilemedi.',
        );
      }
      final data = response.data;
      final row = data is Map<String, dynamic>
          ? data
          : data is Map
              ? Map<String, dynamic>.from(data)
              : null;
      if (row == null) {
        return const VisitLoadResult(
          visits: [],
          error: 'Ziyaret kaydedilemedi.',
        );
      }
      await _firstOk('/api/visits/summary', headers, {'city_code': cityCode});
      final visit = FieldVisit.fromApi(
        row,
        ilName: _cityName(cityCode),
        ilceName: places?.districtName(_asInt(row['district_code']) ?? district),
        mahalleName: places?.quarterName(
          _asInt(row['district_code']) ?? district,
          _asInt(row['quarter_code']) ?? quarter,
        ),
      );
      return VisitLoadResult(visits: [visit]);
    } catch (error) {
      final data = error is DioException ? error.response?.data : null;
      return VisitLoadResult(
        visits: const [],
        error: _message(data) ?? 'Ziyaret kaydedilemedi.',
      );
    }
  }

  Future<VisitLoadResult> updateVisit({
    required FieldVisit current,
    required String officeName,
    required String metPerson,
    required int score,
    required List<String> notes,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return const VisitLoadResult(
          visits: [],
          error: 'Oturum bulunamadı. Tekrar giriş yapın.',
        );
      }

      final cityCode = int.tryParse(current.provinceId);
      final districtCode = int.tryParse(current.districtId);
      final quarterCode = int.tryParse(current.neighborhoodId);
      final body = <String, dynamic>{
        'lat': current.lat,
        'lon': current.lng,
        'score': score,
        if (cityCode != null) 'city_code': cityCode,
        'office_name': officeName.trim().length > 512
            ? officeName.trim().substring(0, 512)
            : officeName.trim(),
        'met_person': metPerson.trim().length > 255
            ? metPerson.trim().substring(0, 255)
            : metPerson.trim(),
        'notes': notes
            .map((note) => note.trim())
            .where((note) => note.isNotEmpty)
            .toList(),
        if (districtCode != null) 'district_code': districtCode,
        if (quarterCode != null) 'quarter_code': quarterCode,
      };

      final urls = [
        '$_base/visits/${current.id}/',
        '$_base/visits/${current.id}',
      ];
      Response<dynamic>? response;
      for (final url in urls) {
        response = await _send('PATCH', url, headers, body);
        if ((response?.statusCode ?? 0) >= 200 &&
            (response?.statusCode ?? 0) < 300) {
          break;
        }
        response = await _send('PUT', url, headers, body);
        if ((response?.statusCode ?? 0) >= 200 &&
            (response?.statusCode ?? 0) < 300) {
          break;
        }
      }

      final status = response?.statusCode ?? 0;
      if (response == null || status < 200 || status >= 300) {
        return VisitLoadResult(
          visits: const [],
          error: _message(response?.data) ?? 'Ziyaret güncellenemedi.',
        );
      }
      final data = response.data;
      final row = data is Map<String, dynamic>
          ? data
          : data is Map
              ? Map<String, dynamic>.from(data)
              : null;
      final parsed = row == null
          ? null
          : FieldVisit.fromApi(
              row,
              ilName: current.ilName ?? _cityName(cityCode),
              ilceName: current.ilceName,
              mahalleName: current.mahalleName,
            );
      final visit = parsed == null || parsed.officeName.trim().isEmpty
          ? current.copyWith(
              officeName: officeName.trim(),
              personName: metPerson.trim(),
              score: score,
              notes: notes,
            )
          : parsed;
      return VisitLoadResult(visits: [visit]);
    } catch (error) {
      final data = error is DioException ? error.response?.data : null;
      return VisitLoadResult(
        visits: const [],
        error: _message(data) ?? 'Ziyaret güncellenemedi.',
      );
    }
  }

  Future<Response<dynamic>?> _send(
    String method,
    String url,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    try {
      debugPrint('Visit $method $url');
      return await _dio.request<dynamic>(
        url,
        data: body,
        options: Options(
          method: method,
          headers: headers,
          responseType: ResponseType.json,
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(seconds: 20),
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
    } on DioException catch (error) {
      debugPrint('Visit $method failed $url ${error.message}');
      return error.response;
    }
  }

  Future<Map<String, String>?> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT') ?? prefs.getString('auth_token');
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

  List<String> _endpoint(String path) {
    final resource = path.replaceFirst(RegExp(r'^/api'), '');
    return ['$_base$resource'];
  }

  Future<void> _firstOk(
    String path,
    Map<String, String> headers,
    Map<String, dynamic> query,
  ) async {
    for (final url in _endpoint(path)) {
      final next = await _get(url, headers, query);
      final status = next?.statusCode ?? 0;
      if (status >= 200 && status < 300) return;
    }
  }

  Future<({List<Map<String, dynamic>>? rows, String? error})> _firstList(
    String path,
    Map<String, String> headers,
    Map<String, dynamic> query,
  ) async {
    String? lastError;
    for (final url in _endpoint(path)) {
      final next = await _get(url, headers, query);
      if (next == null) continue;
      final status = next.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final list = _asList(next.data);
        if (list != null) return (rows: list, error: null);
      } else {
        lastError = _message(next.data) ?? lastError;
      }
    }
    return (rows: null, error: lastError);
  }

  Future<Response<dynamic>?> _get(
    String url,
    Map<String, String> headers,
    Map<String, dynamic> query,
  ) async {
    try {
      debugPrint('Visit GET $url');
      return await _dio.get<dynamic>(
        url,
        queryParameters: query.isEmpty ? null : query,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(seconds: 12),
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
          extra: const {'skipSessionExpire': true},
        ),
      );
    } on DioException catch (error) {
      debugPrint('Visit GET failed $url ${error.message}');
      return error.response;
    }
  }

  Future<_CityPlaces?> _loadDistricts(
    int cityCode,
    Map<String, String> headers,
  ) async {
    final cached = _districtCache[cityCode];
    if (cached != null) return cached;
    final urls = <(String, Map<String, dynamic>)>[
      ('$_base/get-districts', {'code': cityCode}),
      ('$_base/refProvince/$cityCode', {'type': 'place'}),
    ];
    for (final item in urls) {
      final response = await _get(item.$1, headers, item.$2);
      final list = response == null ? null : _asList(response.data);
      if ((response?.statusCode ?? 0) >= 200 &&
          (response?.statusCode ?? 0) < 300 &&
          list != null) {
        final places = _CityPlaces.parse(list);
        _districtCache[cityCode] = places;
        return places;
      }
    }
    return null;
  }

  String? _cityName(int? cityCode) {
    if (cityCode == null) return null;
    final id = cityCode.toString().padLeft(2, '0');
    return FranchiseMapCatalog.find(id, FranchiseMapCatalog.provinces)?.name;
  }

  String? _message(dynamic data) {
    if (data is Map) {
      final message = data['message'] ?? data['MESSAGE'];
      if (message is String && message.trim().isNotEmpty) return message;
      final details = data['details'];
      if (details is List && details.isNotEmpty && details.first is Map) {
        final detail = details.first['message'];
        if (detail != null) return detail.toString();
      }
    }
    return null;
  }
}

List<Map<String, dynamic>>? _asList(dynamic data) {
  var raw = data;
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      raw = jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
  if (raw is Map) {
    raw = raw['visits'] ?? raw['data'] ?? raw['items'] ?? raw['rows'] ?? raw['result'];
  }
  if (raw is! List) return null;
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

class _CityPlaces {
  _CityPlaces(this._districts);

  final Map<int, _DistrictPlace> _districts;

  factory _CityPlaces.parse(List<Map<String, dynamic>> rows) {
    final districts = <int, _DistrictPlace>{};
    for (final row in rows) {
      final code = _asInt(row['code']);
      final name = row['name']?.toString();
      if (code == null || name == null || name.isEmpty) continue;
      final quarters = <int, String>{};
      _collectQuarters(row['quarters'], quarters);
      final villages = row['villages'];
      if (villages is List) {
        for (final village in villages) {
          if (village is Map) {
            _collectQuarters(village['quarters'], quarters);
          }
        }
      }
      districts[code] = _DistrictPlace(name, quarters);
    }
    return _CityPlaces(districts);
  }

  String? districtName(int? code) {
    if (code == null) return null;
    return _districts[code]?.name;
  }

  String? quarterName(int? districtCode, int? quarterCode) {
    if (districtCode == null || quarterCode == null) return null;
    return _districts[districtCode]?.quarters[quarterCode];
  }

  ({int? districtCode, int? quarterCode}) codesFor(
    String? districtName,
    String? quarterName,
  ) {
    int? districtCode;
    final wantedDistrict = _placeKey(districtName);
    if (wantedDistrict.isNotEmpty) {
      for (final entry in _districts.entries) {
        if (_placeKey(entry.value.name) == wantedDistrict) {
          districtCode = entry.key;
          break;
        }
      }
    }
    int? quarterCode;
    final wantedQuarter = _placeKey(quarterName);
    if (wantedQuarter.isNotEmpty) {
      for (final entry in _districts.entries) {
        if (districtCode != null && entry.key != districtCode) continue;
        for (final quarter in entry.value.quarters.entries) {
          if (_placeKey(quarter.value) == wantedQuarter) {
            quarterCode = quarter.key;
            districtCode ??= entry.key;
            break;
          }
        }
        if (quarterCode != null) break;
      }
    }
    return (districtCode: districtCode, quarterCode: quarterCode);
  }
}

String _placeKey(String? value) {
  if (value == null) return '';
  var text = value.trim().toLowerCase();
  text = text
      .replaceAll('ı', 'i')
      .replaceAll('i̇', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
  text = text.replaceAll(RegExp(r'\b(mh|mah|mahallesi)\b'), '');
  return text.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _DistrictPlace {
  _DistrictPlace(this.name, this.quarters);

  final String name;
  final Map<int, String> quarters;
}

void _collectQuarters(dynamic raw, Map<int, String> into) {
  if (raw is! List) return;
  for (final item in raw) {
    if (item is! Map) continue;
    final code = _asInt(item['code']);
    final name = item['name']?.toString();
    if (code != null && name != null && name.isNotEmpty) {
      into[code] = name;
    }
  }
}
