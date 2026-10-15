import 'package:flutter/material.dart';
import '../services/permission_service.dart';

// Permission-based UI - İzinlere göre widget gösterme/gizleme
class PermissionWidget extends StatelessWidget {
  final String resource;
  final String action;
  final Widget child;
  final Widget? fallback;
  final bool showIfNoPermission;

  const PermissionWidget({
    super.key,
    required this.resource,
    required this.action,
    required this.child,
    this.fallback,
    this.showIfNoPermission = false,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();
    final hasPermission = permissionService.roleStatu(resource, action);

    if (hasPermission) {
      return child;
    }

    if (showIfNoPermission) {
      return fallback ?? const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }
}

// Action button with permission check
class PermissionActionButton extends StatelessWidget {
  final String resource;
  final String action;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;

  const PermissionActionButton({
    super.key,
    required this.resource,
    required this.action,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      resource: resource,
      action: action,
      child: ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

// FloatingActionButton with permission
class PermissionFAB extends StatelessWidget {
  final String resource;
  final String action;
  final VoidCallback onPressed;
  final Widget child;

  const PermissionFAB({
    super.key,
    required this.resource,
    required this.action,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      resource: resource,
      action: action,
      child: FloatingActionButton(
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

// Tab with permission check
class PermissionTab extends StatelessWidget {
  final String resource;
  final String action;
  final Widget child;

  const PermissionTab({
    super.key,
    required this.resource,
    required this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      resource: resource,
      action: action,
      child: child,
    );
  }
}

// Menu item with permission
class PermissionMenuItem extends StatelessWidget {
  final String resource;
  final String action;
  final Widget child;
  final VoidCallback? onTap;

  const PermissionMenuItem({
    super.key,
    required this.resource,
    required this.action,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      resource: resource,
      action: action,
      child: ListTile(
        onTap: onTap,
        title: child,
      ),
    );
  }
}

// Conditional widget based on role level
class RoleLevelWidget extends StatelessWidget {
  final int minimumLevel;
  final Widget child;
  final Widget? fallback;

  const RoleLevelWidget({
    super.key,
    required this.minimumLevel,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();
    final hasLevel = permissionService.hasMinimumLevel(minimumLevel);

    if (hasLevel) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

// Admin only widget
class AdminOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnlyWidget({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();

    if (permissionService.isAdmin) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

// Manager or above widget
class ManagerOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const ManagerOnlyWidget({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();

    if (permissionService.isManager) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

// Multiple permissions check (AND logic)
class MultiPermissionWidget extends StatelessWidget {
  final List<Map<String, String>> permissions; // [{"resource": "users", "action": "create"}]
  final Widget child;
  final Widget? fallback;

  const MultiPermissionWidget({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();
    
    final hasAllPermissions = permissions.every((perm) => 
      permissionService.roleStatu(perm['resource']!, perm['action']!)
    );

    if (hasAllPermissions) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

// Permission helper mixin for stateful widgets
mixin PermissionMixin {
  PermissionService get permissionService => PermissionService();

  bool roleStatu(String resource, String action) {
    return permissionService.roleStatu(resource, action);
  }

  bool canPerformAction(String resource) {
    return permissionService.canPerformAction(resource);
  }

  bool canViewList(String resource) {
    return permissionService.canViewList(resource);
  }

  bool hasFullAccess(String resource) {
    return permissionService.hasFullAccess(resource);
  }

  bool get isAdmin => permissionService.isAdmin;
  bool get isManager => permissionService.isManager;
  bool get isAgent => permissionService.isAgent;
} 