import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../models/rapor/broker_row_model.dart';
import '../../models/rapor/rapor_row_model.dart';
import 'package:zecorner/core/config/env_api.dart';

/// Rapor listesi API parametreleri
class RaporListParams {
  final String startDate;
  final String endDate;
  final String type; // 'advisor' | 'office'
  final String state; // SOLD, RENTED, vb.
  final int page;
  final int pageSize;

  const RaporListParams({
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.state,
    this.page = 1,
    this.pageSize = 9999,
  });
}

/// Rapor türü metninden API state değerine eşleme
String raporTuruToState(String raporTuru) {
  const map = {
    'En çok satış yapan': 'SOLD',
    'En çok kiralama yapan': 'RENTED',
    'En çok satış ve kiralama yapan': 'SOLD', // API'de iki state gönderilebilir, şimdilik SOLD
    'En çok ilanı olan': 'LISTED',
    'Ofis Ciroları': 'SOLD',
    'Danışman/Broker Ciroları': 'SOLD',
    'Tüm danışmanlar': 'SOLD',
    'Tüm brokerlar': 'SOLD',
    'Tüm ofisler': 'SOLD',
  };
  return map[raporTuru] ?? 'SOLD';
}

class RaporRepository {
  final DioClient _client = DioClient();

  Future<List<RaporRowModel>> getAdminListings(RaporListParams params) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT');
    if (token == null || token.isEmpty) {
      throw AuthFailure(message: 'Token bulunamadı. Lütfen tekrar giriş yapın.');
    }

    // .env: DASHBOARD_ADMIN_LISTINGS=/api/zecorner/dashboard/admin/listing (veya .../listings)
    // BASE_URL sadece origin olabilir (${EnvApi.origin}) veya base path'li (${EnvApi.origin}/api/zecorner)
    final pathFromEnv = dotenv.env['DASHBOARD_ADMIN_LISTINGS']?.trim();
    final baseUrlRaw = dotenv.env['BASE_URL']?.trim();
    final apiKey = dotenv.env['X_API_KEY'];
    final appId = dotenv.env['X_APP_ID'];

    final String url;
    if (pathFromEnv != null && pathFromEnv.isNotEmpty) {
      String path = pathFromEnv.startsWith('/') ? pathFromEnv : '/$pathFromEnv';
      String base = baseUrlRaw ?? '${EnvApi.origin}';
      base = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
      // BASE_URL içinde /api/ varsa sadece origin al (path'i tekrarlamayalım)
      if (base.contains('/api')) {
        base = base.substring(0, base.indexOf('/api'));
      }
      url = '$base$path';
      print('📋 Rapor API: BASE=$base, PATH=$path → URL=$url');
    } else {
      const fallbackBase = 'https://test.d1cegqpdj9080.amplifyapp.com';
      const fallbackPath = '/api/admin-dashboard/get-admin-listings/';
      final base = dotenv.env['RAPOR_API_BASE_URL'] ?? fallbackBase;
      url = base.endsWith('/') ? '$base${fallbackPath.replaceFirst('/', '')}' : '$base$fallbackPath';
    }

    // Amplify / BAMMA API genelde Authorization + X-SESSION + X-API-KEY + X-APP-ID bekliyor
    final useApiKey = apiKey ?? ApiConfig.apiKey;
    final useAppId = appId ?? ApiConfig.appId;
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'X-SESSION': token,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (useApiKey.isNotEmpty) headers['X-API-KEY'] = useApiKey;
    if (useAppId.isNotEmpty) headers['X-APP-ID'] = useAppId;

    final queryParams = <String, dynamic>{
      'start_date': params.startDate,
      'end_date': params.endDate,
      'type': params.type,
      'state': params.state,
      'page': params.page.toString(),
      'pageSize': params.pageSize.toString(),
    };

    try {
      var requestUrl = url;
      var response = await _client.dio.get<dynamic>(
        requestUrl,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
        ),
        queryParameters: queryParams,
      );

      // 404 ve path .../listing ile bitiyorsa .../listings dene
      if (response.statusCode == 404 &&
          requestUrl.endsWith('/listing') &&
          requestUrl == url) {
        requestUrl = '${url}s';
        response = await _client.dio.get<dynamic>(
          requestUrl,
          options: Options(
            headers: headers,
            responseType: ResponseType.json,
            validateStatus: (status) => status != null && status < 500,
          ),
          queryParameters: queryParams,
        );
      }

