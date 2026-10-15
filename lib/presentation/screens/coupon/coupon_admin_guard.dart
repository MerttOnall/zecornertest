import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

/// Kupon yönetimi yalnızca admin kullanıcılar içindir.
mixin CouponAdminGuard<T extends StatefulWidget> on State<T> {
  bool couponAccessChecking = true;
  bool canManageCoupons = false;

  Future<void> checkCouponAdminAccess({VoidCallback? onAllowed}) async {
    try {
      final authCubit = context.read<AuthCubit>();
      final roleCodes = await authCubit.getUserRoleCodes();
      if (!mounted) return;
      final allowed =
          roleCodes.contains('role_admin') || authCubit.isAdmin;
      setState(() {
        canManageCoupons = allowed;
        couponAccessChecking = false;
      });
      if (allowed) onAllowed?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        canManageCoupons = false;
        couponAccessChecking = false;
      });
    }
  }

  Widget? couponAccessGate() {
    if (couponAccessChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: AppStatusView.loading(
          title: 'Yetki kontrol ediliyor',
          message: 'Kupon yönetimi erişimi doğrulanıyor.',
        ),
      );
    }
    if (!canManageCoupons) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: AppStatusView.error(
          title: 'Erişim engellendi',
          message: 'Bu sayfa yalnızca admin kullanıcılar içindir.',
          onRetry: () => Navigator.of(context).maybePop(),
          retryLabel: 'Geri Dön',
        ),
      );
    }
    return null;
  }
}
