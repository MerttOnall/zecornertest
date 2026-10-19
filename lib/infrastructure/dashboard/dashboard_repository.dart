import 'dart:math' as math;
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';

class DashboardRepository with BaseRepository {
  static final DashboardRepository _instance = DashboardRepository._internal();
  factory DashboardRepository() => _instance;
  DashboardRepository._internal();

  final DioClient _client = DioClient();

  // Role-based endpoints - .env dosyasındaki tanımlarla uyumlu
  static const Map<String, Map<String, String>> _roleEndpoints = {
    'role_admin': {
      'totals': '/api/zecorner/dashboard/admin/totals',
      'daily-revenue': '/api/zecorner/dashboard/admin/daily_revenue',
      'sales': '/api/zecorner/dashboard/admin/sales',
      'offices': '/api/zecorner/dashboard/admin/offices',
      'advisors': '/api/zecorner/dashboard/admin/advisors',
      'top': '/api/zecorner/dashboard/admin/top',
    },
    'role_advisor': {
      'totals': '/api/zecorner/dashboard/advisor/totals',
      'daily-revenue': '/api/zecorner/dashboard/advisor/daily_revenue',
      'sales': '/api/zecorner/dashboard/advisor/sales',
      'top': '/api/zecorner/dashboard/advisor/top',
    },
    'role_office_broker': {
      'totals': '/api/zecorner/dashboard/office/totals',
      'daily-revenue': '/api/zecorner/dashboard/office/daily_revenue',
      'sales': '/api/zecorner/dashboard/office/sales',
      'offices': '/api/zecorner/dashboard/office/offices',
      'advisors': '/api/zecorner/dashboard/admin/advisors',
      'top': '/api/zecorner/dashboard/office/top',
    },
    'role_office_assistant': {
      'totals': '/api/zecorner/dashboard/office/totals',
      'daily-revenue': '/api/zecorner/dashboard/office/daily_revenue',
      'sales': '/api/zecorner/dashboard/office/sales',
      'offices': '/api/zecorner/dashboard/office/offices',
      'advisors': '/api/zecorner/dashboard/admin/advisors',
      'top': '/api/zecorner/dashboard/office/top',
    },
    'role_accountant': {
      'totals': '/api/zecorner/dashboard/admin/totals',
      'daily-revenue': '/api/zecorner/dashboard/admin/daily_revenue',
      'sales': '/api/zecorner/dashboard/admin/sales',
      'offices': '/api/zecorner/dashboard/admin/offices',
      'advisors': '/api/zecorner/dashboard/admin/advisors',
      'top': '/api/zecorner/dashboard/admin/top',
    },
  };

  /// Login `setInt`, dashboard eski `setString` — ikisini de oku.
  static int? officeIdFromPrefs(SharedPreferences pref) {
    final asInt = pref.getInt('officeId');
    if (asInt != null && asInt > 0) return asInt;
    final parsed = int.tryParse(pref.getString('officeId')?.trim() ?? '');
    if (parsed != null && parsed > 0) return parsed;
    return null;
  }

  // User context data
  Future<Map<String, dynamic>> _getUserContext() async {
    final pref = await SharedPreferences.getInstance();
    final officeId = officeIdFromPrefs(pref);
    final personNo = int.tryParse(pref.getString('userID')?.trim() ?? '');
    final scopedOffice =
        (officeId != null && personNo != null && officeId == personNo)
            ? null
            : officeId;
    return {
      'token': pref.getString('userJWT'),
      'userId': pref.getString('userID'),
      'roleId': pref.getString('roleId'),
      'roleCodes': pref.getStringList('userRoleCodes') ?? <String>[],
      'userIsAdmin': pref.getBool('userIsAdmin') == true,
      'userType': pref.getString('userType'),
      'userTypeDescription': pref.getString('userTypeDescription'),
      'officeId': scopedOffice?.toString(),
      'officeTitle': pref.getString('officeTitle'),
      'advisorId': pref.getString('advisorId'),
    };
  }

