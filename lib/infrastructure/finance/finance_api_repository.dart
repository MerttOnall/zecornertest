import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/mixins/update_mixin.dart';
import '../../models/finance/finance_record_model.dart';
import '../../models/finance/finance_type_model.dart';
import 'package:zecorner/core/config/env_api.dart';

/// BAMMA tam kayıt dönerse `result` veya kök obje; Next başarıda `result` = `{ code, message }` olabilir.
Map<String, dynamic>? _parseAddExpenseResponse(dynamic data) {
  if (data is! Map) return null;
  final map = Map<String, dynamic>.from(data);
  final r = map['result'];
  if (r is Map) {
    final rm = Map<String, dynamic>.from(r);
    if (rm['id'] != null && rm['type'] is String) {
      return rm;
    }
    return null;
  }
  if (map['id'] != null && map['type'] is String) {
    return map;
  }
  return null;
}

/// BAMMA/Next bazen HTTP 200 ile `{ error, state: false }` döner (route yok / iş kuralı).
String? _addExpenseErrorMessage(dynamic data) {
  if (data is! Map) return null;
  final map = Map<String, dynamic>.from(data);
  if (map['state'] == false) {
    final err = map['error'];
    if (err != null) return err.toString();
  }
  if (map['error'] != null && map['result'] == null) {
    return map['error'].toString();
  }
  return null;
}

/// BAMMA düz gövde: `{ "code": "EXPENSE_ADDED", "message": "..." }`
/// Next: `{ "result": { "code": "EXPENSE_ADDED", "message": "..." } }`
bool _isAddExpenseSuccessEnvelope(dynamic data) {
  if (data is! Map) return false;
  final map = Map<String, dynamic>.from(data);
  final rootCode = map['code']?.toString().toUpperCase();
  if (rootCode == 'EXPENSE_ADDED') return true;
  final r = map['result'];
  if (r is Map) {
    final code = r['code']?.toString().toUpperCase();
    return code == 'EXPENSE_ADDED';
  }
  return false;
}

class FinanceApiRepository with UpdateMixin {
  static final FinanceApiRepository _instance = FinanceApiRepository._internal();
  factory FinanceApiRepository() => _instance;
  FinanceApiRepository._internal();

  final DioClient _client = DioClient();
  
  @override
  DioClient get dioClient => _client;

  // GET - Finans türlerini getir
  Future<Either<Failure, List<FinanceType>>> getFinanceTypes() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final endpoint = dotenv.env["FINANCETYPES"] ?? "/api/zecorner/refFinanceTypes";
      final baseUrl = "${EnvApi.origin}";
      final fullUrl = "$baseUrl$endpoint";

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');

      final response = await dioClient.dio.get(
        fullUrl,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        final financeTypes = data
            .map((item) => FinanceType.fromJson(item as Map<String, dynamic>))
            .toList();
        return Right(financeTypes);
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Sunucu hatası oluştu',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz yok."));
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        return Left(NetworkFailure(message: "Bağlantı zaman aşımına uğradı."));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(NetworkFailure(message: "İnternet bağlantınızı kontrol edin."));
      }

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  // GET - Finansal kayıtları getir
  Future<Either<Failure, FinanceResponse>> getFinanceRecords({
    int page = 1,
    int pageSize = 20,
    @Deprecated('Use pageSize') int? limit,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-SESSION': token,
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      };

      final size = limit ?? pageSize;
      // Web Next → BAMMA `/finance/records` query (page + pageSize).
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': size,
        'limit': size,
      };

      if (type != null && type.isNotEmpty && type != 'Tümü') {
        if (type == 'Gelir') {
          queryParams['is_expense'] = false;
        } else if (type == 'Gider') {
          queryParams['is_expense'] = true;
        } else {
          queryParams['type'] = type;
        }
      }

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final endpoint =
          (dotenv.env["FINANCERECORDS"] ?? "/api/zecorner/finance/records")
              .trim();
      final fullUrl = "${EnvApi.origin}$endpoint";

      final response = await dioClient.dio.get(
        fullUrl,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return Right(FinanceResponse.fromJson(response.data));
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Sunucu hatası oluştu',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz yok."));
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Left(NetworkFailure(message: "Bağlantı zaman aşımına uğradı."));
      } else if (e.type == DioExceptionType.connectionError) {
        return Left(NetworkFailure(message: "İnternet bağlantınızı kontrol edin."));
      }

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  // POST - Gider ekle
  Future<Either<Failure, FinanceRecord>> addExpense({
    required String description,
    required double amount,
    required String type,
  }) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      // Postman / BAMMA: POST {origin}/api/zecorner/finance/add-expense + X-SESSION (+ X-HB-* DioClient’ta).
      // Eski Next route: tam URL `.../api/finance-add-expense/` → yalnız Bearer (X-SESSION yok).
      final configured = dotenv.env['FINANCE_ADD_EXPENSE']?.trim() ?? '';
      late final String fullUrl;
      late final bool useXSession;

      final lowerCfg = configured.toLowerCase();
      if (lowerCfg.startsWith('http://') || lowerCfg.startsWith('https://')) {
        fullUrl = configured;
        useXSession = !lowerCfg.contains('finance-add-expense');
      } else {
        final path = configured.isEmpty
            ? '/api/zecorner/finance/add-expense'
            : (configured.startsWith('/') ? configured : '/$configured');
        fullUrl = '${EnvApi.origin}$path';
        useXSession = true;
      }

      final headers = <String, String>{
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (useXSession) 'X-SESSION': token,
      };

      final data = {
        'description': description,
        'amount': amount,
        'type': type,
        'is_expense': true,
      };

      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');
      print('📋 Data: $data');

      final response = await dioClient.dio.post(
        fullUrl,
        data: data,
        options: Options(headers: headers),
      );

      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final errMsg = _addExpenseErrorMessage(response.data);
        if (errMsg != null) {
          return Left(ServerFailure(message: errMsg));
        }
        final payload = _parseAddExpenseResponse(response.data);
        if (payload != null) {
          return Right(FinanceRecord.fromJson(payload));
        }
        if (_isAddExpenseSuccessEnvelope(response.data)) {
          return Right(
            FinanceRecord.stubAfterNextAddExpense(
              type: type,
              description: description,
              amount: amount,
            ),
          );
        }
        return Left(ServerFailure(message: 'Gider yanıtı okunamadı'));
      } else {
        return Left(ServerFailure(
          message: response.data?['message'] ?? 'Sunucu hatası oluştu',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ ERROR Message: ${e.message}');
      print('❌ ERROR Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        final d = e.response?.data;
        if (d is Map && d['DESCRIPTION'] != null) {
          return Left(AuthFailure(message: d['DESCRIPTION'].toString()));
        }
        return Left(AuthFailure(message: "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: "Bu işlem için yetkiniz yok."));
      }

      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen bir hata oluştu',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Unexpected ERROR: $e');
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }
}

