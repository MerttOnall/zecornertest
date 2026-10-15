import 'dart:math' as math;
import 'package:dartz/dartz.dart' hide Task;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/task/task_model.dart';

class TaskRepository with BaseRepository {
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  final DioClient _client = DioClient();

  /// `.env`: `TASK` veya `PTASK`; `BASE_URL` ile birleşir. Boşluklar trim edilir.
  String _taskPath() {
    final raw =
        (dotenv.env['TASK'] ?? dotenv.env['PTASK'] ?? '/api/zecorner/task')
            .trim();
    return raw.isEmpty ? '/api/zecorner/task' : raw;
  }

  /// Prefs bazen `setInt` (ofis, danışman) bazen `setString` ile yazılıyor.
  /// `getString` sayı değerde `int` → `String?` hatası fırlatır.
  String? _prefText(SharedPreferences pref, String key) {
    final value = pref.get(key);
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  // Get user context data
  Future<Map<String, dynamic>> _getUserContext() async {
    final pref = await SharedPreferences.getInstance();
    return {
      'token': _prefText(pref, 'userJWT'),
      'userId': _prefText(pref, 'userID'),
      'roleId': _prefText(pref, 'roleId'),
      'userType': _prefText(pref, 'userType'),
      'userTypeDescription': _prefText(pref, 'userTypeDescription'),
      'officeId': _prefText(pref, 'officeId'),
      'advisorId': _prefText(pref, 'advisorId'),
    };
  }

  // Get all tasks with pagination and sorting
  Future<Either<Failure, TaskResponse>> getTasks({
    int page = 0,
    int? pageSize,
    String? sort,
    String? state,
    String? search,
    /// Web ZeOnline: `type=USER_TASK` vb.
    String? type,
  }) async {
    try {
      final userContext = await _getUserContext();
      final token = userContext['token'] as String?;
      
      // Environment değişkenlerini kontrol et
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];
      final baseUrl = dotenv.env["BASE_URL"];

      // Token kontrolü
      if (token == null || token.isEmpty) {
        print('❌ Task: Token bulunamadı - Kullanıcı giriş yapmamış');
        return left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      // Environment değişkenleri kontrolü
      if (apiKey == null || appId == null || baseUrl == null) {
        print('❌ Task: Environment değişkenleri eksik');
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
        'X-SESSION': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Query parameters
      final queryParams = <String, dynamic>{
        'page': page,
      };

      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      if (pageSize != null && pageSize > 0) {
        queryParams['pageSize'] = pageSize;
      }

      if (state != null && state.isNotEmpty) {
        queryParams['state'] = state;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      // User context bilgilerini logla
      print('👤 Task Request - User Context:');
      print('  📋 User ID: ${userContext['userId']}');
      print('  📋 Role ID: ${userContext['roleId']}');
      print('  📋 User Type: ${userContext['userTypeDescription']}');
      print('  📋 Office ID: ${userContext['officeId']}');
      print('  📋 Advisor ID: ${userContext['advisorId']}');
      print('🎯 Task Request: $baseUrl${_taskPath()}');
      print('📋 Headers: Authorization: Bearer ${token.substring(0, math.min(20, token.length))}...');
      print('📋 Query Params: $queryParams');

      final fullUrl = "$baseUrl${_taskPath()}";
      print('🌐 Full API URL: $fullUrl');
      
      final response = await _client.dio.get(
        fullUrl,
        options: Options(headers: headers),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        print('✅ Task data alındı');
        print('📦 Response data: ${response.data}');
        
        final body = Task.asJsonMap(response.data);
        if (body == null) {
          return left(UnknownFailure(
            message: "Task hatası: görev listesi okunamadı",
          ));
        }
        final taskResponse = TaskResponse.fromJson(body);
        return right(taskResponse);
      } else {
        print('❌ Task response hatası: ${response.statusCode}');
        print('❌ Response data: ${response.data}');
        return left(ServerFailure(
          message: "Task verisi alınamadı (${response.statusCode})",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Task API DioException:');
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
        message: "Task verisi çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel task hatası: $e');
      return left(UnknownFailure(message: "Task hatası: $e"));
    }
  }

  // Get single task by ID
  Future<Either<Failure, Task>> getTaskById(String id) async {
    try {
      final userContext = await _getUserContext();
      final token = userContext['token'] as String?;
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];
      final baseUrl = dotenv.env["BASE_URL"];

      if (token == null || token.isEmpty) {
        return left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null || baseUrl == null) {
        return left(ServerFailure(
          message: "Uygulama yapılandırması eksik. Lütfen yöneticiye başvurun.",
          statusCode: 500,
        ));
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final fullUrl = "$baseUrl${_taskPath()}/$id";
      print('🌐 Get Task by ID URL: $fullUrl');
      
      final response = await _client.dio.get(
        fullUrl,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Task detail alındı');
        final body = Task.asJsonMap(response.data);
        if (body == null) {
          return left(UnknownFailure(message: "Task detayı okunamadı"));
        }
        final task = Task.fromJson(body);
        return right(task);
      } else {
        return left(ServerFailure(
          message: "Task detayı alınamadı (${response.statusCode})",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Get Task by ID DioException: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(
          message: "Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.",
          statusCode: 401,
        ));
      }
      
      return left(NetworkFailure(
        message: "Task detayı çekilirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Genel task detail hatası: $e');
      return left(UnknownFailure(message: "Task detail hatası: $e"));
    }
  }

  /// BAMMA: `POST /api/zecorner/task/{id}` (gövde: güncellenecek alanlar)
  Future<Either<Failure, Task>> updateTask(
    String taskId,
    Map<String, dynamic> body,
  ) async {
    try {
      final userContext = await _getUserContext();
      final token = userContext['token'] as String?;

      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];
      final baseUrl = dotenv.env["BASE_URL"];

      if (token == null || token.isEmpty) {
        return left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      if (apiKey == null || appId == null || baseUrl == null) {
        return left(ServerFailure(
          message: "Uygulama yapılandırması eksik. Lütfen yöneticiye başvurun.",
          statusCode: 500,
        ));
      }

      if (taskId.isEmpty) {
        return left(ServerFailure(message: "Geçersiz görev kimliği.", statusCode: 400));
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final fullUrl = "$baseUrl${_taskPath()}/$taskId";
      print('🌐 Update Task URL: $fullUrl');
      print('📋 Update Task body: $body');

      final response = await _client.dio.post(
        fullUrl,
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Task? parsed;
        final raw = response.data;
        final rawMap = Task.asJsonMap(raw);
        if (rawMap != null) {
          if (rawMap.containsKey('id')) {
            try {
              parsed = Task.fromJson(rawMap);
            } catch (_) {}
          }
          if (parsed == null) {
            final inner = Task.asJsonMap(rawMap['data'] ?? rawMap['task']);
            if (inner != null) {
              try {
                parsed = Task.fromJson(inner);
              } catch (_) {}
            }
          }
        }
        if (parsed != null) {
          return right(parsed);
        }
        return await getTaskById(taskId);
      }

      return left(ServerFailure(
        message: "Görev güncellenemedi (${response.statusCode})",
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      print('❌ Update Task DioException: ${e.message}');

      if (e.response?.statusCode == 401) {
        return left(AuthFailure(
          message: "Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.",
          statusCode: 401,
        ));
      }

      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;

      return left(NetworkFailure(
        message: msg ?? "Görev güncellenirken hata: ${e.message}",
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      print('❌ Update Task hatası: $e');
      return left(UnknownFailure(message: "Görev güncelleme hatası: $e"));
    }
  }
}

