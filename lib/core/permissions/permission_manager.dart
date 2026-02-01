import 'package:get_it/get_it.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

/// Singleton class to manage user permissions throughout the app
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  final AuthService _authService = GetIt.I<AuthService>();

  List<String> _permissions = [];
  String _role = '';

  /// Initialize permissions from current user
  Future<void> initialize() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _permissions = user.permissions ?? [];
      _role = user.role;
    }
  }

  /// Update permissions (call this after login or when user data changes)
  void updatePermissions(UserModel user) {
    _permissions = user.permissions ?? [];
    _role = user.role;
  }

  /// Clear permissions (call on logout)
  void clear() {
    _permissions = [];
    _role = '';
  }

  /// Get current user permissions
  List<String> get permissions => List.unmodifiable(_permissions);

  /// Get current user role
  String get role => _role;

  /// Check if user is admin (by role or system.admin permission)
  bool get isAdmin => _role == 'ADMIN' || _permissions.contains('system.admin');

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    // Admin has all permissions
    if (isAdmin) return true;
    return _permissions.contains(permission);
  }

  /// Check if user has any of the given permissions
  bool hasAnyPermission(List<String> permissions) {
    if (isAdmin) return true;
    return permissions.any((p) => _permissions.contains(p));
  }

  /// Check if user has all of the given permissions
  bool hasAllPermissions(List<String> permissions) {
    if (isAdmin) return true;
    return permissions.every((p) => _permissions.contains(p));
  }

  /// Check CRUD permissions for a resource
  bool canCreate(String resource) => hasPermission('$resource.create');
  bool canRead(String resource) => hasPermission('$resource.read');
  bool canUpdate(String resource) => hasPermission('$resource.update');
  bool canDelete(String resource) => hasPermission('$resource.delete');

  /// Check if user has any CRUD permission for a resource
  bool hasAnyAccessTo(String resource) {
    return hasAnyPermission([
      '$resource.create',
      '$resource.read',
      '$resource.update',
      '$resource.delete',
    ]);
  }

  /// Debugging helper - print all permissions
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
