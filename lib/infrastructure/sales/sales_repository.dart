import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/config/api_config.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/dashboard/admin /admin_sales_model.dart';

class SalesQueryParams {
  final int page;
  final int pageSize;
  final DateTime startDate;
  final DateTime endDate;
  final String sortOrder;
  final String sortColumn;
  final String? status;
  final String? search;
  final int? officeContactNo;
  final int? userContactNo;

  const SalesQueryParams({
    this.page = 1,
    this.pageSize = 500,
    required this.startDate,
    required this.endDate,
    this.sortOrder = 'desc',
    this.sortColumn = 'date',
    this.status,
    this.search,
    this.officeContactNo,
    this.userContactNo,
  });

  Map<String, String> toQueryMap() {
    final query = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'sortOrder': sortOrder,
      'sortColumn': sortColumn,
    };
    if (status != null && status!.isNotEmpty) query['status'] = status!;
    if (search != null && search!.trim().isNotEmpty) {
      query['search'] = search!.trim();
    }
    if (officeContactNo != null) {
      query['office'] = officeContactNo.toString();
    }
    if (userContactNo != null) {
      query['contact'] = userContactNo.toString();
    }
    return query;
  }
}

class SalesRepository {
  static const Map<String, String> _roleSalesPaths = {
    'role_advisor': '/api/zecorner/dashboard/advisor/sales',
    'role_office_broker': '/api/zecorner/dashboard/office/sales',
    'role_office_assistant': '/api/zecorner/dashboard/office/sales',
    'role_admin': '/api/zecorner/dashboard/admin/sales',
    'role_accountant': '/api/zecorner/dashboard/admin/sales',
  };

  static const Map<String, String> _roleSalesEnvKeys = {
    'role_advisor': 'DASHBOARD_ADVISOR_SALES',
    'role_office_broker': 'DASHBOARD_OFFICE_SALES',
    'role_office_assistant': 'DASHBOARD_OFFICE_SALES',
    'role_admin': 'DASHBOARD_ADMIN_SALES',
    'role_accountant': 'DASHBOARD_ADMIN_SALES',
  };

  Future<AdminSalesModel> getAllSales({
    required SalesQueryParams params,
    String roleCode = 'role_admin',
    bool roleEndpointOnly = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT');
    if (token == null || token.isEmpty) {
      throw AuthFailure(message: 'Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }

    final apiKey = dotenv.env['X_API_KEY'] ?? ApiConfig.apiKey;
    final appId = dotenv.env['X_APP_ID'] ?? ApiConfig.appId;

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'X-API-KEY': apiKey,
      'X-APP-ID': appId,
      'X-SESSION': token,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final urls = roleEndpointOnly
        ? [_dashboardSalesUrl(roleCode)]
        : _resolveSalesUrls(roleCode);
    int? lastStatus;
    String? lastMessage;

    for (final url in urls) {
      try {
        final response = await Dio().get<dynamic>(
          url,
          queryParameters: params.toQueryMap(),
          options: Options(
            headers: headers,
            responseType: ResponseType.json,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          return AdminSalesModel.fromJson(response.data);
        }

        lastStatus = response.statusCode;
        final data = response.data;
        if (data is Map && data['message'] != null) {
          lastMessage = data['message'].toString();
        }

        // Sonraki URL'yi dene (Amplify 401, route yok vb.)
        if (_shouldTryNextUrl(response.statusCode)) {
          continue;
        }

        throw NetworkFailure(
          message: lastMessage ?? 'Satış verileri yüklenemedi (${response.statusCode})',
          statusCode: response.statusCode,
        );
      } on DioException catch (e) {
        lastStatus = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          lastMessage = data['message'].toString();
        }
        if (_shouldTryNextUrl(e.response?.statusCode)) {
          continue;
        }
        rethrow;
      }
    }

    if (lastStatus == 401) {
      throw AuthFailure(message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.');
    }

    throw NetworkFailure(
      message: lastMessage ?? 'Satış verileri yüklenemedi${lastStatus != null ? ' ($lastStatus)' : ''}',
      statusCode: lastStatus,
    );
  }

  bool _shouldTryNextUrl(int? statusCode) {
    return statusCode == null ||
        statusCode == 401 ||
        statusCode == 404 ||
        statusCode == 405;
  }

  List<String> _resolveSalesUrls(String roleCode) {
    final urls = <String>[];

    // Web Next `/allSales` → BAMMA `{BAMMA_APP_URL}/allSales`
    final bamma = (dotenv.env['BAMMA_APP_URL']?.trim().isNotEmpty == true)
        ? dotenv.env['BAMMA_APP_URL']!.trim().replaceAll(RegExp(r'/$'), '')
        : EnvApi.zecornerBase;
    urls.add('$bamma/allSales/');
    urls.add('${EnvApi.zecornerBase}/allSales/');

    // Rol bazlı dashboard yedek
    urls.add(_dashboardSalesUrl(roleCode));
    if (roleCode != 'role_admin' && roleCode != 'role_accountant') {
      urls.add(_dashboardSalesUrl('role_admin'));
    }

    // 3) Next.js get-all-sales — web cookie oturumu gerektirebilir, son yedek
    final explicit = dotenv.env['GET_ALL_SALES']?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      if (explicit.startsWith('http')) {
        urls.add(EnvApi.amplifyStyleTrailingSlash(explicit)!);
      } else {
        final path = explicit.startsWith('/') ? explicit : '/$explicit';
        final trailingPath = path.endsWith('/') ? path : '$path/';
        if (!path.contains('/api/zecorner')) {
          final webOrigin = EnvApi.webNextApiOrigin;
          if (webOrigin != null && webOrigin.isNotEmpty) {
            urls.add('$webOrigin$trailingPath');
          }
        }
        urls.add('${EnvApi.origin}$trailingPath');
      }
    }

    return urls.toSet().toList();
  }

  String _dashboardSalesUrl(String roleCode) {
    final envKey = _roleSalesEnvKeys[roleCode] ?? 'DASHBOARD_ADMIN_SALES';
    final fromEnv = dotenv.env[envKey]?.trim();
    final path = (fromEnv != null && fromEnv.isNotEmpty)
        ? fromEnv
        : (_roleSalesPaths[roleCode] ?? _roleSalesPaths['role_admin']!);

    final normalized = path.startsWith('/') ? path : '/$path';
    return '${EnvApi.origin}${normalized.endsWith('/') ? normalized : '$normalized/'}';
  }
}
