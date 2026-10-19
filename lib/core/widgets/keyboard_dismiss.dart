import 'package:flutter/material.dart';

/// Yazı alanı dışına dokunulunca klavyeyi kapatır.
/// Dokunuşu yutmaz; buton, liste ve diğer alanlar çalışmaya devam eder.
class KeyboardDismiss extends StatelessWidget {
  const KeyboardDismiss({super.key, required this.child});

  final Widget child;

  void _dismissIfOutside(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return;

    final renderObject = focus.context?.findRenderObject();
    if (renderObject is RenderBox && renderObject.attached && renderObject.hasSize) {
      final topLeft = renderObject.localToGlobal(Offset.zero);
      final rect = topLeft & renderObject.size;
      if (rect.contains(event.position)) return;
    }

    focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _dismissIfOutside,
      child: child,
    );
  }
}
