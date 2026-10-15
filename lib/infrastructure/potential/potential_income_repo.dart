import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/dashboard/potential/potential_income_model.dart';
import '../dashboard/dashboard_repository.dart';

class PotentialIncomeRepository with BaseRepository {
  static final PotentialIncomeRepository _instance = PotentialIncomeRepository._internal();
  factory PotentialIncomeRepository() => _instance;
  PotentialIncomeRepository._internal();

  final DioClient _client = DioClient();

  /// Potansiyel gelir verisini getir
  Future<Either<Failure, PotentialIncomeModel>> getPotentialIncome() async {
    try {
      print('💰 Potential Income Repository - getPotentialIncome() başlatıldı');
      print('💰 Potential Income API çağrılıyor...');
      
      // Token ve office ID al (int veya string)
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final officeIdInt = DashboardRepository.officeIdFromPrefs(pref);
      final officeId = officeIdInt?.toString();
      
      print('🔍 SharedPreferences - Token: ${token != null ? 'MEVCUT' : 'YOK'}');
      print('🔍 SharedPreferences - Office ID: $officeId');
      
      if (token == null || token.isEmpty) {
        print('❌ Potential Income: Token bulunamadı');
        return left(AuthFailure(message: "Token bulunamadı. Lütfen tekrar giriş yapın."));
      }

      // Environment değişkenlerini kontrol et
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];
      final baseUrl = dotenv.env["BASE_URL"];

      if (apiKey == null || appId == null || baseUrl == null) {
        print('❌ Potential Income: Environment değişkenleri eksik');
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

      // Query parameters - token'daki office ID'yi kullan
      final queryParams = <String, dynamic>{};
      if (officeId != null && officeId.isNotEmpty) {
        queryParams['office'] = int.tryParse(officeId) ?? 0;
        print('🏢 Office ID from token: $officeId');
      }

      final endpoint = '/api/zecorner/potential-income/';
      final fullUrl = "$baseUrl$endpoint";
      
      print('🌐 Potential Income API URL: $fullUrl');
      print('📋 Query Params: $queryParams');
      print('🔑 Token: ${token.substring(0, 20)}...');
      print('🏢 Office ID from SharedPreferences: $officeId');

      final response = await _client.dio.get(
        fullUrl,
        options: Options(headers: headers),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        print('✅ Potential Income data alındı');
        print('📦 Response data: ${response.data}');
        print('📦 Response data type: ${response.data.runtimeType}');
        
        try {
          final potentialIncomeModel = PotentialIncomeModel.fromJson(response.data as Map<String, dynamic>);
          print('✅ Potential Income Model oluşturuldu: ${potentialIncomeModel.potentialIncome}');
          return right(potentialIncomeModel);
        } catch (parseError) {
          print('❌ Potential Income Model parse hatası: $parseError');
          return left(UnknownFailure(message: "Veri parse hatası: $parseError"));
        }
      } else {
        print('❌ Potential Income response hatası: ${response.statusCode}');
        print('❌ Response data: ${response.data}');
        return left(ServerFailure(
          message: "Potansiyel gelir verisi alınamadı (${response.statusCode})",
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      print('❌ Potential Income API DioException:');
      print('  - Type: ${e.type}');
      print('  - Message: ${e.message}');
      print('  - Response: ${e.response?.data}');
      print('  - Status Code: ${e.response?.statusCode}');
      
      if (e.response?.statusCode == 401) {
        return left(AuthFailure(message: "Oturum süresi dolmuş. Lütfen tekrar giriş yapın."));
      } else if (e.response?.statusCode == 403) {
        return left(AuthFailure(message: "Bu işlem için yetkiniz bulunmamaktadır."));
      } else if (e.response?.statusCode == 404) {
        return left(ServerFailure(
          message: "Potansiyel gelir verisi bulunamadı",
          statusCode: 404,
        ));
      } else if (e.response?.statusCode == 500) {
        return left(ServerFailure(
          message: "Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.",
          statusCode: 500,
        ));
      } else {
        return left(ServerFailure(
          message: "Bağlantı hatası: ${e.message}",
          statusCode: e.response?.statusCode,
        ));
      }
    } catch (e) {
      print('❌ Potential Income genel hata: $e');
      return left(UnknownFailure(message: "Beklenmeyen hata: $e"));
    }
  }
}
