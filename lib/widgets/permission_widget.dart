import 'package:flutter/material.dart';
import '../core/permissions/permission_manager.dart';

/// Widget that shows/hides child based on user permissions
///
/// Usage examples:
///
/// 1. Single permission check:
///    PermissionWidget(
///      permission: 'products.create',
///      child: ElevatedButton(...),
///    )
///
/// 2. Multiple permissions (any):
///    PermissionWidget(
///      anyPermissions: ['products.create', 'products.update'],
///      child: ElevatedButton(...),
///    )
///
/// 3. Multiple permissions (all):
///    PermissionWidget(
///      allPermissions: ['products.read', 'products.update'],
///      child: ElevatedButton(...),
///    )
///
/// 4. With fallback widget:
///    PermissionWidget(
///      permission: 'products.delete',
///      child: DeleteButton(),
///      fallback: Text('No permission'),
///    )
class PermissionWidget extends StatelessWidget {
  final String? permission;
  final List<String>? anyPermissions;
  final List<String>? allPermissions;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    super.key,
    this.permission,
    this.anyPermissions,
    this.allPermissions,
    required this.child,
    this.fallback,
  }) : assert(
          permission != null || anyPermissions != null || allPermissions != null,
          'At least one permission parameter must be provided',
        );

  @override
  Widget build(BuildContext context) {
    final permissionManager = PermissionManager();
    bool hasAccess = false;

    if (permission != null) {
      hasAccess = permissionManager.hasPermission(permission!);
    } else if (anyPermissions != null) {
      hasAccess = permissionManager.hasAnyPermission(anyPermissions!);
    } else if (allPermissions != null) {
      hasAccess = permissionManager.hasAllPermissions(allPermissions!);
    }

    if (hasAccess) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Builder variant for more complex permission logic
class PermissionBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool hasPermission) builder;
  final String? permission;
  final List<String>? anyPermissions;
  final List<String>? allPermissions;

  const PermissionBuilder({
    super.key,
    required this.builder,
    this.permission,
    this.anyPermissions,
    this.allPermissions,
  }) : assert(
          permission != null || anyPermissions != null || allPermissions != null,
          'At least one permission parameter must be provided',
        );

  @override
  Widget build(BuildContext context) {
    final permissionManager = PermissionManager();
    bool hasAccess = false;

    if (permission != null) {
      hasAccess = permissionManager.hasPermission(permission!);
    } else if (anyPermissions != null) {
      hasAccess = permissionManager.hasAnyPermission(anyPermissions!);
    } else if (allPermissions != null) {
      hasAccess = permissionManager.hasAllPermissions(allPermissions!);
    }

    return builder(context, hasAccess);
  }
}
