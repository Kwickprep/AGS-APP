// Role-based access control configuration matching the web frontend exactly.
// This mirrors ags-frontend/src/app/auth/rbac-config.ts

/// CRUD permission level for an entity
enum CrudPermission { full, viewOnly, filtered, hidden }

/// Per-entity permission config for a role
class EntityPermission {
  final CrudPermission crud;
  final bool canCreate;
  final bool canEditOwn;
  final bool canEditAll;
  final bool canDeleteOwn;
  final bool canDeleteAll;
  final bool canExecute;
  final List<String>? createRoleFilter;

  const EntityPermission({
    required this.crud,
    this.canCreate = false,
    this.canEditOwn = false,
    this.canEditAll = false,
    this.canDeleteOwn = false,
    this.canDeleteAll = false,
    this.canExecute = false,
    this.createRoleFilter,
  });

  /// Full access
  static const full = EntityPermission(
    crud: CrudPermission.full,
    canCreate: true,
    canEditOwn: true,
    canEditAll: true,
    canDeleteOwn: true,
    canDeleteAll: true,
    canExecute: true,
  );

  /// View-only (list + detail, no CUD)
  static const viewOnly = EntityPermission(
    crud: CrudPermission.viewOnly,
  );
}

/// RBAC config for a specific role
class RoleConfig {
  /// Route paths hidden from this role (drawer + direct navigation blocked)
  final List<String> hiddenRoutes;

  /// Menu items hidden from drawer for this role
  final List<String> hiddenMenuItems;

  /// Per-entity permissions
  final Map<String, EntityPermission> entityPermissions;

  const RoleConfig({
    this.hiddenRoutes = const [],
    this.hiddenMenuItems = const [],
    this.entityPermissions = const {},
  });
}

/// The static RBAC configuration — mirrors web frontend exactly
class RbacConfig {
  static const Map<String, RoleConfig> config = {
    'EMPLOYEE': RoleConfig(
      hiddenRoutes: [
        '/activity-types',
        '/whatsapp/template-categories',
        '/whatsapp/auto-replies',
        '/whatsapp/analytics',
      ],
      hiddenMenuItems: [
        '/activity-types',
        '/whatsapp/template-categories',
        '/whatsapp/auto-replies',
        '/whatsapp/analytics',
      ],
      entityPermissions: {
        // View-only entities (EMPLOYEE can list/view, no create/edit/delete)
        'products': EntityPermission.viewOnly,
        'themes': EntityPermission.viewOnly,
        'categories': EntityPermission.viewOnly,
        'brands': EntityPermission.viewOnly,
        'companies': EntityPermission.viewOnly,

        // WhatsApp campaigns: view-only for EMPLOYEE (no create/edit/delete/execute)
        // Permission string used: 'whatsapp.create', 'whatsapp.update', 'whatsapp.delete', 'whatsapp.send'
        // But 'whatsapp' entity = messages (full access), so campaigns need separate key
        'whatsapp-campaign': EntityPermission(
          crud: CrudPermission.viewOnly,
          canExecute: false,
        ),

        // Filtered (own records only)
        // Keys match the permission string prefix used in screens
        'inquiries': EntityPermission(
          crud: CrudPermission.filtered,
          canCreate: true,
          canEditOwn: true,
          canEditAll: false,
          canDeleteOwn: true,
          canDeleteAll: false,
        ),
        'activities': EntityPermission(
          crud: CrudPermission.filtered,
          canCreate: true,
          canEditOwn: true,
          canEditAll: false,
          canDeleteOwn: true,
          canDeleteAll: false,
        ),
        'users': EntityPermission(
          crud: CrudPermission.filtered,
          canCreate: true,
          createRoleFilter: ['CUSTOMER'],
        ),

        // Full access
        'groups': EntityPermission.full,
        'tags': EntityPermission.full,
        'dashboard': EntityPermission.full,
        'whatsapp': EntityPermission.full,
        'whatsapp-template': EntityPermission.full,
      },
    ),
  };

  /// Get config for a role. Returns null for ADMIN (admin has full access).
  static RoleConfig? getConfig(String role) => config[role];

  /// Check if a route is hidden for a given role
  static bool isRouteHidden(String role, String route) {
    if (role == 'ADMIN') return false;
    final cfg = config[role];
    if (cfg == null) return false;
    return cfg.hiddenRoutes.contains(route);
  }

  /// Check if a menu item is hidden for a given role
  static bool isMenuItemHidden(String role, String route) {
    if (role == 'ADMIN') return false;
    final cfg = config[role];
    if (cfg == null) return false;
    return cfg.hiddenMenuItems.contains(route);
  }

  /// Get entity permission for a role. Returns null (= full access) if not configured.
  static EntityPermission? getEntityPermission(String role, String entity) {
    if (role == 'ADMIN') return null; // admin = full access
    final cfg = config[role];
    if (cfg == null) return null;
    return cfg.entityPermissions[entity];
  }
}
