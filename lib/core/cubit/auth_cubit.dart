import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repositories/base_repository.dart';
import '../../infrastructure/login/login_repository.dart';
import '../../infrastructure/role/role_repository.dart';
import '../models/user_model.dart';
import '../models/permission_model.dart';
import '../../models/login/login_model.dart';
import '../config/api_config.dart';
import '../services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/widgets/role-sidebar/role_sidebar.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> with BaseRepository {
  final PermissionService _permissionService = PermissionService();
  final LoginRepository _loginRepository = LoginRepository();
  final RoleRepository _roleRepository = RoleRepository();
  int _signInSerial = 0;
  
  AuthCubit() : super(AuthInitial());

  // Kayıtlı oturum varsa aç. Çıkış yalnız kullanıcının kendi isteğiyle olur.
  Future<void> initializeAuth() async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final restored = await _loginRepository.restoreAuthenticatedUserIfValid();
      if (restored != null) {
        print('Auth: Kayıtlı oturum geri yüklendi (${restored.email})');
        await _loadUserPermissions(restored.role);
        await _loginRepository.debugPrintStoredRoleCodes();
        emit(AuthAuthenticated(restored));
        return;
      }

      print('Auth: Geçerli oturum yok — giriş gerekli');
      emit(AuthUnauthenticated());
    } catch (e) {
      print('Auth initialization hatası: $e');
      emit(AuthUnauthenticated());
    }
  }

  // Sign in with LoginRepository
  Future<void> signIn(
    String email,
    String password,
  ) async {
    final serial = ++_signInSerial;
    emit(AuthLoading());
    
    try {
      final loginModel = LoginAuthentication(
        email: ValueNotNull(email),
        password: ValueNotNull(password),
      );
      
      final result = await _loginRepository.login(loginModel);
      
      result.fold(
        (failure) {
          if (serial != _signInSerial) return;
          emit(AuthError(failure.message));
        },
        (success) async {
          if (serial != _signInSerial) return;
          _permissionService.clearPermissions();
          RoleSidebar.clearSidebarCache();
          // Login başarılı - user bilgilerini SharedPreferences'ten al
          try {
            final pref = await SharedPreferences.getInstance();
            if (serial != _signInSerial) return;
            
            final userId = pref.getString('userID') ?? '1';
            final userName = pref.getString('userName') ?? '';
            final userSurname = pref.getString('userSurname') ?? '';
            final userEmail = pref.getString('userEmail') ?? email;
            final userPhone = pref.getString('userPhone') ?? '';
            final userType = pref.getString('userType') ?? '1';
            final userTypeDescription = pref.getString('userTypeDescription') ?? '';
            final roleId = pref.getString('roleId') ?? userType;
            
            final user = UserModel(
              id: userId,
              email: userEmail,
              fullName: '$userName $userSurname'.trim(),
              phone: userPhone,
              role: roleId,
              isActive: true,
              createdAt: DateTime.now(),
              profileImageUrl: '',
            );
            
            print('User oluşturuldu: ${user.fullName} ($userTypeDescription)');
            print('Role ID: $roleId');
            if (serial != _signInSerial) return;
            
            // Kullanıcının rolünü yükle
            await _loadUserPermissions(roleId);
            if (serial != _signInSerial) return;
            
            // Debug için kayıtlı role kodlarını yazdır
            await _loginRepository.debugPrintStoredRoleCodes();
            
            emit(AuthAuthenticated(user));
          } catch (e) {
            print('User bilgileri okuma hatası: $e');
            if (serial != _signInSerial) return;
            // Hata durumunda geçici user oluştur
            final user = UserModel(
              id: '1',
              email: email,
              fullName: '',
              phone: '',
              role: '1',
              isActive: true,
              createdAt: DateTime.now(),
              profileImageUrl: '',
            );
            emit(AuthAuthenticated(user));
          }
        },
      );
    } catch (e) {
      emit(AuthError('Beklenmeyen hata: $e'));
    }
  }

  // Sign up (eski metod - gerekirse güncellenebilir)
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    emit(AuthLoading());
    
    final result = await handleApiCall(() => dioClient.post<Map<String, dynamic>>(
      AuthEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'role': role,
      },
    ));
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (response) async {
        final userData = response['user'];
        if (userData != null) {
          final user = UserModel.fromMap(userData);
          
          // Load user permissions
          await _loadUserPermissions(user.role);
          
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthError('Kayıt başarısız'));
        }
      },
    );
  }

  // Sign out with LoginRepository
  Future<void> signOut() async {
    _signInSerial++;
    emit(AuthLoading());
    
    try {
      // LoginRepository ile çıkış yap
      await _loginRepository.logout();

      // Permission servisini temizle
      _permissionService.clearPermissions();
      RoleSidebar.clearSidebarCache();

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Çıkış yapılırken hata oluştu: $e'));
    }
  }

  /// JWT süresi dolduğunda veya API 401 döndüğünde (Dio köprüsü); tercihen login ekranına yönlendirilir.
  Future<void> onSessionExpiredFromServer() async {
    _signInSerial++;
    if (state is AuthUnauthenticated) return;
    try {
      await _loginRepository.logout();
      _permissionService.clearPermissions();
      RoleSidebar.clearSidebarCache();
    } catch (_) {}
    emit(AuthUnauthenticated());
  }

  // Reset password (eski metod - gerekirse güncellenebilir)
  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    
    final result = await handleApiCall(() => dioClient.post(
      AuthEndpoints.resetPassword,
      data: {'email': email},
    ));
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthPasswordResetSent()),
    );
  }

  // Update user profile (eski metod - gerekirse güncellenebilir)
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      emit(AuthLoading());
      
      final result = await handleApiCall(() => dioClient.put<UserModel>(
        AuthEndpoints.profile,
        data: data,
        fromJson: (responseData) => UserModel.fromMap(responseData),
      ));
      
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (updatedUser) async {
          // Reload permissions if role changed
          if (updatedUser.role != currentUser.role) {
            await _loadUserPermissions(updatedUser.role);
          }
          emit(AuthAuthenticated(updatedUser));
        },
      );
    }
  }

  // Load user permissions from API
  Future<void> _loadUserPermissions(String roleId) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final sessionAdmin = pref.getBool('userIsAdmin') == true;
      _permissionService.setSessionAdmin(sessionAdmin);
      print('API\'den rol bilgisi yükleniyor... RoleID: $roleId (admin: $sessionAdmin)');
      
      // API'den kullanıcının rolünü çek
      final result = await _permissionService.loadUserRole(roleId);
      
      result.fold(
        (failure) {
          print('Rol yükleme hatası: ${failure.message}');
          // Rol yüklenemese bile devam et, sadece temel yetkileri ver
        },
        (role) {
          print('Rol başarıyla yüklendi: ${role.name} (Level: ${role.level})');
          print('Role Code: ${role.code}');
          print('İzinler: ${role.permissions.length} adet');
          
          // Role detaylarını logla
          print('Role detayları:');
          print('  - ID: ${role.id}');
          print('  - Name: ${role.name}');
          print('  - Code: ${role.code}');
          print('  - Level: ${role.level}');
          print('  - Permissions: ${role.permissions.length}');
        },
      );
      
    } catch (e) {
      print('Rol yükleme sırasında hata: $e');
      // Hata durumunda bile devam et
    }
  }

  // Clear error
  void clearError() {
    if (state is AuthError) {
      emit(AuthUnauthenticated());
    }
  }

  // Get current user
  UserModel? get currentUser {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user;
    }
    return null;
  }

  // Check if authenticated
  bool get isAuthenticated => state is AuthAuthenticated;

  // Get current role
  String? get currentRole => currentUser?.role;
  
  // Get current role object
  Role? get currentRoleObject => _permissionService.currentRole;
  
  // Check if user has permission
  bool hasPermission(String resource, String action) {
    return _permissionService.roleStatu(resource, action);
  }
  
  // Check if user can perform action
  bool canPerformAction(String resource) {
    return _permissionService.canPerformAction(resource);
  }
  
  // Check if user can view list
  bool canViewList(String resource) {
    return _permissionService.canViewList(resource);
  }
  
  // Check if user has full access
  bool hasFullAccess(String resource) {
    return _permissionService.hasFullAccess(resource);
  }
  
  // Role level checks
  bool get isAdmin => _permissionService.isAdmin;
  bool get isManager => _permissionService.isManager;
  bool get isAgent => _permissionService.isAgent;
  
  // Role code checks - Web projesindeki mantığa göre
  bool get isRoleAdmin => _permissionService.currentRole?.code == 'role_admin';
  bool get isRoleAdvisor => _permissionService.currentRole?.code == 'role_advisor';
  bool get isRoleOfficeBroker => _permissionService.currentRole?.code == 'role_office_broker';
  bool get isRoleOfficeAssistant => _permissionService.currentRole?.code == 'role_office_assistant';
  bool get isRoleFormApplications => _permissionService.currentRole?.code == 'role_form_applications';
  bool get isRoleFormApplicationsAdmin => _permissionService.currentRole?.code == 'role_form_applications_admin';
  bool get isRoleSaleApplications => _permissionService.currentRole?.code == 'role_sale_applications';
  bool get isRoleSaleApplicationsAdmin => _permissionService.currentRole?.code == 'role_sale_applications_admin';
  
  // Get current role code
  String? get currentRoleCode => _permissionService.currentRole?.code;
  
  // Get all role codes (for includes check like in web)
  List<String> get allRoleCodes {
    final role = _permissionService.currentRole;
    if (role?.code != null) {
      return [role!.code!];
    }
    return [];
  }
  
  // Check if role includes specific role (like web project)
  bool hasRole(String roleCode) {
    return allRoleCodes.contains(roleCode);
  }
  
  // Web projesindeki mantığa göre kullanıcı tipini belirle
  Future<String> getUserType() async {
    final currentUser = this.currentUser;
    if (currentUser == null) return 'default';
    
    final userId = int.tryParse(currentUser.id) ?? 0;
    final result = await _roleRepository.getUserType(userId);
    
    return result.fold(
      (failure) {
        print('AuthCubit: Kullanıcı tipi belirleme hatası: ${failure.message}');
        return 'default';
      },
      (userType) {
        print('AuthCubit: Kullanıcı tipi: $userType');
        return userType;
      },
    );
  }
  
  // Web projesindeki mantığa göre office ID'yi getir
  Future<int?> getOfficeId() async {
    final currentUser = this.currentUser;
    if (currentUser == null) return null;
    
    final userId = int.tryParse(currentUser.id) ?? 0;
    final result = await _roleRepository.getUserOfficeId(userId);
    
    return result.fold(
      (failure) {
        print('AuthCubit: Office ID getirme hatası: ${failure.message}');
        return null;
      },
      (officeId) => officeId,
    );
  }
  
  // Web projesindeki mantığa göre advisor ID'yi getir
  Future<int?> getAdvisorId() async {
    final currentUser = this.currentUser;
    if (currentUser == null) return null;
    
    final userId = int.tryParse(currentUser.id) ?? 0;
    final result = await _roleRepository.getUserAdvisorId(userId);
    
    return result.fold(
      (failure) {
        print('AuthCubit: Advisor ID getirme hatası: ${failure.message}');
        return null;
      },
      (advisorId) => advisorId,
    );
  }
  
  // Web projesindeki mantığa göre kullanıcının rollerini kontrol et
  Future<bool> checkUserRole(String roleCode) async {
    final currentUser = this.currentUser;
    if (currentUser == null) return false;
    
    final userId = int.tryParse(currentUser.id) ?? 0;
    final result = await _roleRepository.hasRole(userId, roleCode);
    
    return result.fold(
      (failure) {
        print('AuthCubit: Role kontrolü hatası: ${failure.message}');
        return false;
      },
      (hasRole) => hasRole,
    );
  }
  
  // Web projesindeki mantığa göre kullanıcının tüm rollerini getir
  Future<List<String>> getUserRoleCodes() async {
    final currentUser = this.currentUser;
    if (currentUser == null) return [];
    
    // Önce SharedPreferences'den role kodlarını dene
    final storedRoleCodes = await _getStoredUserRoleCodes();
    if (storedRoleCodes.isNotEmpty) {
      print('AuthCubit: SharedPreferences\'den role kodları alındı: $storedRoleCodes');
      return storedRoleCodes;
    }
    
    // SharedPreferences'de yoksa API'den dene
    final userId = int.tryParse(currentUser.id) ?? 0;
    final result = await _roleRepository.getUserRoleCodes(userId);
    
    return result.fold(
      (failure) {
        print('AuthCubit: Role kodları getirme hatası: ${failure.message}');
        // Son çare olarak mevcut role'ü döndür
        final currentRole = _permissionService.currentRole;
        if (currentRole?.code != null) {
          print('AuthCubit: Mevcut role code döndürülüyor: ${currentRole!.code}');
          return [currentRole.code!];
        }
        return [];
      },
      (roleCodes) {
        print('AuthCubit: API\'den role kodları alındı: $roleCodes');
        return roleCodes;
      },
    );
  }
  
  // SharedPreferences'den kayıtlı role kodlarını getir
  Future<List<String>> _getStoredUserRoleCodes() async {
    final result = await _roleRepository.getStoredUserRoleCodes();
    return result.fold(
      (failure) {
        print('AuthCubit: Kayıtlı role kodları getirme hatası: ${failure.message}');
        return [];
      },
      (roleCodes) => roleCodes,
    );
  }
  
  // Web projesindeki mantığa göre kullanıcı tipini belirle (SharedPreferences'den)
  Future<String> getStoredUserType() async {
    final result = await _roleRepository.getStoredUserType();
    return result.fold(
      (failure) {
        print('AuthCubit: Kayıtlı kullanıcı tipi getirme hatası: ${failure.message}');
        return 'default';
      },
      (userType) => userType,
    );
  }
  
  // Web projesindeki mantığa göre office ID'yi getir (SharedPreferences'den)
  Future<int?> getStoredOfficeId() async {
    final result = await _roleRepository.getStoredOfficeId();
    return result.fold(
      (failure) {
        print('AuthCubit: Kayıtlı office ID getirme hatası: ${failure.message}');
        return null;
      },
      (officeId) => officeId,
    );
  }
  
  // Web projesindeki mantığa göre advisor ID'yi getir (SharedPreferences'den)
  Future<int?> getStoredAdvisorId() async {
    final result = await _roleRepository.getStoredAdvisorId();
    return result.fold(
      (failure) {
        print('AuthCubit: Kayıtlı advisor ID getirme hatası: ${failure.message}');
        return null;
      },
      (advisorId) => advisorId,
    );
  }

  /// get-user-info `type_description`. Rol kodu `role_franchise_sales` başka
  /// franchise tipleriyle ortak; bu unvan director paneline gider.
  static const String franchiseRegionDirectorType =
      'Franchise Saha ve Geliştirme Bölge Yöneticisi';

  static bool isFranchiseRegionDirector(String? typeDescription) {
    final normalized = (typeDescription ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    return normalized == franchiseRegionDirectorType.toLowerCase();
  }

  /// İşlem bildirimi onayları yalnız broker rütbesine açık.
  /// Ofis asistanı ve danışman bu rütbe sayılmaz.
  static bool isBrokerRank({
    List<String> roleCodes = const [],
    String? typeDescription,
  }) {
    if (roleCodes.contains('role_office_broker')) return true;
    final normalized = (typeDescription ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    return normalized == 'broker';
  }

  // Web sitesindeki mantığa göre dashboard seçimi
  Future<String> getDashboardRoute() async {
    final userRoleCodes = await getUserRoleCodes();
    final officeId = await getStoredOfficeId();
    final advisorId = await getStoredAdvisorId();
    final pref = await SharedPreferences.getInstance();
    final typeDescription = pref.getString('userTypeDescription') ?? '';
    
    final sessionAdmin = pref.getBool('userIsAdmin') == true;
    
    print('AuthCubit: Dashboard seçimi - Role Codes: $userRoleCodes, Office ID: $officeId, Advisor ID: $advisorId, Type: $typeDescription, Admin: $sessionAdmin');
    
    // is_admin true ise admin paneli. Değilse eski rol sırası.
    if (sessionAdmin) {
      print('AuthCubit: Admin dashboard seçildi (is_admin)');
      return '/dashboard'; // AdminMain
    } else if (isFranchiseRegionDirector(typeDescription)) {
      print('AuthCubit: Director dashboard seçildi (bölge yöneticisi)');
      return '/director-dashboard';
    } else if (userRoleCodes.contains('role_accountant')) {
      print('AuthCubit: Muhasebe dashboard seçildi (accountant)');
      return '/accounting-dashboard'; // AccountingDashboard
    } else if (userRoleCodes.contains('role_advisor') || advisorId != null) {
      print('AuthCubit: Advisor dashboard seçildi (advisor)');
      return '/danisman-dashboard'; // AdvisorMain
    } else if (userRoleCodes.contains('role_office_broker') ||
        userRoleCodes.contains('role_office_assistant')) {
      print('AuthCubit: Office dashboard seçildi (office)');
      return '/broker-dashboard'; // OfficeMain
    } else if (userRoleCodes.contains('role_franchise_sales')) {
      print('AuthCubit: Franchise dashboard seçildi (franchise_sales)');
      return '/franchise-dashboard'; // FranchiseDashboard
    } else if (userRoleCodes.contains('role_form_applications') || 
               userRoleCodes.contains('role_form_applications_admin')) {
      print('AuthCubit: Form applications dashboard seçildi - franchise dashboard kullanılıyor');
      return '/franchise-dashboard'; // Form applications için franchise dashboard (başvuru formları içeriği)
    } else if (userRoleCodes.contains('role_sale_applications') || 
               userRoleCodes.contains('role_sale_applications_admin')) {
      print('AuthCubit: Sale applications dashboard seçildi');
      return '/broker-dashboard'; // Sale applications için broker dashboard
    }
    
    print('AuthCubit: Varsayılan dashboard seçildi');
    return '/broker-dashboard'; // Varsayılan
  }
  
  // Check minimum level
  bool hasMinimumLevel(int level) {
    return _permissionService.hasMinimumLevel(level);
  }
  
  // Get all permissions
  Map<String, bool> getPermissions() {
    return _permissionService.getPermissions();
  }
  
  // Get granted permissions list
  List<String> getGrantedPermissions() {
    return _permissionService.getGrantedPermissions();
  }
  
  // Check if role is loaded
  bool get isRoleLoaded => _permissionService.isRoleLoaded;
} 