  // Get role-specific endpoint
  String _getEndpointForUserRole(String endpointType, Map<String, dynamic> userContext) {
    final userTypeDesc = userContext['userTypeDescription'] as String?;
    final userType = userContext['userType'] as String?;
    final roleId = userContext['roleId'] as String?;
    final officeId = userContext['officeId'] as String?;
    final advisorId = userContext['advisorId'] as String?;
    
    final roleCodes = (userContext['roleCodes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    String roleCode = 'role_office_broker';

    bool has(String code) =>
        roleCodes.contains(code) ||
        userTypeDesc == code ||
        userType == code ||
        roleId == code;

    if (userContext['userIsAdmin'] == true || has('role_admin')) {
      roleCode = 'role_admin';
    } else if (has('role_advisor')) {
      roleCode = 'role_advisor';
    } else if (has('role_office_broker')) {
      roleCode = 'role_office_broker';
    } else if (has('role_office_assistant')) {
      roleCode = 'role_office_assistant';
    } else if (has('role_accountant')) {
      roleCode = 'role_accountant';
    } else if (userType == null && userTypeDesc == null && roleId == null) {
      roleCode = 'role_admin';
    } else {
      roleCode = 'role_office_broker';
    }
    
    print('🔍 Role Detection:');
    print('  - UserTypeDescription: $userTypeDesc');
    print('  - UserType: $userType');
    print('  - RoleId: $roleId');
    print('  - OfficeId: $officeId');
    print('  - AdvisorId: $advisorId');
    print('  - Selected Role Code: $roleCode');
    
    final endpoints = _roleEndpoints[roleCode];
    if (endpoints == null) {
      print('  ❌ Role için endpoint bulunamadı: $roleCode');
      print('  🔄 Admin endpoint\'leri kullanılacak');
      return _roleEndpoints['role_admin']![endpointType]!;
    }
    
    final endpoint = endpoints[endpointType];
    if (endpoint == null) {
      print('  ❌ Endpoint type bulunamadı: $endpointType');
      print('  🔄 Admin endpoint\'leri kullanılacak');
      return _roleEndpoints['role_admin']![endpointType]!;
    }
    
    print('  ✅ Endpoint seçildi: $endpoint');
    return endpoint;
  }

  // Universal dashboard methods - Role-based automatic endpoint selection
  Map<String, dynamic> _withOffice(
    Map<String, dynamic> userContext, [
    Map<String, dynamic>? extra,
  ]) {
    final q = <String, dynamic>{...?extra};
    final office = userContext['officeId']?.toString().trim();
    if (office != null && office.isNotEmpty && office != '0') {
      q['office'] = office;
    }
    return q;
  }

  Future<Either<Failure, Map<String, dynamic>>> getDashboardTotals() async {
    final userContext = await _getUserContext();
    final endpoint = _getEndpointForUserRole('totals', userContext);
    
    print('📊 Dashboard Totals - User: ${userContext['userTypeDescription']}, Endpoint: $endpoint');
    return await _makeAuthenticatedRequest(
      endpoint,
      userContext,
      queryParams: _withOffice(userContext),
    );
  }

  /// Web gelir grafiği ile aynı: 2024’ten içinde bulunulan yıla, 12 ay.
  static const int chartFilterStartYear = 2024;

  static List<int> chartFilterYears() {
    final current = DateTime.now().year;
    final start = current < chartFilterStartYear ? current : chartFilterStartYear;
    return [for (var year = current; year >= start; year--) year];
  }

  static List<int> chartFilterMonths() =>
      List<int>.generate(12, (index) => index + 1);

  static Map<String, dynamic> chartFilterRange(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    String two(int value) => value.toString().padLeft(2, '0');
    return {
      'start_date':
          '${start.year}-${two(start.month)}-${two(start.day)}T00:00:00',
      'end_date': '${end.year}-${two(end.month)}-${two(end.day)}T23:59:59',
    };
  }

  Future<Either<Failure, Map<String, dynamic>>> getDashboardDailyRevenue({
    int? year,
    int? month,
  }) async {
    final userContext = await _getUserContext();
    final endpoint = _getEndpointForUserRole('daily-revenue', userContext);
    final now = DateTime.now();
    
    print('📈 Dashboard Daily Revenue - User: ${userContext['userTypeDescription']}, Endpoint: $endpoint');
    return await _makeAuthenticatedRequest(
      endpoint,
      userContext,
      queryParams: _withOffice(
        userContext,
        chartFilterRange(year ?? now.year, month ?? now.month),
      ),
    );
  }

  Future<Either<Failure, Map<String, dynamic>>> getDashboardAdvisors({int page = 1}) async {
    final userContext = await _getUserContext();
    final endpoint = _getEndpointForUserRole('advisors', userContext);
    
    print('👥 Dashboard Advisors - User: ${userContext['userTypeDescription']}, Endpoint: $endpoint, Page: $page');
    print('👥 Office ID: ${userContext['officeId']}');

    final now = DateTime.now();
    final queryParams = _withOffice(userContext, {
      'page': page.toString(),
      'pageSize': '100',
      'start_date': '${now.year}-01-01T00:00:00',
      'end_date': '${now.year}-12-31T23:59:59',
      'sortColumn': 'last_transaction',
      'sortOrder': 'desc',
    });
    
    print('👥 Query Params: $queryParams');
    
    return await _makeAuthenticatedRequest(endpoint, userContext, queryParams: queryParams);
  }

  Future<Either<Failure, Map<String, dynamic>>> getDashboardSales({int page = 1}) async {
    final userContext = await _getUserContext();
    final endpoint = _getEndpointForUserRole('sales', userContext);
    
    print('💰 Dashboard Sales - User: ${userContext['userTypeDescription']}, Endpoint: $endpoint, Page: $page');
    
    final queryParams = _withOffice(userContext, {
      'page': page.toString(),
      'pageSize': '50',
    });
    
    return await _makeAuthenticatedRequest(endpoint, userContext, queryParams: queryParams);
  }

  Future<Either<Failure, Map<String, dynamic>>> getDashboardTop() async {
    final userContext = await _getUserContext();
    final endpoint = _getEndpointForUserRole('top', userContext);
    
    print('🏆 Dashboard Top - User: ${userContext['userTypeDescription']}, Endpoint: $endpoint');
    return await _makeAuthenticatedRequest(
      endpoint,
      userContext,
      queryParams: _withOffice(userContext),
    );
  }

  // Admin specific methods - Direkt admin endpoint'lerini kullan (role detection yapmadan)
  Future<Either<Failure, Map<String, dynamic>>> getAdminTotals() async {
    final userContext = await _getUserContext();
    // Admin endpoint'ini direkt kullan - role detection yapma
    const endpoint = '/api/zecorner/dashboard/admin/totals';
    
    print('📊 Admin Totals - Endpoint: $endpoint (role detection bypass)');
    return await _makeAuthenticatedRequest(endpoint, userContext);
  }

  Future<Either<Failure, Map<String, dynamic>>> getAdminDailyRevenue({
    int? year,
    int? month,
  }) async {
    final userContext = await _getUserContext();
    // Admin endpoint'ini direkt kullan - role detection yapma
    const endpoint = '/api/zecorner/dashboard/admin/daily_revenue';
    final now = DateTime.now();
    
    print('📈 Admin Daily Revenue - Endpoint: $endpoint (role detection bypass)');
    return await _makeAuthenticatedRequest(
      endpoint,
      userContext,
      queryParams: chartFilterRange(year ?? now.year, month ?? now.month),
    );
  }

  Future<Either<Failure, Map<String, dynamic>>> getAdminSales() async {
    final userContext = await _getUserContext();
    // Admin endpoint'ini direkt kullan - role detection yapma
    const endpoint = '/api/zecorner/dashboard/admin/sales';
    
    print('💰 Admin Sales - Endpoint: $endpoint (role detection bypass)');
    return await _makeAuthenticatedRequest(endpoint, userContext);
  }

  Future<Either<Failure, Map<String, dynamic>>> getAdminTop() async {
    final userContext = await _getUserContext();
    // Admin endpoint'ini direkt kullan - role detection yapma
    const endpoint = '/api/zecorner/dashboard/admin/top';
    
    print('🏆 Admin Top - Endpoint: $endpoint (role detection bypass)');
    return await _makeAuthenticatedRequest(endpoint, userContext);
  }

  Future<Either<Failure, Map<String, dynamic>>> getAdminOffices({
    int page = 1,
    int pageSize = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userContext = await _getUserContext();
    // Admin endpoint'ini direkt kullan - role detection yapma
    const endpoint = '/api/zecorner/dashboard/admin/offices';

    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

    String fmt(DateTime d, {required bool endOfDay}) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return endOfDay
          ? '$y-$m-${day}T23:59:59'
          : '$y-$m-${day}T00:00:00';
    }

    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'start_date': fmt(start, endOfDay: false),
      'end_date': fmt(end, endOfDay: true),
      'sortColumn': 'last_transaction',
      'sortOrder': 'desc',
    };

    print('🏢 Admin Offices - Endpoint: $endpoint (role detection bypass)');
    print('🏢 Admin Offices - Query Params: $queryParams');
    return await _makeAuthenticatedRequest(endpoint, userContext, queryParams: queryParams);
  }

  Future<Either<Failure, Map<String, dynamic>>> getAdminAdvisors({int page = 1, int pageSize = 500}) async {
    final userContext = await _getUserContext();
    // Admin endpoint'ini direkt kullan - role detection yapma
    const endpoint = '/api/zecorner/dashboard/admin/advisors';
    
    // Son işlem tarihine göre sıralama; yeterli danışman çekmek için pageSize büyük (ofis kartında last_transaction fallback)
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'sortColumn': 'last_transaction',
      'sortOrder': 'desc',
    };
    
    print('👥 Admin Advisors - Endpoint: $endpoint (role detection bypass)');
    print('👥 Admin Advisors - Query Params: $queryParams');
    return await _makeAuthenticatedRequest(endpoint, userContext, queryParams: queryParams);
  }

