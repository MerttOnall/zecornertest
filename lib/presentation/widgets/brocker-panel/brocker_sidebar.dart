import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../screens/dashboard/broker_dashboard_screen.dart';
import '../../screens/dashboard/admin_dashboard_screen.dart';
import '../../screens/dashboard/danisman_dashboard_screen.dart';
import '../../../core/cubit/auth_cubit.dart';

class BrockerSidebar extends StatelessWidget {
  const BrockerSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Center(
              child: SvgPicture.asset(
                "assets/logo/zecorner-logo1.svg",
                width: 150,
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Ana Sayfa',
            onTap: () => _navigateToDashboard(context),
            isSelected: true,
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Müşteriler',
            onTap: () => _navigateToRoleAwareScreen(context, '/customers'),
          ),
          _buildDrawerItem(
            icon: Icons.folder_special,
            title: 'Portföyüm',
            onTap: () => _navigateToRoleAwareScreen(context, '/portfolio'),
          ),
          _buildDrawerItem(
            icon: Icons.real_estate_agent,
            title: 'İlanlarım',
            onTap: () => _navigateToRoleAwareScreen(context, '/my-listings'),
          ),
          _buildDrawerItem(
            icon: Icons.business,
            title: 'Ofisim',
            onTap: () => _navigateToRoleAwareScreen(context, '/my-office'),
          ),
          _buildDrawerItem(
            icon: Icons.campaign,
            title: 'Ze-İlanlar',
            onTap: () => _navigateToRoleAwareScreen(context, '/zeilan'),
          ),
          _buildDrawerItem(
            icon: Icons.notifications,
            title: 'Duyurular',
            onTap: () => _navigateToRoleAwareScreen(context, '/announcements'),
          ),
          _buildDrawerItem(
            icon: Icons.assignment,
            title: 'Görev Yöneticisi',
            onTap: () => _navigateToRoleAwareScreen(context, '/task-manager'),
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Akıllı Ajandam',
            onTap: () => _navigateToRoleAwareScreen(context, '/agenda'),
          ),
          _buildDrawerItem(
            icon: Icons.message,
            title: 'Mesajlar',
            onTap: () => _navigateToRoleAwareScreen(context, '/profile-chat'),
          ),
          _buildDrawerItem(
            icon: Icons.local_offer,
            title: 'Kampanyalar',
            onTap: () => _navigateToRoleAwareScreen(context, '/offers'),
          ),
          _buildDrawerItem(
            icon: Icons.account_balance_wallet,
            title: 'Finans',
            onTap: () => _navigateToRoleAwareScreen(context, '/finance'),
          ),
          _buildDrawerItem(
            icon: Icons.folder,
            title: 'ZeDosya',
            onTap: () => _navigateToRoleAwareScreen(context, '/zedosya'),
          ),
          _buildDrawerItem(
            icon: Icons.description,
            title: 'Başvuru Formları',
            onTap: () => _navigateToRoleAwareScreen(context, '/bform'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Colors.red.shade50,
                  Colors.white,
                ],
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.red : Colors.red.shade300,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.red : Colors.red.shade900,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
        hoverColor: Colors.red.shade50,
        selectedTileColor: Colors.red.shade50,
        selected: isSelected,
      ),
    );
  }

  // Web sitesindeki mantığa göre dashboard'a yönlendirme
  void _navigateToDashboard(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final dashboardRoute = await authCubit.getDashboardRoute();
    
    print('BrockerSidebar - Dashboard yönlendirme - Route: $dashboardRoute');
    
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
  void _navigateToRoleAwareScreen(BuildContext context, String route) async {
    final authCubit = context.read<AuthCubit>();
    final userRoleCodes = await authCubit.getUserRoleCodes();
    
    print('BrockerSidebar - Role-aware yönlendirme - Route: $route, User Role Codes: $userRoleCodes');
    print('BrockerSidebar - Current Role Code: ${authCubit.currentRoleCode}');
    
    // Role sistemini koruyarak yönlendirme
    // Önce mevcut dashboard route'unu al
    final currentDashboardRoute = await authCubit.getDashboardRoute();
    
    // Route'a göre role-aware yönlendirme - role sistemini koruyarak
    if (route == '/customers') {
      // Müşteriler sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/portfolio') {
      // Portföy sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/my-listings') {
      // İlanlarım sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/my-office') {
      // Ofisim sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/zeilan') {
      // Ze-İlanlar sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/announcements') {
      // Duyurular sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/task-manager') {
      // Görev Yöneticisi sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/agenda') {
      // Akıllı Ajandam sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/profile-chat') {
      // Mesajlar sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/offers') {
      // Kampanyalar sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/finance') {
      // Finans sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/zedosya') {
      // ZeDosya sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else if (route == '/bform') {
      // Başvuru Formları sayfası - role sistemini koru
      Navigator.pushNamed(context, route);
    } else {
      // Bilinmeyen route için varsayılan davranış
      Navigator.pushNamed(context, route);
    }
  }
} 