import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/presentation/home-screens/home_about_screen.dart';
import 'package:zecorner/presentation/home-screens/home_profile_cerez_screen.dart';
import 'package:zecorner/presentation/home-screens/home_profile_kosul_screen.dart';
import 'package:zecorner/presentation/home-screens/home_profile_kvkk_screen.dart';
import 'package:zecorner/presentation/home-screens/home_team_screen.dart';
import 'package:zecorner/presentation/login/login_screen.dart';
import 'package:zecorner/presentation/register/register_screen.dart';
import 'package:zecorner/presentation/screens/contact_screen.dart';
import 'package:zecorner/presentation/screens/profile/account_settings_screen.dart';
import 'package:zecorner/presentation/screens/profile/favorite_danisman_screnn.dart';
import 'package:zecorner/presentation/screens/profile/favorite_list_screen.dart';
// import 'package:zecorner/presentation/screens/profile/profile_chat_screen.dart';
import 'package:zecorner/presentation/screens/profile/profile_notification_screen.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/models/users/user_profile_model.dart';
import 'package:zecorner/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class HomeProfileScreen extends StatefulWidget {
  const HomeProfileScreen({super.key});

  @override
  State<HomeProfileScreen> createState() => _HomeProfileScreenState();
}

class _HomeProfileScreenState extends State<HomeProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  // Animation controllers for background
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _waveController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _waveAnimation;
  
  int _currentIndex = 4;
  UserProfileModel? _profile;
  bool _loadingProfile = true;
  String _fallbackName = '';
  String _fallbackEmail = '';
  String _fallbackPhone = '';
  String _fallbackRole = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    // Original animations
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    
    // Background animation controllers
    _rotationController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    
    // Initialize background animations
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
    
    _fadeController.forward();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _fallbackName =
            '${prefs.getString('userName') ?? ''} ${prefs.getString('userSurname') ?? ''}'
                .trim();
        _fallbackEmail = prefs.getString('userEmail') ?? '';
        _fallbackPhone = prefs.getString('userPhone') ?? '';
        _fallbackRole = prefs.getString('userTypeDescription') ?? '';
      });
      final profile = await UserProfileService().getUserInfo();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Çıkış yapıldığında ana sayfaya yönlendir
          Navigator.of(context).pushReplacementNamed('/home-listings');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE53935), // Kırmızı
                Color(0xFFD32F2F), // Koyu kırmızı
                Color(0xFFB71C1C), // Çok koyu kırmızı
                Color(0xFF8E0000), // En koyu kırmızı
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated background elements
              // Sağ üst büyük daire
              Positioned(
                right: -120,
                top: -120,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_rotationController, _pulseAnimation]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              
              // Sol alt orta daire
              Positioned(
                left: -80,
                bottom: -80,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_rotationController, _pulseAnimation]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_rotationController.value * 1.5 * math.pi,
                      child: Transform.scale(
                        scale: _pulseAnimation.value * 0.8,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              
              // Orta dalga efekti
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 150,
                top: MediaQuery.of(context).size.height / 4,
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(300, 100),
                      painter: WavePainter(_waveAnimation.value),
                    );
                  },
                ),
              ),
              
              // Küçük yüzen parçacıklar
              ...List.generate(8, (index) {
                return Positioned(
                  left: (index * 50.0) % MediaQuery.of(context).size.width,
                  top: (index * 80.0) % MediaQuery.of(context).size.height,
                  child: AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          math.sin(_floatingAnimation.value + index) * 10,
                          math.cos(_floatingAnimation.value + index) * 10,
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 6 + (index % 3) * 2,
                      height: 6 + (index % 3) * 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
              
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Custom AppBar with floating animation
                    AnimatedBuilder(
                      animation: _floatingAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatingAnimation.value * 0.3),
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Colors.white,
                                  Color(0xFFF5F5F5),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Profilim',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                            // Logout button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      contentPadding: const EdgeInsets.all(24),
                                      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                                      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                                      title: const Text(
                                        'Çıkış Yap',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      content: const Text(
                                        'Hesaptan çıkış yapmak istediğinize emin misiniz?',
                                        style: TextStyle(
                                          color: Color(0xFF5D6D7E),
                                          fontSize: 16,
                                          height: 1.4,
                                        ),
                                      ),
                                      actions: [
                                        Container(
                                          height: 44,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 20),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Hayır',
                                              style: TextStyle(
                                                color: Color(0xFF5D6D7E),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFE53935),
                                                Color(0xFFD32F2F),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFE53935).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              // AuthCubit ile çıkış yap
                                              context.read<AuthCubit>().signOut();
                                            },
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(horizontal: 20),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Evet',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Profile content
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                                children: [
                                  _ProfileIdentityCard(
                                    profile: _profile,
                                    loading: _loadingProfile,
                                    fallbackName: _fallbackName,
                                    fallbackEmail: _fallbackEmail,
                                    fallbackPhone: _fallbackPhone,
                                    fallbackRole: _fallbackRole,
                                    onEdit: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AccountSettingsScreen(),
                                        ),
                                      );
                                      if (mounted) _loadProfile();
                                    },
                                  ),
                                  _SectionTitle('Favoriler'),
                                  _AnimatedProfileTile(
                                    icon: Icons.favorite_outline,
                                    text: 'Favori İlanlar',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const FavoriteListScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _AnimatedProfileTile(
                                    icon: Icons.people_outline,
                                    text: 'Favori Danışmanlar',
                                    onTap: () { 
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const FavoriteDanismanScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  _SectionTitle('İletişim'),
                                  // _AnimatedProfileTile(
                                  //   icon: Icons.message_outlined,
                                  //   text: 'Mesajlar',
                                  //   onTap: () {
                                  //     Navigator.of(context).push(
                                  //       MaterialPageRoute(
                                  //         builder: (context) =>
                                  //             const ProfileChatScreenWrapper(),
                                  //       ),
                                  //     );
                                  //   },
                                  // ),
                                  _AnimatedProfileTile(
                                    icon: Icons.notifications_outlined,
                                    text: 'Bildirimler',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const ProfileNotificationScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  _SectionTitle('Hesap'),
                                  _AnimatedProfileTile(
                                    icon: Icons.settings_outlined,
                                    text: 'Hesap Ayarları',
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const AccountSettingsScreen(),
                                        ),
                                      );
                                      if (mounted) _loadProfile();
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  _SectionTitle('Hukuki'),
                                  _AnimatedProfileTile(
                                    icon: Icons.privacy_tip_outlined,
                                    text: 'KVKK',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const HomeProfileKvkkScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _AnimatedProfileTile(
                                    icon: Icons.article_outlined,
                                    text: 'Çerez Politikası',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const HomeProfileCerezScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _AnimatedProfileTile(
                                    icon: Icons.view_list_outlined,
                                    text: 'Kullanım Koşulları',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const HomeProfileKosulScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  const SizedBox(height: 40),
                                  
                                  // Action buttons
                                  // AnimatedBuilder(
                                  //   animation: _floatingAnimation,
                                  //   builder: (context, child) {
                                  //     return Transform.translate(
                                  //       offset: Offset(0, _floatingAnimation.value * 0.2),
                                  //       child: child,
                                  //     );
                                  //   },
                                  //   child: Column(
                                  //     children: [
                                  //       // Login button
                                  //       Container(
                                  //         width: double.infinity,
                                  //         height: 52,
                                  //         decoration: BoxDecoration(
                                  //           gradient: const LinearGradient(
                                  //             colors: [
                                  //               Color(0xFFE53935),
                                  //               Color(0xFFD32F2F),
                                  //             ],
                                  //           ),
                                  //           borderRadius: BorderRadius.circular(12),
                                  //           boxShadow: [
                                  //             BoxShadow(
                                  //               color: const Color(0xFFE53935).withOpacity(0.4),
                                  //               blurRadius: 15,
                                  //               offset: const Offset(0, 8),
                                  //             ),
                                  //           ],
                                  //         ),
                                  //         child: ElevatedButton(
                                  //           onPressed: () {
                                  //             Navigator.of(context).push(
                                  //               MaterialPageRoute(
                                  //                 builder: (context) => const LoginScreen(),
                                  //               ),
                                  //             );
                                  //           },
                                  //           style: ElevatedButton.styleFrom(
                                  //             backgroundColor: Colors.transparent,
                                  //             shadowColor: Colors.transparent,
                                  //             shape: RoundedRectangleBorder(
                                  //               borderRadius: BorderRadius.circular(12),
                                  //             ),
                                  //           ),
                                  //           child: const Text(
                                  //             'Giriş Yap',
                                  //             style: TextStyle(
                                  //               color: Colors.white,
                                  //               fontSize: 16,
                                  //               fontWeight: FontWeight.w600,
                                  //               letterSpacing: 0.5,
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       ),
                                        
                                  //       const SizedBox(height: 16),
                                        
                                  //       // Register button
                                  //       Container(
                                  //         width: double.infinity,
                                  //         height: 52,
                                  //         decoration: BoxDecoration(
                                  //           borderRadius: BorderRadius.circular(12),
                                  //           border: Border.all(
                                  //             color: const Color(0xFFE53935),
                                  //             width: 2,
                                  //           ),
                                  //           boxShadow: [
                                  //             BoxShadow(
                                  //               color: const Color(0xFFE53935).withOpacity(0.1),
                                  //               blurRadius: 10,
                                  //               offset: const Offset(0, 4),
                                  //             ),
                                  //           ],
                                  //         ),
                                  //         child: ElevatedButton(
                                  //           onPressed: () {
                                  //             Navigator.of(context).push(
                                  //               MaterialPageRoute(
                                  //                 builder: (context) => const RegisterScreen(),
                                  //               ),
                                  //             );
                                  //           },
                                  //           style: ElevatedButton.styleFrom(
                                  //             backgroundColor: Colors.white,
                                  //             shadowColor: Colors.transparent,
                                  //             shape: RoundedRectangleBorder(
                                  //               borderRadius: BorderRadius.circular(12),
                                  //             ),
                                  //           ),
                                  //           child: const Text(
                                  //             'Hesap Oluştur',
                                  //             style: TextStyle(
                                  //               color: Color.fromRGBO(238, 46, 36, 1),
                                  //               fontSize: 16,
                                  //               fontWeight: FontWeight.w600,
                                  //               letterSpacing: 0.5,
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavbar(
          currentIndex: _currentIndex,
          onTap: (index) {},
        ),
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  final UserProfileModel? profile;
  final bool loading;
  final String fallbackName;
  final String fallbackEmail;
  final String fallbackPhone;
  final String fallbackRole;
  final VoidCallback onEdit;

  const _ProfileIdentityCard({
    required this.profile,
    required this.loading,
    required this.fallbackName,
    required this.fallbackEmail,
    required this.fallbackPhone,
    required this.fallbackRole,
    required this.onEdit,
  });

  String _clean(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text == '0' || text == '-') return '';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final name = _clean(
      profile == null ? fallbackName : '${profile!.name} ${profile!.surname}',
    );
    final role = _clean(profile?.typeDescription ?? fallbackRole);
    final profession = _clean(profile?.detail.profession?.description);
    final email = _clean(profile?.email ?? fallbackEmail);
    final phone = _clean(profile?.tel ?? fallbackPhone);
    final office = _clean(profile?.connectedContactTitle);
    final uavt = profile?.address.uavtAddress;
    final place = [
      if (uavt != null && uavt.districtName.trim().isNotEmpty) uavt.districtName.trim(),
      if (uavt != null && uavt.provinceName.trim().isNotEmpty) uavt.provinceName.trim(),
    ].join(', ');
    final subtitle = profession.isNotEmpty && profession != role ? profession : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0D6D4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProfileAvatar(
                picture: profile?.detail.picture ?? profile?.detail.logo,
                loading: loading && profile == null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Profilim' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C2430),
                        height: 1.2,
                      ),
                    ),
                    if (role.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (phone.isNotEmpty || email.isNotEmpty || office.isNotEmpty || place.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F2F4)),
            const SizedBox(height: 8),
            if (phone.isNotEmpty) _infoRow(Icons.phone_outlined, phone),
            if (email.isNotEmpty) _infoRow(Icons.mail_outline, email),
            if (office.isNotEmpty) _infoRow(Icons.apartment_outlined, office),
            if (place.isNotEmpty) _infoRow(Icons.location_on_outlined, place),
          ] else if (loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFFE53935),
              backgroundColor: Color(0xFFF8E6E5),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFE53935)),
              label: const Text(
                'Hesap ayarları',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFE53935)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  final String? picture;
  final bool loading;

  const _ProfileAvatar({required this.picture, required this.loading});

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  int _urlIndex = 0;
  bool _advancing = false;

  @override
  void didUpdateWidget(covariant _ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.picture != widget.picture) {
      _urlIndex = 0;
      _advancing = false;
    }
  }

  List<String> _urls(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return const [];
    if (trimmed.startsWith('http')) return [trimmed];
    final encoded = Uri.encodeQueryComponent(trimmed);
    final urls = <String>[];
    final origin = EnvApi.webNextApiOrigin;
    if (origin != null && origin.isNotEmpty) {
      urls.add('$origin/api/retrieve-file/?name=$encoded');
      urls.add('$origin/api/retrieve-file?name=$encoded&type=image');
    }
    final direct = ImageUtils.getS3FileUrl(trimmed);
    if (direct.isNotEmpty) urls.add(direct);
    urls.addAll(ImageUtils.getAlternativeImageUrls(trimmed));
    final seen = <String>{};
    return urls.where(seen.add).toList();
  }

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    final urls = _urls(widget.picture ?? '');
    final showPlaceholder = widget.loading || urls.isEmpty || _urlIndex >= urls.length;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.25), width: 2),
      ),
      child: ClipOval(
        child: showPlaceholder
            ? const ColoredBox(
                color: Color(0xFFFDECEC),
                child: Icon(Icons.person, color: Color(0xFFE53935), size: 36),
              )
            : Image.network(
                urls[_urlIndex],
                width: size,
                height: size,
                fit: BoxFit.cover,
                headers: const {'User-Agent': 'com.zecorner.app'},
                errorBuilder: (_, __, ___) {
                  if (!_advancing && _urlIndex < urls.length - 1) {
                    _advancing = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _urlIndex++;
                        _advancing = false;
                      });
                    });
                  }
                  return const ColoredBox(
                    color: Color(0xFFFDECEC),
                    child: Icon(Icons.person, color: Color(0xFFE53935), size: 36),
                  );
                },
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 0, 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromRGBO(238, 46, 36, 1),
          fontSize: 14,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _AnimatedProfileTile extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  
  const _AnimatedProfileTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });
  
  @override
  State<_AnimatedProfileTile> createState() => _AnimatedProfileTileState();
}

class _AnimatedProfileTileState extends State<_AnimatedProfileTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 1.0,
      upperBound: 1.02,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _pressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _pressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _pressed ? Colors.grey[50] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _pressed 
                      ? const Color(0xFFE53935).withOpacity(0.3)
                      : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFFE53935),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for wave effect
class WavePainter extends CustomPainter {
  final double animationValue;
  
  WavePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    for (int i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final y = size.height / 2 + 
          math.sin((x / size.width * 2 * math.pi) + animationValue) * 20;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
