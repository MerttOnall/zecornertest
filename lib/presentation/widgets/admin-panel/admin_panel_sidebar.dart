import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../screens/dashboard/broker_dashboard_screen.dart';
import '../../screens/dashboard/admin_dashboard_screen.dart';
import '../../screens/dashboard/danisman_dashboard_screen.dart';
import '../../screens/tilan/tum_ilan_screen.dart';
import '../../../core/cubit/auth_cubit.dart';

class AdminPanelSidebar extends StatefulWidget {
  final String currentPage;

  const AdminPanelSidebar({
    super.key,
    required this.currentPage,
  });

  @override
  State<AdminPanelSidebar> createState() => _AdminPanelSidebarState();
}

class _AdminPanelSidebarState extends State<AdminPanelSidebar>
    with TickerProviderStateMixin {
  String _selectedItem = 'Ana Sayfa';
  bool _isPersonsExpanded = false;
  bool _isSystemSettingsExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.currentPage;
    _isPersonsExpanded =
        widget.currentPage == 'Ofisler' || widget.currentPage == 'Kişiler';

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdminPanelSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      setState(() {
        _selectedItem = widget.currentPage;
        _isPersonsExpanded =
            widget.currentPage == 'Ofisler' || widget.currentPage == 'Kişiler';
      });
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
      case 'Kullanıcılar':
        _navigateToRoleAwareScreen(context, '/users', userRoleCodes);
        break;
      case 'Kişiler':
        _navigateToRoleAwareScreen(context, '/persons', userRoleCodes);
        break;
      case 'Ofisler':
        _navigateToRoleAwareScreen(context, '/offices', userRoleCodes);
        break;
      case 'Müşteriler':
        _navigateToRoleAwareScreen(context, '/customers', userRoleCodes);
        break;
      case 'Portföyüm':
        _navigateToRoleAwareScreen(context, '/portfolio', userRoleCodes);
        break;
      case 'İlanlarım':
        _navigateToRoleAwareScreen(context, '/my-listings', userRoleCodes);
        break;
      case 'Sistem Ayarları':
        _navigateToRoleAwareScreen(context, '/system-settings', userRoleCodes);
        break;
      case 'Ofisim':
        _navigateToRoleAwareScreen(context, '/my-office', userRoleCodes);
        break;
      case 'Ze-İlanlar':
        _navigateToRoleAwareScreen(context, '/zeilan', userRoleCodes);
        break;
      case 'Duyurular':
        _navigateToRoleAwareScreen(context, '/announcements', userRoleCodes);
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
      case 'ZeDosya':
        _navigateToRoleAwareScreen(context, '/zedosya', userRoleCodes);
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
      case 'Seminer ve Eğitimler':
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
      case 'İlan Onay':
        _navigateToRoleAwareScreen(context, '/listings/approval', userRoleCodes);
        break;
      case 'Tüm İlanlar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TumIlanScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Drawer(
        backgroundColor: Colors.white,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Clean Header
              Container(
                height: 140,
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

              // Menu Items - Scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.dashboard_outlined,
                        title: 'Ana Sayfa',
                        onTap: () => _handleNavigation(context, 'Ana Sayfa'),
                        isSelected: _selectedItem == 'Ana Sayfa',
                      ),
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Kullanıcılar',
                        onTap: () => _handleNavigation(context, 'Kullanıcılar'),
                        isSelected: _selectedItem == 'Kullanıcılar',
                      ),
                      _buildExpandableItem(
                        icon: Icons.people_outline,
                        title: 'Kişiler',
                        isExpanded: _isPersonsExpanded,
                        isSelected: _selectedItem == 'Kişiler' ||
                            _selectedItem == 'Ofisler',
                        onTap: () {
                          setState(() {
                            _isPersonsExpanded = !_isPersonsExpanded;
                            _selectedItem = 'Kişiler';
                          });
                          _handleNavigation(context, 'Kişiler');
                        },
                        children: [
                          _buildSubMenuItem(
                            icon: Icons.business_outlined,
                            title: 'Ofisler',
                            onTap: () {
                              setState(() {
                                _selectedItem = 'Ofisler';
                              });
                              _handleNavigation(context, 'Ofisler');
                            },
                            isSelected: _selectedItem == 'Ofisler',
                          ),
                        ],
                      ),
                      _buildMenuItem(
                        icon: Icons.groups_outlined,
                        title: 'Müşteriler',
                        onTap: () => _handleNavigation(context, 'Müşteriler'),
                        isSelected: _selectedItem == 'Müşteriler',
                      ),
                      _buildMenuItem(
                        icon: Icons.folder_outlined,
                        title: 'Portföyüm',
                        onTap: () => _handleNavigation(context, 'Portföyüm'),
                        isSelected: _selectedItem == 'Portföyüm',
                      ),
                      _buildExpandableItem(
                        icon: Icons.home_work_outlined,
                        title: 'İlanlarım',
                        isExpanded: _selectedItem == 'İlanlarım' ||
                            _selectedItem == 'İlan Onay',
                        isSelected: _selectedItem == 'İlanlarım' ||
                            _selectedItem == 'İlan Onay',
                        onTap: () => _handleNavigation(context, 'İlanlarım'),
                        children: [
                          _buildSubMenuItem(
                            icon: Icons.list_alt_outlined,
                            title: 'İlanlarım',
                            onTap: () =>
                                _handleNavigation(context, 'İlanlarım'),
                            isSelected: _selectedItem == 'İlanlarım',
                          ),
                          _buildSubMenuItem(
                            icon: Icons.check_circle_outline,
                            title: 'İlan Onay',
                            onTap: () =>
                                _handleNavigation(context, 'İlan Onay'),
                            isSelected: _selectedItem == 'İlan Onay',
                          ),
                          _buildSubMenuItem(
                            icon: Icons.list_alt_outlined,
                            title: 'Tüm İlanlar',
                            onTap: () =>
                                _handleNavigation(context, 'Tüm İlanlar'),
                            isSelected: _selectedItem == 'Tüm İlanlar',
                          ),
                        ],
                      ),
                      _buildSystemSettingsSection(context),
                      _buildMenuItem(
                        icon: Icons.business_outlined,
                        title: 'Ofisim',
                        onTap: () => _handleNavigation(context, 'Ofisim'),
                        isSelected: _selectedItem == 'Ofisim',
                      ),
                      _buildMenuItem(
                        icon: Icons.campaign_outlined,
                        title: 'Ze-İlanlar',
                        onTap: () => _handleNavigation(context, 'Ze-İlanlar'),
                        isSelected: _selectedItem == 'Ze-İlanlar',
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Duyurular',
                        onTap: () => _handleNavigation(context, 'Duyurular'),
                        isSelected: _selectedItem == 'Duyurular',
                      ),
                      _buildMenuItem(
                        icon: Icons.assignment_outlined,
                        title: 'Görev Yöneticisi',
                        onTap: () =>
                            _handleNavigation(context, 'Görev Yöneticisi'),
                        isSelected: _selectedItem == 'Görev Yöneticisi',
                      ),
                      _buildMenuItem(
                        icon: Icons.calendar_month_outlined,
                        title: 'Akıllı Ajandam',
                        onTap: () =>
                            _handleNavigation(context, 'Akıllı Ajandam'),
                        isSelected: _selectedItem == 'Akıllı Ajandam',
                      ),
                      _buildMenuItem(
                        icon: Icons.message_outlined,
                        title: 'Mesajlar',
                        onTap: () => _handleNavigation(context, 'Mesajlar'),
                        isSelected: _selectedItem == 'Mesajlar',
                      ),
                      _buildMenuItem(
                        icon: Icons.local_offer_outlined,
                        title: 'Kampanyalar',
                        onTap: () => _handleNavigation(context, 'Kampanyalar'),
                        isSelected: _selectedItem == 'Kampanyalar',
                      ),
                      _buildMenuItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Finans',
                        onTap: () => _handleNavigation(context, 'Finans'),
                        isSelected: _selectedItem == 'Finans',
                      ),
                      _buildMenuItem(
                        icon: Icons.folder_copy_outlined,
                        title: 'ZeDosya',
                        onTap: () => _handleNavigation(context, 'ZeDosya'),
                        isSelected: _selectedItem == 'ZeDosya',
                      ),
                      // _buildMenuItem(
                      //   icon: Icons.newspaper_outlined,
                      //   title: 'ZeHaber',
                      //   onTap: () => _handleNavigation(context, 'ZeHaber'),
                      //   isSelected: _selectedItem == 'ZeHaber',
                      // ),
                      // _buildMenuItem(
                      //   icon: Icons.article_outlined,
                      //   title: 'ZeBlog',
                      //   onTap: () => _handleNavigation(context, 'ZeBlog'),
                      //   isSelected: _selectedItem == 'ZeBlog',
                      // ),
                      // _buildMenuItem(
                      //   icon: Icons.help_outline,
                      //   title: 'Sıkça Sorulan Sorular',
                      //   onTap: () =>
                      //       _handleNavigation(context, 'Sıkça Sorulan Sorular'),
                      //   isSelected: _selectedItem == 'Sıkça Sorulan Sorular',
                      // ),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Başvuru Formları',
                        onTap: () =>
                            _handleNavigation(context, 'Başvuru Formları'),
                        isSelected: _selectedItem == 'Başvuru Formları',
                      ),
                      _buildMenuItem(
                        icon: Icons.school_outlined,
                        title: 'Seminer ve Eğitimler',
                        onTap: () =>
                            _handleNavigation(context, 'Seminer ve Eğitimler'),
                        isSelected: _selectedItem == 'Seminer ve Eğitimler',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(left: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
      ],
    );
  }

  Widget _buildSubMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
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

  Widget _buildSystemSettingsSection(BuildContext context) {
    final bool isIlanlar = _selectedItem == 'Öne Çıkan İlanlar';
    final bool isDanismanlar = _selectedItem == 'Öne Çıkan Danışmanlar';
    final bool isSystemSelected = isIlanlar || isDanismanlar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isSystemSettingsExpanded = !_isSystemSettingsExpanded;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isSystemSelected
                      ? const Color(0xFFE53935).withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 24,
                      color: isSystemSelected
                          ? const Color(0xFFE53935)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Sistem Ayarları',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSystemSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSystemSelected
                              ? const Color(0xFFE53935)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isSystemSettingsExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 22,
                        color: isSystemSelected
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
        if (_isSystemSettingsExpanded)
          Container(
            margin: const EdgeInsets.only(left: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSubMenuItem(
                  icon: Icons.star_outline,
                  title: 'Öne Çıkan İlanlar',
                  onTap: () async {
                    setState(() {
                      _selectedItem = 'Öne Çıkan İlanlar';
                      _isSystemSettingsExpanded = true;
                    });
                    final authCubit = context.read<AuthCubit>();
                    final userRoleCodes = await authCubit.getUserRoleCodes();
                    _navigateToRoleAwareScreen(context, '/system-settings', userRoleCodes);
                  },
                  isSelected: isIlanlar,
                ),
                _buildSubMenuItem(
                  icon: Icons.person_outline,
                  title: 'Öne Çıkan Danışmanlar',
                  onTap: () async {
                    setState(() {
                      _selectedItem = 'Öne Çıkan Danışmanlar';
                      _isSystemSettingsExpanded = true;
                    });
                    final authCubit = context.read<AuthCubit>();
                    final userRoleCodes = await authCubit.getUserRoleCodes();
                    _navigateToRoleAwareScreen(context, '/one-of-the-consultants', userRoleCodes);
                  },
                  isSelected: isDanismanlar,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Web sitesindeki mantığa göre dashboard'a yönlendirme
  void _navigateToDashboard(BuildContext context, List<String> userRoleCodes) async {
    final authCubit = context.read<AuthCubit>();
    final dashboardRoute = await authCubit.getDashboardRoute();
    
    print('AdminPanelSidebar - Dashboard yönlendirme - Route: $dashboardRoute');
    
    // Route'a göre dashboard seçimi
    switch (dashboardRoute) {
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
