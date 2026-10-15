import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/services/local_device_notification_service.dart';
import 'package:zecorner/core/services/notification_tray_sync_service.dart';
import 'package:zecorner/router/app_navigator.dart';
import 'package:zecorner/router/app_router.dart';

/// Giriş yapılmışken API bildirimlerini telefona senkronlar; yaşam döngüsü ve periyodik kontrol.
class NotificationBootstrap extends StatefulWidget {
  const NotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationBootstrap> createState() => _NotificationBootstrapState();
}

class _NotificationBootstrapState extends State<NotificationBootstrap>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _scheduledInitialSync = false;
  bool _handledLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleLaunchNotification();
      _tryScheduleSyncForCurrentAuth();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncDebounced();
    }
    if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> _handleLaunchNotification() async {
    if (_handledLaunch) return;
    _handledLaunch = true;
    final target =
        await LocalDeviceNotificationService.instance.consumeAppLaunchRouting();
    if (!mounted) return;
    if (target == NotificationLaunchTarget.profileNotifications) {
      final auth = context.read<AuthCubit>();
      if (auth.state is AuthAuthenticated) {
        appNavigatorKey.currentState
            ?.pushNamed(AppRouter.profileNotification);
      }
    }
  }

  void _tryScheduleSyncForCurrentAuth() {
    final auth = context.read<AuthCubit>();
    if (auth.state is AuthAuthenticated) {
      _onAuthenticated();
    }
  }

  void _onAuthenticated() {
    if (_scheduledInitialSync) return;
    _scheduledInitialSync = true;
    Future<void>.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      _syncDebounced();
      await LocalDeviceNotificationService.instance
          .syncAppRemindersFromPreferences();
    });
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 4), (_) {
      if (mounted) _syncDebounced();
    });
  }

  void _onLoggedOut() {
    _scheduledInitialSync = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    LocalDeviceNotificationService.instance.cancelAllAppReminderSchedules();
  }

  void _syncDebounced() {
    final auth = context.read<AuthCubit>();
    if (auth.state is! AuthAuthenticated) return;
    NotificationTraySyncService.instance.syncDebounced();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthAuthenticated ||
          (prev is AuthAuthenticated && curr is! AuthAuthenticated),
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _onAuthenticated();
        } else {
          _onLoggedOut();
        }
      },
      child: widget.child,
    );
  }
}
