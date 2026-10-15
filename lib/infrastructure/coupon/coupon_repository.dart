import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/network/dio_client.dart';
import 'package:zecorner/models/coupon/coupon_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class CouponRepository {
  final DioClient _dioClient = DioClient();

  /// Kullanıcının kullanılabilir kuponlarını getirir
  Future<Either<Failure, List<CouponModel>>> getCoupons({
    int? contactNo,
  }) async {
    try {
      // Token ve API key'leri al
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

      // Headers oluştur - X-SESSION ile
      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final queryParams = <String, dynamic>{};
      
      if (contactNo != null) {
        queryParams['contact'] = contactNo;
      }

      final baseUrl = "${EnvApi.origin}";
      final endpoint = "/api/zecorner/pay/coupons";
      final fullUrl = "$baseUrl$endpoint";

      print('🎫 Kuponlar yükleniyor...');
      print('🔑 JWT Token: ${token.substring(0, 20)}...');
      print('🌐 API Endpoint: $fullUrl');
      print('📋 Query Parameters: $queryParams');

      final response = await _dioClient.dio.get(
        fullUrl,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: headers),
      );

      print('✅ Kuponlar Response: ${response.statusCode}');
      print('📦 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final couponResponse = CouponListResponse.fromJson(response.data);
        print('🎫 ${couponResponse.coupons.length} kupon yüklendi');
        return Right(couponResponse.coupons);
      }

      return Left(ServerFailure(message: 'Kuponlar yüklenemedi'));
    } on DioException catch (e) {
      print('❌ Kupon API Hatası: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        return const Right([]); // Kupon bulunamadı
      }
      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? 'Bağlantı hatası',
      ));
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Kuponu uygular ve indirimli tutarı hesaplar
  Future<Either<Failure, Map<String, dynamic>>> applyCoupon({
    required String couponId,
    required int contactNo,
    required double originalAmount,
  }) async {
    try {
      // Token ve API key'leri al
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

      // Headers oluştur - X-SESSION ile
      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final baseUrl = "${EnvApi.origin}";
      final endpoint = "/api/zecorner/pay/apply-coupon";
      final fullUrl = "$baseUrl$endpoint";

      final response = await _dioClient.dio.post(
        fullUrl,
        data: {
          'coupon_id': couponId,
          'contact': contactNo,
          'amount': originalAmount,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return Right(response.data);
      }

      return Left(ServerFailure(message: 'Kupon uygulanamadı'));
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data?['message'] ?? 'Kupon uygulanamadı',
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// İndirim tutarını hesaplar (client-side)
  double calculateDiscount(CouponModel coupon, double originalAmount) {
    if (coupon.isFree) {
      return originalAmount; // Tamamen ücretsiz
    }
    
    if (coupon.isDiscount && coupon.discountData != null) {
      if (coupon.discountData!.discountType == 'percent') {
        // Yüzde indirim
        return originalAmount * (coupon.discountData!.amount / 100);
      } else {
        // Sabit tutar indirim
        return coupon.discountData!.amount;
      }
    }
    
    return 0;
  }
}
