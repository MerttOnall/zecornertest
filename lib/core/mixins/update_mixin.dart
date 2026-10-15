import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/network/dio_client.dart';

mixin UpdateMixin {
  DioClient get dioClient;

  Future<Either<Failure, R>> updateData<R>({
    required String endpoint,
    required Map<String, dynamic> data,
    required R Function(Map<String, dynamic>) fromJson,
    Map<String, String>? headers,
  }) async {
    try {
      print('🔄 Update Request: $endpoint');
      print('📤 Data: $data');

      final response = await dioClient.dio.post(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );

      print('✅ Update Response: ${response.statusCode}');
      print('📦 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final result = fromJson(response.data['data'] ?? response.data);
        return Right(result);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Güncelleme işlemi başarısız',
        ));
      }
    } catch (e) {
      print('❌ Update Error: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
        } else if (e.response?.statusCode == 404) {
          return Left(ServerFailure(message: 'API endpoint bulunamadı'));
        } else {
          return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
        }
      }
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }
}
