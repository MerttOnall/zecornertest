import 'package:flutter/material.dart';

/// Compact in-card empty state: pulsing icon + "Veri yok".
class EmptyDataView extends StatefulWidget {
  const EmptyDataView({
    super.key,
    this.title = 'Veri yok',
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.compact = false,
    this.expanded = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool compact;
  final bool expanded;

  @override
  State<EmptyDataView> createState() => _EmptyDataViewState();
}

class _EmptyDataViewState extends State<EmptyDataView>
    with SingleTickerProviderStateMixin {
  static const Color _red = Color(0xFFEE2E24);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _pulse.value = 0.5;
      } else {
        _pulse.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final expanded = widget.expanded;
    final iconSize = compact ? 26.0 : (expanded ? 42.0 : 34.0);
    final circle = compact ? 60.0 : (expanded ? 96.0 : 76.0);
    final titleSize = compact ? 15.0 : (expanded ? 20.0 : 17.0);
    final subtitleSize = compact ? 12.0 : (expanded ? 14.0 : 13.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: compact ? 12 : (expanded ? 28 : 24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_pulse.value);
              return Transform.scale(
                scale: 0.96 + (t * 0.08),
                child: Container(
                  width: circle,
                  height: circle,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _red.withValues(alpha: 0.08 + t * 0.05),
                    boxShadow: [
                      BoxShadow(
                        color: _red.withValues(alpha: 0.10 + t * 0.08),
                        blurRadius: 14 + t * 8,
                        spreadRadius: t * 1.5,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Icon(
              widget.icon,
              size: iconSize,
              color: _red.withValues(alpha: 0.88),
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleSize,
                height: 1.45,
                color: _muted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
