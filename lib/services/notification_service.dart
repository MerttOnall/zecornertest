import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/error/failures.dart';
import '../core/network/dio_client.dart';
import '../infrastructure/notification/notification_repository.dart';
import '../models/notification/p_notification_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final NotificationRepository _repository = NotificationRepository();

  /// Kullanıcının bildirimlerini getir
  Future<Either<Failure, NotificationResponse>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    return await _repository.getNotifications(page: page, limit: limit);
  }

  /// Okunmamış bildirim sayısını getir
  Future<Either<Failure, int>> getUnreadNotificationCount() async {
    return await _repository.getUnreadNotificationCount();
  }

  /// Bildirimi okundu olarak işaretle
  Future<Either<Failure, bool>> markAsRead(int notificationId) async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/notifications/$notificationId/read';

      // Token'ı al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');

      final response = await DioClient().dio.put(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-API-Version': '1.0',
            'X-Client': 'flutter-app',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Bildirim okundu olarak işaretlenemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Bildirim bulunamadı', statusCode: 404));
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        return Left(ServerFailure(
          message: 'Sunucu hatası',
          statusCode: e.response!.statusCode,
        ));
      } else {
        return Left(NetworkFailure(message: 'Ağ bağlantı hatası: ${e.message}'));
      }
    } catch (e) {
      return Left(UnknownFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<Either<Failure, bool>> markAllAsRead() async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/notifications/mark-all-read';

      // Token'ı al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');

      final response = await DioClient().dio.put(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-API-Version': '1.0',
            'X-Client': 'flutter-app',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Tüm bildirimler okundu olarak işaretlenemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Bildirimler bulunamadı', statusCode: 404));
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        return Left(ServerFailure(
          message: 'Sunucu hatası',
          statusCode: e.response!.statusCode,
        ));
      } else {
        return Left(NetworkFailure(message: 'Ağ bağlantı hatası: ${e.message}'));
      }
    } catch (e) {
      return Left(UnknownFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  /// Bildirim sil
  Future<Either<Failure, bool>> deleteNotification(int notificationId) async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/notifications/$notificationId';

      // Token'ı al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');

      final response = await DioClient().dio.delete(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-API-Version': '1.0',
            'X-Client': 'flutter-app',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Bildirim silinemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Bildirim bulunamadı', statusCode: 404));
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        return Left(ServerFailure(
          message: 'Sunucu hatası',
          statusCode: e.response!.statusCode,
        ));
      } else {
        return Left(NetworkFailure(message: 'Ağ bağlantı hatası: ${e.message}'));
      }
    } catch (e) {
      return Left(UnknownFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  /// Bildirim türüne göre icon döndür
  static String getNotificationIcon(String action) {
    switch (action) {
      case 'SALE_FORM':
        return '📋';
      case 'RENT_FORM':
        return '🏠';
      case 'CONTACT_CREATED':
        return '👤';
      case 'redirect_to_link':
        return '🔗';
      default:
        return '📢';
    }
  }

  /// Bildirim türüne göre renk döndür
  static int getNotificationColor(String action) {
    switch (action) {
      case 'SALE_FORM':
        return 0xFF4CAF50; // Yeşil
      case 'RENT_FORM':
        return 0xFF2196F3; // Mavi
      case 'CONTACT_CREATED':
        return 0xFFE53935; // Kırmızı
      case 'redirect_to_link':
        return 0xFF9C27B0; // Mor
      default:
        return 0xFF607D8B; // Gri
    }
  }

  /// Tarih formatını düzenle
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Az önce';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} dakika önce';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} saat önce';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Bilinmeyen tarih';
    }
  }
}
