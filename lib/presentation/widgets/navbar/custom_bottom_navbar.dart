import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/presentation/home-screens/home_list_screen.dart';
import 'package:zecorner/presentation/home-screens/home_office_screen.dart';
import 'package:zecorner/presentation/home-screens/home_portfoy_screen.dart';
import 'package:zecorner/presentation/home-screens/home_tum_ilan_screen.dart';
import 'package:zecorner/presentation/screens/portfolio/add_portfolio_screen.dart';
import 'package:zecorner/presentation/home-screens/home_ilan_screen.dart';
import 'package:zecorner/presentation/home-screens/home_profile_screen.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/login/login_screen.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_sidebar.dart';
import 'package:zecorner/presentation/widgets/brocker-panel/brocker_sidebar.dart';
import 'package:zecorner/presentation/widgets/danisman-panel/danisman_sidebar.dart';
import 'package:zecorner/presentation/widgets/franchise-panel/franchise_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/navbar_navigation.dart';

/// Sayfa bazlı navbar teması. [homeWelcome] sadece ana sayfa (kırmızı arka plan) için.
enum NavbarTheme { standard, homeWelcome }

class CustomBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final NavbarTheme theme;

  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
    required Null Function(dynamic index) onTap,
    this.theme = NavbarTheme.standard,
  });



  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // Role sistemine göre navbar seçimi
        if (authState is AuthAuthenticated) {
          final authCubit = context.read<AuthCubit>();
          
          // Role ID'sine göre navbar seçimi
          final roleId = authCubit.currentRole;
          print('Mevcut Role ID: $roleId');
          print('Admin: ${authCubit.isAdmin}');
          print('Manager: ${authCubit.isManager}');
          print('Agent: ${authCubit.isAgent}');
          
          // Web projesindeki role mantığına göre navbar seçimi
          final roleCode = authCubit.currentRoleCode;
          final currentRole = authCubit.currentRoleObject;
          
          print('Mevcut Role Code: $roleCode');
          print('Mevcut Role Object: ${currentRole?.name} (${currentRole?.code})');
          print('All Role Codes: ${authCubit.allRoleCodes}');
          
          // Web projesindeki mantığa göre navbar seçimi - async olarak role kodlarını al
          return FutureBuilder<({List<String> codes, bool isAdmin})>(
            future: () async {
              final codes = await authCubit.getUserRoleCodes();
              final prefs = await SharedPreferences.getInstance();
              return (
                codes: codes,
                isAdmin: prefs.getBool('userIsAdmin') == true,
              );
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: kBottomNavigationBarHeight,
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }
              
              final userRoleCodes = snapshot.data?.codes ?? [];
              final isAdminUser = snapshot.data?.isAdmin == true;
              print('Navbar - User Role Codes: $userRoleCodes, Admin: $isAdminUser');
              
              if (isAdminUser) {
                print('Admin navbar seçildi (is_admin)');
                return AdminNavbar(
                  currentIndex: currentIndex,
                  onTap: (index) {},
                );
              } else if (userRoleCodes.contains('role_advisor')) {
                print('Advisor navbar seçildi (role_advisor)');
                return DanismanNavbar(
                  currentIndex: currentIndex,
                  onTap: (index) {},
                );
              } else if (userRoleCodes.contains('role_office_broker') || userRoleCodes.contains('role_office_assistant')) {
                print('Office navbar seçildi (role_office_broker/role_office_assistant)');
                return BrokerNavbar(
                  currentIndex: currentIndex,
                  onTap: (index) {},
                );
              } else if (userRoleCodes.contains('role_form_applications') || userRoleCodes.contains('role_form_applications_admin')) {
                print('Form Applications navbar seçildi');
                return BrokerNavbar(
                  currentIndex: currentIndex,
                  onTap: (index) {},
                );
              } else if (userRoleCodes.contains('role_sale_applications') || userRoleCodes.contains('role_sale_applications_admin')) {
                print('Sale Applications navbar seçildi');
                return BrokerNavbar(
                  currentIndex: currentIndex,
                  onTap: (index) {},
                );
              } else {
                // Diğer roller için varsayılan navbar
                print('Varsayılan navbar seçildi (Role Code: $roleCode)');
                return FrancahiseNavbar(
                  currentIndex: currentIndex,
                  onTap: (index) {},
                );
              }
            },
          );
        }
        
        // Giriş yapmamış kullanıcılar için varsayılan navbar
        final isHomeWelcome = theme == NavbarTheme.homeWelcome;
        // Ana sayfa: beyaz cam navbar (referans fotoğraftan farklı – daha temiz)
        final barColor = isHomeWelcome
            ? Colors.white.withOpacity(0.96)
            : Colors.white;
        final selectedBg = isHomeWelcome
            ? const Color(0xFFDD1A2F).withOpacity(0.12)
            : Colors.red.withOpacity(0.1);
        final iconActive = isHomeWelcome ? const Color(0xFFDD1A2F) : Colors.red;
        final iconInactive = isHomeWelcome ? const Color(0xFF64748B) : Colors.grey[400]!;
        final fabColor = isHomeWelcome ? const Color(0xFFDD1A2F) : Colors.red;
        final fabIconColor = Colors.white;
        final fabShadow = isHomeWelcome
            ? [
                BoxShadow(
                  color: const Color(0xFFDD1A2F).withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, spreadRadius: 2, offset: const Offset(0, 2))];

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: isHomeWelcome ? 20 : 0, sigmaY: isHomeWelcome ? 20 : 0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: isHomeWelcome
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ]
                    : null,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int i = 0; i < 5; i++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (i == currentIndex) return;
                              if ((i == 2 || i == 4) && authState is! AuthAuthenticated) {
                                NavbarNavigation.open(context, const LoginScreen());
                                return;
                              }
                              if (authState is AuthAuthenticated) {
                                final authCubit = context.read<AuthCubit>();
                                if (i == 2 && !authCubit.isAdmin && !authCubit.isManager && !authCubit.isAgent) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Bu işlem için yetkiniz bulunmamaktadır.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                              }
                              String? targetRoute;
                              switch (i) {
                                case 0: targetRoute = '/home-listings'; break;
                                case 1: targetRoute = '/home-office'; break;
                                case 2: targetRoute = '/add-portfolio'; break;
                                case 3: targetRoute = '/home-ilan'; break;
                                case 4: targetRoute = '/home-profile'; break;
                              }
                              Widget? page;
                              switch (targetRoute) {
                                case '/home-listings': page = const HomeListingsScreen(); break;
                                case '/home-office': page = const HomeOfficeScreen(); break;
                                case '/add-portfolio': page = const HomePortfoyScreen(); break;
                                case '/home-ilan': page = const HomeTumIlansScreen(); break;
                                case '/home-profile': page = const HomeProfileScreen(); break;
                              }
                              if (page != null) {
                                NavbarNavigation.push(context, page);
                              }
                            },
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: i == 2 ? 48 : 44,
                                height: i == 2 ? 48 : 44,
                                decoration: BoxDecoration(
                                  color: i == 2 ? fabColor : (currentIndex == i ? selectedBg : Colors.transparent),
                                  shape: BoxShape.circle,
                                  boxShadow: i == 2 ? fabShadow : [],
                                ),
                                child: Icon(
                                  i == 0 ? Icons.home_rounded
                                      : i == 1 ? Icons.business_rounded
                                      : i == 2 ? Icons.add_rounded
                                      : i == 3 ? Icons.search_rounded
                                      : Icons.person_rounded,
                                  color: i == 2 ? fabIconColor : (currentIndex == i ? iconActive : iconInactive),
                                  size: i == 2 ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 