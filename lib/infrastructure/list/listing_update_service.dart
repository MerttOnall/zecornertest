import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/config/api_config.dart';
import 'package:zecorner/models/list/listing_panel_model.dart';
import 'package:zecorner/models/list/listing_update_request.dart';
import 'package:zecorner/core/config/env_api.dart';

class ListingUpdateService {
  final Dio _dio;

  ListingUpdateService() : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectionTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  /// Get listing detail by ID
  Future<Either<Failure, ListingPanelModel>> getListingDetail(String listingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');
      
      if (userJWT == null) {
        return Left(AuthFailure(message: 'Kullanıcı oturumu bulunamadı'));
      }

      // Use real API endpoint for listing detail (GET /api/zecorner/listing/{id})
      final fullUrl = "${EnvApi.origin}/api/zecorner/listing/$listingId";
      
      print('🔍 Getting listing detail: $fullUrl');
      
      final response = await _dio.get(
        fullUrl,
        options: Options(
          headers: {
            'X-SESSION': userJWT,
            'X-API-KEY': 'ed017c68-24ca-4239-ae68-0fa041391855',
            'X-APP-ID': 'zecorner',
            'X-HB-USER-AGENT': 'flutter-app',
            'X-HB-IP': '::1',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ Listing detail response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // The API returns { detail: {...} } structure as in web
        final listingData = response.data['detail'] ?? response.data;
        final listing = ListingPanelModel.fromJson(listingData);
        return Right(listing);
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Get listing detail error: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'İlan bulunamadı'));
      } else {
        return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ Get listing detail error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  /// Update listing
  Future<Either<Failure, ListingUpdateResponse>> updateListing(
    String listingId,
    ListingUpdateRequest request,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');
      
      if (userJWT == null) {
        return Left(AuthFailure(message: 'Kullanıcı oturumu bulunamadı'));
      }

      // Use real API endpoint for update (POST to /api/zecorner/listing/{id})
      final fullUrl = "${EnvApi.origin}/api/zecorner/listing/$listingId";
      
      print('📝 Updating listing: $fullUrl');
      print('📝 Request data: ${request.toJson()}');
      
      // Use POST method as in web
      final response = await _dio.post(
        fullUrl,
        data: request.toJson(),
        options: Options(
          headers: {
            'X-SESSION': userJWT,
            'X-API-KEY': 'ed017c68-24ca-4239-ae68-0fa041391855',
            'X-APP-ID': 'zecorner',
            'X-HB-USER-AGENT': 'flutter-app',
            'X-HB-IP': '::1',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ Update listing response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final updateResponse = ListingUpdateResponse.fromJson(response.data);
        return Right(updateResponse);
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Update listing error: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'İlan bulunamadı'));
      } else if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Geçersiz veri';
        return Left(ServerFailure(message: errorMessage));
      } else {
        return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ Update listing error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  /// Update listing state
  Future<Either<Failure, ListingUpdateResponse>> updateListingState(
    String listingId,
    ListingStateUpdateRequest request,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');
      
      if (userJWT == null) {
        return Left(AuthFailure(message: 'Kullanıcı oturumu bulunamadı'));
      }

      // Use real API endpoint for state update (POST to /api/zecorner/listing/{id})
      final fullUrl = "${EnvApi.origin}/api/zecorner/listing/$listingId";
      
      print('🔄 Updating listing state: $fullUrl');
      print('🔄 State: ${request.state}');
      
      // Use POST method as in web
      final response = await _dio.post(
        fullUrl,
        data: request.toJson(),
        options: Options(
          headers: {
            'X-SESSION': userJWT,
            'X-API-KEY': 'ed017c68-24ca-4239-ae68-0fa041391855',
            'X-APP-ID': 'zecorner',
            'X-HB-USER-AGENT': 'flutter-app',
            'X-HB-IP': '::1',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ Update listing state response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final updateResponse = ListingUpdateResponse.fromJson(response.data);
        return Right(updateResponse);
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Update listing state error: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'İlan bulunamadı'));
      } else if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Geçersiz durum';
        return Left(ServerFailure(message: errorMessage));
      } else {
        return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ Update listing state error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  /// Get listing states
  Future<Either<Failure, List<ListingState>>> getListingStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');
      
      if (userJWT == null) {
        return Left(AuthFailure(message: 'Kullanıcı oturumu bulunamadı'));
      }

      // Use real API endpoint for listing states (GET /api/zecorner/refListingStates)
      final fullUrl = "${EnvApi.origin}/api/zecorner/refListingStates";
      
      print('📋 Getting listing states: $fullUrl');
      
      final response = await _dio.get(
        fullUrl,
        options: Options(
          headers: {
            'X-SESSION': userJWT,
            'X-API-KEY': 'ed017c68-24ca-4239-ae68-0fa041391855',
            'X-APP-ID': 'zecorner',
            'X-HB-USER-AGENT': 'flutter-app',
            'X-HB-IP': '::1',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ Listing states response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> statesData = response.data ?? [];
        final states = statesData.map((state) => ListingState.fromJson(state)).toList();
        return Right(states);
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ Get listing states error: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else {
        return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ Get listing states error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }
}
