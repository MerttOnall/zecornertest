import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zecorner/presentation/home-screens/home_tum_ilan_screen.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/presentation/login/login_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'dart:ui';

class HomeListingsScreen extends StatefulWidget {
  const HomeListingsScreen({super.key});

  @override
  State<HomeListingsScreen> createState() => _HomeListingsScreenState();
}

class _HomeListingsScreenState extends State<HomeListingsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthAndRedirect());
  }

  Future<void> _checkAuthAndRedirect() async {
    if (_hasCheckedAuth) return;

    final authCubit = context.read<AuthCubit>();
    while (mounted && authCubit.state is AuthLoading) {
      await Future.delayed(const Duration(milliseconds: 40));
    }
    if (!mounted) return;

    _hasCheckedAuth = true;

    final authState = authCubit.state;

    if (authState is AuthAuthenticated) {
      final dashboardRoute = await authCubit.getDashboardRoute();
      print('HomeListingsScreen: Authenticated kullanıcı tespit edildi, dashboard route: $dashboardRoute');
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(dashboardRoute);
      }
    }
  }

  Widget _buildBackground() {
    return const _RedBokehBackground();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: isMobile ? 56 : 64,
        automaticallyImplyLeading: false,
        title: Semantics(
          label: 'ZE Corner',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SvgPicture.asset(
              "assets/logo/zecorner-logo2.svg",
              width: isMobile ? 144 : 180,
              fit: BoxFit.contain,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Arka plan – dokunmayı geçir (butonlara basılabilsin)
          Positioned.fill(
            child: IgnorePointer(
              child: _buildBackground(),
            ),
          ),
          // Üst hafif karartma – logo okunaklı
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.12),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.04),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // İçerik – modern ilk ekran
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 56,
                  vertical: isMobile ? 20 : 44,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? 420 : 700,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isMobile ? 28 : 44),
                      _ModernWelcomeCard(isMobile: isMobile),
                      SizedBox(height: isMobile ? 24 : 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        theme: NavbarTheme.homeWelcome,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Sayfa yönlendirmeleri burada yapılabilir
        },
      ),
    );
  }
}

/// İlk iki fotoğraftaki gibi kırmızı bokeh animasyonlu arka plan.
class _RedBokehBackground extends StatefulWidget {
  const _RedBokehBackground();

  @override
  State<_RedBokehBackground> createState() => _RedBokehBackgroundState();
}

