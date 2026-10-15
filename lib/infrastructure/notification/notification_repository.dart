import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/notification/p_notification_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class NotificationRepository with BaseRepository {
  static final NotificationRepository _instance = NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal();

  final DioClient _client = DioClient();
  static const String _localReadIdsKey = 'notification_read_ids';

  Future<Set<int>> _getLocalReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_localReadIdsKey) ?? <String>[];
    return ids.map(int.parse).toSet();
  }

  Future<void> _persistLocalReadId(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_localReadIdsKey) ?? <String>[];
    final key = '$notificationId';
    if (!ids.contains(key)) {
      ids.add(key);
      await prefs.setStringList(_localReadIdsKey, ids);
    }
  }

  Future<List<PNotificationModel>> _mergeLocalReadState(
    List<PNotificationModel> notifications,
  ) async {
    final localReadIds = await _getLocalReadIds();
    if (localReadIds.isEmpty) return notifications;

    return notifications
        .map(
          (notification) => notification.isRead || !localReadIds.contains(notification.id)
              ? notification
              : notification.copyWith(read: true),
        )
        .toList();
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT');
    final apiKey = dotenv.env['X_API_KEY'];
    final appId = dotenv.env['X_APP_ID'];

    if (token == null) {
      throw AuthFailure(message: 'Token bulunamadı. Lütfen tekrar giriş yapın.');
    }
    if (apiKey == null || appId == null) {
      throw AuthFailure(message: 'API anahtarları bulunamadı.');
    }

    return {
      'X-SESSION': token,
      'X-API-KEY': apiKey,
      'X-APP-ID': appId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Kullanıcının bildirimlerini getir
  Future<Either<Failure, NotificationResponse>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/notifications';

      // Token'ı al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
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

      print('🚀 REQUEST: GET $url');
      print('📤 Headers: $headers');
      print('📤 Data: null');
      
      final response = await _client.dio.get(
        url,
        queryParameters: {
          'page': page,
          'pageSize': limit,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final notificationResponse = NotificationResponse.fromJson(response.data);
        final mergedNotifications =
            await _mergeLocalReadState(notificationResponse.notifications);
        return Right(
          NotificationResponse(
            notifications: mergedNotifications,
            totalCount: notificationResponse.totalCount,
            totalPages: notificationResponse.totalPages,
            page: notificationResponse.page,
          ),
        );
      } else {
        return Left(ServerFailure(
          message: 'Bildirimler getirilemedi',
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

  /// Okunmamış bildirim sayısını getir
  Future<Either<Failure, int>> getUnreadNotificationCount() async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/notifications/unread-count';

      // Token'ı al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
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

      final response = await _client.dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final count = response.data['count'] as int? ?? 0;
        return Right(count);
      } else {
        return Left(ServerFailure(
          message: 'Okunmamış bildirim sayısı getirilemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Bildirim sayısı bulunamadı', statusCode: 404));
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

  /// Bildirimi okundu olarak işaretle
  Future<Either<Failure, bool>> markAsRead(int notificationId) async {
    await _persistLocalReadId(notificationId);

    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final headers = await _authHeaders();

      final primaryUrl = '$baseUrl/api/zecorner/notifications/$notificationId/read';
      final primaryResponse = await _client.dio.put(
        primaryUrl,
        options: Options(headers: headers),
      );

      if (primaryResponse.statusCode == 200) {
        return const Right(true);
      }

      final legacyUrl = '$baseUrl/notification/setRead/$notificationId';
      final legacyResponse = await _client.dio.get(
        legacyUrl,
        options: Options(headers: headers),
      );

      if (legacyResponse.statusCode == 200) {
        final data = legacyResponse.data;
        final code = data is Map ? data['code'] : null;
        if (code == 'MARK_READ_DONE' || code == null) {
          return const Right(true);
        }
      }

      // Yerel okundu durumu kaydedildi; API senkronu başarısız olsa da UI'da kalıcı kalsın.
      return const Right(true);
    } on AuthFailure {
      return const Right(true);
    } on DioException {
      return const Right(true);
    } catch (_) {
      return const Right(true);
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<Either<Failure, bool>> markAllAsRead() async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/notifications/mark-all-read';

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
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

      final response = await _client.dio.put(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Bildirimler okundu olarak işaretlenemedi',
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
}