import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'dart:math' as math;
import 'package:zecorner/core/services/permission_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
  // Animation controllers
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _waveController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
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
    
    // Initialize animations
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
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _waveController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(238, 46, 36, 1), // Kırmızı
              Color.fromRGBO(211, 47, 47, 1), // Koyu kırmızı
              Color.fromRGBO(183, 28, 28, 1), // Çok koyu kırmızı
              Color.fromRGBO(142, 0, 0, 1), // En koyu kırmızı
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
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
              top: MediaQuery.of(context).size.height / 3,
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
            
            // Logo with floating animation
            Positioned(
              top: isMobile ? 95 : 120,
              left: MediaQuery.of(context).size.width / 4,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value * 0.5),
                    child: child,
                  );
                },
                child: SvgPicture.asset(
                  'assets/logo/zecorner-logo2.svg',
                  height: isMobile ? 45 : 60,
                  width: isMobile ? 45 : 60,
                ),
              ),
            ),

            // Sağ alt parlak daire - kartın ALTINDA kalsın (beyaz alan üzerinde kırmızılık olmasın)
            Positioned(
              right: -60,
              bottom: -30,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_rotationController, _pulseAnimation]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_rotationController.value * 2 * math.pi,
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF8A80).withOpacity(0.35),
                          const Color(0xFFFF5252).withOpacity(0.18),
                          const Color(0xFFE53935).withOpacity(0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 0.65, 1.0],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            
            // Login card with enhanced design
            Align(
              alignment: const Alignment(0, 0.40),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20.0 : 60.0),
                    child: AnimatedBuilder(
                      animation: _floatingAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatingAnimation.value * 0.3),
                          child: child,
                        );
                      },
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          // Kart genişliğini mobilde de daha dar tutarak daha modern ve hafif görünüm
                          maxWidth: isMobile ? 380 : 620,
                        ),
                        child: Card(
                          color: Colors.white.withOpacity(0.98),
                          elevation: isMobile ? 18 : 24,
                          shadowColor: Colors.black.withOpacity(0.22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.98),
                                  Colors.white.withOpacity(0.96),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: isMobile ? 0.8 : 1.2,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 22.0 : 40.0,
                                vertical: isMobile ? 22.0 : 36.0,
                              ),
                              child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [
                                          Color.fromRGBO(238, 46, 36, 1),
                                          Color.fromRGBO(238, 46, 36, 1),
                                        ],
                                      ).createShader(bounds),
                                      child: Text(
                                        "Giriş Yap",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isMobile ? 22 : 34,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.15,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isMobile ? 35 : 48),
                                
                                // Form fields with enhanced styling
                                _buildAnimatedLabel('E-posta', isMobile: isMobile),
                                SizedBox(height: isMobile ? 8 : 12),
                                _buildEnhancedTextField(
                                  controller: _emailController,
                                  hintText: 'E-postanızı giriniz',
                                  icon: Icons.mail_outline_rounded,
                                  validator: _validateEmail,
                                  isMobile: isMobile,
                                ),
                                SizedBox(height: isMobile ? 20 : 28),
                                
                                _buildAnimatedLabel('Şifre', isMobile: isMobile),
                                SizedBox(height: isMobile ? 8 : 12),
                                _buildEnhancedTextField(
                                  controller: _passwordController,
                                  hintText: 'Şifre giriniz',
                                  icon: Icons.lock_open_rounded,
                                  obscureText: !_isPasswordVisible,
                                  isPassword: true,
                                  validator: _validatePassword,
                                  isMobile: isMobile,
                                ),
                                SizedBox(height: isMobile ? 18 : 26),
                                
                                // Enhanced submit button
                                Container(
                                  width: double.infinity,
                                  height: isMobile ? 52 : 64,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE53935),
                                        Color(0xFFD32F2F),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE53935).withOpacity(0.4),
                                        blurRadius: isMobile ? 15 : 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: BlocConsumer<AuthCubit, AuthState>(
                                    listener: (context, state) {
                                      if (state is AuthAuthenticated) {
                                        // AuthCubit'ten role durumunu kontrol et
                                        final authCubit = context.read<AuthCubit>();
                                        
                                        print('Login başarılı - Role göre yönlendirme yapılıyor...');
                                        print('Role yüklü mü: ${authCubit.isRoleLoaded}');
                                        print('Kullanıcı rolü: ${authCubit.currentRole}');
                                        print('Admin mı: ${authCubit.isAdmin}');
                                        print('Manager mı: ${authCubit.isManager}');
                                        print('Agent mı: ${authCubit.isAgent}');
                                        
                                        if (!authCubit.isRoleLoaded) {
                                          // Rol henüz yüklenmediyse bekle
                                          print('Rol henüz yüklenmedi, bekleniyor...');
                                          Future.delayed(const Duration(milliseconds: 1500), () {
                                            _navigateBasedOnRole(context, PermissionService());
                                          });
                                        } else {
                                          _navigateBasedOnRole(context, PermissionService());
                                        }
                                      } else if (state is AuthError) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(state.message),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    builder: (context, state) {
                                      return ElevatedButton(
                                        onPressed: state is AuthLoading ? null : () async {
                                          if (_formKey.currentState!.validate()) {
                                            // API entegrasyonu
                                            context.read<AuthCubit>().signIn(
                                              _emailController.text.trim(),
                                              _passwordController.text,
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                                          ),
                                        ),
                                        child: state is AuthLoading
                                            ? SizedBox(
                                                width: isMobile ? 20 : 24,
                                                height: isMobile ? 20 : 24,
                                                child: const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'Giriş Yap',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isMobile ? 16 : 20,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: isMobile ? 12 : 16),
                                Center(
                                  child: Text(
                                    'İş ortaklarımız içindir',
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                    ),
                  ),
                ),
              ),
            ),
            
            // === Alt kısım animasyonları ===
            
            // Alt dalga katmanı 1 (en arkada, geniş)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 150),
                      painter: BottomWavePainter(
                        _waveAnimation.value,
                        0,
                        Colors.white.withOpacity(0.06),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Alt dalga katmanı 2 (ortada)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 110),
                      painter: BottomWavePainter(
                        _waveAnimation.value,
                        math.pi / 3,
                        Colors.white.withOpacity(0.04),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Alt dalga katmanı 3 (en önde, dar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 75),
                      painter: BottomWavePainter(
                        _waveAnimation.value,
                        math.pi * 0.7,
                        Colors.white.withOpacity(0.08),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Kart altı yüzen geometrik şekiller (elmas ve daireler)
            ...List.generate(6, (index) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              final xFactors = [0.08, 0.85, 0.42, 0.22, 0.68, 0.52];
              final yFactors = [0.78, 0.73, 0.85, 0.81, 0.76, 0.88];
              final sizes = [14.0, 10.0, 16.0, 12.0, 8.0, 11.0];
              
              return Positioned(
                left: screenWidth * xFactors[index],
                top: screenHeight * yFactors[index],
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_floatingAnimation, _rotationController]),
                    builder: (context, child) {
                      final floatVal = _floatingAnimation.value;
                      return Transform.translate(
                        offset: Offset(
                          math.sin(floatVal + index * 1.3) * 14,
                          math.cos(floatVal + index * 0.9) * 16,
                        ),
                        child: Transform.rotate(
                          angle: _rotationController.value * 2 * math.pi * (index.isEven ? 0.4 : -0.4),
                          child: Opacity(
                            opacity: (0.25 + math.sin(floatVal + index) * 0.15).clamp(0.0, 1.0),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: sizes[index],
                      height: sizes[index],
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(index.isEven ? 3 : sizes[index] / 2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            
            // Animasyonlu halka - sol alt
            Positioned(
              left: MediaQuery.of(context).size.width * 0.12,
              bottom: 55,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnimation, _rotationController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.7,
                      child: Transform.rotate(
                        angle: _rotationController.value * math.pi,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Animasyonlu halka - sağ alt
            Positioned(
              right: MediaQuery.of(context).size.width * 0.18,
              bottom: 85,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnimation, _rotationController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.5,
                      child: Transform.rotate(
                        angle: -_rotationController.value * 1.5 * math.pi,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Animasyonlu halka - orta
            Positioned(
              left: MediaQuery.of(context).size.width * 0.48,
              bottom: 40,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnimation, _rotationController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.6,
                      child: Transform.rotate(
                        angle: _rotationController.value * 2.5 * math.pi,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Yükselen parlak noktalar (sparkle efekti)
            ...List.generate(5, (index) {
              final screenWidth = MediaQuery.of(context).size.width;
              final xPositions = [
                screenWidth * 0.15,
                screenWidth * 0.35,
                screenWidth * 0.55,
                screenWidth * 0.75,
                screenWidth * 0.90,
              ];
              
              return Positioned(
                left: xPositions[index],
                bottom: 25 + index * 22.0,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_floatingAnimation, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          math.sin(_floatingAnimation.value * 2 + index) * 8,
                          -(math.sin(_floatingAnimation.value * 1.5 + index * 0.7)).abs() * 22,
                        ),
                        child: Opacity(
                          opacity: (0.2 + math.sin(_pulseAnimation.value + index) * 0.15).clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 4.0 + (index % 2) * 2.0,
                      height: 4.0 + (index % 2) * 2.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }
  
  Widget _buildAnimatedLabel(String text, {required bool isMobile}) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_floatingAnimation.value * 0.1, 0),
          child: child,
        );
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile ? 16 : 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2C3E50),
        ),
      ),
    );
  }
  
  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    String? Function(String?)? validator,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isMobile ? 10 : 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: TextStyle(
          fontSize: isMobile ? 16 : 18,
          color: const Color(0xFF2C3E50),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: isMobile ? 14 : 16,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFE53935),
            size: isMobile ? 20 : 24,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFFE53935),
                    size: isMobile ? 20 : 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: isMobile ? 1 : 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: const BorderSide(
              color: Color.fromRGBO(238, 46, 36, 1),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 16 : 20,
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta alanı boş bırakılamaz';
    }
    
    // Email regex pattern
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(pattern);
    
    if (!regex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre alanı boş bırakılamaz';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    return null;
  }

  void _navigateBasedOnRole(BuildContext context, PermissionService permissionService) async {
    print('_navigateBasedOnRole çağrıldı');
    print('Mevcut rol: ${permissionService.currentRole?.name}');
    print('Rol seviyesi: ${permissionService.currentRole?.level}');
    print('Role Code: ${permissionService.currentRole?.code}');
    print('Admin mı: ${permissionService.isAdmin}');
    print('Manager mı: ${permissionService.isManager}');
    print('Agent mı: ${permissionService.isAgent}');
    
    // AuthCubit'ten role bilgilerini al
    final authCubit = context.read<AuthCubit>();
    
    // Web sitesindeki mantığa göre dashboard route'unu al
    final dashboardRoute = await authCubit.getDashboardRoute();
    
    print('Login - Seçilen Dashboard Route: $dashboardRoute');
    
    // Route'a göre yönlendirme
    Navigator.pushReplacementNamed(context, dashboardRoute);
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

// Custom painter for bottom wave effect
class BottomWavePainter extends CustomPainter {
  final double animationValue;
  final double phaseOffset;
  final Color color;
  
  BottomWavePainter(this.animationValue, this.phaseOffset, this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, size.height);
    
    for (int i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final y = size.height * 0.4 + 
          math.sin((x / size.width * 3 * math.pi) + animationValue + phaseOffset) * 15 +
          math.cos((x / size.width * 2 * math.pi) + animationValue * 0.7 + phaseOffset) * 8;
      
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