  // Advisor specific methods - Direkt advisor endpoint'lerini kullan (role detection yapmadan)
  Future<Either<Failure, Map<String, dynamic>>> getAdvisorDailyRevenue({
    int? year,
    int? month,
  }) async {
    final userContext = await _getUserContext();
    // Advisor endpoint'ini direkt kullan - role detection yapma
    const endpoint = '/api/zecorner/dashboard/advisor/daily_revenue';
    final now = DateTime.now();
    
    print('📈 Advisor Daily Revenue - Endpoint: $endpoint (role detection bypass)');
    return await _makeAuthenticatedRequest(
      endpoint,
      userContext,
      queryParams: chartFilterRange(year ?? now.year, month ?? now.month),
    );
  }

  // Backward compatibility - Delegate to universal methods
  Future<Either<Failure, Map<String, dynamic>>> getAdvisorTotals() async => getDashboardTotals();
  Future<Either<Failure, Map<String, dynamic>>> getAdvisorSales() async => getDashboardSales();
  
  Future<Either<Failure, Map<String, dynamic>>> getOfficeTotals() async => getDashboardTotals();
  Future<Either<Failure, Map<String, dynamic>>> getOfficeDailyRevenue({
    int? year,
    int? month,
  }) async =>
      getDashboardDailyRevenue(year: year, month: month);
  Future<Either<Failure, Map<String, dynamic>>> getOfficeSales() async => getDashboardSales();
  Future<Either<Failure, Map<String, dynamic>>> getOfficeTop() async => getDashboardTop();

