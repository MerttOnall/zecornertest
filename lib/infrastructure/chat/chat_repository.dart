import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/chat_message_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class ChatRepository with BaseRepository {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();

  final DioClient _client = DioClient();

  /// Chat listesini getir
  Future<Either<Failure, ChatListModel>> getChatList({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/chats';

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
        final chatListResponse = ChatListModel.fromJson(response.data);
        return Right(chatListResponse);
      } else {
        return Left(ServerFailure(
          message: 'Chat listesi getirilemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Chat listesi bulunamadı', statusCode: 404));
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

  /// Belirli bir chat'in detaylarını getir
  Future<Either<Failure, ChatItem>> getChatDetail(String chatId) async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/chats/$chatId';

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
        final chatDetail = ChatItem.fromJson(response.data);
        return Right(chatDetail);
      } else {
        return Left(ServerFailure(
          message: 'Chat detayı getirilemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Chat detayı bulunamadı', statusCode: 404));
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

  /// Mesaj gönder
  Future<Either<Failure, bool>> sendMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/chats/$chatId/messages';

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

      final response = await _client.dio.post(
        url,
        data: {
          'message': message,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Mesaj gönderilemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Chat bulunamadı', statusCode: 404));
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

  /// Chat mesajlarını getir
  Future<Either<Failure, ChatMessagesModel>> getChatMessages({
    required String chatId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/chatMessages';

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
          'chatId': chatId,  // try 'chatId' instead of 'chat_id'
          'page': page,
          'pageSize': limit,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        // Response'u ChatMessagesModel formatına çevir
        final responseData = response.data;
        ChatMessagesModel chatMessagesResponse;
        
        if (responseData is Map<String, dynamic>) {
          // Eğer response zaten ChatMessagesModel formatındaysa
          chatMessagesResponse = ChatMessagesModel.fromJson(responseData);
        } else if (responseData is List) {
          // Eğer response sadece mesaj listesiyse, ChatMessagesModel formatına çevir
          final messages = (responseData as List)
              .map((i) => ChatMessage.fromJson(i))
              .toList();
          chatMessagesResponse = ChatMessagesModel(
            messages: messages,
            totalCount: messages.length,
            totalPages: 1,
            page: 1,
          );
        } else {
          return Left(ServerFailure(
            message: 'Beklenmeyen response formatı',
            statusCode: response.statusCode,
          ));
        }
        
        return Right(chatMessagesResponse);
      } else {
        return Left(ServerFailure(
          message: 'Chat mesajları getirilemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Chat mesajları bulunamadı', statusCode: 404));
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

  /// Chat geçmişini getir
  Future<Either<Failure, List<Map<String, dynamic>>>> getChatHistory(String chatId) async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/chats/$chatId/messages';

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
        final messages = List<Map<String, dynamic>>.from(response.data);
        return Right(messages);
      } else {
        return Left(ServerFailure(
          message: 'Chat geçmişi getirilemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Chat geçmişi bulunamadı', statusCode: 404));
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

  /// Okunmamış mesaj sayısını sıfırla
  Future<Either<Failure, bool>> markAsRead(String chatId) async {
    try {
      final baseUrl = dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
      final url = '$baseUrl/api/zecorner/chats/$chatId/read';

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

      final response = await _client.dio.put(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Mesajlar okundu olarak işaretlenemedi',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Yetkilendirme hatası'));
      } else if (e.response?.statusCode == 403) {
        return Left(AuthFailure(message: 'Erişim reddedildi'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'Chat bulunamadı', statusCode: 404));
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
