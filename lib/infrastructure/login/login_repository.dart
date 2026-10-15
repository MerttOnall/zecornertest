import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth/auth_session_storage.dart';
import '../../core/error/auth_failures.dart';
import '../../core/models/user_model.dart';
import '../../models/login/login_model.dart';
import '../../core/network/dio_client.dart';
import '../../core/repositories/base_repository.dart';
import 'package:zecorner/core/config/env_api.dart';

class LoginRepository with BaseRepository {
  static const String keyUserJwt = AuthSessionStorage.keyUserJwt;
  static const String keyAuthToken = AuthSessionStorage.keyAuthToken;
  static const String keyAuthPersistSession =
      AuthSessionStorage.keyAuthPersistSession;
  static const String keyAuthSessionExpiresMs =
      AuthSessionStorage.keyAuthSessionExpiresMs;
  static const String keyLoginRememberMeDefault =
      AuthSessionStorage.keyLoginRememberMeDefault;

  static final LoginRepository _instance = LoginRepository._internal();
  factory LoginRepository() => _instance;
  LoginRepository._internal();

  final DioClient _client = DioClient();

  /// API yanıtının e-posta/şifre hatası olup olmadığını kontrol eder.
  bool _isCredentialErrorResponse(String apiError) {
    if (apiError.isEmpty) return false;
    final lower = apiError.toLowerCase();
    const credentialKeywords = [
      'invalid', 'wrong', 'incorrect', 'credential', 'unauthorized',
      'email', 'password', 'şifre', 'e-posta', 'eposta', 'hatalı', 'yanlış',
      'geçersiz', 'kimlik', 'authentication failed', 'login failed',
    ];
    return credentialKeywords.any((k) => lower.contains(k));
  }

  Future<Either<IAuthFailure, Unit>> login(
    LoginAuthentication loginModel,
  ) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final data = loginModel.toMap();
      final url = dotenv.env["LOGIN"];
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (url == null) {
        return left(const LoginAuthFailure(
            errorMessage: "Env dosyasında LOGIN tanımlanmamış."));
      }

      if (apiKey == null || appId == null) {
        return left(const LoginAuthFailure(
            errorMessage:
                "Env dosyasında X_API_KEY veya X_APP_ID tanımlanmamış."));
      }

      print('Login başlatılıyor...');
      print('Email: ${loginModel.email.getOrCrash()}');
      print('API Key: $apiKey');
      print('App ID: $appId');

