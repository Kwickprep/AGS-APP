import 'package:flutter/material.dart';
import '../../config/huge_icons.dart';
import '../../config/routes.dart';
import 'permission_manager.dart';

/// Represents a module/feature in the app with role-based visibility.
///
/// Matches the web frontend's approach: modules are hidden based on role,
/// not granular permission tokens.
class AppModule {
  final String name;
  final IconData icon;
  final String route;

  /// Roles that should NOT see this module in the drawer.
  /// Empty = visible to all roles.
  final List<String> hiddenForRoles;

  const AppModule({
    required this.name,
    required this.icon,
    required this.route,
    this.hiddenForRoles = const [],
  });

  /// Check if this module is visible for the given role
  bool isVisibleForRole(String role) {
    if (role == 'ADMIN') return true; // Admin sees everything
    return !hiddenForRoles.contains(role);
  }
}

/// All app modules configuration — matches web frontend sidebar exactly
class PermissionConfig {
  static const List<AppModule> allModules = [
    // --- Core modules (visible to ADMIN + EMPLOYEE) ---
    AppModule(
      name: 'Brands',
      icon: HugeIcons.award03,
      route: AppRoutes.brands,
    ),
    AppModule(
      name: 'Categories',
      icon: HugeIcons.orthogonalEdge,
      route: AppRoutes.categories,
    ),
    AppModule(
      name: 'Themes',
      icon: HugeIcons.colors,
      route: AppRoutes.themes,
    ),
    AppModule(
      name: 'Tags',
      icon: HugeIcons.tag01,
      route: AppRoutes.tags,
    ),
    AppModule(
      name: 'Products',
      icon: HugeIcons.package,
      route: AppRoutes.products,
    ),
    AppModule(
      name: 'Activities',
      icon: HugeIcons.chartColumn,
      route: AppRoutes.activities,
    ),
    AppModule(
      name: 'Activity Types',
      icon: HugeIcons.share07,
      route: AppRoutes.activityTypes,
      hiddenForRoles: ['EMPLOYEE'],
    ),
    AppModule(
      name: 'Inquiries',
      icon: HugeIcons.messageQuestion,
      route: AppRoutes.inquiries,
    ),
    AppModule(
      name: 'Groups',
      icon: HugeIcons.userGroup,
      route: AppRoutes.groups,
    ),
    AppModule(
      name: 'Users',
      icon: HugeIcons.userMultiple02,
      route: AppRoutes.users,
    ),
    AppModule(
      name: 'Companies',
      icon: HugeIcons.bandage,
      route: AppRoutes.companies,
    ),

    // --- WhatsApp modules ---
    AppModule(
      name: 'Messages',
      icon: HugeIcons.message01,
      route: AppRoutes.messages,
    ),
    AppModule(
      name: 'Template Categories',
      icon: Icons.folder_outlined,
      route: AppRoutes.templateCategories,
      hiddenForRoles: ['EMPLOYEE'],
    ),
    AppModule(
      name: 'Auto Replies',
      icon: Icons.reply_all_outlined,
      route: AppRoutes.autoReplies,
      hiddenForRoles: ['EMPLOYEE'],
    ),
    AppModule(
      name: 'Campaigns',
      icon: Icons.campaign_outlined,
      route: AppRoutes.campaigns,
      // Visible to EMPLOYEE (view-only) — entity permissions handle CUD blocking
    ),
    AppModule(
      name: 'WA Analytics',
      icon: Icons.analytics_outlined,
      route: AppRoutes.whatsappAnalytics,
      hiddenForRoles: ['EMPLOYEE', 'CUSTOMER'],
    ),
    AppModule(
      name: 'WA Templates',
      icon: Icons.description_outlined,
      route: AppRoutes.whatsappTemplates,
      // Visible to both ADMIN and EMPLOYEE
    ),
  ];

  /// Get modules visible for the current user's role
  static List<AppModule> getVisibleModules() {
    final role = PermissionManager().role;
    if (role == 'ADMIN') return allModules.toList();
    return allModules.where((m) => m.isVisibleForRole(role)).toList();
  }

  /// Legacy: Get modules filtered by user permissions
  /// Still works but now delegates to role-based filtering
  static List<AppModule> getAccessibleModules(List<String> userPermissions) {
    return getVisibleModules();
  }
}