  // Generic authenticated request method
  Future<Either<Failure, Map<String, dynamic>>> _makeAuthenticatedRequest(
    String endpoint, 
    Map<String, dynamic> userContext, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final token = userContext['token'] as String?;
      
      // Environment değişkenlerini kontrol et
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];
      final baseUrl = dotenv.env["BASE_URL"];

      // Token kontrolü
      if (token == null || token.isEmpty) {
        print('❌ Dashboard: Token bulunamadı - Kullanıcı giriş yapmamış');
        return left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      // Environment değişkenleri kontrolü
      if (apiKey == null || appId == null || baseUrl == null) {
        print('❌ Dashboard: Environment değişkenleri eksik');
        print('  X_API_KEY: ${apiKey != null ? 'MEVCUT' : 'EKSİK'}');
        print('  X_APP_ID: ${appId != null ? 'MEVCUT' : 'EKSİK'}');
        print('  BASE_URL: ${baseUrl != null ? 'MEVCUT' : 'EKSİK'}');
        return left(ServerFailure(
          message: "Uygulama yapılandırması eksik. Lütfen yöneticiye başvurun.",
          statusCode: 500,
        ));
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token, // API'nin ihtiyaç duyduğu session header
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // User context bilgilerini logla
      print('👤 Dashboard Request - User Context:');
      print('  📋 User ID: ${userContext['userId']}');
      print('  📋 Role ID: ${userContext['roleId']}');
      print('  📋 User Type: ${userContext['userTypeDescription']}');
      print('  📋 Office ID: ${userContext['officeId']}');
      print('  📋 Advisor ID: ${userContext['advisorId']}');
      print('🎯 Dashboard Request: $baseUrl$endpoint');
      print('📋 Headers: Authorization: Bearer ${token.substring(0, math.min(20, token.length))}...');

      final fullUrl = "$baseUrl$endpoint";
      print('🌐 Full API URL: $fullUrl');
      
      final response = await _client.dio.get(
        fullUrl,
        options: Options(headers: headers),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        print('✅ Dashboard data alındı: $endpoint');
        print('📦 Response data: ${response.data}');
        final data = response.data;
        if (data is Map) return right(Map<String, dynamic>.from(data));
        if (data is List) return right(<String, dynamic>{'offices': data});
        return right(data is Map<String, dynamic> ? data : <String, dynamic>{});
      } else {
        print('❌ Dashboard response hatası: ${response.statusCode}');
        print('❌ Response data: ${response.data}');
        return left(ServerFailure(
          message: "Dashboard verisi alınamadı (${response.statusCode})",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Dashboard API DioException:');
      print('  📡 Request URL: ${e.requestOptions.uri}');
      print('  📋 Request Headers: ${e.requestOptions.headers}');
      print('  ❌ Error Message: ${e.message}');
      print('  📊 Status Code: ${e.response?.statusCode}');
      print('  📦 Response Data: ${e.response?.data}');
      print('  🔍 Response Headers: ${e.response?.headers}');
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(
          message: "Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.",
          statusCode: 401,
        ));
      }
      
      return left(NetworkFailure(
        message: "Dashboard verisi çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel dashboard hatası: $e');
      return left(UnknownFailure(message: "Dashboard hatası: $e"));
    }
  }
} 