      if (response.statusCode != 200) {
        final data = response.data;
        if (data is Map && data['message'] != null) {
          throw NetworkFailure(
            message: data['message'].toString(),
            statusCode: response.statusCode,
          );
        }
        throw NetworkFailure(
          message: 'Rapor alınamadı (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) return [];
      final data = response.data;
      // Sunucu {"error":"...","state":false} döndürürse boş liste kabul et
      if (data is Map && (data['error'] != null || data['state'] == false)) {
        return [];
      }
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = (data['data'] ?? data['list'] ?? data['listings'] ?? data['results']) as List<dynamic>? ?? [];
      } else {
        return [];
      }
      return list
          .map((e) => RaporRowModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthFailure(message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.');
      }
      String message = 'Rapor yüklenemedi';
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      } else if (data != null) {
        message = data.toString();
      }
      throw NetworkFailure(message: message, statusCode: e.response?.statusCode);
    }
  }

  /// "Tüm brokerlar" seçildiğinde: önce GET_CONTACTS, 404/boşsa CONTACTS (BASE_URL) ile dene.
  /// Query: sortOrder=asc, sortColumn=contact_no, pageSize=100, page=1, types=10 (broker).
  Future<List<BrokerRowModel>> getBrokersFromContactApi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT');
    if (token == null || token.isEmpty) {
      throw AuthFailure(message: 'Token bulunamadı. Lütfen tekrar giriş yapın.');
    }

    final baseUrlRaw = dotenv.env['BASE_URL']?.trim();
    final getContactsPath = dotenv.env['GET_CONTACTS']?.trim();
    final contactsPath = dotenv.env['CONTACTS']?.trim() ?? dotenv.env['CONTACT']?.trim();
    final apiKey = dotenv.env['X_API_KEY'];
    final appId = dotenv.env['X_APP_ID'];

    String base = baseUrlRaw ?? '${EnvApi.origin}';
    base = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    if (base.contains('/api')) {
      base = base.substring(0, base.indexOf('/api'));
    }

    final useApiKey = apiKey ?? ApiConfig.apiKey;
    final useAppId = appId ?? ApiConfig.appId;
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'X-SESSION': token,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (useApiKey.isNotEmpty) headers['X-API-KEY'] = useApiKey;
    if (useAppId.isNotEmpty) headers['X-APP-ID'] = useAppId;

    const queryParams = <String, dynamic>{
      'sortOrder': 'asc',
      'sortColumn': 'contact_no',
      'pageSize': 100,
      'page': 1,
      'searchText': '',
      'types': 10,
      'type': 10,
    };

    Future<Response<dynamic>> Function(String url) doGet = (url) => _client.dio.get<dynamic>(
          url,
          queryParameters: queryParams,
          options: Options(
            headers: headers,
            responseType: ResponseType.json,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

    try {
      // 1) GET_CONTACTS varsa dene (/api/get-contacts veya Amplify path)
      String url;
      if (getContactsPath != null && getContactsPath.isNotEmpty) {
        String path = getContactsPath.startsWith('/') ? getContactsPath : '/$getContactsPath';
        if (!path.endsWith('/')) path = '$path/';
        url = '$base$path';
      } else {
        url = '$base/api/get-contacts/';
      }

      print('📋 Tüm brokerlar (1. deneme): $url');
      Response<dynamic> response = await doGet(url);

      // 2) 404 veya boş liste ise CONTACTS endpoint'ini dene (aynı BASE_URL, /api/zecorner/contacts)
      if (response.statusCode == 404 || response.statusCode == 405) {
        final fallbackPath = (contactsPath != null && contactsPath.isNotEmpty)
            ? (contactsPath.startsWith('/') ? contactsPath : '/$contactsPath')
            : '/api/zecorner/contacts';
        url = '$base$fallbackPath';
        print('📋 Tüm brokerlar (2. deneme CONTACTS): $url');
        response = await doGet(url);
      }

      if (response.statusCode != 200) {
        final data = response.data;
        if (data is Map && data['message'] != null) {
          throw NetworkFailure(
            message: data['message'].toString(),
            statusCode: response.statusCode,
          );
        }
        throw NetworkFailure(
          message: 'Broker listesi alınamadı (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) return [];
      final data = response.data;
      List<dynamic> rawList = _extractBrokerList(data);
      print('📋 Tüm brokerlar: ${rawList.length} kayıt');

      return rawList.map((e) {
        if (e is! Map<String, dynamic>) {
          return BrokerRowModel.fromJson(Map<String, dynamic>.from(e is Map ? e : <String, dynamic>{}));
        }
        return BrokerRowModel.fromJson(e);
      }).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthFailure(message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.');
      }
      String message = 'Broker listesi yüklenemedi';
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      throw NetworkFailure(message: message, statusCode: e.response?.statusCode);
    }
  }

  static List<dynamic> _extractBrokerList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is! Map) return [];
    final map = data as Map<String, dynamic>;
    final list = map['contacts'] ?? map['data'] ?? map['list'] ?? map['results'] ?? map['items'] ?? map['content'];
    if (list is List) return list;
    if (list is Map) {
      final inner = list['contacts'] ?? list['data'];
      if (inner is List) return inner;
    }
    return [];
  }
}
