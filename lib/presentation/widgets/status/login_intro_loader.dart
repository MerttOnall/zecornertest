import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Girişten sonraki ilk pano yüklemesini bir kez kaplar.
/// Çıkışta [arm] ile yeniden kurulur; sonraki sayfa geçişlerine karışmaz.
class LoginIntroGate {
  static bool _pending = true;

  static void arm() {
    _pending = true;
  }

  static bool claim() {
    if (!_pending) return false;
    _pending = false;
    return true;
  }
}

class LoginIntroHost extends StatefulWidget {
  const LoginIntroHost({
    super.key,
    required this.loading,
    required this.child,
  });

  final bool loading;
  final Widget child;

  @override
  State<LoginIntroHost> createState() => _LoginIntroHostState();
}

class _LoginIntroHostState extends State<LoginIntroHost> {
  late final bool _ownsIntro;
  late bool _cover;
  late bool _sawLoading;

  @override
  void initState() {
    super.initState();
    _ownsIntro = LoginIntroGate.claim();
    _cover = _ownsIntro;
    _sawLoading = widget.loading;
  }

  @override
  void didUpdateWidget(LoginIntroHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_cover) return;
    if (widget.loading) {
      _sawLoading = true;
      return;
    }
    if (_sawLoading) {
      _cover = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cover) return widget.child;
    return const LoginIntroScreen();
  }
}

class LoginIntroScreen extends StatefulWidget {
  const LoginIntroScreen({super.key});

  @override
  State<LoginIntroScreen> createState() => _LoginIntroScreenState();
}

class _LoginIntroScreenState extends State<LoginIntroScreen>
    with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFE53935);

  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFC62828),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Material(
        color: _red,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEF5350),
                Color(0xFFE53935),
                Color(0xFFD32F2F),
              ],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) {
                final turn = _spin.value;
                final pulse = 0.96 + 0.04 * math.sin(turn * math.pi * 2);
                return SizedBox(
                  width: 248,
                  height: 248,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(248, 248),
                        painter: _ArcPainter(
                          turn: turn,
                          color: Colors.white,
                          stroke: 3.4,
                          sweep: 1.45,
                        ),
                      ),
                      CustomPaint(
                        size: const Size(196, 196),
                        painter: _ArcPainter(
                          turn: -turn * 0.65,
                          color: Colors.white.withValues(alpha: 0.72),
                          stroke: 2.2,
                          sweep: 0.85,
                        ),
                      ),
                      Transform.scale(
                        scale: pulse,
                        child: SvgPicture.asset(
                          'assets/logo/zecorner-logo2.svg',
                          width: 132,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.turn,
    required this.color,
    required this.stroke,
    required this.sweep,
  });

  final double turn;
  final Color color;
  final double stroke;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.18),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      turn * math.pi * 2 - math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.turn != turn;
}
