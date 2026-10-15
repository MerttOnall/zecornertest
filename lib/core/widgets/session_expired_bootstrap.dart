import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/network/session_expiration_bridge.dart';
import 'package:zecorner/router/app_navigator.dart';
import 'package:zecorner/router/app_router.dart';

/// Dio üzerinden oturum düştüğünde [AuthCubit] ve navigator kökünü günceller.
class SessionExpiredBootstrap extends StatefulWidget {
  const SessionExpiredBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<SessionExpiredBootstrap> createState() =>
      _SessionExpiredBootstrapState();
}

class _SessionExpiredBootstrapState extends State<SessionExpiredBootstrap> {
  @override
  void initState() {
    super.initState();
    registerSessionExpiredHandler(_onExpired);
  }

  @override
  void dispose() {
    registerSessionExpiredHandler(null);
    super.dispose();
  }

  Future<void> _onExpired() async {
    if (!mounted) return;
    await context.read<AuthCubit>().onSessionExpiredFromServer();
    if (!mounted) return;
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRouter.homeListings,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
