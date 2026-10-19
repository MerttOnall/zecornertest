import 'package:flutter/material.dart';

/// Hızlı navbar dokunuşlarını tek geçişte toplar.
/// Ara sayfa açılmaz; kalan sayfanın yüklemesi yarıda kesilmez.
class NavbarNavigation {
  static int _ticket = 0;

  static int get ticket => _ticket;

  static int claim() => ++_ticket;

  static void open(BuildContext context, Widget page) {
    final ticket = claim();
    final navigator = Navigator.of(context);
    replaceLater(ticket, navigator, page);
  }

  static void push(BuildContext context, Widget page) {
    final ticket = claim();
    final navigator = Navigator.of(context);
    _go(ticket, () => navigator.push(_route(page)));
  }

  static void replaceLater(int ticket, NavigatorState navigator, Widget page) {
    _go(ticket, () => navigator.pushReplacement(_route(page)));
  }

  static void replaceNamedLater(int ticket, NavigatorState navigator, String route) {
    _go(ticket, () => navigator.pushReplacementNamed(route));
  }

  static void _go(int ticket, VoidCallback action) {
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (ticket != _ticket) return;
      action();
    });
  }

  static PageRouteBuilder<void> _route(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
  }
}
