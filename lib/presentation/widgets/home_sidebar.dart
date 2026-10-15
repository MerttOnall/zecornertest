import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zecorner/router/app_router.dart';

class HomeSidebar extends StatefulWidget {
  final String currentPage;

  const HomeSidebar({
    super.key,
    required this.currentPage,
  });

  @override
  State<HomeSidebar> createState() => _HomeSidebarState();
}

class _HomeSidebarState extends State<HomeSidebar> {
  late String _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.currentPage;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Logo
          SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(16),
            child: SvgPicture.asset(
              'assets/logo/zecorner-logo1.svg',
              height: 40,
            ),
          ),
          const SizedBox(height: 8),

          // Ana Sayfa
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Ana Sayfa',
            onTap: () => Navigator.pushNamed(context, AppRouter.homeListings),
            isSelected: _selectedItem == 'Ana Sayfa',
          ),

          // Ofislerimiz
          _buildDrawerItem(
            icon: Icons.business,
            title: 'Ofislerimiz',
            onTap: () => Navigator.pushNamed(context, AppRouter.homeOffice),
            isSelected: _selectedItem == 'Ofislerimiz',
          ),

           // Ekibimiz
          _buildDrawerItem(
            icon: Icons.people_outline,
            title: 'Ekibimiz',
            onTap: () => Navigator.pushNamed(context, AppRouter.team),
            isSelected: _selectedItem == 'Ekibimiz',
          ),

           // Semirler
          _buildDrawerItem(
            icon: Icons.list,
            title: 'Seminerler',
            onTap: () => Navigator.pushNamed(context, AppRouter.homeSeminer),
            isSelected: _selectedItem == 'Seminerler',
          ),

           // Zehaber mobil menüde kapalı.
          // _buildDrawerItem(
          //   icon: Icons.list,
          //   title: 'Zehaber',
          //   onTap: () => Navigator.pushNamed(context, AppRouter.homeZehaber),
          //   isSelected: _selectedItem == 'Zehaber',
          // ),

          // Hakkımızda
          _buildDrawerItem(
            icon: Icons.info,
            title: 'Hakkımızda',
            onTap: () => Navigator.pushNamed(context, AppRouter.about),
            isSelected: _selectedItem == 'Hakkımızda',
          ),

          // İletişim
          _buildDrawerItem(
            icon: Icons.contact_phone,
            title: 'İletişim',
            onTap: () {Navigator.pushNamed(context, AppRouter.contact);},
            isSelected: _selectedItem == 'İletişim',
          ),

          // Franchise
          _buildDrawerItem(
            icon: Icons.person_add,
            title: 'Franchise',
            onTap: () => Navigator.pushNamed(context, AppRouter.homeFranchise),
            isSelected: _selectedItem == 'Franchise',
          ),

          // Blog
          _buildDrawerItem(
            icon: Icons.article_outlined,
            title: 'Blog',
            onTap: () => Navigator.pushNamed(context, AppRouter.blog),
            isSelected: _selectedItem == 'Blog',
          ),

           // SSS mobil menüde kapalı.
          // _buildDrawerItem(
          //   icon: Icons.help_outline,
          //   title: 'SSS',
          //   onTap: () => Navigator.pushNamed(context, AppRouter.sss),
          //   isSelected: _selectedItem == 'SSS',
          // ),

         

          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Hesap Oluştur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFFE53935) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFFE53935) : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: Colors.red.shade50,
    );
  }
} 