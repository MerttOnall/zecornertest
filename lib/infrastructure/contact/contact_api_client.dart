import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ContactApiClient {
  late Dio _dio;

  ContactApiClient() {
    _dio = Dio();
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🚀 REQUEST: ${options.method} ${options.uri}');
          print('📤 Headers: ${options.headers}');
          print('📤 Data: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ RESPONSE: ${response.statusCode}');
          print('📥 Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ ERROR: ${error.type}');
          print('❌ Message: ${error.message}');
          print('❌ Response: ${error.response?.statusCode} - ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }

  Future<String?> getStoredToken() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('userJWT');
  }

  Future<String?> getStoredApiKey() async {
    // Geçici olarak hardcode - .env dosyası olmadığı için
    return "ed017c68-24ca-4239-ae68-0fa041391855";
  }

  Future<String?> getStoredAppId() async {
    // Geçici olarak hardcode - .env dosyası olmadığı için
    return "zecorner";
  }
}