      try {
        // Header'ları ayarla
        final headers = {
          'X-API-KEY': apiKey,
          'X-APP-ID': appId,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'ZecornerMobile/1.0',
        };

        print('📋 Headers: $headers');

        // Direkt login isteği
        final response = await _client.dio.post(
          "${EnvApi.origin}/api/zecorner/signIn",
          data: data,
          options: Options(
            headers: headers,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        print('Login Response Status: ${response.statusCode}');
        print('Login Response Data: ${response.data['token']}');

        if (response.statusCode != 200) {
          final statusCode = response.statusCode ?? 0;
          final apiError = response.data["error"]?.toString() ?? response.data["message"]?.toString() ?? "";
          final isCredentialError = statusCode == 401 ||
              statusCode == 403 ||
              _isCredentialErrorResponse(apiError);
          final errorMessage = isCredentialError
              ? "E-posta ya da şifre bilgisi hatalı"
              : (apiError.isNotEmpty ? apiError : "Giriş başarısız.");
          return left(LoginAuthFailure(errorMessage: errorMessage));
        }

        // JWT Token'ı kaydet (userJWT + auth_token - office_repo vb. auth_token kullanıyor)
        final token = response.data['token'];
        if (token != null && token is String) {
          final generation = await AuthSessionStorage.synchronized(() async {
            final generation = await AuthSessionStorage.beginFreshSession();
            if (!AuthSessionStorage.isCurrent(generation)) return -1;
            await pref.setString(keyUserJwt, token);
            await pref.setString(keyAuthToken, token);
            await _applySessionAfterLogin(pref);
            return generation;
          });
          if (generation < 0 || !AuthSessionStorage.isCurrent(generation)) {
            return left(const LoginAuthFailure(
                errorMessage: "Oturum değişti, tekrar giriş yapın."));
          }

          // Token prefs'te yeni. İstek bu token ile gider, eski Bearer karışmaz.
          final userInfoResult = await _fetchUserInfo(token);
          if (!AuthSessionStorage.isCurrent(generation)) {
            return left(const LoginAuthFailure(
                errorMessage: "Oturum değişti, tekrar giriş yapın."));
          }
          final saved = await AuthSessionStorage.synchronized(() async {
            if (!AuthSessionStorage.isCurrent(generation)) return false;
            await userInfoResult.fold(
              (failure) async {
                print('User bilgileri çekilemedi: ${failure.message}');
                print('Login başarılı! Token kaydedildi');
              },
              (userInfo) async {
                print('User bilgileri başarıyla çekildi: ${userInfo['name']}');
                await _saveUserInfo(userInfo, generation);
                print('Login ve user bilgileri başarılı!');
              },
            );
            return AuthSessionStorage.isCurrent(generation);
          });
          if (!saved) {
            return left(const LoginAuthFailure(
                errorMessage: "Oturum değişti, tekrar giriş yapın."));
          }
          return right(unit);
        } else {
          return left(const LoginAuthFailure(errorMessage: "Token alınamadı."));
        }
      } on DioException catch (e) {
        print('DioException: ${e.message}');
        print('Response: ${e.response?.data}');
        final statusCode = e.response?.statusCode ?? 0;
        final apiError = e.response?.data["error"]?.toString() ?? e.response?.data["message"]?.toString() ?? "";
        final isCredentialError = statusCode == 401 ||
            statusCode == 403 ||
            _isCredentialErrorResponse(apiError);
        final errorMessage = isCredentialError
            ? "E-posta ya da şifre bilgisi hatalı"
            : (apiError.isNotEmpty ? apiError : "Sunucu hatası oluştu.");
        return left(LoginAuthFailure(errorMessage: errorMessage));
      }
    } catch (e) {
      print('Genel hata: $e');
      return left(LoginAuthFailure(errorMessage: "Platform hatası oluştu: $e"));
    }
  }

  // Kayıtlı token'ı al
  Future<String?> getStoredToken() async {
    try {
      print('getStoredToken başlatıldı...');
      await Future.delayed(const Duration(milliseconds: 50));
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString(keyUserJwt);
      print('Token alındı: ${token != null ? 'MEVCUT' : 'BOŞ'}');
      return token;
    } catch (e) {
      print('Token alma HATASI: $e');
      return null;
    }
  }

  // Kullanıcı ID'sini al
  Future<String?> getStoredUserId() async {
    try {
      print('getStoredUserId başlatıldı...');
      await Future.delayed(const Duration(milliseconds: 50));
      final pref = await SharedPreferences.getInstance();
      final userId = pref.getString('userID');
      print('UserID alındı: ${userId != null ? 'MEVCUT' : 'BOŞ'}');
      return userId;
    } catch (e) {
      print('UserID alma HATASI: $e');
      return null;
    }
  }

  // Role ID'sini al
  Future<String?> getStoredRoleId() async {
    try {
      print('getStoredRoleId başlatıldı...');
      await Future.delayed(const Duration(milliseconds: 50));
      final pref = await SharedPreferences.getInstance();
      final roleId = pref.getString('roleId');
      print('RoleID alındı: ${roleId != null ? 'MEVCUT' : 'BOŞ'}');
      return roleId;
    } catch (e) {
      print('RoleID alma HATASI: $e');
      return null;
    }
  }

  // Company ID'sini al
  Future<String?> getStoredCompanyId() async {
    try {
      print('getStoredCompanyId başlatıldı...');
      await Future.delayed(const Duration(milliseconds: 50));
      final pref = await SharedPreferences.getInstance();
      final companyId = pref.getString('companyId');
      print('CompanyID alındı: ${companyId != null ? 'MEVCUT' : 'BOŞ'}');
      return companyId;
    } catch (e) {
      print('CompanyID alma HATASI: $e');
      return null;
    }
  }

