import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import 'package:zecorner/core/config/env_api.dart';

class SignupRepository {
  static final SignupRepository _instance = SignupRepository._internal();
  factory SignupRepository() => _instance;
  SignupRepository._internal();

  final DioClient _client = DioClient();

  // POST - Kullanıcı kaydı yap
  Future<Either<Failure, SignupResponseModel>> registerUser({
    required String name,
    required String surname,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
    String? nationality,
    int? type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('📝 Yeni kullanıcı kaydı yapılıyor...');
      print('👤 Email: $email');
      print('📱 Telefon: ${phone ?? 'Yok'}');
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        print('❌ API anahtarları bulunamadı');
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestData = {
        'name': name,
        'surname': surname,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        if (phone != null) 'phone': phone,
        if (nationality != null) 'nationality': nationality,
        if (type != null) 'type': type,
        if (additionalData != null) ...additionalData,
      };

      print('📤 Kayıt verileri gönderiliyor...');

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/register",
        data: requestData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Kullanıcı kaydı başarılı');
        final signupResponse = SignupResponseModel.fromJson(response.data);
        
        print('🆔 Oluşturulan User ID: ${signupResponse.userId}');
        
        return Right(signupResponse);
      } else {
        print('❌ Kullanıcı kaydı başarısız: ${response.statusCode}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Kullanıcı kaydı yapılamadı'
        ));
      }
    } catch (e) {
      print('❌ Kullanıcı kaydı hatası: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          return Left(ServerFailure(
            message: e.response?.data['message'] ?? 'Geçersiz kullanıcı bilgileri'
          ));
        } else if (e.response?.statusCode == 409) {
          return Left(ServerFailure(
            message: 'Bu email adresi zaten kullanılıyor'
          ));
        } else if (e.response?.statusCode == 422) {
          return Left(ServerFailure(
            message: 'Kullanıcı bilgileri doğrulama hatası'
          ));
        }
      }
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Hızlı kayıt (minimal bilgilerle)
  Future<Either<Failure, SignupResponseModel>> quickRegister({
    required String email,
    required String password,
    String? name,
    String? surname,
  }) async {
    try {
      print('⚡ Hızlı kullanıcı kaydı yapılıyor...');
      print('📧 Email: $email');
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestData = {
        'email': email,
        'password': password,
        'confirm_password': password,
        'name': name ?? '',
        'surname': surname ?? '',
      };

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/register/quick",
        data: requestData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Hızlı kayıt başarılı');
        final signupResponse = SignupResponseModel.fromJson(response.data);
        
        print('🆔 Oluşturulan User ID: ${signupResponse.userId}');
        
        return Right(signupResponse);
      } else {
        print('❌ Hızlı kayıt başarısız: ${response.statusCode}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Hızlı kayıt yapılamadı'
        ));
      }
    } catch (e) {
      print('❌ Hızlı kayıt hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Email doğrulama
  Future<Either<Failure, bool>> verifyEmail({
    required String userId,
    required String verificationCode,
  }) async {
    try {
      print('📧 Email doğrulanıyor...');
      print('🆔 User ID: $userId');
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestData = {
        'user_id': userId,
        'verification_code': verificationCode,
      };

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/register/verify-email",
        data: requestData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Email başarıyla doğrulandı');
        return const Right(true);
      } else {
        print('❌ Email doğrulama başarısız: ${response.statusCode}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Email doğrulanamadı'
        ));
      }
    } catch (e) {
      print('❌ Email doğrulama hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Doğrulama kodu tekrar gönder
  Future<Either<Failure, bool>> resendVerificationCode(String userId) async {
    try {
      print('🔄 Doğrulama kodu tekrar gönderiliyor...');
      print('🆔 User ID: $userId');
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/register/resend-code",
        data: {'user_id': userId},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Doğrulama kodu tekrar gönderildi');
        return const Right(true);
      } else {
        print('❌ Doğrulama kodu gönderilemedi: ${response.statusCode}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Doğrulama kodu gönderilemedi'
        ));
      }
    } catch (e) {
      print('❌ Doğrulama kodu gönderme hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Email kullanılabilirlik kontrolü
  Future<Either<Failure, bool>> checkEmailAvailability(String email) async {
    try {
      print('📧 Email kullanılabilirliği kontrol ediliyor: $email');
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/register/check-email",
        queryParameters: {'email': email},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final isAvailable = response.data['available'] ?? false;
        print(isAvailable ? '✅ Email kullanılabilir' : '❌ Email zaten kullanılıyor');
        return Right(isAvailable);
      } else {
        print('❌ Email kontrolü başarısız: ${response.statusCode}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Email kontrolü yapılamadı'
        ));
      }
    } catch (e) {
      print('❌ Email kontrol hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Sosyal medya ile kayıt (Google, Facebook, Apple)
  Future<Either<Failure, SignupResponseModel>> registerWithSocialMedia({
    required String provider, // 'google', 'facebook', 'apple'
    required String socialToken,
    String? email,
    String? name,
    String? surname,
    String? profilePicture,
  }) async {
    try {
      print('🔗 Sosyal medya ile kayıt yapılıyor: $provider');
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestData = {
        'provider': provider,
        'social_token': socialToken,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (surname != null) 'surname': surname,
        if (profilePicture != null) 'profile_picture': profilePicture,
      };

      final response = await _client.dio.post(
        "${EnvApi.origin}/api/zecorner/register/social",
        data: requestData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Sosyal medya kaydı başarılı');
        final signupResponse = SignupResponseModel.fromJson(response.data);
        
        print('🆔 User ID: ${signupResponse.userId}');
        
        return Right(signupResponse);
      } else {
        print('❌ Sosyal medya kaydı başarısız: ${response.statusCode}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Sosyal medya kaydı yapılamadı'
        ));
      }
    } catch (e) {
      print('❌ Sosyal medya kayıt hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // DELETE - Kayıt işlemini iptal et (henüz doğrulanmamış hesaplar için)
  Future<Either<Failure, bool>> cancelRegistration(String userId) async {
    try {
      print('❌ Kayıt işlemi iptal ediliyor...');
      print('🆔 User ID: $userId');
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.delete(
        "${EnvApi.origin}/api/zecorner/register/$userId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Kayıt işlemi başarıyla iptal edildi');
        return const Right(true);
      } else {
        print('❌ Kayıt iptali başarısız: ${response.statusCode}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Kayıt iptali yapılamadı'
        ));
      }
    } catch (e) {
      print('❌ Kayıt iptal hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Kayıt durumu kontrolü
  Future<Either<Failure, RegistrationStatusModel>> getRegistrationStatus(String userId) async {
    try {
      print('📊 Kayıt durumu kontrol ediliyor...');
      print('🆔 User ID: $userId');
      
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: "API anahtarları bulunamadı."));
      }

      final headers = {
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/register/status/$userId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('✅ Kayıt durumu getirildi');
        final status = RegistrationStatusModel.fromJson(response.data);
        
        print('📧 Email doğrulandı: ${status.emailVerified}');
        print('📱 Telefon doğrulandı: ${status.phoneVerified}');
        print('✅ Kayıt tamamlandı: ${status.registrationCompleted}');
        
        return Right(status);
      } else {
        print('❌ Kayıt durumu getirilemedi: ${response.statusCode}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Kayıt durumu getirilemedi'
        ));
      }
    } catch (e) {
      print('❌ Kayıt durumu kontrol hatası: $e');
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }
}

// Response Models
class SignupResponseModel {
  final String userId;

  SignupResponseModel({
    required this.userId,
  });

  factory SignupResponseModel.fromJson(Map<String, dynamic> json) {
    return SignupResponseModel(
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
    };
  }
}

class RegistrationStatusModel {
  final String userId;
  final bool emailVerified;
  final bool phoneVerified;
  final bool registrationCompleted;
  final DateTime? createdAt;
  final DateTime? verifiedAt;
  final List<String> completedSteps;
  final List<String> pendingSteps;

  RegistrationStatusModel({
    required this.userId,
    required this.emailVerified,
    required this.phoneVerified,
    required this.registrationCompleted,
    this.createdAt,
    this.verifiedAt,
    this.completedSteps = const [],
    this.pendingSteps = const [],
  });

  factory RegistrationStatusModel.fromJson(Map<String, dynamic> json) {
    return RegistrationStatusModel(
      userId: json['user_id'] ?? '',
      emailVerified: json['email_verified'] ?? false,
      phoneVerified: json['phone_verified'] ?? false,
      registrationCompleted: json['registration_completed'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
      completedSteps: List<String>.from(json['completed_steps'] ?? []),
      pendingSteps: List<String>.from(json['pending_steps'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'registration_completed': registrationCompleted,
      'created_at': createdAt?.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'completed_steps': completedSteps,
      'pending_steps': pendingSteps,
    };
  }
}

// Helper Extension for SignupResponseModel
extension SignupResponseModelHelpers on SignupResponseModel {
  /// User ID boş mu kontrol et
  bool get hasValidUserId => userId.isNotEmpty;

  /// User ID formatlanmış gösterim
  String get formattedUserId => userId.length > 8 ? '${userId.substring(0, 8)}...' : userId;

  /// UUID formatında mı kontrol et
  bool get isValidUUID {
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    return uuidRegex.hasMatch(userId.toLowerCase());
  }
}

// Helper Extension for RegistrationStatusModel  
extension RegistrationStatusModelHelpers on RegistrationStatusModel {
  /// Kayıt tamamlanma yüzdesi
  int get completionPercentage {
    final totalSteps = completedSteps.length + pendingSteps.length;
    if (totalSteps == 0) return 0;
    return ((completedSteps.length / totalSteps) * 100).round();
  }

  /// Kayıt durumu açıklaması
  String get statusDescription {
    if (registrationCompleted) return 'Kayıt tamamlandı';
    if (emailVerified && phoneVerified) return 'Doğrulamalar tamamlandı';
    if (emailVerified) return 'Email doğrulandı, telefon bekleniyor';
    if (phoneVerified) return 'Telefon doğrulandı, email bekleniyor';
    return 'Doğrulamalar bekleniyor';
  }

  /// Durum ikonu
  String get statusIcon {
    if (registrationCompleted) return '✅';
    if (emailVerified && phoneVerified) return '🔄';
    if (emailVerified || phoneVerified) return '⏳';
    return '❌';
  }

  /// Kayıt ne kadar sürede tamamlandı (eğer tamamlandıysa)
  String? get registrationDuration {
    if (createdAt == null || verifiedAt == null) return null;
    
    final duration = verifiedAt!.difference(createdAt!);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} dakika';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} saat';
    } else {
      return '${duration.inDays} gün';
    }
  }

  /// Sonraki adım nedir
  String? get nextStep {
    if (registrationCompleted) return null;
    if (!emailVerified) return 'Email doğrulama';
    if (!phoneVerified) return 'Telefon doğrulama';
    if (pendingSteps.isNotEmpty) return pendingSteps.first;
    return null;
  }

  /// Formatlanmış oluşturulma tarihi
  String? get formattedCreatedAt {
    if (createdAt == null) return null;
    return '${createdAt!.day.toString().padLeft(2, '0')}.${createdAt!.month.toString().padLeft(2, '0')}.${createdAt!.year}';
  }

  /// Formatlanmış doğrulama tarihi
  String? get formattedVerifiedAt {
    if (verifiedAt == null) return null;
    return '${verifiedAt!.day.toString().padLeft(2, '0')}.${verifiedAt!.month.toString().padLeft(2, '0')}.${verifiedAt!.year}';
  }
}
