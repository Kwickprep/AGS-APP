import 'package:flutter/material.dart';
import '../../config/huge_icons.dart';
import '../../config/routes.dart';

/// Represents a module/feature in the app with its associated permissions
class AppModule {
  final String name;
  final IconData icon;
  final String route;
  final String? readPermission;
  final String? createPermission;
  final String? updatePermission;
  final String? deletePermission;

  const AppModule({
    required this.name,
    required this.icon,
    required this.route,
    this.readPermission,
    this.createPermission,
    this.updatePermission,
    this.deletePermission,
  });

  /// Check if user has any permission for this module
  bool hasAnyPermission(List<String> userPermissions) {
    final permissions = [
      readPermission,
      createPermission,
      updatePermission,
      deletePermission,
    ].where((p) => p != null).cast<String>();

    if (permissions.isEmpty) return true; // Public module

    return permissions.any((p) => userPermissions.contains(p));
  }
}

/// All app modules configuration
class PermissionConfig {
  static const List<AppModule> allModules = [
    AppModule(
      name: 'Brands',
      icon: HugeIcons.award03,
      route: AppRoutes.brands,
      readPermission: 'brands.read',
      createPermission: 'brands.create',
      updatePermission: 'brands.update',
      deletePermission: 'brands.delete',
    ),
    AppModule(
      name: 'Categories',
      icon: HugeIcons.orthogonalEdge,
      route: AppRoutes.categories,
      readPermission: 'categories.read',
      createPermission: 'categories.create',
      updatePermission: 'categories.update',
      deletePermission: 'categories.delete',
    ),
    AppModule(
      name: 'Themes',
      icon: HugeIcons.colors,
      route: AppRoutes.themes,
      readPermission: 'themes.read',
      createPermission: 'themes.create',
      updatePermission: 'themes.update',
      deletePermission: 'themes.delete',
    ),
    AppModule(
      name: 'Tags',
      icon: HugeIcons.tag01,
      route: AppRoutes.tags,
      readPermission: 'tags.read',
      createPermission: 'tags.create',
      updatePermission: 'tags.update',
      deletePermission: 'tags.delete',
    ),
    AppModule(
      name: 'Products',
      icon: HugeIcons.package,
      route: AppRoutes.products,
      readPermission: 'products.read',
      createPermission: 'products.create',
      updatePermission: 'products.update',
      deletePermission: 'products.delete',
    ),
    AppModule(
      name: 'Activities',
      icon: HugeIcons.chartColumn,
      route: AppRoutes.activities,
      readPermission: 'activities.read',
      createPermission: 'activities.create',
      updatePermission: 'activities.update',
      deletePermission: 'activities.delete',
    ),
    AppModule(
      name: 'Activity Types',
      icon: HugeIcons.share07,
      route: AppRoutes.activityTypes,
      readPermission: 'activity-types.read',
      createPermission: 'activity-types.create',
      updatePermission: 'activity-types.update',
      deletePermission: 'activity-types.delete',
    ),
    AppModule(
      name: 'Inquiries',
      icon: HugeIcons.messageQuestion,
      route: AppRoutes.inquiries,
      readPermission: 'inquiries.read',
      createPermission: 'inquiries.create',
      updatePermission: 'inquiries.update',
      deletePermission: 'inquiries.delete',
    ),
    AppModule(
      name: 'Groups',
      icon: HugeIcons.userGroup,
      route: AppRoutes.groups,
      readPermission: 'groups.read',
      createPermission: 'groups.create',
      updatePermission: 'groups.update',
      deletePermission: 'groups.delete',
    ),
    AppModule(
      name: 'Users',
      icon: HugeIcons.userMultiple02,
      route: AppRoutes.users,
      readPermission: 'users.read',
      createPermission: 'users.create',
      updatePermission: 'users.update',
      deletePermission: 'users.delete',
    ),
    AppModule(
      name: 'Companies',
      icon: HugeIcons.bandage,
      route: AppRoutes.companies,
      readPermission: 'companies.read',
      createPermission: 'companies.create',
      updatePermission: 'companies.update',
      deletePermission: 'companies.delete',
    ),
  ];

  /// Get modules filtered by user permissions
  static List<AppModule> getAccessibleModules(List<String> userPermissions) {
    return allModules
        .where((module) => module.hasAnyPermission(userPermissions))
        .toList();
  }
}
