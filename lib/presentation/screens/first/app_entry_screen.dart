import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/screens/first/onboarding_screen.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';
import 'package:zecorner/router/app_router.dart';

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const Duration _authWaitSlice = Duration(milliseconds: 40);
  static const int _authWaitMaxIterations = 375; // ~15 sn

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingAndNavigate();
    });
  }

  Future<void> _waitForAuthReady(AuthCubit authCubit) async {
    var i = 0;
    while (mounted &&
        authCubit.state is AuthLoading &&
        i < _authWaitMaxIterations) {
      await Future.delayed(_authWaitSlice);
      i++;
    }
  }

  Future<void> _checkOnboardingAndNavigate() async {
    if (!mounted) return;

    final authCubit = context.read<AuthCubit>();
    await _waitForAuthReady(authCubit);

    if (!mounted) return;

    // Geçerli oturum + beni hatırla ile açılış: 3 sayfalık onboarding gösterme, direkt panel
    if (authCubit.state is AuthAuthenticated) {
      final dashboardRoute = await authCubit.getDashboardRoute();
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      if (!kDebugMode) {
        await prefs.setBool(_onboardingCompletedKey, true);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(dashboardRoute);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // Debug modunda her seferinde onboarding göster (giriş yokken; hot reload test)
    final onboardingCompleted = kDebugMode
        ? false
        : (prefs.getBool(_onboardingCompletedKey) ?? false);

    if (!mounted) return;

    if (onboardingCompleted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.homeListings);
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AppStatusPage.loading();
  }
}