  /// Oturum ve kullanıcı verilerini siler; onboarding / "beni hatırla" tercihi kalır.
  Future<void> clearAuthSessionPreservingAppPrefs() async {
    await AuthSessionStorage.clearAuthSessionData();
  }

  Future<void> _applySessionAfterLogin(SharedPreferences pref) async {
    await pref.setBool(keyAuthPersistSession, true);
    await pref.setBool(keyLoginRememberMeDefault, true);
  }

  /// Kayıtlı token varsa kullanıcıyı geri yükler.
  /// Süre dolmuş olsa da, "beni hatırla" olmasa da oturum silinmez.
  Future<UserModel?> restoreAuthenticatedUserIfValid() async {
    final pref = await SharedPreferences.getInstance();
    final token = pref.getString(keyUserJwt);
    if (token == null || token.isEmpty) return null;
    final userId = pref.getString('userID') ?? '';
    final userName = pref.getString('userName') ?? '';
    final userSurname = pref.getString('userSurname') ?? '';
    final userEmail = pref.getString('userEmail') ?? '';
    final userPhone = pref.getString('userPhone') ?? '';
    final userType = pref.getString('userType') ?? '1';
    final roleId = pref.getString('roleId') ?? userType;
    return UserModel(
      id: userId,
      email: userEmail,
      fullName: '$userName $userSurname'.trim(),
      phone: userPhone,
      role: roleId,
      isActive: true,
      createdAt: DateTime.now(),
      profileImageUrl: '',
    );
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      print('Logout başlatıldı...');
      await Future.delayed(const Duration(milliseconds: 50));
      await AuthSessionStorage.synchronized(
        () => clearAuthSessionPreservingAppPrefs(),
      );
      print('Logout BAŞARILI - oturum temizlendi');
    } catch (e) {
      print('Logout HATASI: $e');
    }
  }

  // Debug için kayıtlı role kodlarını yazdır
  Future<void> debugPrintStoredRoleCodes() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final roleCodes = pref.getStringList('userRoleCodes') ?? [];
      final roleId = pref.getString('roleId');
      final roleCode = pref.getString('roleCode');
      final userIsAdmin = pref.getBool('userIsAdmin') ?? false;
      
      print('=== DEBUG: Kayıtlı Role Bilgileri ===');
      print('Role ID: $roleId');
      print('Role Code: $roleCode');
      print('User Is Admin: $userIsAdmin');
      print('User Role Codes: $roleCodes');
      print('=====================================');
    } catch (e) {
      print('Debug print hatası: $e');
    }
  }

  // User bilgilerini X-SESSION ile çek
  Future<Either<IAuthFailure, Map<String, dynamic>>> _fetchUserInfo(String token) async {
    try {
      final headers = {
        'X-API-KEY': 'ed017c68-24ca-4239-ae68-0fa041391855',
        'X-APP-ID': 'zecorner',
        'X-SESSION': token,
        'Content-Type': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/getUserInfo",
        options: Options(
          headers: headers,
          extra: {
            // Login sırasında 401, az önce kaydedilen token'ı silmesin.
            'skipSessionExpire': true,
          },
        ),
      );

      if (response.statusCode == 200) {
        return right(response.data as Map<String, dynamic>);
      } else {
        return left(LoginAuthFailure(errorMessage: "User bilgileri alınamadı"));
      }
    } on DioException catch (e) {
      return left(LoginAuthFailure(
          errorMessage: "User bilgileri çekilirken hata: ${e.message}"));
    }
  }

  // User bilgilerini SharedPreferences'e kaydet (Web projesindeki mantığa göre)
  Future<void> _saveUserInfo(Map<String, dynamic> userInfo, int generation) async {
    try {
      if (!AuthSessionStorage.isCurrent(generation)) return;
      final pref = await SharedPreferences.getInstance();
      if (!AuthSessionStorage.isCurrent(generation)) return;
      
      // Temel user bilgileri
      await pref.setString('userID', userInfo['contact_no'].toString());
      final eids = userInfo['eids']?.toString().trim();
      if (eids != null && eids.isNotEmpty) {
        await pref.setString('userEids', eids);
      }
      await pref.setString('userName', userInfo['name'] ?? '');
      await pref.setString('userSurname', userInfo['surname'] ?? '');
      await pref.setString('userEmail', userInfo['e_mail'] ?? '');
      await pref.setString('userPhone', userInfo['tel'] ?? '');
      
      // Rol bilgileri
      await pref.setString('userType', userInfo['type'].toString());
      await pref.setString('userTypeDescription', userInfo['type_description'] ?? '');

      bool asBool(dynamic value) {
        if (value == true) return true;
        if (value is num) return value != 0;
        if (value is String) {
          final normalized = value.trim().toLowerCase();
          return normalized == 'true' || normalized == '1';
        }
        return false;
      }

      // Sidebar yalnız bu alana bakar. Rol kodları olduğu gibi kalır.
      await pref.setBool('userIsAdmin', asBool(userInfo['is_admin']));
      
      // Role ID'yi kaydet - roles array'inden ilk role ID'yi al
      final roles = userInfo['roles'] as List<dynamic>?;
      if (roles != null && roles.isNotEmpty) {
        final firstRole = roles.first;
        final roleId = firstRole['id']?.toString();
        if (roleId != null) {
          await pref.setString('roleId', roleId);
          print('LoginRepository: Role ID kaydedildi: $roleId');
        }
        
        // Role code'unu da kaydet (eğer varsa)
        final roleCode = firstRole['code']?.toString();
        if (roleCode != null) {
          await pref.setString('roleCode', roleCode);
          print('LoginRepository: Role Code kaydedildi: $roleCode');
        }
      }
      
      // Permissions array'ini string olarak kaydet
      final permissions = userInfo['permissions'] as List<dynamic>?;
      if (permissions != null) {
        await pref.setString('userPermissions', permissions.join(','));
      }
      
      // Web projesindeki mantığa göre tüm kullanıcı rollerini kaydet
      if (roles != null) {
        final roleCodes = roles
            .where((role) => role is Map && role['code'] != null)
            .map((role) => (role as Map)['code'].toString())
            .toList();
        
        await pref.setStringList('userRoleCodes', roleCodes);
        print('LoginRepository: User Role Codes kaydedildi: $roleCodes');
        
        final rolesJson = roleCodes.join(',');
        await pref.setString('userRoles', rolesJson);
      }
      
      // Ofis: get-user-info `connected_contact` (ilanlardaki office id). office_id yoksa bu kullanılır.
      int asInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString().trim()) ?? 0;
      }

      final personNo = asInt(userInfo['contact_no']);
      final connectedOffice = asInt(userInfo['connected_contact']);
      final loginOffice = asInt(userInfo['office_id']);
      final officeId = connectedOffice > 0 && connectedOffice != personNo
          ? connectedOffice
          : (loginOffice > 0 && loginOffice != personNo
              ? loginOffice
              : (connectedOffice > 0 ? connectedOffice : 0));
      if (officeId > 0) {
        await pref.setInt('officeId', officeId);
        print('LoginRepository: Office ID kaydedildi: $officeId');
      }
      final officeTitle = userInfo['connected_contact_title']?.toString().trim();
      if (officeTitle != null && officeTitle.isNotEmpty) {
        await pref.setString('officeTitle', officeTitle);
      }

      if (userInfo['advisor_id'] != null) {
        await pref.setInt('advisorId', userInfo['advisor_id']);
        print('LoginRepository: Advisor ID kaydedildi: ${userInfo['advisor_id']}');
      }
      
      if (userInfo['contact_type'] != null) {
        await pref.setInt('contactType', userInfo['contact_type']);
        print('LoginRepository: Contact Type kaydedildi: ${userInfo['contact_type']}');
      }
      
      if (userInfo['status'] != null) {
        await pref.setString('userStatus', userInfo['status'].toString());
        print('LoginRepository: User Status kaydedildi: ${userInfo['status']}');
      }
      
      print('LoginRepository: User bilgileri SharedPreferences\'e kaydedildi');
    } catch (e) {
      print('LoginRepository: User bilgileri kaydetme hatası: $e');
    }
  }
}
