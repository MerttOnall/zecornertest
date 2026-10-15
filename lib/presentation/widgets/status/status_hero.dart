import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/status/status_tokens.dart';

class StatusHero extends StatefulWidget {
  const StatusHero({
    super.key,
    required this.kind,
    this.size = 240,
  });

  final AppStatusKind kind;
  final double size;

  @override
  State<StatusHero> createState() => _StatusHeroState();
}

class _StatusHeroState extends State<StatusHero>
    with TickerProviderStateMixin {
  late final AnimationController _loop;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _enter.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startLoopIfAllowed();
  }

  void _startLoopIfAllowed() {
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disable) {
      _loop.value = 0.35;
      _loop.stop();
      _enter.value = 1;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _enter]),
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _StatusHeroPainter(
              kind: widget.kind,
              loop: _loop.value,
              enter: Curves.easeOutBack.transform(_enter.value.clamp(0.0, 1.0)),
            ),
          );
        },
      ),
    );
  }
}

class _StatusHeroPainter extends CustomPainter {
  _StatusHeroPainter({
    required this.kind,
    required this.loop,
    required this.enter,
  });

  final AppStatusKind kind;
  final double loop;
  final double enter;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = enter <= 0 ? 0.001 : enter.clamp(0.0, 1.15);
    canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);

    switch (kind) {
      case AppStatusKind.loading:
        _paintBadge(canvas, size, isLoading: true);
      case AppStatusKind.success:
        _paintBadge(canvas, size, isLoading: false);
      case AppStatusKind.notFound:
        _paintNotFound(canvas, size);
      case AppStatusKind.missing:
        _paintMissing(canvas, size);
      case AppStatusKind.error:
        _paintBroken(canvas, size);
    }
    canvas.restore();
  }

  void _paintBadge(Canvas canvas, Size size, {required bool isLoading}) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.22;
    final t = loop * math.pi * 2;

    final glow = Paint()
      ..color = StatusTokens.red.withValues(alpha: 0.10 + 0.06 * math.sin(t))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(c, radius * 1.85, glow);

    final pulseA = (math.sin(t) + 1) / 2;
    final pulseB = (math.sin(t + math.pi) + 1) / 2;
    _drawRing(
      canvas,
      c,
      radius * (1.55 + 0.12 * pulseA),
      StatusTokens.red.withValues(alpha: 0.10 + 0.08 * (1 - pulseA)),
      3,
    );
    _drawDashedCircle(
      canvas,
      c,
      radius * (1.78 + 0.08 * pulseB),
      StatusTokens.red.withValues(alpha: 0.28),
      7,
      6,
      isLoading ? t : t * 0.25,
      1.6,
    );

    final badge = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFF4A40), StatusTokens.red, StatusTokens.redDark],
        stops: const [0.0, 0.62, 1.0],
        center: const Alignment(-0.25, -0.35),
      ).createShader(Rect.fromCircle(center: c, radius: radius));
    canvas.drawCircle(c, radius, badge);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawCircle(c, radius * 0.86, inner);

    if (isLoading) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.12
        ..strokeCap = StrokeCap.round
        ..color = Colors.white;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: radius * 0.42),
        t,
        math.pi * 1.15,
        false,
        arc,
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: radius * 0.42),
        t + math.pi * 1.35,
        math.pi * 0.35,
        false,
        arc..color = Colors.white.withValues(alpha: 0.35),
      );
    } else {
      final check = Path()
        ..moveTo(c.dx - radius * 0.32, c.dy + radius * 0.02)
        ..lineTo(c.dx - radius * 0.08, c.dy + radius * 0.26)
        ..lineTo(c.dx + radius * 0.36, c.dy - radius * 0.24);
      final metrics = check.computeMetrics().toList();
      if (metrics.isEmpty) return;
      final metric = metrics.first;
      final drawn = metric.extractPath(0, metric.length * enter.clamp(0.0, 1.0));
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white,
      );
    }
  }

  void _paintNotFound(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + size.height * 0.02);
    final r = size.shortestSide * 0.34;
    final t = loop * math.pi * 2;
    final floatY = math.sin(t) * 3.5;

    canvas.drawCircle(c, r, Paint()..color = StatusTokens.red);

    final path = Path()
      ..moveTo(c.dx - r * 0.78, c.dy + r * 0.12)
      ..quadraticBezierTo(
        c.dx - r * 0.15,
        c.dy - r * 0.55,
        c.dx + r * 0.42,
        c.dy - r * 0.08,
      );
    _drawDashedPath(
      canvas,
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = StatusTokens.ink.withValues(alpha: 0.55),
      5,
      5,
      loop * 18,
    );
    canvas.drawCircle(
      Offset(c.dx - r * 0.78, c.dy + r * 0.12),
      3.2,
      Paint()..color = StatusTokens.ink,
    );
    canvas.drawCircle(
      Offset(c.dx + r * 0.42, c.dy - r * 0.08),
      3.2,
      Paint()..color = StatusTokens.ink,
    );

    final pinTip = Offset(c.dx - r * 0.62, c.dy + r * 0.28 + math.sin(t) * 5);
    _drawPin(canvas, pinTip, r * 0.62);

    canvas.save();
    canvas.translate(c.dx + r * 0.18, c.dy + floatY * 0.4);
    canvas.rotate(-0.18);
    final card = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: r * 1.05, height: r * 0.78),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4),
    );
    canvas.drawRRect(card, Paint()..color = Colors.white);
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x11000000),
    );
    _drawHouse(canvas, const Offset(0, 6), r * 0.42, StatusTokens.red);
    canvas.restore();

    final pillText = 'ADRES BULUNAMADI';
    final tp = TextPainter(
      text: TextSpan(
        text: pillText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(c.dx + r * 0.42, c.dy - r * 0.72),
        width: tp.width + 18,
        height: 22,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(pillRect, Paint()..color = StatusTokens.ink);
    tp.paint(
      canvas,
      Offset(
        pillRect.center.dx - tp.width / 2,
        pillRect.center.dy - tp.height / 2,
      ),
    );
  }

  void _paintMissing(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 8);
    final t = loop * math.pi * 2;
    final lift = 7 + math.sin(t) * 5;
    final s = size.shortestSide;

    final shadow = Paint()
      ..color = const Color(0x14000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + s * 0.28),
        width: s * 0.62,
        height: 16,
      ),
      shadow,
    );

    final houseSize = s * 0.28;
    _drawHouse(
      canvas,
      Offset(c.dx, c.dy + 10),
      houseSize,
      StatusTokens.red,
      drawRoof: false,
    );

    final roofBase = Offset(c.dx, c.dy - houseSize * 0.18);
    final roofPeak = Offset(c.dx, roofBase.dy - houseSize * 0.42 - lift);
    final dash = Path()
      ..moveTo(c.dx, roofBase.dy - 4)
      ..lineTo(c.dx, roofPeak.dy + houseSize * 0.18);
    _drawDashedPath(
      canvas,
      dash,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = StatusTokens.ink.withValues(alpha: 0.35),
      3.5,
      3.5,
      loop * 10,
    );

    final roof = Path()
      ..moveTo(roofPeak.dx, roofPeak.dy)
      ..lineTo(c.dx - houseSize * 0.62, roofBase.dy - lift * 0.15)
      ..lineTo(c.dx + houseSize * 0.62, roofBase.dy - lift * 0.15)
      ..close();
    canvas.drawPath(roof, Paint()..color = StatusTokens.red);
  }

  void _paintBroken(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final t = loop * math.pi * 2;
    final split = 10 + math.sin(t) * 2.4;
    final shiver = math.sin(t * 4) * 0.8;
    final s = size.shortestSide;
    final w = s * 0.34;
    final h = s * 0.42;

    void folder(Offset origin, double rot, {required bool left}) {
      canvas.save();
      canvas.translate(origin.dx + shiver, origin.dy);
      canvas.rotate(rot);
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        const Radius.circular(10),
      );
      canvas.drawRRect(body, Paint()..color = StatusTokens.red);
      final tab = RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.42, -h * 0.62, w * 0.42, 14),
        const Radius.circular(6),
      );
      canvas.drawRRect(tab, Paint()..color = StatusTokens.red);

      final line = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = -h * 0.12 + i * 14.0;
        final start = left ? -w * 0.28 : -w * 0.18;
        final end = left ? w * 0.18 : w * 0.28;
        canvas.drawLine(Offset(start, y), Offset(end, y), line);
      }
      canvas.restore();
    }

    folder(Offset(c.dx - w * 0.42 - split, c.dy), -0.12, left: true);
    folder(Offset(c.dx + w * 0.42 + split, c.dy), 0.12, left: false);

    final pulse = 0.88 + 0.12 * math.sin(t * 2);
    final badgeR = s * 0.09 * pulse;
    canvas.drawCircle(c, badgeR, Paint()..color = StatusTokens.ink);

    final bang = TextPainter(
      text: TextSpan(
        text: '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: badgeR * 1.55,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    bang.paint(
      canvas,
      Offset(c.dx - bang.width / 2, c.dy - bang.height / 2 - 1),
    );
  }

  void _drawHouse(
    Canvas canvas,
    Offset origin,
    double w,
    Color color, {
    bool drawRoof = true,
    double roofLift = 0,
  }) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: origin, width: w, height: w * 0.72),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(body, Paint()..color = color);

    final win = Paint()..color = Colors.white;
    final winS = w * 0.16;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: origin + Offset(-w * 0.18, -w * 0.06),
          width: winS,
          height: winS,
        ),
        Radius.circular(2),
      ),
      win,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: origin + Offset(w * 0.18, -w * 0.06),
          width: winS,
          height: winS,
        ),
        Radius.circular(2),
      ),
      win,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: origin + Offset(0, w * 0.16),
          width: w * 0.18,
          height: w * 0.34,
        ),
        const Radius.circular(2.5),
      ),
      win,
    );

    if (drawRoof) {
      final roof = Path()
        ..moveTo(origin.dx, origin.dy - w * 0.58 - roofLift)
        ..lineTo(origin.dx - w * 0.58, origin.dy - w * 0.22)
        ..lineTo(origin.dx + w * 0.58, origin.dy - w * 0.22)
        ..close();
      canvas.drawPath(roof, Paint()..color = color);
    }
  }

  void _drawPin(Canvas canvas, Offset tip, double height) {
    final r = height * 0.28;
    final cy = tip.dy - height * 0.38;
    final cx = tip.dx;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..quadraticBezierTo(cx + r * 1.45, cy + r * 0.35, cx + r, cy)
      ..arcToPoint(
        Offset(cx - r, cy),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..quadraticBezierTo(cx - r * 1.45, cy + r * 0.35, tip.dx, tip.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = StatusTokens.ink);
    canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = Colors.white);
    _drawHouse(canvas, Offset(cx, cy + 1.5), r * 0.7, StatusTokens.ink);
  }

  void _drawRing(Canvas canvas, Offset c, double r, Color color, double width) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset c,
    double r,
    Color color,
    double dash,
    double gap,
    double rot,
    double width,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;
    final circ = 2 * math.pi * r;
    final n = (circ / (dash + gap)).floor();
    if (n <= 0) return;
    final sweep = dash / r;
    final skip = (dash + gap) / r;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        rot + i * skip,
        sweep,
        false,
        paint,
      );
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dash,
    double gap,
    double phase,
  ) {
    for (final metric in path.computeMetrics()) {
      var d = phase % (dash + gap);
      while (d < metric.length) {
        final end = math.min(d + dash, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StatusHeroPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.loop != loop ||
        oldDelegate.enter != enter;
  }
}
