import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackgroundWidget extends StatefulWidget {
  final Widget child;
  const AnimatedBackgroundWidget({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBackgroundWidget> createState() => _AnimatedBackgroundWidgetState();
}

class _AnimatedBackgroundWidgetState extends State<AnimatedBackgroundWidget>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animasyonlu arka plan desenleri
        Positioned(
          top: -100,
          right: -100,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: child,
              );
            },
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.red.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),
        ),
        // Yüzen daire
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.3,
          left: -150,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * _floatingAnimation.value),
                child: child,
              );
            },
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.red.withOpacity(0.05),
                    Colors.red.withOpacity(0.01),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        // Küçük yüzen şekiller
        ...List.generate(5, (index) {
          final random = math.Random();
          final size = random.nextDouble() * 50 + 20;
          final initialX = random.nextDouble() * MediaQuery.of(context).size.width;
          final initialY = random.nextDouble() * MediaQuery.of(context).size.height;

          return Positioned(
            left: initialX,
            top: initialY,
            child: AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    10 * math.sin((index + 1) * _floatingAnimation.value * math.pi),
                    15 * math.cos((index + 1) * _floatingAnimation.value * math.pi),
                  ),
                  child: Transform.rotate(
                    angle: _rotationController.value * math.pi * (index + 1),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.05),
                            Colors.red.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(index.isEven ? size / 2 : 5),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
        // Sayfa içeriği
        widget.child,
      ],
    );
  }
} 