class _RedBokehBackgroundState extends State<_RedBokehBackground>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _pulseController.repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    );
    _slideController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _slideController]),
            builder: (context, child) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _RedBokehPainter(
                  pulsePhase: _pulseAnim.value,
                  slidePhase: _slideController.value,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RedBokehPainter extends CustomPainter {
  final double pulsePhase;
  final double slidePhase;

  _RedBokehPainter({required this.pulsePhase, required this.slidePhase});

  static const List<double> _seeds = [
    0.12, 0.67, 0.34, 0.91, 0.55, 0.23, 0.78, 0.45, 0.89, 0.31,
    0.56, 0.02, 0.71, 0.44, 0.19, 0.93, 0.61, 0.38, 0.85, 0.27,
    0.49, 0.76, 0.08, 0.62, 0.95, 0.41, 0.17, 0.84, 0.53, 0.29,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Zemin: ikinci fotoğraf gibi – üst parlak kırmızı, alta doğru koyulaşan gradient
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color.fromRGBO(245, 55, 50, 1),  // Üst: parlak kırmızı
        const Color.fromRGBO(220, 45, 42, 1),
        const Color.fromRGBO(190, 32, 30, 1),
        const Color.fromRGBO(150, 15, 15, 1),  // Alt: derin kırmızı
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
    canvas.drawRect(bgRect, Paint()..shader = bgGradient.createShader(bgRect));

    final t = slidePhase * math.pi * 2;

    // 1) Sabit yumuşak lekeler – ucuz, arka planı doldurur (animasyon yok)
    final softSpotPaint = Paint()..isAntiAlias = true;
    for (int i = 0; i < 10; i++) {
      final sx = _seeds[i] * w * 1.1 - w * 0.05;
      final sy = _seeds[(i + 5) % _seeds.length] * h * 1.05;
      final r = 36.0 + _seeds[(i + 3) % _seeds.length] * 50;
      final op = 0.06 + _seeds[(i + 7) % _seeds.length] * 0.06;
      final spotGradient = RadialGradient(
        colors: [
          Color.fromRGBO(255, 220, 200, op),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      );
      softSpotPaint.shader = spotGradient.createShader(Rect.fromCircle(center: Offset(sx, sy), radius: r));
      canvas.drawCircle(Offset(sx, sy), r, softSpotPaint);
    }

    // 2) Eğri çizgiler – az nokta, hafif hareket
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final lineOff = math.sin(t * 0.5) * 6;
    for (int i = 0; i < 4; i++) {
      final u = (i + 1) / 5;
      final path = Path();
      path.moveTo(w * (0.06 + u * 0.12) + lineOff, -h * 0.02);
      path.quadraticBezierTo(w * (0.4 + u * 0.15), h * (0.3 + u * 0.12), w * (0.55 + u * 0.2), h * (0.55 + u * 0.08));
      path.quadraticBezierTo(w * (0.75 + u * 0.15), h * (0.82 + u * 0.06), w * (0.94 - u * 0.08), h * 1.06);
      canvas.drawPath(path, linePaint);
    }

    // 3) Dalgalı çizgiler – daha az adım (kasma olmaz)
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    const int waveSteps = 26;
    for (int lineIndex = 0; lineIndex < 4; lineIndex++) {
      final baseY = lineIndex < 3
          ? h * (0.28 + lineIndex * 0.2) + math.sin(t + lineIndex) * 8
          : h * (0.78 + math.sin(t * 0.7) * 6);
      final amp = lineIndex < 3 ? 14.0 + lineIndex * 6.0 : 12.0;
      final freq = 0.011 + lineIndex * 0.002;
      final path = Path();
      for (int i = 0; i <= waveSteps; i++) {
        final x = (i / waveSteps) * (w + 30) - 15;
        final y = baseY + amp * math.sin(x * freq + t * 0.25 + lineIndex * 0.4);
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);
    }

    // 4) Baloncuklar – blur YOK (kasma nedeni), 3 renk gradient, az sayı
    final driftX = (slidePhase * w) % (w + 60) - 30;
    final waveX = math.sin(t) * w * 0.02;
    final waveY = math.cos(t * 0.5) * h * 0.012;

    const int totalShapes = 55;
    for (int i = 0; i < totalShapes; i++) {
      final seed = _seeds[i % _seeds.length];
      final seed2 = _seeds[(i + 3) % _seeds.length];
      final seed3 = _seeds[(i + 5) % _seeds.length];
      final baseX = (0.03 + seed * 0.94) * w + driftX * (0.15 + seed3) + waveX;
      final baseY = (0.06 + seed2 * 0.9) * h + waveY;
      final x = baseX.clamp(-30.0, w + 30);
      final y = baseY.clamp(0.0, h + 20);
      final center = Offset(x, y);

      final sizeSeed = _seeds[(i + 7) % _seeds.length];
      final heightFactor = (y / h).clamp(0.0, 1.0);
      final pulse = 0.97 + 0.03 * math.sin(pulsePhase * math.pi * 2 + seed * 6.28);

      final sizeType = i % 4;
      final topBias = 1.0 - heightFactor * 0.25;
      final radius = sizeType == 0
          ? (1.5 + sizeSeed * 2.5) * pulse * topBias
          : sizeType == 1
              ? (3.5 + sizeSeed * 7) * (0.55 + 0.45 * heightFactor) * pulse
              : sizeType == 2
                  ? (5.0 + sizeSeed * 12) * (0.55 + 0.45 * heightFactor) * pulse
                  : (7.0 + sizeSeed * 18) * (0.6 + 0.4 * heightFactor) * pulse;
      final opacity = (0.5 + 0.35 * heightFactor + sizeSeed * 0.05).clamp(0.5, 0.82);

      final bubbleGradient = RadialGradient(
        center: const Alignment(0.0, -0.25),
        radius: 1.0,
        colors: [
          Color.fromRGBO(255, 198, 175, opacity),
          Color.fromRGBO(255, 145, 128, opacity * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = bubbleGradient.createShader(Rect.fromCircle(center: center, radius: radius))
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RedBokehPainter oldDelegate) =>
      oldDelegate.pulsePhase != pulsePhase || oldDelegate.slidePhase != slidePhase;
}

class _ModernWelcomeCard extends StatefulWidget {
  final bool isMobile;
  const _ModernWelcomeCard({required this.isMobile});

  @override
  State<_ModernWelcomeCard> createState() => _ModernWelcomeCardState();
}

class _ModernWelcomeCardState extends State<_ModernWelcomeCard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _floatingAnim;

  @override
  void initState() {
    super.initState();

    // Basit fade ve slide animasyonu
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Login sayfası gibi belirgin floating animasyonu
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _floatingAnim = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController.forward();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatingAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_floatingAnim.value * 0.4, _floatingAnim.value),
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.isMobile ? 28 : 38),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(widget.isMobile ? 28 : 38),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.95),
                      width: widget.isMobile ? 2 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        blurRadius: widget.isMobile ? 40 : 56,
                        offset: const Offset(0, 16),
                        spreadRadius: -6,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: widget.isMobile ? 28 : 40,
                        offset: const Offset(0, 10),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 28 : 48,
                    vertical: widget.isMobile ? 32 : 48,
                  ),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dekoratif ikon
                        Container(
                          width: widget.isMobile ? 52 : 60,
                          height: widget.isMobile ? 52 : 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.home_rounded,
                            size: widget.isMobile ? 28 : 32,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                        SizedBox(height: widget.isMobile ? 22 : 30),
                        Text(
                          "Hoş Geldiniz",
                          style: TextStyle(
                            fontSize: widget.isMobile ? 30 : 42,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: widget.isMobile ? -0.6 : -1,
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: widget.isMobile ? 10 : 14),
                        // Ortalanmış accent çizgi
                        Center(
                          child: Container(
                            width: 48,
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.55),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(height: widget.isMobile ? 16 : 22),
                        Text(
                          "A'dan ZE'ye Gayrimenkul",
                          style: TextStyle(
                            fontSize: widget.isMobile ? 15 : 19,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: widget.isMobile ? 32 : 44),

                        // Tüm İlanlar Butonu
                        _AnimatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const HomeTumIlansScreen(),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                          isPrimary: true,
                          isMobile: widget.isMobile,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Tüm İlanlar",
                                style: TextStyle(
                                  fontSize: widget.isMobile ? 16 : 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: widget.isMobile ? 8 : 12),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: widget.isMobile ? 20 : 24,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: widget.isMobile ? 12 : 18),
                        // Giriş Yap Butonu
                        _AnimatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const LoginScreen(),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                          isPrimary: false,
                          isMobile: widget.isMobile,
                          child: Text(
                            "Giriş Yap",
                            style: TextStyle(
                              fontSize: widget.isMobile ? 16 : 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
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

// Animasyonlu Buton Widget'ı
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isPrimary;
  final bool isMobile;

  const _AnimatedButton({
    required this.onPressed,
    required this.child,
    required this.isPrimary,
    required this.isMobile,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.isMobile ? 16.0 : 20.0;
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: double.infinity,
              height: widget.isMobile ? 56 : 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.32),
                          blurRadius: widget.isMobile ? 18 : 24,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: widget.isPrimary
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onPressed,
                        borderRadius: BorderRadius.circular(radius),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE53935),
                                Color(0xFFD32F2F),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: IconTheme(
                            data: const IconThemeData(color: Colors.white),
                            child: DefaultTextStyle(
                              style: const TextStyle(color: Colors.white),
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: widget.onPressed,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: const Color(0xFFE53935),
                        side: BorderSide(
                          color: const Color(0xFFE53935).withOpacity(0.7),
                          width: widget.isMobile ? 2 : 2.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radius),
                        ),
                      ),
                      child: widget.child,
                    ),
            ),
          );
        },
      ),
    );
  }
}
