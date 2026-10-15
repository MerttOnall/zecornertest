import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          // Animasyonlu arka plan
          SizedBox.expand(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundPainter(
                    _controller.value,
                    Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
          // Sayfa içeriği
          widget.child,
        ],
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  BackgroundPainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Üst sağ daire
    paint.color = const Color(0xFFE53935).withOpacity(0.03);
    canvas.drawCircle(
      Offset(size.width * 1.2, -size.height * 0.2),
      size.width * 0.8 + 30 * math.sin(animationValue * math.pi * 2),
      paint,
    );

    // Alt sol daire
    paint.color = const Color(0xFFE53935).withOpacity(0.02);
    canvas.drawCircle(
      Offset(-size.width * 0.2, size.height * 1.2),
      size.width * 0.8 + 30 * math.cos(animationValue * math.pi * 2),
      paint,
    );

    // Orta daire
    paint.color = const Color(0xFFE53935).withOpacity(0.01);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.4 + 20 * math.sin((animationValue + 0.5) * math.pi * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
} 