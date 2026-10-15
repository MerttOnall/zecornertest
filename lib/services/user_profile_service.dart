import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';
import '../models/users/user_profile_model.dart';
import '../services/update_delete_service.dart';
import '../models/update_delete/update_delete_models.dart';

/// User Profile Güncelleme Servisi
/// Bu servis kullanıcı profil bilgilerini yönetir
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final UpdateDeleteService _updateDeleteService = UpdateDeleteService();

  static const String _updateUserInfoEndpoint = '/api/zecorner/updateUserInfo';

  /// Kullanıcı bilgilerini getir (getUserInfo API - X-SESSION ile)
  Future<UserProfileModel> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
      }

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      ));

      final response = await dio.get(
        '/getUserInfo',
        options: Options(
          headers: {
            'X-API-KEY': ApiConfig.apiKey,
            'X-APP-ID': ApiConfig.appId,
            'X-SESSION': token,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return UserProfileModel.fromJson(
          response.data is Map<String, dynamic>
              ? response.data
              : Map<String, dynamic>.from(response.data),
        );
      } else {
        throw Exception(
            'Kullanıcı bilgileri alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Oturum süresi doldu. Lütfen tekrar giriş yapın.');
      }
      throw Exception(
          'Kullanıcı bilgileri alınırken hata oluştu: ${e.message}');
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınırken hata oluştu: $e');
    }
  }

  /// Kullanıcı profil bilgilerini güncelle
  Future<OperationResultModel> updateUserProfile({
    required UserProfileModel updatedProfile,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      // Güncelleme verilerini hazırla
      final updateData = updatedProfile.toUpdateJson();
      
      // UpdateDeleteService kullanarak güncelleme yap
      final result = await _updateDeleteService.updateItem(
        id: updatedProfile.contactNo.toString(),
        updateData: updateData,
        updatedBy: updatedBy,
        reason: reason ?? 'Profil bilgileri güncellendi',
        endpoint: _updateUserInfoEndpoint,
      );

      return result;
    } catch (e) {
      return OperationResultModel.error(
        message: 'Profil güncelleme işlemi sırasında hata oluştu: $e',
        errorCode: 'USER_PROFILE_UPDATE_ERROR',
      );
    }
  }

  /// Kullanıcı profil resmini güncelle
  Future<OperationResultModel> updateProfilePicture({
    required String contactNo,
    required String picturePath,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      final updateData = {
        'detail': {
          'picture': picturePath,
        }
      };

      final result = await _updateDeleteService.updateItem(
        id: contactNo,
        updateData: updateData,
        updatedBy: updatedBy,
        reason: reason ?? 'Profil resmi güncellendi',
        endpoint: _updateUserInfoEndpoint,
      );

      return result;
    } catch (e) {
      return OperationResultModel.error(
        message: 'Profil resmi güncelleme işlemi sırasında hata oluştu: $e',
        errorCode: 'PROFILE_PICTURE_UPDATE_ERROR',
      );
    }
  }

  /// Kullanıcı sosyal medya bilgilerini güncelle
  Future<OperationResultModel> updateSocialMedia({
    required String contactNo,
    required UserSocialMediaModel socialMedia,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      final updateData = {
        'detail': {
          'social_media': socialMedia.toJson(),
        }
      };

      final result = await _updateDeleteService.updateItem(
        id: contactNo,
        updateData: updateData,
        updatedBy: updatedBy,
        reason: reason ?? 'Sosyal medya bilgileri güncellendi',
        endpoint: _updateUserInfoEndpoint,
      );

      return result;
    } catch (e) {
      return OperationResultModel.error(
        message: 'Sosyal medya güncelleme işlemi sırasında hata oluştu: $e',
        errorCode: 'SOCIAL_MEDIA_UPDATE_ERROR',
      );
    }
  }

  /// Kullanıcı adres bilgilerini güncelle
  Future<OperationResultModel> updateAddress({
    required String contactNo,
    required UserAddressModel address,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      final updateData = {
        'address': address.toUpdateJson(),
      };

      final result = await _updateDeleteService.updateItem(
        id: contactNo,
        updateData: updateData,
        updatedBy: updatedBy,
        reason: reason ?? 'Adres bilgileri güncellendi',
        endpoint: _updateUserInfoEndpoint,
      );

      return result;
    } catch (e) {
      return OperationResultModel.error(
        message: 'Adres güncelleme işlemi sırasında hata oluştu: $e',
        errorCode: 'ADDRESS_UPDATE_ERROR',
      );
    }
  }

  /// Kullanıcı eğitim bilgilerini güncelle
  Future<OperationResultModel> updateEducation({
    required String contactNo,
    required UserEducationModel education,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      final updateData = {
        'detail': {
          'education': education.toJson(),
        }
      };

      final result = await _updateDeleteService.updateItem(
        id: contactNo,
        updateData: updateData,
        updatedBy: updatedBy,
        reason: reason ?? 'Eğitim bilgileri güncellendi',
        endpoint: _updateUserInfoEndpoint,
      );

      return result;
    } catch (e) {
      return OperationResultModel.error(
        message: 'Eğitim güncelleme işlemi sırasında hata oluştu: $e',
        errorCode: 'EDUCATION_UPDATE_ERROR',
      );
    }
  }

  /// Kullanıcı meslek bilgilerini güncelle
  Future<OperationResultModel> updateProfession({
    required String contactNo,
    required UserProfessionModel profession,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      final updateData = {
        'detail': {
          'profession': profession.toJson(),
        }
      };

      final result = await _updateDeleteService.updateItem(
        id: contactNo,
        updateData: updateData,
        updatedBy: updatedBy,
        reason: reason ?? 'Meslek bilgileri güncellendi',
        endpoint: _updateUserInfoEndpoint,
      );

      return result;
    } catch (e) {
      return OperationResultModel.error(
        message: 'Meslek güncelleme işlemi sırasında hata oluştu: $e',
        errorCode: 'PROFESSION_UPDATE_ERROR',
      );
    }
  }

  /// Kullanıcı hakkında bilgilerini güncelle
  Future<OperationResultModel> updateAboutInfo({
    required String contactNo,
    required String coverLetter,
    required String areasOfExpertise,
    required String reference,
    required int sectoralExperience,
    required bool marketingPermission,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      final updateData = {
        'detail': {
          'cover_letter': coverLetter,
          'areas_of_expertise': areasOfExpertise,
          'reference': reference,
          'sectoral_experience': sectoralExperience,
          'marketing_communication_permission': marketingPermission,
        }
      };

      final result = await _updateDeleteService.updateItem(
        id: contactNo,
        updateData: updateData,
        updatedBy: updatedBy,
        reason: reason ?? 'Hakkında bilgileri güncellendi',
        endpoint: _updateUserInfoEndpoint,
      );

      return result;
    } catch (e) {
      return OperationResultModel.error(
        message: 'Hakkında bilgileri güncelleme işlemi sırasında hata oluştu: $e',
        errorCode: 'ABOUT_UPDATE_ERROR',
      );
    }
  }

  /// Kullanıcı işlem geçmişini getir
  Future<List<Map<String, dynamic>>> getUserOperationHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      return await _updateDeleteService.getOperationHistory(
        itemId: 'user_profile',
        operationType: 'update',
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Kullanıcı işlem geçmişi alınırken hata oluştu: $e');
    }
  }

  /// Şifre sıfırlama isteği gönder
  Future<OperationResultModel> requestPasswordReset({
    required String email,
    required String contactNo,
  }) async {
    try {
      // Simulated API call delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Simulated password reset request
      return OperationResultModel.success(
        message: 'Şifre sıfırlama e-postası başarıyla gönderildi',
        resultData: {
          'email': email,
          'contact_no': contactNo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      return OperationResultModel.error(
        message: 'Şifre sıfırlama isteği gönderilirken hata oluştu: $e',
        errorCode: 'PASSWORD_RESET_ERROR',
      );
    }
  }

  /// Belge yükleme işlemi
  Future<OperationResultModel> uploadDocument({
    required String contactNo,
    required String documentType,
    required String filePath,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      // Simulated file upload
      await Future.delayed(const Duration(milliseconds: 1500));

      final updateData = {
        'attachments': {
          documentType: filePath,
        }
      };

      final result = await _updateDeleteService.updateItem(
        id: contactNo,
        updateData: updateData,
        updatedBy: updatedBy,
        reason: reason ?? '$documentType belgesi yüklendi',
        endpoint: _updateUserInfoEndpoint,
      );

      return result;
    } catch (e) {
      return OperationResultModel.error(
        message: 'Belge yükleme işlemi sırasında hata oluştu: $e',
        errorCode: 'DOCUMENT_UPLOAD_ERROR',
      );
    }
  }
}
