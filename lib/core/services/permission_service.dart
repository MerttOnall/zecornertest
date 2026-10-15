import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' hide Options;
import 'package:dio/dio.dart';
import '../models/permission_model.dart';
import '../models/user_model.dart';
import '../network/dio_client.dart';
import '../repositories/base_repository.dart';
import '../utils/either.dart';
import '../error/failures.dart';
import '../config/api_config.dart';
import '../../infrastructure/login/login_repository.dart';

class PermissionService with BaseRepository {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  Role? _currentRole;
  Map<String, bool> _permissionCache = {};
  bool _sessionAdmin = false;

  // JWT roleId - Token'dan çekilen rol ID'si
  String? get jwtRoleId => _currentRole?.id;

  // RolesRepo flow - API'den rol listesi çekme
  Future<Either<Failure, List<Role>>> getAllRoles() async {
    try {
      print('PermissionService: Tüm roller çekiliyor...');
      
      // Login repository'den token al
      final LoginRepository loginRepo = LoginRepository();
      final token = await loginRepo.getStoredToken();
      
      if (token == null) {
        print('PermissionService: Token bulunamadı');
        return Left(NetworkFailure(message: 'Token bulunamadı'));
      }
      
      // Header'ları ayarla
      final headers = {
        'X-API-KEY': 'ed017c68-24ca-4239-ae68-0fa041391855',
        'X-APP-ID': 'zecorner',
        'X-SESSION': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      print('PermissionService: API çağrısı yapılıyor...');
      print('URL: ${ApiConfig.baseUrl}${RoleEndpoints.roles}');
      print('Headers: $headers');
      
      final response = await dioClient.dio.get(
        RoleEndpoints.roles,
        options: Options(headers: headers),
      );
      
      print('PermissionService: API yanıtı alındı');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final roles = data.map((item) => Role.fromMap(item)).toList();
        print('PermissionService: ${roles.length} rol başarıyla yüklendi');
        return Right(roles);
      } else {
        print('PermissionService: API hatası - ${response.statusCode}');
        return Left(NetworkFailure(message: 'API hatası: ${response.statusCode}'));
      }
    } catch (e) {
      print('PermissionService: Beklenmeyen hata - $e');
      return Left(NetworkFailure(message: 'Roller çekme hatası: $e'));
    }
  }

  // Kullanıcının rolünü yükle
  Future<Either<Failure, Role>> loadUserRole(String roleId) async {
    try {
      print('PermissionService: Rol yükleme başlatıldı - RoleID: $roleId');
      
      // Önce tüm rolleri çek
      final allRolesResult = await getAllRoles();
      
      return allRolesResult.fold(
        (failure) {
          print('PermissionService: Roller çekilemedi - ${failure.message}');
          return Left(failure);
        },
        (allRoles) {
          print('PermissionService: ${allRoles.length} rol çekildi');
          
          // getUserInfo rollerinde id olmayabilir; role_admin koduyla da eşleş.
          Role? foundRole;
          for (final role in allRoles) {
            print('  - Kontrol edilen rol: ID=${role.id}, Name=${role.name}, Code=${role.code}');
            if (role.id == roleId || role.code == roleId) {
              foundRole = role;
              break;
            }
          }
          
          if (foundRole == null) {
            print('PermissionService: Role ID $roleId bulunamadı');
            print('Mevcut roller:');
            for (final role in allRoles) {
              print('  - ID: ${role.id}, Name: ${role.name}, Code: ${role.code}');
            }
            return Left(NetworkFailure(message: 'Role ID $roleId bulunamadı'));
          }
          
          print('PermissionService: Rol yükleme BAŞARILI');
          print('  - Rol Adı: ${foundRole.name}');
          print('  - Rol Seviyesi: ${foundRole.level}');
          print('  - Role Code: ${foundRole.code}');
          print('  - İzin Sayısı: ${foundRole.permissions.length}');
          
          _currentRole = foundRole;
          _buildPermissionCache(foundRole);
          
          // İzinleri logla
          for (final permission in foundRole.permissions) {
            print('  - İzin: ${permission.resource}:${permission.action}');
          }
          
          return Right(foundRole);
        },
      );
    } catch (e) {
      print('PermissionService: Beklenmeyen hata - $e');
      return Left(NetworkFailure(message: 'Rol yükleme hatası: $e'));
    }
  }

  // Permission map - getPermissions() ile izin haritası
  Map<String, bool> getPermissions() {
    return Map.unmodifiable(_permissionCache);
  }

  // Rol check - roleStatu() ile izin kontrolü
  bool roleStatu(String resource, String action) {
    final key = '$resource:$action';
    return _permissionCache[key] ?? false;
  }

  // Action vs List - Eylem izni vs görüntüleme izni
  bool canPerformAction(String resource) {
    return roleStatu(resource, 'create') || 
           roleStatu(resource, 'update') || 
           roleStatu(resource, 'delete');
  }

  bool canViewList(String resource) {
    return roleStatu(resource, 'read') || roleStatu(resource, 'list');
  }

  // Belirli kaynağa tam erişim kontrolü
  bool hasFullAccess(String resource) {
    return roleStatu(resource, 'create') &&
           roleStatu(resource, 'read') &&
           roleStatu(resource, 'update') &&
           roleStatu(resource, 'delete');
  }

  /// getUserInfo `is_admin` bayrağı. Rol listesi id ile eşleşmese de admin sayılır.
  void setSessionAdmin(bool value) {
    _sessionAdmin = value;
  }

  // Yönetici kontrolü
  bool get isAdmin =>
      _sessionAdmin ||
      _currentRole?.code == 'role_admin' ||
      _currentRole?.level == 10;
  bool get isManager => (_currentRole?.level ?? 0) >= 7;
  bool get isAgent => (_currentRole?.level ?? 0) >= 5;

  // Rol seviyesi kontrolü
  bool hasMinimumLevel(int level) {
    return (_currentRole?.level ?? 0) >= level;
  }

  // İzin cache'ini oluştur
  void _buildPermissionCache(Role role) {
    _permissionCache.clear();
    
    for (final permission in role.permissions) {
      final key = '${permission.resource}:${permission.action}';
      _permissionCache[key] = true;
    }
  }

  // JWT token'dan rol ID'sini çıkar
  Future<String?> _extractRoleFromToken() async {
    try {
      // LoginRepository'den kayıtlı roleId'yi al
      final LoginRepository loginRepo = LoginRepository();
      final roleId = await loginRepo.getStoredRoleId();
      print('Token\'dan çıkarılan roleId: $roleId');
      return roleId;
    } catch (e) {
      print('Token\'dan roleId çıkarma hatası: $e');
      return _currentRole?.id;
    }
  }

  // İzinleri temizle
  void clearPermissions() {
    _currentRole = null;
    _permissionCache.clear();
    _sessionAdmin = false;
  }

  // Mevcut rol
  Role? get currentRole => _currentRole;

  // Rol yüklü mü kontrolü
  bool get isRoleLoaded => _currentRole != null;

  // Debug için izin listesi
  List<String> getGrantedPermissions() {
    return _permissionCache.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  // Kaynak bazlı izin listesi
  Map<String, List<String>> getPermissionsByResource() {
    final resourcePermissions = <String, List<String>>{};
    
    for (final entry in _permissionCache.entries) {
      if (entry.value) {
        final parts = entry.key.split(':');
        if (parts.length == 2) {
          final resource = parts[0];
          final action = parts[1];
          
          resourcePermissions.putIfAbsent(resource, () => []).add(action);
        }
      }
    }
    
    return resourcePermissions;
  }
} 