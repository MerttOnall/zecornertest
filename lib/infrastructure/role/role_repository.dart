import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_config.dart';
import '../../models/role/role_model.dart';
import 'package:zecorner/core/config/env_api.dart';

class RoleRepository {
  static final RoleRepository _instance = RoleRepository._internal();
  factory RoleRepository() => _instance;
  RoleRepository._internal();

  final DioClient _client = DioClient();

  // GET - Tüm rolleri getir
  Future<Either<Failure, List<RoleModel>>> getAllRoles() async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print('🔄 RoleRepository: Roller çekiliyor...');
      print('📋 URL: ${EnvApi.origin}/api/zecorner/roles');
      print('📋 Headers: $headers');

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/roles",
        options: Options(headers: headers),
      );

      print('✅ RoleRepository: API yanıtı alındı');
      print('📊 Status: ${response.statusCode}');
      print('📦 Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('📦 Raw Data Type: ${data.runtimeType}');
        print('📦 Raw Data: $data');
        
        List<dynamic> rolesList;
        if (data is List) {
          rolesList = data;
        } else if (data is Map && data['data'] != null) {
          rolesList = data['data'] as List<dynamic>;
        } else {
          rolesList = [];
        }
        
        print('📦 Processed Roles List: $rolesList');
        final roles = rolesList.map((json) => RoleModel.fromJson(json)).toList();
        print('✅ ${roles.length} rol başarıyla yüklendi');
        return Right(roles);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Roller getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - ID'ye göre rol getir
  Future<Either<Failure, RoleModel>> getRoleById(int roleId) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/roles/$roleId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final role = RoleModel.fromJson(response.data['data'] ?? response.data);
        return Right(role);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Rol bulunamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Contact type'a göre roller getir
  Future<Either<Failure, List<RoleModel>>> getRolesByContactType(int contactTypeCode) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${ApiConfig.baseUrl}${RoleEndpoints.roles}",
        queryParameters: {'contact_type': contactTypeCode},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final roles = data.map((json) => RoleModel.fromJson(json)).toList();
        return Right(roles);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Roller getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Kullanıcının rollerini getir (Web projesindeki mantığa göre)
  Future<Either<Failure, List<RoleModel>>> getUserRoles(int userId) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${ApiConfig.baseUrl}/zecorner/users/$userId/roles",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final roles = data.map((json) => RoleModel.fromJson(json)).toList();
        
        // Web projesindeki mantığa göre role kodlarını logla
        print('RoleRepository: Kullanıcı rolleri alındı');
        for (final role in roles) {
          print('  - Role: ${role.name} (${role.code})');
        }
        
        return Right(roles);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Kullanıcı rolleri getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Yeni rol oluştur
  Future<Either<Failure, RoleModel>> createRole(RoleModel role) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.post(
        "${ApiConfig.baseUrl}${RoleEndpoints.roles}",
        data: role.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdRole = RoleModel.fromJson(response.data['data'] ?? response.data);
        return Right(createdRole);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Rol oluşturulamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // PUT - Rol güncelle
  Future<Either<Failure, RoleModel>> updateRole(int roleId, RoleModel role) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.put(
        "${EnvApi.origin}/api/zecorner/roles/$roleId",
        data: role.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final updatedRole = RoleModel.fromJson(response.data['data'] ?? response.data);
        return Right(updatedRole);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Rol güncellenemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // DELETE - Rol sil
  Future<Either<Failure, bool>> deleteRole(int roleId) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.delete(
        "${EnvApi.origin}/api/zecorner/roles/$roleId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Rol silinemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // POST - Kullanıcıya rol ata
  Future<Either<Failure, bool>> assignRoleToUser(int userId, int roleId) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.post(
        "${ApiConfig.baseUrl}/zecorner/users/$userId/roles",
        data: {'role_id': roleId},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Rol atanamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // DELETE - Kullanıcıdan rol kaldır
  Future<Either<Failure, bool>> removeRoleFromUser(int userId, int roleId) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.delete(
        "${EnvApi.origin}/api/zecorner/users/$userId/roles/$roleId",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return Right(true);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Rol kaldırılamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Kullanıcının belirli bir izni var mı kontrol et
  Future<Either<Failure, bool>> checkUserPermission(int userId, String permission) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/users/$userId/permissions",
        queryParameters: {'permission': permission},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final hasPermission = response.data['has_permission'] ?? false;
        return Right(hasPermission);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'İzin kontrolü yapılamadı'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Kullanıcının tüm izinlerini getir
  Future<Either<Failure, List<String>>> getUserPermissions(int userId) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/users/$userId/permissions",
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> permissionsData = response.data['permissions'] ?? [];
        final permissions = permissionsData.map((permission) => permission.toString()).toList();
        return Right(permissions);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'İzinler getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // GET - Contact type'a göre varsayılan rolleri getir
  Future<Either<Failure, List<RoleModel>>> getDefaultRolesByContactType(int contactTypeCode) async {
    try {
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

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _client.dio.get(
        "${EnvApi.origin}/api/zecorner/roles/default",
        queryParameters: {'contact_type': contactTypeCode},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final roles = data.map((json) => RoleModel.fromJson(json)).toList();
        return Right(roles);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Varsayılan roller getirilemedi'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Bağlantı hatası: $e'));
    }
  }

  // Web projesindeki mantığa göre role kontrol methodları
  // GET - Kullanıcının belirli bir role'ü var mı kontrol et
  Future<Either<Failure, bool>> hasRole(int userId, String roleCode) async {
    try {
      final rolesResult = await getUserRoles(userId);
      return rolesResult.fold(
        (failure) => Left(failure),
        (roles) {
          final hasRole = roles.any((role) => role.code == roleCode);
          print('RoleRepository: Kullanıcı $roleCode role\'üne sahip mi: $hasRole');
          return Right(hasRole);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Role kontrolü hatası: $e'));
    }
  }

  // GET - Kullanıcının role kodlarını getir (Web projesindeki roles.includes() mantığı için)
  Future<Either<Failure, List<String>>> getUserRoleCodes(int userId) async {
    try {
      final rolesResult = await getUserRoles(userId);
      return rolesResult.fold(
        (failure) => Left(failure),
        (roles) {
          final roleCodes = roles.map((role) => role.code).where((code) => code != null).cast<String>().toList();
          print('RoleRepository: Kullanıcı role kodları: $roleCodes');
          return Right(roleCodes);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Role kodları getirme hatası: $e'));
    }
  }

  // GET - Web projesindeki mantığa göre kullanıcı tipini belirle
  Future<Either<Failure, String>> getUserType(int userId) async {
    try {
      final roleCodesResult = await getUserRoleCodes(userId);
      return roleCodesResult.fold(
        (failure) => Left(failure),
        (roleCodes) {
          String userType = 'default';
          
          // Web projesindeki mantığa göre user type belirleme
          if (roleCodes.contains('role_admin')) {
            userType = 'admin';
          } else if (roleCodes.contains('role_advisor')) {
            userType = 'advisor';
          } else if (roleCodes.contains('role_office_broker') || roleCodes.contains('role_office_assistant')) {
            userType = 'office';
          } else if (roleCodes.contains('role_form_applications') || roleCodes.contains('role_form_applications_admin')) {
            userType = 'form_applications';
          } else if (roleCodes.contains('role_sale_applications') || roleCodes.contains('role_sale_applications_admin')) {
            userType = 'sale_applications';
          }
          
          print('RoleRepository: Kullanıcı tipi belirlendi: $userType');
          return Right(userType);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Kullanıcı tipi belirleme hatası: $e'));
    }
  }

  // GET - Kullanıcının office ID'sini getir (Web projesindeki officeId mantığı için)
  Future<Either<Failure, int?>> getUserOfficeId(int userId) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final officeId = pref.getInt('officeId');
      
      if (officeId != null) {
        print('RoleRepository: Kullanıcı office ID: $officeId');
        return Right(officeId);
      } else {
        print('RoleRepository: Kullanıcı office ID bulunamadı');
        return Right(null);
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Office ID getirme hatası: $e'));
    }
  }

  // GET - Kullanıcının advisor ID'sini getir (Web projesindeki advisorId mantığı için)
  Future<Either<Failure, int?>> getUserAdvisorId(int userId) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final advisorId = pref.getInt('advisorId');
      
      if (advisorId != null) {
        print('RoleRepository: Kullanıcı advisor ID: $advisorId');
        return Right(advisorId);
      } else {
        print('RoleRepository: Kullanıcı advisor ID bulunamadı');
        return Right(null);
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Advisor ID getirme hatası: $e'));
    }
  }

  // GET - SharedPreferences'den kayıtlı role kodlarını getir (Web projesindeki mantığa göre)
  Future<Either<Failure, List<String>>> getStoredUserRoleCodes() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final roleCodes = pref.getStringList('userRoleCodes') ?? [];
      
      print('RoleRepository: Kayıtlı role kodları: $roleCodes');
      return Right(roleCodes);
    } catch (e) {
      return Left(ServerFailure(message: 'Kayıtlı role kodları getirme hatası: $e'));
    }
  }

  // GET - SharedPreferences'den kayıtlı kullanıcı tipini getir
  Future<Either<Failure, String>> getStoredUserType() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final userType = pref.getString('userType') ?? 'default';
      
      print('RoleRepository: Kayıtlı kullanıcı tipi: $userType');
      return Right(userType);
    } catch (e) {
      return Left(ServerFailure(message: 'Kayıtlı kullanıcı tipi getirme hatası: $e'));
    }
  }

  // GET - SharedPreferences'den kayıtlı office ID'yi getir
  Future<Either<Failure, int?>> getStoredOfficeId() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final officeId = pref.getInt('officeId');
      
      print('RoleRepository: Kayıtlı office ID: $officeId');
      return Right(officeId);
    } catch (e) {
      return Left(ServerFailure(message: 'Kayıtlı office ID getirme hatası: $e'));
    }
  }

  // GET - SharedPreferences'den kayıtlı advisor ID'yi getir
  Future<Either<Failure, int?>> getStoredAdvisorId() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final advisorId = pref.getInt('advisorId');
      
      print('RoleRepository: Kayıtlı advisor ID: $advisorId');
      return Right(advisorId);
    } catch (e) {
      return Left(ServerFailure(message: 'Kayıtlı advisor ID getirme hatası: $e'));
    }
  }
}
