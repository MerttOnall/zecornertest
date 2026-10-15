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
import 'package:zecorner/core/cubit/auth_cubit.dart';
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

  @override
  void initState() {
    super.initState();
    
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
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                                children: [
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
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const AccountSettingsScreen(),
                                        ),
                                      );
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
