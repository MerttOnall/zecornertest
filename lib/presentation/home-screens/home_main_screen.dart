import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/presentation/home-screens/home_profile_screen.dart';
import 'package:zecorner/presentation/home-screens/home_office_screen.dart';
import 'package:zecorner/presentation/home-screens/home_ilan_screen.dart';
import 'package:zecorner/presentation/home-screens/home_list_screen.dart';
// AddPortfolioScreen varsa import et, yoksa boş bir widget ile doldurulabilir.

class HomeMainScreen extends StatefulWidget {
  const HomeMainScreen({Key? key}) : super(key: key);

  @override
  State<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends State<HomeMainScreen> {
  int _currentIndex = 4; // Profil sekmesiyle başla

  final List<Widget> _pages = const [
    HomeListingsScreen(), // 0: Ana Sayfa
    HomeOfficeScreen(),   // 1: Ofisler
    SizedBox.shrink(),    // 2: Portföy Ekle (veya AddPortfolioScreen())
    HomeIlanScreen(),     // 3: İlanlar
    HomeProfileScreen(),  // 4: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
} 