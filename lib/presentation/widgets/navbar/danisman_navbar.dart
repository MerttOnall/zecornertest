import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:zecorner/presentation/home-screens/home_list_screen.dart';
import 'package:zecorner/presentation/home-screens/home_office_screen.dart';
import 'package:zecorner/presentation/home-screens/home_portfoy_screen.dart';
import 'package:zecorner/presentation/home-screens/home_tum_ilan_screen.dart';
import 'package:zecorner/presentation/screens/dashboard/admin_dashboard_screen.dart';
import 'package:zecorner/presentation/screens/dashboard/danisman_dashboard_screen.dart';
import 'package:zecorner/presentation/screens/tilan/tum_ilan_screen.dart';
import 'package:zecorner/presentation/screens/office/offices_screen.dart';
import 'package:zecorner/presentation/screens/persons/persons_screen.dart';
import 'package:zecorner/presentation/screens/portfolio/add_portfolio_screen.dart';
import 'package:zecorner/presentation/screens/srapor/srapor_screen.dart';
import 'package:zecorner/presentation/home-screens/home_ilan_screen.dart';
import 'package:zecorner/presentation/home-screens/home_profile_screen.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DanismanNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const DanismanNavbar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(

      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 5; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      // Role kontrolü
                      final authCubit = context.read<AuthCubit>();
                      final userRoleCodes = await authCubit.getUserRoleCodes();
                      
                      // Sadece danışman rolü varsa devam et
                      if (!userRoleCodes.contains('role_advisor')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bu sayfaya erişim yetkiniz bulunmamaktadır.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      String? targetRoute;
                      switch (i) {
                        case 0:
                          targetRoute = '/danisman-dashboard';
                          break;
                        case 1:
                          targetRoute = '/srapor';
                          break;
                        case 2:
                          targetRoute = '/add-portfolio';
                          break;
                        case 3:
                          targetRoute = '/tum-ilanlar';
                          break;
                        case 4:
                          targetRoute = '/home-profile';
                          break;
                      }
                      Widget? page;
                      switch (targetRoute) {
                        case '/danisman-dashboard':
                          page = const DanismanDashboardScreen();
                          break;
                        case '/srapor':
                          page = const SraporScreen();
                          break;
                        case '/add-portfolio':
                          page = const AddPortfolioScreen();
                          break;
                        case '/tum-ilanlar':
                          page = const TumIlanScreen();
                          break;
                        case '/home-profile':
                          page = const HomeProfileScreen();
                          break;
                      }
                      if (page != null) {
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => page!,
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child;
                            },
                          ),
                        );
                      }
                    },
                    child: Center(
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: i == 2
                              ? Colors.red
                              : (currentIndex == i ? Colors.red.withOpacity(0.1) : Colors.transparent),
                          shape: BoxShape.circle,
                          boxShadow: i == 2
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          i == 0
                              ? Icons.home_outlined
                              : i == 1
                                  ? Icons.bar_chart_outlined
                                  : i == 2
                                      ? Icons.add
                                      : i == 3
                                          ? Icons.search
                                          : Icons.person_outline,
                          color: i == 2
                              ? Colors.white
                              : (currentIndex == i ? Colors.red : Colors.grey[400]),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 