import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? redirectRoute;

  const AuthGuard({
    super.key,
    required this.child,
    this.redirectRoute = '/login',
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Kullanıcı giriş yapmamışsa login sayfasına yönlendir
          Navigator.of(context).pushReplacementNamed(redirectRoute!);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            // Kullanıcı giriş yapmışsa sayfayı göster
            return child;
          } else if (state is AuthLoading) {
            return const AppStatusPage.loading(
              title: 'Oturum kontrol ediliyor.',
              message: 'Güvenli girişiniz doğrulanıyor, lütfen bekleyin.',
            );
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(redirectRoute!);
            });
            return const AppStatusPage.loading(
              title: 'Yönlendiriliyorsunuz.',
              message: 'Giriş sayfasına alınırken lütfen bekleyin.',
            );
          }
        },
      ),
    );
  }
}

// Korumalı sayfa wrapper'ı
class ProtectedPage extends StatelessWidget {
  final Widget child;
  final String? redirectRoute;

  const ProtectedPage({
    super.key,
    required this.child,
    this.redirectRoute = '/login',
  });

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      redirectRoute: redirectRoute,
      child: child,
    );
  }
} 