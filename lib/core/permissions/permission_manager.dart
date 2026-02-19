import 'package:get_it/get_it.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'rbac_config.dart';

/// Singleton class to manage user permissions throughout the app.
///
/// Uses a role-based approach matching the web frontend:
/// - ADMIN: full access to everything
/// - EMPLOYEE: restricted via RbacConfig (hidden routes, view-only entities, filtered CRUD)
/// - CUSTOMER: separate shell, no access to admin pages
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  final AuthService _authService = GetIt.I<AuthService>();

  List<String> _permissions = [];
  String _role = '';
  String _userId = '';

  /// Initialize permissions from current user
  Future<void> initialize() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _permissions = user.permissions ?? [];
      _role = user.role;
      _userId = user.id;
    }
  }

  /// Update permissions (call this after login or when user data changes)
  void updatePermissions(UserModel user) {
    _permissions = user.permissions ?? [];
    _role = user.role;
    _userId = user.id;
  }

  /// Clear permissions (call on logout)
  void clear() {
    _permissions = [];
    _role = '';
    _userId = '';
  }

  // ========== Basic getters ==========

  List<String> get permissions => List.unmodifiable(_permissions);
  String get role => _role;
  String get userId => _userId;

  bool get isAdmin => _role == 'ADMIN' || _permissions.contains('system.admin');
  bool get isEmployee => _role == 'EMPLOYEE';
  bool get isCustomer => _role == 'CUSTOMER';

  // ========== Granular permission checks (legacy, still used by some screens) ==========

  bool hasPermission(String permission) {
    if (isAdmin) return true;

    // Check RBAC config for entity permission patterns (e.g., 'products.create')
    // This ensures role-based restrictions override backend-sent permissions
    final parts = permission.split('.');
    if (parts.length == 2) {
      final entity = parts[0];
      final action = parts[1];
      final perm = _getEntityPerm(entity);
      if (perm != null) {
        // RBAC config exists for this entity — use it
        switch (action) {
          case 'create':
            return perm.canCreate;
          case 'update':
            return perm.canEditAll || perm.canEditOwn;
          case 'delete':
            return perm.canDeleteAll || perm.canDeleteOwn;
          case 'read':
            // view-only still allows read
            return true;
          case 'send':
          case 'execute':
            return perm.canExecute;
        }
      }
    }

    return _permissions.contains(permission);
  }

  bool hasAnyPermission(List<String> permissions) {
    if (isAdmin) return true;
    return permissions.any((p) => _permissions.contains(p));
  }

  bool hasAllPermissions(List<String> permissions) {
    if (isAdmin) return true;
    return permissions.every((p) => _permissions.contains(p));
  }

  // ========== Role-based route/menu checks (matching web RBAC) ==========

  /// Check if a route is hidden for the current user's role
  bool isRouteHidden(String route) {
    return RbacConfig.isRouteHidden(_role, route);
  }

  /// Check if a menu item should be hidden for the current user's role
  bool isMenuItemHidden(String route) {
    return RbacConfig.isMenuItemHidden(_role, route);
  }

  // ========== Entity-level CRUD checks (matching web RBAC) ==========

  /// Get the entity permission config for current role.
  /// Returns null = full access (admin or no config).
  EntityPermission? _getEntityPerm(String entity) {
    return RbacConfig.getEntityPermission(_role, entity);
  }

  /// Can the user create a new record for this entity?
  bool canCreateEntity(String entity) {
    if (isAdmin) return true;
    final perm = _getEntityPerm(entity);
    if (perm == null) return true; // no config = full access
    return perm.canCreate;
  }

  /// Can the user edit this record?
  /// Pass [createdById] for ownership check on filtered entities.
  bool canEditEntity(String entity, {String? createdById}) {
    if (isAdmin) return true;
    final perm = _getEntityPerm(entity);
    if (perm == null) return true;
    if (perm.canEditAll) return true;
    if (perm.canEditOwn && createdById != null && createdById == _userId) return true;
    return false;
  }

  /// Can the user delete this record?
  /// Pass [createdById] for ownership check on filtered entities.
  bool canDeleteEntity(String entity, {String? createdById}) {
    if (isAdmin) return true;
    final perm = _getEntityPerm(entity);
    if (perm == null) return true;
    if (perm.canDeleteAll) return true;
    if (perm.canDeleteOwn && createdById != null && createdById == _userId) return true;
    return false;
  }

  /// Can the user execute actions on this entity (e.g., run a campaign)?
  bool canExecuteEntity(String entity) {
    if (isAdmin) return true;
    final perm = _getEntityPerm(entity);
    if (perm == null) return true;
    return perm.canExecute;
  }

  /// Is this entity view-only for the current role?
  bool isViewOnly(String entity) {
    if (isAdmin) return false;
    final perm = _getEntityPerm(entity);
    if (perm == null) return false;
    return perm.crud == CrudPermission.viewOnly;
  }

  /// Get the create role filter (e.g., EMPLOYEE can only create CUSTOMER users)
  List<String>? getCreateRoleFilter(String entity) {
    if (isAdmin) return null;
    final perm = _getEntityPerm(entity);
    return perm?.createRoleFilter;
  }

  // ========== Legacy resource CRUD (delegates to role-based now) ==========

  bool canCreate(String resource) {
    if (isAdmin) return true;
    // Try role-based first
    final perm = _getEntityPerm(resource);
    if (perm != null) return perm.canCreate;
    // Fallback to granular permission
    return hasPermission('$resource.create');
  }

  bool canRead(String resource) {
    if (isAdmin) return true;
    return hasPermission('$resource.read');
  }

  bool canUpdate(String resource) {
    if (isAdmin) return true;
    final perm = _getEntityPerm(resource);
    if (perm != null) return perm.canEditAll || perm.canEditOwn;
    return hasPermission('$resource.update');
  }

  bool canDelete(String resource) {
    if (isAdmin) return true;
    final perm = _getEntityPerm(resource);
    if (perm != null) return perm.canDeleteAll || perm.canDeleteOwn;
    return hasPermission('$resource.delete');
  }

  bool hasAnyAccessTo(String resource) {
    return hasAnyPermission([
      '$resource.create',
      '$resource.read',
      '$resource.update',
      '$resource.delete',
    ]);
  }

  // ========== Debug ==========

  void printPermissions() {
    print('=== User Permissions ===');
    print('Role: $_role');
    print('Is Admin: $isAdmin');
    print('Permissions (${_permissions.length}):');
    for (var permission in _permissions) {
      print('  - $permission');
    }
    print('=======================');
  }
}
