import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/dashboard/broker_dashboard_screen.dart';
import '../../screens/dashboard/admin_dashboard_screen.dart';
import '../../screens/dashboard/danisman_dashboard_screen.dart';
import '../../screens/dashboard/franchaise_dashboard_screen.dart';
import '../../screens/tilan/tum_ilan_screen.dart';
import '../../screens/pay/pay_screen.dart';
import '../../screens/srapor/srapor_screen.dart';
import '../../screens/reports/report_theme.dart';
import '../../screens/reports/reports_screen.dart';
import '../../../core/auth/auth_session_storage.dart';
import '../../../core/cubit/auth_cubit.dart';
import '../../../core/cubit/user_profile_cubit.dart';
import '../../../core/cubit/user_profile_state.dart';
import '../../../infrastructure/role/role_repository.dart';
import '../../../infrastructure/users/users_repository.dart';
import '../../../models/users/users_model.dart';
import '../../../router/app_router.dart';

// Menu Item Model
class MenuItem {
  final IconData icon;
  final String title;
  final String route;
  final dynamic permission; // String or List<String>
  final List<MenuItem>? subRoutes;
  final int? notification;

  MenuItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.permission,
    this.subRoutes,
    this.notification,
  });
}

/// Eski rol kodları, web’deki permission string’iyle aynı kapıyı açar.
const Map<String, List<String>> _permissionRoleAliases = {
  'form_applications.view': ['role_form_applications'],
  'form_applications.admin': ['role_form_applications_admin'],
  'sale_applications.view': ['role_sale_applications'],
  'sale_applications.list': ['role_sale_applications'],
  'sale_applications.admin': ['role_sale_applications_admin'],
  'sale_applications.delete': ['role_sale_applications_admin'],
};

/// Web SideMenu `havePermission` ile aynı: `any` herkese açık,
/// `admin_only` yalnız admin, `role_*` rol kodu, liste ise biri yeter.
/// İzin listesi henüz yoksa rol menüsü gizlenmez.
bool menuPermissionAllows({
  required dynamic permission,
  required bool isAdmin,
  required Iterable<String> roleCodes,
  required Iterable<String> permissions,
  required bool enforcePermissions,
}) {
  if (permission == null) return false;
  if (permission == 'any') return true;
  if (isAdmin) return true;
  if (permission == 'admin_only') return false;

  bool matchesOne(String perm) {
    if (perm == 'any') return true;
    if (perm == 'admin_only') return false;
    if (perm.startsWith('role_')) {
      return roleCodes.contains(perm) || permissions.contains(perm);
    }
    if (permissions.contains(perm) || roleCodes.contains(perm)) return true;
    final aliases = _permissionRoleAliases[perm];
    if (aliases == null) return false;
    for (final role in aliases) {
      if (roleCodes.contains(role) || permissions.contains(role)) return true;
    }
    return false;
  }

  if (!enforcePermissions) {
    if (permission is String && permission.startsWith('role_')) {
      return roleCodes.contains(permission) || permissions.contains(permission);
    }
    if (permission is List) {
      final hasConcrete = permission.any(
        (perm) => perm is String && perm != 'admin_only' && perm != 'any' && !perm.startsWith('role_'),
      );
      if (hasConcrete) return true;
      for (final perm in permission) {
        if (perm is String && matchesOne(perm)) return true;
      }
      return false;
    }
    return true;
  }

  if (permission is String) return matchesOne(permission);
  if (permission is List) {
    for (final perm in permission) {
      if (perm is String && matchesOne(perm)) return true;
    }
    return false;
  }
  return false;
}

class RoleSidebar extends StatefulWidget {
  final String currentPage;

  const RoleSidebar({
    super.key,
    required this.currentPage,
  });

  /// Sayfa içi aksiyonlar (durum ekle/sil) sidebar ile aynı izin listesini kullanır.
  static bool allows(dynamic permission, {required bool isAdmin, required Iterable<String> roleCodes, required Iterable<String> permissions}) {
    final cachedRoles = _RoleSidebarState._cachedUserRoleCodes ?? const <String>[];
    final cachedPermissions = _RoleSidebarState._cachedUserPermissions ?? const <String>[];
    return menuPermissionAllows(
      permission: permission,
      isAdmin: isAdmin || _RoleSidebarState._cachedIsAdminUser,
      roleCodes: {...roleCodes, ...cachedRoles},
      permissions: {...permissions, ...cachedPermissions},
      enforcePermissions: true,
    );
  }

  @override
  State<RoleSidebar> createState() => _RoleSidebarState();

  /// Çıkış veya oturum düşüşünde önceki kullanıcının sidebar önbelleğini temizler.
  static void clearSidebarCache() {
    _RoleSidebarState._cachedUserRoleCodes = null;
    _RoleSidebarState._cachedUserPermissions = null;
    _RoleSidebarState._cachedUserEmail = null;
    _RoleSidebarState._cachedUserTypeDescription = null;
    _RoleSidebarState._cachedIsAdminUser = false;
    _RoleSidebarState._isDataLoaded = false;
    _RoleSidebarState._isLoadingInBackground = false;
  }

  // Sidebar verilerini yüklemek için static metod
  static Future<void> preloadSidebarData(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final currentUser = authCubit.currentUser;
    final currentUserEmail = currentUser?.email;

    // Eğer kullanıcı değiştiyse cache'i temizle
    if (_RoleSidebarState._cachedUserEmail != null && 
        _RoleSidebarState._cachedUserEmail != currentUserEmail) {
      _RoleSidebarState._cachedUserRoleCodes = null;
      _RoleSidebarState._cachedUserPermissions = null;
      _RoleSidebarState._cachedUserEmail = null;
      _RoleSidebarState._cachedUserTypeDescription = null;
      _RoleSidebarState._isDataLoaded = false;
      print('🔄 Kullanıcı değişti, cache temizlendi');
    }

    // Verileri arka planda yükle
    await _RoleSidebarState._loadSidebarDataInBackground(context);
  }
}

class _RoleSidebarState extends State<RoleSidebar> {
  String _selectedItem = 'Ana Sayfa';
  bool _isPersonsExpanded = false;
  // bool _isSystemSettingsExpanded = false; // Sistem Ayarları geçici olarak devre dışı
  bool _isMuhasebeExpanded = false;
  bool _isPortfolioExpanded = false;
  bool _isCustomersExpanded = false;
  bool _isKuponlarExpanded = false;
  bool _isBformExpanded = false;
  bool _isSeminarExpanded = false;
  bool _isRaporlarExpanded = false;
  bool _isTransactionsExpanded = false;
  bool _didFocusCurrentPage = false;
  
  List<String> _userRoleCodes = [];
  List<String> _userPermissions = [];
  String? _userEmail;
  String? _userTypeDescription;
  bool _isAdminUser = false;

  // Scroll controller for scrolling to active item
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  // Cache için static değişkenler
  static List<String>? _cachedUserRoleCodes;
  static List<String>? _cachedUserPermissions;
  static String? _cachedUserEmail;
  static String? _cachedUserTypeDescription;
  static bool _cachedIsAdminUser = false;
  static bool _isDataLoaded = false;
  static bool _isLoadingInBackground = false;
  static final List<Function()> _updateCallbacks = [];

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.currentPage;
    _isPersonsExpanded =
        widget.currentPage == 'Ofisler' || widget.currentPage == 'Kişiler' || widget.currentPage == 'Tüm Kişiler' || widget.currentPage == 'Onay Bekleyen Kişiler';
    _isMuhasebeExpanded =
        widget.currentPage == 'Faturalar' || widget.currentPage == 'Havale Onayları' || widget.currentPage == 'Muhasebe';
    _isPortfolioExpanded =
        widget.currentPage == 'Portföyüm' || widget.currentPage == 'Tüm Portföylerler' || widget.currentPage == 'Portföy Onay';
    _isCustomersExpanded =
        widget.currentPage == 'Müşteriler' || widget.currentPage == 'Tüm Müşteriler' || widget.currentPage == 'Alıcılar' || widget.currentPage == 'Satıcılar' || widget.currentPage == 'Potansiyel Müşteriler';
    _isKuponlarExpanded =
        widget.currentPage == 'Kuponlar' || widget.currentPage == 'Kupon Şablonları';
    _isBformExpanded = _isBformSection(widget.currentPage);
    _isSeminarExpanded = _isSeminarSection(widget.currentPage);
    _isRaporlarExpanded = _isReportsSection(widget.currentPage);
    _isTransactionsExpanded = _isTransactionsSection(widget.currentPage);

    _loadFromCache();
    _updateCallbacks.add(_updateFromCache);
    _scheduleFocusCurrentPage();
  }
  
  void _scheduleFocusCurrentPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusCurrentPage(0);
    });
  }

  /// Drawer açılınca bulunulan madde görünsün. Kaydırma animasyonu yok;
  /// menü verisi bir kare geç gelse de birkaç kare daha dener.
  void _focusCurrentPage(int attempt) {
    if (!mounted || _didFocusCurrentPage) return;
    final context = _contextForPage(_selectedItem);
    final canScroll = _scrollController.hasClients &&
        _scrollController.position.hasContentDimensions &&
        _scrollController.position.viewportDimension > 0;
    if (context == null || !canScroll) {
      if (attempt < 12) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusCurrentPage(attempt + 1);
        });
      }
      return;
    }
    _didFocusCurrentPage = true;
    Scrollable.ensureVisible(
      context,
      duration: Duration.zero,
      alignment: 0.12,
    );
  }

  BuildContext? _contextForPage(String title) {
    final direct = _itemKeys[title]?.currentContext;
    if (direct != null) return direct;
    final suffix = '::$title';
    for (final entry in _itemKeys.entries) {
      if (entry.key.endsWith(suffix)) {
        final childContext = entry.value.currentContext;
        if (childContext != null) return childContext;
      }
    }
    return null;
  }

  @override
  void dispose() {
    // Callback'i kaldır
    _updateCallbacks.remove(_updateFromCache);
    _scrollController.dispose();
    super.dispose();
  }

  // Cache'den verileri yükle. initState içinde setState yok; ilk kare tam menüyle gelir.
  void _loadFromCache() {
    if (_isDataLoaded && _cachedUserRoleCodes != null && _cachedUserPermissions != null) {
      _userRoleCodes = List<String>.from(_cachedUserRoleCodes!);
      _userPermissions = List<String>.from(_cachedUserPermissions!);
      _userEmail = _cachedUserEmail;
      _userTypeDescription = _cachedUserTypeDescription;
      _isAdminUser = _cachedIsAdminUser;
      print('✅ Sidebar verileri cache\'den yüklendi');
    } else {
      _userRoleCodes = [];
      _userPermissions = [];
      _userEmail = null;
      _userTypeDescription = null;
      _isAdminUser = false;
      print('ℹ️ Sidebar cache\'de veri yok, boş gösteriliyor');
    }
  }

  // Cache güncellendiğinde çağrılacak callback
  void _updateFromCache() {
    if (mounted && _isDataLoaded && _cachedUserRoleCodes != null && _cachedUserPermissions != null) {
      setState(() {
        _userRoleCodes = _cachedUserRoleCodes!;
        _userPermissions = _cachedUserPermissions!;
        _userEmail = _cachedUserEmail;
        _userTypeDescription = _cachedUserTypeDescription;
        _isAdminUser = _cachedIsAdminUser;
      });
      print('✅ Sidebar verileri cache\'den güncellendi');
      _scheduleFocusCurrentPage();
    }
  }

  // Static metod - dashboard açıldığında çağrılacak
  static Future<void> _loadSidebarDataInBackground(BuildContext context) async {
    // Eğer zaten yükleniyorsa, tekrar başlatma
    if (_isLoadingInBackground) {
      print('⏳ Sidebar verileri zaten yükleniyor...');
      return;
    }

    _isLoadingInBackground = true;
    final generation = AuthSessionStorage.sessionGeneration;
    print('🔄 Sidebar verileri arka planda yükleniyor...');

    try {
      final authCubit = context.read<AuthCubit>();
      final currentUser = authCubit.currentUser;
      final currentUserEmail = currentUser?.email;
      
      // Get role codes
      var userRoleCodes = await authCubit.getUserRoleCodes();
      
      // Get user email for super admin check
      final userEmail = currentUserEmail;

      final prefs = await SharedPreferences.getInstance();
      var typeDescription = prefs.getString('userTypeDescription') ?? '';
      
      // Collect all permissions from multiple sources
      final allPermissions = <String>{};
      // Yalnızca getUserInfo is_admin. Rol kodu bunu açmaz.
      var isAdminUser = prefs.getBool('userIsAdmin') == true;

      // 1. Try to get permissions from UserProfileCubit
      try {
        final userProfileCubit = context.read<UserProfileCubit>();
        await userProfileCubit.loadUserProfile();
        
        if (userProfileCubit.state is UserProfileLoaded) {
          final userProfile = (userProfileCubit.state as UserProfileLoaded).userProfile;
          allPermissions.addAll(userProfile.permissions);
          final profileType = userProfile.typeDescription.trim();
          if (profileType.isNotEmpty) typeDescription = profileType;
          isAdminUser = userProfile.isAdmin;
          final apiCodes = userProfile.roles
              .map((role) => role.code)
              .where((code) => code.isNotEmpty)
              .toList();
          if (!userProfile.isAdmin) {
            apiCodes.remove('role_admin');
          }
          if (apiCodes.isNotEmpty) {
            userRoleCodes = apiCodes;
          }
          print('✅ Permissions from UserProfile: ${userProfile.permissions.length}');
        }
      } catch (e) {
        print('⚠️ Error loading from UserProfileCubit: $e');
      }
      
      // 2. Try to get permissions from roles in current user (if available)
      try {
        final prefs = await SharedPreferences.getInstance();
        final contactNoStr = prefs.getString('userID');
        final contactNo = int.tryParse(contactNoStr ?? '') ?? 0;
        
        if (contactNo > 0 || userEmail != null) {
          final usersRepository = UsersRepository();
          final result = await usersRepository.getUsers(page: 1, limit: 100);
          
          result.fold(
            (failure) {
              print('⚠️ Error getting users: ${failure.message}');
            },
            (usersResponse) {
              UserModel? currentUserData;
              try {
                if (contactNo > 0) {
                  currentUserData = usersResponse.users.firstWhere(
                    (user) => user.contactNo == contactNo,
                  );
                } else if (userEmail != null) {
                  currentUserData = usersResponse.users.firstWhere(
                    (user) => user.email == userEmail,
                  );
                }
              } catch (e) {
                print('⚠️ Current user not found in users list: $e');
              }
              
              if (currentUserData != null) {
                for (final role in currentUserData.roles) {
                  if (role.permissions != null && role.permissions!.isNotEmpty) {
                    allPermissions.addAll(role.permissions!);
                    print('✅ Permissions from role ${role.code}: ${role.permissions!.length}');
                  }
                }
              }
            },
          );
        }
      } catch (e) {
        print('⚠️ Error getting permissions from users API: $e');
      }
      
      // 3. Try to get permissions from SharedPreferences or RoleRepository API
      final additionalPermissions = await _getPermissionsFromRolesStatic(context);
      allPermissions.addAll(additionalPermissions);
      
      final userPermissions = allPermissions.toList();
      print('✅ Total permissions loaded: ${userPermissions.length}');

      if (!context.mounted || !AuthSessionStorage.isCurrent(generation)) return;
      if (context.read<AuthCubit>().currentUser?.email != currentUserEmail) {
        return;
      }
      
      // Verileri cache'e kaydet
      _cachedUserRoleCodes = userRoleCodes;
      _cachedUserPermissions = userPermissions;
      _cachedUserEmail = userEmail;
      _cachedUserTypeDescription = typeDescription;
      _cachedIsAdminUser = isAdminUser;
      _isDataLoaded = true;
      print('✅ Sidebar verileri cache\'e kaydedildi');
      
      // Tüm aktif sidebar instance'larını güncelle
      for (final callback in _updateCallbacks) {
        callback();
      }
    } catch (e) {
      print('❌ Error loading sidebar data: $e');
    } finally {
      _isLoadingInBackground = false;
    }
  }

  // Static versiyonu - preload için
  static Future<List<String>> _getPermissionsFromRolesStatic(BuildContext context) async {
    try {
      final authCubit = context.read<AuthCubit>();
      final currentUser = authCubit.currentUser;
      
      if (currentUser == null) {
        print('⚠️ Current user is null');
        return [];
      }
      
      // Try to get permissions from SharedPreferences first (login'de kaydedilmiş)
      try {
        final prefs = await SharedPreferences.getInstance();
        final permissionsString = prefs.getString('userPermissions');
        if (permissionsString != null && permissionsString.isNotEmpty) {
          final permissions = permissionsString.split(',').where((p) => p.isNotEmpty).toList();
          print('✅ Permissions loaded from SharedPreferences: ${permissions.length}');
          return permissions;
        }
      } catch (e) {
        print('⚠️ Error getting permissions from SharedPreferences: $e');
      }
      
      // Try to get permissions from RoleRepository API
      try {
        final userId = int.tryParse(currentUser.id) ?? 0;
        if (userId > 0) {
          final roleRepository = RoleRepository();
          final result = await roleRepository.getUserPermissions(userId);
          
          return result.fold(
            (failure) {
              print('⚠️ Error getting permissions from API: ${failure.message}');
              return [];
            },
            (permissions) {
              print('✅ Permissions loaded from API: ${permissions.length}');
              return permissions;
            },
          );
        }
      } catch (e) {
        print('⚠️ Error getting permissions from RoleRepository: $e');
      }
      
      return [];
    } catch (e) {
      print('❌ Error getting permissions from roles: $e');
      return [];
    }
  }

  Future<List<String>> _getPermissionsFromRoles() async {
    try {
      final authCubit = context.read<AuthCubit>();
      final currentUser = authCubit.currentUser;
      
      if (currentUser == null) {
        print('⚠️ Current user is null');
        return [];
      }
      
      // Try to get permissions from SharedPreferences first (login'de kaydedilmiş)
      try {
        final prefs = await SharedPreferences.getInstance();
        final permissionsString = prefs.getString('userPermissions');
        if (permissionsString != null && permissionsString.isNotEmpty) {
          final permissions = permissionsString.split(',').where((p) => p.isNotEmpty).toList();
          print('✅ Permissions loaded from SharedPreferences: ${permissions.length}');
          print('📋 Permissions: $permissions');
          return permissions;
        }
      } catch (e) {
        print('⚠️ Error getting permissions from SharedPreferences: $e');
      }
      
      // Try to get permissions from RoleRepository API
      try {
        final userId = int.tryParse(currentUser.id) ?? 0;
        if (userId > 0) {
          final roleRepository = RoleRepository();
          final result = await roleRepository.getUserPermissions(userId);
          
          return result.fold(
            (failure) {
              print('⚠️ Error getting permissions from API: ${failure.message}');
              return [];
            },
            (permissions) {
              print('✅ Permissions loaded from API: ${permissions.length}');
              print('📋 Permissions: $permissions');
              return permissions;
            },
          );
        }
      } catch (e) {
        print('⚠️ Error getting permissions from RoleRepository: $e');
      }
      
      return [];
    } catch (e) {
      print('❌ Error getting permissions from roles: $e');
      return [];
    }
  }

  // Web SideMenu ile aynı. İzin listesi boşsa mevcut rol menüsü durur.
  bool _havePermission(dynamic permission) {
    final enforce = _isDataLoaded && _userPermissions.isNotEmpty;
    return menuPermissionAllows(
      permission: permission,
      isAdmin: _isAdminUser,
      roleCodes: _userRoleCodes,
      permissions: _userPermissions,
      enforcePermissions: enforce,
    );
  }

  MenuItem _bformMenuItem() {
    return MenuItem(
      icon: Icons.description_outlined,
      title: 'Başvuru Formları',
      route: '/bform',
      permission: const [
        'form_applications.view',
        'form_applications.admin',
        'sale_applications.view',
        'sale_applications.admin',
        'form_applications.web_advisor',
        'form.web_advisor.manage',
        'role_office_broker',
      ],
      subRoutes: [
        MenuItem(
          icon: Icons.business_outlined,
          title: 'Ofis Başvuruları',
          route: '/bform/office',
          permission: const ['form_applications.view', 'form_applications.admin'],
        ),
        MenuItem(
          icon: Icons.person_outline,
          title: 'Danışman Başvuruları',
          route: '/bform/advisor',
          permission: 'admin_only',
        ),
        MenuItem(
          icon: Icons.badge_outlined,
          title: 'Web Danışman Başvuruları',
          route: '/bform/web-advisor',
          permission: const [
            'form_applications.web_advisor',
            'form.web_advisor.manage',
            'admin_only',
            'role_office_broker',
          ],
        ),
        MenuItem(
          icon: Icons.shopping_cart_outlined,
          title: 'Satış Talepleri',
          route: '/bform/sale-request',
          permission: const ['sale_applications.view', 'sale_applications.admin'],
        ),
        MenuItem(
          icon: Icons.block_outlined,
          title: 'Kara Liste',
          route: '/bform/blacklist',
          permission: const ['form_applications.view', 'form_applications.admin'],
        ),
      ],
    );
  }

  // Check if user is super admin
  bool get _isSuperAdmin => _userEmail == "admin@hausberry.com";

  // is_admin true ise admin menüsü. Değilse eski rol sırası.
  List<MenuItem> _getMenuRoutes() {
    if (_isAdminUser) {
      return _isSuperAdmin ? _getSuperAdminRoutes() : _getDefaultRoutes();
    }

    final isFranchiseSales = _userRoleCodes.contains('role_franchise_sales');
    final isAccountant = _userRoleCodes.contains('role_accountant');
    final isBroker = _userRoleCodes.contains('role_office_broker') ||
        _userRoleCodes.contains('role_office_assistant');

    if (isFranchiseSales &&
        AuthCubit.isFranchiseRegionDirector(_userTypeDescription)) {
      return _getDirectorRoutes();
    } else if (isFranchiseSales) {
      return _getFranchiseSalesRoutes();
    } else if (isAccountant) {
      return _getAccountantRoutes();
    } else if (_userRoleCodes.contains('role_advisor')) {
      return _getAdvisorRoutes();
    } else if (isBroker) {
      return _getBrokerRoutes();
    } else {
      return _getDefaultRoutes();
    }
  }

  /// Danışman — yalnızca danışman panelinde kullanılan sayfalar.
  /// Admin / broker / muhasebe menülerine dokunulmaz.
  List<MenuItem> _getAdvisorRoutes() {
    return [
      MenuItem(
        icon: Icons.home_outlined,
        title: 'Ana Sayfa',
        route: '/danisman-dashboard',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.assignment_turned_in_outlined,
        title: 'İşlem Bildirimleri',
        route: '/transaction-notification',
        permission: "portfolio.view",
      ),
      MenuItem(
        icon: Icons.emoji_events_outlined,
        title: 'Ödül Sistemi',
        route: '/zeonline/rewards',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.person_add_alt_1_outlined,
        title: 'Müşteriler',
        route: '/customers',
        permission: "customers.view",
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Portföyüm',
        route: '/portfolio',
        permission: "portfolio.view",
      ),
      MenuItem(
        icon: Icons.badge_outlined,
        title: 'Ze-İlanlar',
        route: '/zeilan',
        permission: "portfolio.view",
      ),
      MenuItem(
        icon: Icons.flag_outlined,
        title: 'Görev Yöneticisi',
        route: '/task-manager',
        permission: "task.view",
      ),
      MenuItem(
        icon: Icons.menu_book_outlined,
        title: 'Akıllı Ajandam',
        route: '/agenda',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.mail_outline_rounded,
        title: 'Mesajlar',
        route: '/profile-chat',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.account_balance_outlined,
        title: 'Eğitici Videolar',
        route: '/training-videos',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.campaign_outlined,
        title: 'Kampanyalar',
        route: '/offers',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.trending_up_rounded,
        title: 'Finans',
        route: '/finance',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.calculate_outlined,
        title: 'Faturalarım',
        route: '/invoices',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.bar_chart_rounded,
        title: 'Raporlar',
        route: '/reports',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.folder_copy_outlined,
        title: 'ZeDosya',
        route: '/zedosya',
        permission: "file.view",
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Dosyalarım',
        route: '/my-files',
        permission: "any",
      ),
      _bformMenuItem(),
      MenuItem(
        icon: Icons.school_outlined,
        title: 'Seminer ve Eğitimler',
        route: '/seminar',
        permission: "any",
      ),
    ];
  }

  /// Broker / ofis asistanı — web ZeOnline broker menüsü (bizdeki sayfalar).
  /// Admin-only sayfalar yok: Kullanıcılar, Ofisler, Kişiler, Kuponlar, Muhasebe,
  /// ZeHaber, ZeBlog, SSS, Duyurular.
  List<MenuItem> _getBrokerRoutes() {
    return [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: 'Ana Sayfa',
        route: '/broker-dashboard',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.assignment_turned_in_outlined,
        title: 'İşlem Bildirimleri',
        route: '/transaction-notification',
        permission: "portfolio.view",
        subRoutes: [
          MenuItem(
            icon: Icons.assignment_turned_in_outlined,
            title: 'İşlem Bildirimi',
            route: '/transaction-notification',
            permission: "portfolio.view",
          ),
          MenuItem(
            icon: Icons.post_add_outlined,
            title: 'Diğer İşlem Bildirimi',
            route: '/other-transaction-notification',
            permission: "portfolio.view",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.verified_user,
        title: 'İşlem Bildirim Onayları',
        route: '/zeonline/transaction-approvals',
        permission: ["listing.approve", "role_office_broker"],
      ),
      MenuItem(
        icon: Icons.card_giftcard,
        title: 'Ödül Sistemi',
        route: '/zeonline/rewards',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.groups_outlined,
        title: 'Müşteriler',
        route: '/customers',
        permission: "customers.view",
        subRoutes: [
          MenuItem(
            icon: Icons.groups_outlined,
            title: 'Tüm Müşteriler',
            route: '/customers',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.person_outline,
            title: 'Alıcılar',
            route: '/customers/alicilar',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.person_outline,
            title: 'Satıcılar',
            route: '/customers/saticilar',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.person_outline,
            title: 'Potansiyel Müşteriler',
            route: '/customers/potansiyel-musteriler',
            permission: "any",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Portföyüm',
        route: '/portfolio',
        permission: "portfolio.view",
      ),
      MenuItem(
        icon: Icons.check_circle_outline,
        title: 'Portföy Onay',
        route: '/portfolio/approve',
        permission: ["listing.approve", "role_office_broker"],
      ),
      MenuItem(
        icon: Icons.folder_copy_outlined,
        title: 'Tüm Portföyler',
        route: '/admin/portfolio',
        permission: "listing.view_all",
      ),
      MenuItem(
        icon: Icons.business_outlined,
        title: 'Ofisim',
        route: '/my-office',
        permission: "office.manage",
      ),
      MenuItem(
        icon: Icons.campaign_outlined,
        title: 'Ze-İlanlar',
        route: '/zeilan',
        permission: "portfolio.view",
      ),
      MenuItem(
        icon: Icons.assignment_outlined,
        title: 'Görev Yöneticisi',
        route: '/task-manager',
        permission: "task.view",
      ),
      MenuItem(
        icon: Icons.calendar_month_outlined,
        title: 'Akıllı Ajandam',
        route: '/agenda',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.ondemand_video_outlined,
        title: 'Eğitici Videolar',
        route: '/training-videos',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.local_offer_outlined,
        title: 'Kampanyalar',
        route: '/offers',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Finans',
        route: '/finance',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Faturalarım',
        route: '/invoices',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.assessment_outlined,
        title: 'Raporlar',
        route: '/reports',
        permission: "any",
        subRoutes: [
          MenuItem(
            icon: Icons.trending_up_rounded,
            title: 'Satış Raporu',
            route: '/reports',
            permission: "any",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.folder_copy_outlined,
        title: 'ZeDosya',
        route: '/zedosya',
        permission: "file.view",
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Dosyalarım',
        route: '/my-files',
        permission: "any",
      ),
      _bformMenuItem(),
      MenuItem(
        icon: Icons.school_outlined,
        title: 'Seminer ve Eğitimler',
        route: '/seminar',
        permission: "any",
        subRoutes: [
          MenuItem(
            icon: Icons.school_outlined,
            title: 'Seminerler',
            route: '/events',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.school_outlined,
            title: 'Eğitimler',
            route: '/educations',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.school_outlined,
            title: 'Yönetim',
            route: '/seminar',
            permission: "seminar.list",
          ),
        ],
      ),
    ];
  }

  /// Franchise Saha ve Geliştirme Bölge Yöneticisi — düz menü, alt menü yok.
  List<MenuItem> _getDirectorRoutes() {
    return [
      MenuItem(
        icon: Icons.home_outlined,
        title: 'Ana Sayfa',
        route: '/director-dashboard',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.apartment_outlined,
        title: 'Ofisler',
        route: '/offices',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.location_on_outlined,
        title: 'Franchise Haritası',
        route: '/franchise-map',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Tüm Portföyler',
        route: '/admin/portfolio',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.badge_outlined,
        title: 'Ze-İlanlar',
        route: '/zeilan',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.menu_book_outlined,
        title: 'Akıllı Ajandam',
        route: '/agenda',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.mail_outline_rounded,
        title: 'Mesajlar',
        route: '/profile-chat',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.account_balance_outlined,
        title: 'Eğitici Videolar',
        route: '/training-videos',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.forum_outlined,
        title: 'Müşteri Yorumları',
        route: '/customer-reviews',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.campaign_outlined,
        title: 'Kampanyalar',
        route: '/offers',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.trending_up_rounded,
        title: 'Finans',
        route: '/finance',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.calculate_outlined,
        title: 'Ödemelerim',
        route: '/invoices',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.calculate_outlined,
        title: 'Muhasebe',
        route: '/all-invoices',
        permission: "admin_only",
      ),
      MenuItem(
        icon: Icons.bar_chart_rounded,
        title: 'Raporlar',
        route: '/reports',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'ZeDosya',
        route: '/zedosya',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Dosyalarım',
        route: '/my-files',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.edit_note_rounded,
        title: 'Başvuru Formları',
        route: '/bform',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.school_outlined,
        title: 'Seminer ve Eğitimler',
        route: '/seminar',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.workspace_premium_outlined,
        title: 'Ödül Sistemi',
        route: '/zeonline/rewards',
        permission: "any",
      ),
    ];
  }

  List<MenuItem> _getFranchiseSalesRoutes() {
    return [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: 'Ana Sayfa',
        route: '/franchise-dashboard',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.person_outline,
        title: 'Kullanıcılar',
        route: '/users',
        permission: "admin_only",
      ),
      MenuItem(
        icon: Icons.business_outlined,
        title: 'Ofisler',
        route: '/offices',
        permission: "offices.list",
      ),
      MenuItem(
        icon: Icons.people_outline,
        title: 'Kişiler',
        route: '/persons',
        permission: "contact.list",
        subRoutes: [
          MenuItem(
            icon: Icons.people_outline,
            title: 'Tüm Kişiler',
            route: '/persons',
            permission: "contact.list",
          ),
          MenuItem(
            icon: Icons.person_add_outlined,
            title: 'Onay Bekleyen Kişiler',
            route: '/pending-contacts',
            permission: "admin_only",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Tüm Portföyler',
        route: '/admin/portfolio',
        permission: "listing.view_all",
      ),
      // MenuItem(
      //   icon: Icons.settings_outlined,
      //   title: 'Sistem Ayarları',
      //   route: '/system-settings',
      //   permission: ["admin_only"],
      //   subRoutes: [
      //     MenuItem(
      //       icon: Icons.star_outline,
      //       title: 'Öne Çıkan İlanlar',
      //       route: '/system-settings/featured-advertisements',
      //       permission: "admin_only",
      //     ),
      //     MenuItem(
      //       icon: Icons.star_outline,
      //       title: 'Öne Çıkan Danışmanlar',
      //       route: '/system-settings/featured-advisors',
      //       permission: "admin_only",
      //     ),
      //   ],
      // ),
      MenuItem(
        icon: Icons.campaign_outlined,
        title: 'Ze-İlanlar',
        route: '/zeilan',
        permission: "portfolio.view",
      ),
      MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Duyurular',
        route: '/announcements',
        permission: "announcement.list",
      ),
      MenuItem(
        icon: Icons.assignment_outlined,
        title: 'Görev Yöneticisi',
        route: '/task-manager',
        permission: "task.view",
      ),
      MenuItem(
        icon: Icons.calendar_month_outlined,
        title: 'Akıllı Ajandam',
        route: '/agenda',
        permission: "any",
      ),
      // MenuItem(
      //   icon: Icons.message_outlined,
      //   title: 'Mesajlar',
      //   route: '/profile-chat',
      //   permission: "any",
      // ),
      MenuItem(
        icon: Icons.ondemand_video_outlined,
        title: 'Eğitici Videolar',
        route: '/training-videos',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.local_offer_outlined,
        title: 'Kampanyalar',
        route: '/offers',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Finans',
        route: '/finance',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.confirmation_number_outlined,
        title: 'Kuponlar',
        route: '/coupons',
        permission: const ["admin_only", "role_office_broker"],
        subRoutes: [
          MenuItem(
            icon: Icons.confirmation_number_outlined,
            title: 'Kuponlar',
            route: '/coupons',
            permission: const ["admin_only", "role_office_broker"],
          ),
          MenuItem(
            icon: Icons.style_outlined,
            title: 'Kupon Şablonları',
            route: '/coupons/templates',
            permission: const ["admin_only", "role_office_broker"],
          ),
        ],
      ),
      MenuItem(
        icon: Icons.calculate_outlined,
        title: 'Ödemelerim',
        route: '/invoices',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.calculate_outlined,
        title: 'Muhasebe',
        route: '/all-invoices',
        permission: "admin_only",
        subRoutes: [
          MenuItem(
            icon: Icons.calculate_outlined,
            title: 'Faturalar',
            route: '/all-invoices',
            permission: "admin_only",
          ),
          MenuItem(
            icon: Icons.check_circle_outline,
            title: 'Havale Onayları',
            route: '/accounting/transactions',
            permission: "admin_only",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.folder_copy_outlined,
        title: 'ZeDosya',
        route: '/zedosya',
        permission: "file.view",
      ),
      // ZeHaber mobil menüde kapalı.
      // MenuItem(
      //   icon: Icons.newspaper_outlined,
      //   title: 'ZeHaber',
      //   route: '/zehaber',
      //   permission: "news.list",
      // ),
      // ZeBlog mobil menüde kapalı.
      // MenuItem(
      //   icon: Icons.article_outlined,
      //   title: 'ZeBlog',
      //   route: '/zeblog',
      //   permission: "blog.list",
      // ),
      // Sıkça Sorulan Sorular mobil menüde kapalı.
      // MenuItem(
      //   icon: Icons.help_outline,
      //   title: 'Sıkça Sorulan Sorular',
      //   route: '/admin-sss',
      //   permission: "faq.list",
      //   subRoutes: [
      //     MenuItem(
      //       icon: Icons.help_outline,
      //       title: 'Tüm Sorular',
      //       route: '/admin-sss',
      //       permission: "faq.list",
      //     ),
      //     MenuItem(
      //       icon: Icons.category_outlined,
      //       title: 'SSS Kategoriler',
      //       route: '/admin-sss/category',
      //       permission: "faq.list",
      //     ),
      //   ],
      // ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Dosyalarım',
        route: '/my-files',
        permission: "any",
      ),
      _bformMenuItem(),
      MenuItem(
        icon: Icons.school_outlined,
        title: 'Seminer ve Eğitimler',
        route: '/seminar',
        permission: "any",
        subRoutes: [
          MenuItem(
            icon: Icons.school_outlined,
            title: 'Seminerler',
            route: '/events',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.school_outlined,
            title: 'Eğitimler',
            route: '/educations',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.school_outlined,
            title: 'Yönetim',
            route: '/seminar',
            permission: "seminar.list",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.card_giftcard,
        title: 'Ödül Sistemi',
        route: '/zeonline/rewards',
        permission: "any",
      ),
    ];
  }

  List<MenuItem> _getAccountantRoutes() {
    return [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: 'Ana Sayfa',
        route: '/accounting-dashboard',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.assignment_turned_in_outlined,
        title: 'İşlem Bildirimleri',
        route: '/transaction-notification',
        permission: "any",
        subRoutes: [
          MenuItem(
            icon: Icons.assignment_turned_in_outlined,
            title: 'İşlem Bildirimi',
            route: '/transaction-notification',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.post_add_outlined,
            title: 'Diğer İşlem Bildirimi',
            route: '/other-transaction-notification',
            permission: "any",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.calculate_outlined,
        title: 'Muhasebe',
        route: '/all-invoices',
        permission: "admin_only",
        subRoutes: [
          MenuItem(
            icon: Icons.receipt_outlined,
            title: 'Faturalar',
            route: '/all-invoices',
            permission: "admin_only",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.ondemand_video_outlined,
        title: 'Eğitici Videolar',
        route: '/training-videos',
        permission: "any",
      ),
    ];
  }

  List<MenuItem> _getSuperAdminRoutes() {
    return [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: 'Ana Sayfa',
        route: '/dashboard',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.assignment_turned_in_outlined,
        title: 'İşlem Bildirimleri',
        route: '/transaction-notification',
        permission: "portfolio.view",
        subRoutes: [
          MenuItem(
            icon: Icons.assignment_turned_in_outlined,
            title: 'İşlem Bildirimi',
            route: '/transaction-notification',
            permission: "portfolio.view",
          ),
          MenuItem(
            icon: Icons.post_add_outlined,
            title: 'Diğer İşlem Bildirimi',
            route: '/other-transaction-notification',
            permission: "portfolio.view",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.verified_user,
        title: 'İşlem Bildirim Onayları',
        route: '/zeonline/transaction-approvals',
        permission: "role_office_broker",
      ),
      MenuItem(
        icon: Icons.person_outline,
        title: 'Kullanıcılar',
        route: '/users',
        permission: "admin_only",
      ),
      MenuItem(
        icon: Icons.business_outlined,
        title: 'Ofisler',
        route: '/offices',
        permission: "offices.list",
      ),
      MenuItem(
        icon: Icons.location_on_outlined,
        title: 'Franchise Haritası',
        route: '/franchise-map',
        permission: const ["visit.create", "visit.admin"],
      ),
      MenuItem(
        icon: Icons.business_outlined,
        title: 'Ofisim',
        route: '/my-office',
        permission: const ["admin_only", "office.manage"],
      ),
      MenuItem(
        icon: Icons.people_outline,
        title: 'Kişiler',
        route: '/persons',
        permission: "contact.list",
        subRoutes: [
          MenuItem(
            icon: Icons.people_outline,
            title: 'Tüm Kişiler',
            route: '/persons',
            permission: "contact.list",
          ),
          MenuItem(
            icon: Icons.person_add_outlined,
            title: 'Onay Bekleyen Kişiler',
            route: '/pending-contacts',
            permission: "admin_only",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Tüm Portföyler',
        route: '/admin/portfolio',
        permission: "admin_only",
      ),
      MenuItem(
        icon: Icons.assessment_outlined,
        title: 'Raporlar',
        route: '/reports',
        permission: "admin_only",
        subRoutes: [
          MenuItem(
            icon: Icons.trending_up_rounded,
            title: 'Satış Raporu',
            route: '/reports',
            permission: "admin_only",
          ),
          MenuItem(
            icon: Icons.calendar_month_rounded,
            title: 'Yıllık Satış Raporu',
            route: '/reports',
            permission: "admin_only",
          ),
          MenuItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Cari Rapor',
            route: '/reports',
            permission: "admin_only",
          ),
          MenuItem(
            icon: Icons.assessment_outlined,
            title: 'Genel Raporlar',
            route: '/reports',
            permission: "admin_only",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.confirmation_number_outlined,
        title: 'Kuponlar',
        route: '/coupons',
        permission: const ["admin_only", "role_office_broker"],
        subRoutes: [
          MenuItem(
            icon: Icons.confirmation_number_outlined,
            title: 'Kuponlar',
            route: '/coupons',
            permission: const ["admin_only", "role_office_broker"],
          ),
          MenuItem(
            icon: Icons.style_outlined,
            title: 'Kupon Şablonları',
            route: '/coupons/templates',
            permission: const ["admin_only", "role_office_broker"],
          ),
        ],
      ),
      MenuItem(
        icon: Icons.calculate_outlined,
        title: 'Muhasebe',
        route: '/all-invoices',
        permission: "admin_only",
        subRoutes: [
          MenuItem(
            icon: Icons.receipt_outlined,
            title: 'Faturalar',
            route: '/all-invoices',
            permission: "admin_only",
          ),
          MenuItem(
            icon: Icons.check_circle_outline,
            title: 'Havale Onayları',
            route: '/accounting/transactions',
            permission: "admin_only",
          ),
        ],
      ),
      _bformMenuItem(),
      MenuItem(
        icon: Icons.edit_note_outlined,
        title: 'Website Formlar',
        route: '/bform/website',
        permission: "admin_only",
      ),
      MenuItem(
        icon: Icons.ondemand_video_outlined,
        title: 'Eğitici Videolar',
        route: '/training-videos',
        permission: "any",
      ),
    ];
  }

  List<MenuItem> _getDefaultRoutes() {
    return [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: 'Ana Sayfa',
        route: '/dashboard',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.assignment_turned_in_outlined,
        title: 'İşlem Bildirimleri',
        route: '/transaction-notification',
        permission: "portfolio.view",
        subRoutes: [
          MenuItem(
            icon: Icons.assignment_turned_in_outlined,
            title: 'İşlem Bildirimi',
            route: '/transaction-notification',
            permission: "portfolio.view",
          ),
          MenuItem(
            icon: Icons.post_add_outlined,
            title: 'Diğer İşlem Bildirimi',
            route: '/other-transaction-notification',
            permission: "portfolio.view",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.verified_user,
        title: 'İşlem Bildirim Onayları',
        route: '/zeonline/transaction-approvals',
        permission: "role_office_broker",
      ),
      MenuItem(
        icon: Icons.card_giftcard,
        title: 'Ödül Sistemi',
        route: '/zeonline/rewards',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.person_outline,
        title: 'Kullanıcılar',
        route: '/users',
        permission: "admin_only",
      ),
      MenuItem(
        icon: Icons.business_outlined,
        title: 'Ofisler',
        route: '/offices',
        permission: "offices.list",
      ),
      MenuItem(
        icon: Icons.location_on_outlined,
        title: 'Franchise Haritası',
        route: '/franchise-map',
        permission: const ["visit.create", "visit.admin"],
      ),
      MenuItem(
        icon: Icons.people_outline,
        title: 'Kişiler',
        route: '/persons',
        permission: "contact.list",
        subRoutes: [
          MenuItem(
            icon: Icons.people_outline,
            title: 'Tüm Kişiler',
            route: '/persons',
            permission: "contact.list",
          ),
          MenuItem(
            icon: Icons.person_add_outlined,
            title: 'Onay Bekleyen Kişiler',
            route: '/pending-contacts',
            permission: "admin_only",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.groups_outlined,
        title: 'Müşteriler',
        route: '/customers',
        permission: "customers.view",
        subRoutes: [
          MenuItem(
            icon: Icons.groups_outlined,
            title: 'Tüm Müşteriler',
            route: '/customers',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.person_outline,
            title: 'Alıcılar',
            route: '/customers/alicilar',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.person_outline,
            title: 'Satıcılar',
            route: '/customers/saticilar',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.person_outline,
            title: 'Potansiyel Müşteriler',
            route: '/customers/potansiyel-musteriler',
            permission: "any",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Portföyüm',
        route: '/portfolio',
        permission: "portfolio.view",
        subRoutes: [
          MenuItem(
            icon: Icons.folder_outlined,
            title: 'Tüm Portföylerler',
            route: '/portfolio',
            permission: "portfolio.view",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Tüm Portföyler',
        route: '/admin/portfolio',
        permission: "listing.view_all",
      ),
      // MenuItem(
      //   icon: Icons.settings_outlined,
      //   title: 'Sistem Ayarları',
      //   route: '/system-settings',
      //   permission: ["admin_only"],
      //   subRoutes: [
      //     MenuItem(
      //       icon: Icons.star_outline,
      //       title: 'Öne Çıkan İlanlar',
      //       route: '/system-settings/featured-advertisements',
      //       permission: "admin_only",
      //     ),
      //     MenuItem(
      //       icon: Icons.star_outline,
      //       title: 'Öne Çıkan Danışmanlar',
      //       route: '/system-settings/featured-advisors',
      //       permission: "admin_only",
      //     ),
      //   ],
      // ),
      MenuItem(
        icon: Icons.business_outlined,
        title: 'Ofisim',
        route: '/my-office',
        permission: ["admin_only", "office.manage"],
      ),
      MenuItem(
        icon: Icons.campaign_outlined,
        title: 'Ze-İlanlar',
        route: '/zeilan',
        permission: "portfolio.view",
      ),
      MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Duyurular',
        route: '/announcements',
        permission: "announcement.list",
      ),
      MenuItem(
        icon: Icons.assignment_outlined,
        title: 'Görev Yöneticisi',
        route: '/task-manager',
        permission: "task.view",
      ),
      MenuItem(
        icon: Icons.calendar_month_outlined,
        title: 'Akıllı Ajandam',
        route: '/agenda',
        permission: "any",
      ),
      // MenuItem(
      //   icon: Icons.message_outlined,
      //   title: 'Mesajlar',
      //   route: '/profile-chat',
      //   permission: "any",
      // ),
      MenuItem(
        icon: Icons.ondemand_video_outlined,
        title: 'Eğitici Videolar',
        route: '/training-videos',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.local_offer_outlined,
        title: 'Kampanyalar',
        route: '/offers',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Finans',
        route: '/finance',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.confirmation_number_outlined,
        title: 'Kuponlar',
        route: '/coupons',
        permission: const ["admin_only", "role_office_broker"],
        subRoutes: [
          MenuItem(
            icon: Icons.confirmation_number_outlined,
            title: 'Kuponlar',
            route: '/coupons',
            permission: const ["admin_only", "role_office_broker"],
          ),
          MenuItem(
            icon: Icons.style_outlined,
            title: 'Kupon Şablonları',
            route: '/coupons/templates',
            permission: const ["admin_only", "role_office_broker"],
          ),
        ],
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Faturalarım',
        route: '/invoices',
        permission: "any",
      ),
      MenuItem(
        icon: Icons.calculate_outlined,
        title: 'Muhasebe',
        route: '/all-invoices',
        permission: "admin_only",
        subRoutes: [
          MenuItem(
            icon: Icons.receipt_outlined,
            title: 'Faturalar',
            route: '/all-invoices',
            permission: "admin_only",
          ),
          MenuItem(
            icon: Icons.check_circle_outline,
            title: 'Havale Onayları',
            route: '/accounting/transactions',
            permission: "admin_only",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.assessment_outlined,
        title: 'Raporlar',
        route: '/reports',
        permission: "admin_only",
        subRoutes: [
          MenuItem(
            icon: Icons.trending_up_rounded,
            title: 'Satış Raporu',
            route: '/reports',
            permission: "admin_only",
          ),
          MenuItem(
            icon: Icons.calendar_month_rounded,
            title: 'Yıllık Satış Raporu',
            route: '/reports',
            permission: "admin_only",
          ),
          MenuItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Cari Rapor',
            route: '/reports',
            permission: "admin_only",
          ),
          MenuItem(
            icon: Icons.assessment_outlined,
            title: 'Genel Raporlar',
            route: '/reports',
            permission: "admin_only",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.folder_copy_outlined,
        title: 'ZeDosya',
        route: '/zedosya',
        permission: "file.view",
      ),
      // ZeHaber mobil menüde kapalı.
      // MenuItem(
      //   icon: Icons.newspaper_outlined,
      //   title: 'ZeHaber',
      //   route: '/zehaber',
      //   permission: "news.list",
      // ),
      // ZeBlog mobil menüde kapalı.
      // MenuItem(
      //   icon: Icons.article_outlined,
      //   title: 'ZeBlog',
      //   route: '/zeblog',
      //   permission: "blog.list",
      // ),
      // Sıkça Sorulan Sorular mobil menüde kapalı.
      // MenuItem(
      //   icon: Icons.help_outline,
      //   title: 'Sıkça Sorulan Sorular',
      //   route: '/admin-sss',
      //   permission: "faq.list",
      //   subRoutes: [
      //     MenuItem(
      //       icon: Icons.help_outline,
      //       title: 'Tüm Sorular',
      //       route: '/admin-sss',
      //       permission: "faq.list",
      //     ),
      //     MenuItem(
      //       icon: Icons.category_outlined,
      //       title: 'SSS Kategoriler',
      //       route: '/admin-sss/category',
      //       permission: "faq.list",
      //     ),
      //   ],
      // ),
      MenuItem(
        icon: Icons.folder_outlined,
        title: 'Dosyalarım',
        route: '/my-files',
        permission: "any",
      ),
      _bformMenuItem(),
      MenuItem(
        icon: Icons.school_outlined,
        title: 'Seminer ve Eğitimler',
        route: '/seminar',
        permission: "any",
        subRoutes: [
          MenuItem(
            icon: Icons.school_outlined,
            title: 'Seminerler',
            route: '/events',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.school_outlined,
            title: 'Eğitimler',
            route: '/educations',
            permission: "any",
          ),
          MenuItem(
            icon: Icons.school_outlined,
            title: 'Yönetim',
            route: '/seminar',
            permission: "seminar.list",
          ),
        ],
      ),
      MenuItem(
        icon: Icons.edit_note_outlined,
        title: 'Website Formlar',
        route: '/bform/website',
        permission: "admin_only",
      ),
    ];
  }

  @override
  void didUpdateWidget(RoleSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      setState(() {
        _selectedItem = widget.currentPage;
        _isPersonsExpanded =
            widget.currentPage == 'Ofisler' || widget.currentPage == 'Kişiler' || widget.currentPage == 'Tüm Kişiler' || widget.currentPage == 'Onay Bekleyen Kişiler';
        _isMuhasebeExpanded =
            widget.currentPage == 'Faturalar' || widget.currentPage == 'Havale Onayları' || widget.currentPage == 'Muhasebe';
        _isPortfolioExpanded =
            widget.currentPage == 'Portföyüm' || widget.currentPage == 'Tüm Portföylerler' || widget.currentPage == 'Portföy Onay';
        _isCustomersExpanded =
            widget.currentPage == 'Müşteriler' || widget.currentPage == 'Tüm Müşteriler' || widget.currentPage == 'Alıcılar' || widget.currentPage == 'Satıcılar' || widget.currentPage == 'Potansiyel Müşteriler';
        _isKuponlarExpanded =
            widget.currentPage == 'Kuponlar' || widget.currentPage == 'Kupon Şablonları';
        _isBformExpanded = _isBformSection(widget.currentPage);
        _isSeminarExpanded = _isSeminarSection(widget.currentPage);
        _isRaporlarExpanded = _isReportsSection(widget.currentPage);
        _isTransactionsExpanded = _isTransactionsSection(widget.currentPage);
      });
      _didFocusCurrentPage = false;
      _scheduleFocusCurrentPage();
    }
  }

  void _handleNavigation(BuildContext context, String title) async {
    setState(() {
      _selectedItem = title;
    });

    // Web projesindeki mantığa göre role-aware navigation
    final authCubit = context.read<AuthCubit>();
    final userRoleCodes = await authCubit.getUserRoleCodes();
    
    print('AdminPanelSidebar - Navigation - Title: $title, User Role Codes: $userRoleCodes');

    // Sayfa yönlendirmeleri - role-aware
    switch (title) {
      case 'Ana Sayfa':
        _navigateToDashboard(context, userRoleCodes);
        break;
      case 'Franchise Haritası':
        Navigator.pushNamed(context, AppRouter.franchiseMap);
        break;
      case 'Müşteri Yorumları':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müşteri Yorumları ekranı projede henüz yok')),
        );
        break;
      case 'Kullanıcılar':
        _navigateToRoleAwareScreen(context, '/users', userRoleCodes);
        break;
      case 'Kişiler':
        _navigateToRoleAwareScreen(context, '/persons', userRoleCodes);
        break;
      case 'Onay Bekleyen Kişiler':
        _navigateToRoleAwareScreen(context, '/pending-contacts', userRoleCodes);
        break;
      case 'Ofisler':
        _navigateToRoleAwareScreen(context, '/offices', userRoleCodes);
        break;
      case 'Müşteriler':
        _navigateToRoleAwareScreen(context, '/customers', userRoleCodes);
        break;
      case 'Alıcılar':
        Navigator.pushNamed(context, AppRouter.customersAlicilar);
        break;
      case 'Satıcılar':
        Navigator.pushNamed(context, AppRouter.customersSaticilar);
        break;
      case 'Potansiyel Müşteriler':
        Navigator.pushNamed(context, AppRouter.customersPotansiyel);
        break;
      case 'Tüm Müşteriler':
        _navigateToRoleAwareScreen(context, '/customers', userRoleCodes);
        break;
      case 'Portföyüm':
        _navigateToRoleAwareScreen(context, '/portfolio', userRoleCodes);
        break;
      case 'Tüm Portföylerler':
        _navigateToRoleAwareScreen(context, '/portfolio', userRoleCodes);
        break;
      // case 'Sistem Ayarları':
      //   _navigateToRoleAwareScreen(context, '/system-settings', userRoleCodes);
      //   break;
      case 'Ofisim':
        _navigateToRoleAwareScreen(context, '/my-office', userRoleCodes);
        break;
      case 'Ze-İlanlar':
        _navigateToRoleAwareScreen(context, '/zeilan', userRoleCodes);
        break;
      case 'Duyurular':
        _navigateToRoleAwareScreen(context, '/announcements', userRoleCodes);
        break;
      case 'Raporlar':
      case 'Yıllık Satış Raporu':
      case 'Cari Rapor':
      case 'Genel Raporlar':
        if (userRoleCodes.contains('role_admin')) {
          _openReportsScreen(context, title);
        } else {
          // Broker / danışman: Satış Raporu ekranı
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SraporScreen()),
          );
        }
        break;
      case 'Görev Yöneticisi':
        _navigateToRoleAwareScreen(context, '/task-manager', userRoleCodes);
        break;
      case 'Akıllı Ajandam':
        _navigateToRoleAwareScreen(context, '/agenda', userRoleCodes);
        break;
      case 'Mesajlar':
        _navigateToRoleAwareScreen(context, '/profile-chat', userRoleCodes);
        break;
      case 'Kampanyalar':
        _navigateToRoleAwareScreen(context, '/offers', userRoleCodes);
        break;
      case 'Finans':
        _navigateToRoleAwareScreen(context, '/finance', userRoleCodes);
        break;
      case 'İşlem Bildirimleri':
      case 'İşlem Bildirimi':
        _navigateToRoleAwareScreen(context, '/transaction-notification', userRoleCodes);
        break;
      case 'Diğer İşlem Bildirimi':
        _navigateToRoleAwareScreen(context, '/other-transaction-notification', userRoleCodes);
        break;
      case 'Satış Raporu':
        if (userRoleCodes.contains('role_admin')) {
          _openReportsScreen(context, title);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SraporScreen()),
          );
        }
        break;
      case 'İşlem Bildirim Onayları':
        if (!AuthCubit.isBrokerRank(
          roleCodes: userRoleCodes,
          typeDescription: _userTypeDescription,
        )) {
          break;
        }
        _navigateToRoleAwareScreen(context, '/zeonline/transaction-approvals', userRoleCodes);
        break;
      case 'Ödül Sistemi':
        _navigateToRoleAwareScreen(context, '/zeonline/rewards', userRoleCodes);
        break;
      case 'Kuponlar':
        _navigateToRoleAwareScreen(context, '/coupons', userRoleCodes);
        break;
      case 'Kupon Şablonları':
        _navigateToRoleAwareScreen(context, '/coupons/templates', userRoleCodes);
        break;
      case 'Faturalarım':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PayScreen()),
        );
        break;
      case 'Ödemelerim':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PayScreen()),
        );
        break;
      case 'Muhasebe':
        // Muhasebe rolü için muhasebe sayfasına yönlendir
        if (userRoleCodes.contains('role_accountant')) {
          Navigator.pushNamed(context, '/all-invoices');
        } else {
          _navigateToRoleAwareScreen(context, '/all-invoices', userRoleCodes);
        }
        break;
      case 'Faturalar':
        Navigator.pushNamed(context, '/all-invoices');
        break;
      case 'Havale Onayları':
        Navigator.pushNamed(context, '/accounting/transactions');
        break;
      case 'ZeDosya':
        _navigateToRoleAwareScreen(context, '/zedosya', userRoleCodes);
        break;
      case 'Dosyalarım':
        _navigateToRoleAwareScreen(context, '/my-files', userRoleCodes);
        break;
      // case 'ZeHaber':
      //   _navigateToRoleAwareScreen(context, '/zehaber', userRoleCodes);
      //   break;
      // case 'ZeBlog':
      //   _navigateToRoleAwareScreen(context, '/zeblog', userRoleCodes);
      //   break;
      // case 'Sıkça Sorulan Sorular':
      //   _navigateToRoleAwareScreen(context, '/admin-sss', userRoleCodes);
      //   break;
      case 'Başvuru Formları':
        _navigateToRoleAwareScreen(context, '/bform', userRoleCodes);
        break;
      case 'Ofis Başvuruları':
        _navigateToRoleAwareScreen(context, '/bform/office', userRoleCodes);
        break;
      case 'Danışman Başvuruları':
        _navigateToRoleAwareScreen(context, '/bform/advisor', userRoleCodes);
        break;
      case 'Web Danışman Başvuruları':
        _navigateToRoleAwareScreen(context, '/bform/web-advisor', userRoleCodes);
        break;
      case 'Website Formlar':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title ekranı birazdan eklenecek')),
        );
        break;
      case 'Satış Talepleri':
        _navigateToRoleAwareScreen(context, '/bform/sale-request', userRoleCodes);
        break;
      case 'Kara Liste':
        _navigateToRoleAwareScreen(context, '/bform/blacklist', userRoleCodes);
        break;
      case 'Seminer ve Eğitimler':
        _navigateToRoleAwareScreen(context, '/seminar', userRoleCodes);
        break;
      case 'Seminerler':
      case 'Etkinlikler':
        _navigateToRoleAwareScreen(context, '/events', userRoleCodes);
        break;
      case 'Eğitimler':
        _navigateToRoleAwareScreen(context, '/educations', userRoleCodes);
        break;
      case 'Yönetim':
        _navigateToRoleAwareScreen(context, '/seminar', userRoleCodes);
        break;
      case 'Eğitici Videolar':
        _navigateToRoleAwareScreen(context, '/training-videos', userRoleCodes);
        break;
      case 'Portföy Onay':
        _navigateToRoleAwareScreen(context, '/portfolio/approve', userRoleCodes);
        break;
      case 'Tüm Portföyler':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TumIlanScreen(),
          ),
        );
        break;
    }
  }

  bool get _isBrokerRank => AuthCubit.isBrokerRank(
        roleCodes: _userRoleCodes,
        typeDescription: _userTypeDescription,
      );

  // Build menu items dynamically based on permissions
  Widget _buildMenuItems() {
    final menuRoutes = _getMenuRoutes().where((item) {
      if (item.title == 'İşlem Bildirim Onayları') return _isBrokerRank;
      return true;
    });
    final filteredRoutes = menuRoutes.where((item) => _havePermission(item.permission)).toList();
    
    // Güvenli bir şekilde children listesini oluştur
    final List<Widget> menuChildren = filteredRoutes.map((item) {
      if (item.subRoutes != null && item.subRoutes!.isNotEmpty) {
        // Expandable item with sub-routes
        final filteredSubRoutes = item.subRoutes!
            .where((subItem) => _havePermission(subItem.permission))
            .toList();
        
        if (filteredSubRoutes.isEmpty) {
          return const SizedBox.shrink(); // Hide if no sub-routes are visible
        }
        
        final isExpanded = _isItemExpanded(item);
        final isSelected = _isItemSelected(item) || filteredSubRoutes.any((sub) => _isItemSelected(sub));
        
        return _buildExpandableMenuItem(
          item: item,
          subRoutes: filteredSubRoutes,
          isExpanded: isExpanded,
          isSelected: isSelected,
        );
      } else {
        // Simple menu item
        return _buildMenuItem(
          icon: item.icon,
          title: item.title,
          onTap: () => _handleNavigation(context, item.title),
          isSelected: _selectedItem == item.title,
        );
      }
    }).toList();
    
    // Sonuna spacing ekle
    menuChildren.add(const SizedBox(height: 24));
    
    return Column(
      children: menuChildren,
    );
  }
  
  // Get or create GlobalKey for an item
  GlobalKey _getItemKey(String title) {
    if (!_itemKeys.containsKey(title)) {
      _itemKeys[title] = GlobalKey();
    }
    return _itemKeys[title]!;
  }

  void _toggleExpanded(String title) {
    switch (title) {
      case 'Kişiler':
        _isPersonsExpanded = !_isPersonsExpanded;
      case 'Muhasebe':
        _isMuhasebeExpanded = !_isMuhasebeExpanded;
      case 'Portföyüm':
        _isPortfolioExpanded = !_isPortfolioExpanded;
      case 'Müşteriler':
        _isCustomersExpanded = !_isCustomersExpanded;
      case 'Kuponlar':
        _isKuponlarExpanded = !_isKuponlarExpanded;
      case 'Başvuru Formları':
        _isBformExpanded = !_isBformExpanded;
      case 'Seminer ve Eğitimler':
        _isSeminarExpanded = !_isSeminarExpanded;
      case 'Raporlar':
        _isRaporlarExpanded = !_isRaporlarExpanded;
      case 'İşlem Bildirimleri':
        _isTransactionsExpanded = !_isTransactionsExpanded;
    }
  }

  bool _isTransactionsSection(String page) {
    return page == 'İşlem Bildirimleri' ||
        page == 'İşlem Bildirimi' ||
        page == 'Diğer İşlem Bildirimi';
  }

  bool _isItemExpanded(MenuItem item) {
    if (item.title == 'Kişiler') return _isPersonsExpanded;
    // if (item.title == 'Sistem Ayarları') return _isSystemSettingsExpanded;
    if (item.title == 'Muhasebe') return _isMuhasebeExpanded;
    if (item.title == 'Portföyüm') return _isPortfolioExpanded;
    if (item.title == 'Müşteriler') return _isCustomersExpanded;
    if (item.title == 'Kuponlar') return _isKuponlarExpanded;
    if (item.title == 'Başvuru Formları') return _isBformExpanded;
    if (item.title == 'Seminer ve Eğitimler') return _isSeminarExpanded;
    if (item.title == 'Raporlar') return _isRaporlarExpanded;
    if (item.title == 'İşlem Bildirimleri') return _isTransactionsExpanded;
    if (item.subRoutes != null) {
      return item.subRoutes!.any((sub) => _selectedItem == sub.title);
    }
    return false;
  }

  bool _isBformSection(String page) {
    return page == 'Başvuru Formları' ||
        page == 'Ofis Başvuruları' ||
        page == 'Danışman Başvuruları' ||
        page == 'Web Danışman Başvuruları' ||
        page == 'Satış Talepleri' ||
        page == 'Kara Liste';
  }

  bool _isSeminarSection(String page) {
    return page == 'Seminer ve Eğitimler' ||
        page == 'Seminerler' ||
        page == 'Eğitimler' ||
        page == 'Yönetim' ||
        page == 'Etkinlikler';
  }

  bool _isReportsSection(String page) {
    return page == 'Raporlar' ||
        page == 'Satış Raporu' ||
        page == 'Yıllık Satış Raporu' ||
        page == 'Cari Rapor' ||
        page == 'Genel Raporlar';
  }

  bool _isItemSelected(MenuItem item) {
    return _selectedItem == item.title;
  }

  Widget _buildExpandableMenuItem({
    required MenuItem item,
    required List<MenuItem> subRoutes,
    required bool isExpanded,
    required bool isSelected,
  }) {
    // Güvenli bir şekilde children listesini oluştur
    if (subRoutes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final List<Widget> childrenWidgets = <Widget>[];
    for (final subItem in subRoutes) {
      childrenWidgets.add(
        _buildSubMenuItem(
          key: _getItemKey('${item.title}::${subItem.title}'),
          icon: subItem.icon,
          title: subItem.title,
          onTap: () {
            setState(() {
              _selectedItem = subItem.title;
              // Expansion state'leri güncelle
              if (item.title == 'Kişiler') {
                _isPersonsExpanded = true;
              } else if (item.title == 'Portföyüm') {
                _isPortfolioExpanded = true;
              } else if (item.title == 'Müşteriler') {
                _isCustomersExpanded = true;
              } else if (item.title == 'Muhasebe') {
                _isMuhasebeExpanded = true;
              } else if (item.title == 'Kuponlar') {
                _isKuponlarExpanded = true;
              } else if (item.title == 'Başvuru Formları') {
                _isBformExpanded = true;
              } else if (item.title == 'Seminer ve Eğitimler') {
                _isSeminarExpanded = true;
              } else if (item.title == 'Raporlar') {
                _isRaporlarExpanded = true;
              }
              // else if (item.title == 'Sistem Ayarları') {
              //   _isSystemSettingsExpanded = true;
              // }
            });
            _handleNavigation(context, subItem.title);
          },
          isSelected: _selectedItem == subItem.title,
        ),
      );
    }
    
    return _buildExpandableItem(
      icon: item.icon,
      title: item.title,
      isExpanded: isExpanded,
      isSelected: isSelected,
      onTap: () {
        final willExpand = !_isItemExpanded(item);
        setState(() => _toggleExpanded(item.title));
        if (!willExpand) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final opened = _itemKeys[item.title]?.currentContext;
          if (!mounted || opened == null) return;
          Scrollable.ensureVisible(
            opened,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: 0.05,
          );
        });
      },
      children: childrenWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.sizeOf(context).width;
    final width = drawerWidth > 360 ? 304.0 : drawerWidth * 0.86;

    return Drawer(
      width: width,
      backgroundColor: Colors.white,
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(229, 57, 53, 1),
            ),
            child: SafeArea(
              child: Center(
                child: SvgPicture.asset(
                  "assets/logo/zecorner-logo2.svg",
                  width: 110,
                  height: 40,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: _buildMenuItems(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      key: _getItemKey(title),
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE53935).withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? const Color(0xFFE53935)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required bool isSelected,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    // Güvenli bir şekilde children listesini oluştur
    final List<Widget> columnChildren = <Widget>[
      Container(
        key: _getItemKey(title),
        margin: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE53935).withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? const Color(0xFFE53935)
                        : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 22,
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
    
    // Eğer expanded ise ve children varsa ekle
    if (isExpanded && children.isNotEmpty) {
      columnChildren.add(
        Container(
          key: ValueKey('${title}_expanded_container'),
          margin: const EdgeInsets.only(left: 32),
          child: Column(
            key: ValueKey('${title}_expanded_column'),
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: columnChildren,
    );
  }

  Widget _buildSubMenuItem({
    Key? key,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      key: key ?? _getItemKey(title),
      margin: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE53935).withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFFE53935)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _openReportsScreen(BuildContext context, String title) {
    final tab = ReportsTabX.fromArgument(title);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsScreen(initialTab: tab),
      ),
    );
  }

  // Web sitesindeki mantığa göre dashboard'a yönlendirme
  void _navigateToDashboard(BuildContext context, List<String> userRoleCodes) async {
    final authCubit = context.read<AuthCubit>();
    final dashboardRoute = await authCubit.getDashboardRoute();
    
    print('AdminPanelSidebar - Dashboard yönlendirme - Route: $dashboardRoute');
    
    // Route'a göre dashboard seçimi
    switch (dashboardRoute) {
      case '/accounting-dashboard':
        Navigator.pushNamed(context, AppRouter.accountingDashboard);
        break;
      case '/franchise-dashboard':
        Navigator.pushNamed(context, AppRouter.franchiseDashboard);
        break;
      case '/director-dashboard':
        Navigator.pushNamed(context, AppRouter.directorDashboard);
        break;
      case '/dashboard':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
        break;
      case '/danisman-dashboard':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DanismanDashboardScreen()));
        break;
      case '/broker-dashboard':
      default:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BrokerDashboardScreen()));
        break;
    }
  }

  // Web projesindeki mantığa göre role-aware screen yönlendirme
  void _navigateToRoleAwareScreen(BuildContext context, String route, List<String> userRoleCodes) async {
    print('AdminPanelSidebar - Role-aware yönlendirme - Route: $route, User Role Codes: $userRoleCodes');
    
    // Role sistemini koruyarak yönlendirme
    
    // Route'a göre role-aware yönlendirme - role sistemini koruyarak
    if (route == '/users') {
      // Kullanıcılar sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/customers') {
      // Müşteriler sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/listings') {
      // İlanlar sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/offices') {
      // Ofisler sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/persons') {
      // Kişiler sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/seminars') {
      // Seminerler sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    // } else if (route == '/zehaber') {
    //   Navigator.pushNamed(context, route);
    } else if (route == '/system-settings') {
      // Sistem Ayarları sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/one-of-the-consultants') {
      // Öne Çıkan Danışmanlar sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else {
      // Bilinmeyen route için varsayılan davranış
      Navigator.pushNamed(context, route);
    }
  }
}
