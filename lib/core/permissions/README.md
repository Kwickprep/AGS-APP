# Role-Based Access Control (RBAC) System

This directory contains the implementation of the Role-Based Access Control system for the AGS Mobile App.

## 📁 File Structure

```
lib/core/permissions/
├── README.md                        # This file
├── permission_config.dart           # Module configurations and permission mappings
├── permission_manager.dart          # Singleton manager for permission state
├── permission_checker.dart          # Helper methods for permission checks
└── permission_usage_examples.dart   # Code examples (reference only)
```

## 🚀 Quick Start

### 1. Permission System is Auto-Initialized

The permission system automatically initializes when a user logs in via OTP or email/password. No manual setup required!

```dart
// This happens automatically in AuthService
await authService.verifyOtp(phoneCode, phoneNumber, otp);
// PermissionManager is already updated with user permissions ✓
```

### 2. Using PermissionWidget

The simplest way to show/hide UI based on permissions:

```dart
import '../../widgets/permission_widget.dart';

// Show button only if user has create permission
PermissionWidget(
  permission: 'products.create',
  child: ElevatedButton(
    onPressed: () => createProduct(),
    child: Text('Create Product'),
  ),
)
```

### 3. Using PermissionChecker

For programmatic permission checks:

```dart
import '../../core/permissions/permission_checker.dart';

void handleDelete() {
  if (PermissionChecker.canDeleteProduct) {
    // User has permission - proceed with delete
    deleteProduct();
  } else {
    // Show error message
    showSnackbar('You don\'t have permission to delete products');
  }
}
```

### 4. Using PermissionManager Directly

For advanced use cases:

```dart
import '../../core/permissions/permission_manager.dart';

final permissionManager = PermissionManager();

// Check if user is admin
if (permissionManager.isAdmin) {
  // Show admin panel
}

// Get user role
String role = permissionManager.role;

// Check multiple permissions
if (permissionManager.hasAllPermissions(['products.read', 'products.update'])) {
  // User has both permissions
}

// Debug - print all permissions
permissionManager.printPermissions();
```

## 📋 Permission Format

Permissions follow the format: `resource.action`

### Available Resources
- `brands` - Brand management
- `categories` - Category management
- `themes` - Theme management
- `tags` - Tag management
- `products` - Product management
- `activities` - Activity management
- `activity-types` - Activity type management
- `inquiries` - Inquiry management
- `groups` - Group management
- `users` - User management
- `companies` - Company management
- `files` - File management
- `whatsapp` - WhatsApp messaging
- `prompts` - Prompt management

### Common Actions
- `.create` - Permission to create new items
- `.read` - Permission to view/read items
- `.update` - Permission to edit/update items
- `.delete` - Permission to delete items

### Special Permissions
- `system.admin` - Super admin with all permissions

### Examples
```dart
'products.create'     // Can create products
'products.read'       // Can view products
'products.update'     // Can edit products
'products.delete'     // Can delete products
'system.admin'        // Has all permissions
```

## 🎯 Common Use Cases

### 1. Show/Hide Create Button

```dart
// In AppBar actions
actions: [
  PermissionWidget(
    permission: 'products.create',
    child: IconButton(
      icon: Icon(Icons.add),
      onPressed: () => navigateToCreate(),
    ),
  ),
],
```

### 2. Show/Hide Action Buttons in Data Table

```dart
Row(
  children: [
    PermissionWidget(
      permission: 'products.update',
      child: IconButton(
        icon: Icon(Icons.edit),
        onPressed: () => editProduct(product),
      ),
    ),
    PermissionWidget(
      permission: 'products.delete',
      child: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => deleteProduct(product),
      ),
    ),
  ],
)
```

### 3. Conditional Rendering with Fallback

```dart
PermissionWidget(
  permission: 'products.delete',
  child: DeleteButton(
    onPressed: () => deleteProduct(),
  ),
  fallback: Text(
    'You don\'t have permission to delete',
    style: TextStyle(color: Colors.grey),
  ),
)
```

### 4. Multiple Permissions (ANY)

```dart
// Show if user has create OR update permission
PermissionWidget(
  anyPermissions: ['products.create', 'products.update'],
  child: EditingToolbar(),
)
```

### 5. Multiple Permissions (ALL)

```dart
// Show only if user has BOTH read AND update permissions
PermissionWidget(
  allPermissions: ['products.read', 'products.update'],
  child: AdvancedSettingsPanel(),
)
```

### 6. Using PermissionBuilder for Complex Logic

```dart
PermissionBuilder(
  permission: 'products.update',
  builder: (context, hasPermission) {
    return ElevatedButton(
      onPressed: hasPermission ? () => editProduct() : null,
      child: Text(
        hasPermission ? 'Edit Product' : 'View Only',
      ),
    );
  },
)
```

### 7. Programmatic Check Before Action

```dart
Future<void> deleteProduct() async {
  // Check permission before proceeding
  if (!PermissionChecker.canDeleteProduct) {
    showErrorSnackbar('No permission to delete products');
    return;
  }

  // Proceed with delete
  await productService.delete(productId);
}
```

### 8. Conditional Navigation

```dart
void navigateToUsers() {
  if (PermissionChecker.hasAnyUserAccess) {
    Navigator.pushNamed(context, AppRoutes.users);
  } else {
    showSnackbar('Access denied');
  }
}
```

## 📱 Auto-Filtered Navigation Menu

The app drawer automatically filters menu items based on user permissions. This is configured in `app_drawer.dart`:

```dart
// Modules are automatically filtered based on user permissions
_accessibleModules = PermissionConfig.getAccessibleModules(
  _permissionManager.permissions,
);
```

To add a new module to the navigation:

1. Add route to `lib/config/routes.dart`
2. Add module to `PermissionConfig.allModules` in `permission_config.dart`:

```dart
AppModule(
  name: 'New Feature',
  icon: HugeIcons.someIcon,
  route: AppRoutes.newFeature,
  readPermission: 'new-feature.read',
  createPermission: 'new-feature.create',
  updatePermission: 'new-feature.update',
  deletePermission: 'new-feature.delete',
),
```

3. That's it! The menu will automatically show/hide based on permissions.

## 🔧 PermissionChecker Quick Reference

```dart
// General
PermissionChecker.isAdmin
PermissionChecker.hasPermission('some.permission')
PermissionChecker.hasAnyPermission(['perm1', 'perm2'])
PermissionChecker.hasAllPermissions(['perm1', 'perm2'])

// Products
PermissionChecker.canCreateProduct
PermissionChecker.canReadProduct
PermissionChecker.canUpdateProduct
PermissionChecker.canDeleteProduct
PermissionChecker.hasAnyProductAccess

// Brands
PermissionChecker.canCreateBrand
PermissionChecker.canReadBrand
PermissionChecker.canUpdateBrand
PermissionChecker.canDeleteBrand
PermissionChecker.hasAnyBrandAccess

// Categories
PermissionChecker.canCreateCategory
PermissionChecker.canReadCategory
PermissionChecker.canUpdateCategory
PermissionChecker.canDeleteCategory
PermissionChecker.hasAnyCategoryAccess

// ... and similar for all other resources
// See permission_checker.dart for complete list
```

## 🎨 Best Practices

### DO ✅

1. **Use PermissionWidget for UI elements**
   ```dart
   PermissionWidget(
     permission: 'products.create',
     child: CreateButton(),
   )
   ```

2. **Use PermissionChecker for business logic**
   ```dart
   if (PermissionChecker.canDeleteProduct) {
     await deleteProduct();
   }
   ```

3. **Check permissions before API calls**
   ```dart
   Future<void> updateProduct() async {
     if (!PermissionChecker.canUpdateProduct) {
       throw Exception('No permission');
     }
     await api.updateProduct();
   }
   ```

4. **Provide user feedback**
   ```dart
   PermissionWidget(
     permission: 'products.delete',
     child: DeleteButton(),
     fallback: Text('Insufficient permissions'),
   )
   ```

### DON'T ❌

1. **Don't bypass permission checks**
   ```dart
   // BAD - No permission check
   await productService.delete(id);

   // GOOD - Check permission first
   if (PermissionChecker.canDeleteProduct) {
     await productService.delete(id);
   }
   ```

2. **Don't hardcode permissions**
   ```dart
   // BAD
   if (user.role == 'ADMIN') { ... }

   // GOOD
   if (PermissionManager().isAdmin) { ... }
   ```

3. **Don't forget to initialize permissions**
   ```dart
   // This is handled automatically in AuthService
   // Just ensure you're using the AuthService properly
   ```

## 🐛 Debugging

### Print User Permissions

```dart
import '../../core/permissions/permission_manager.dart';

// Anywhere in your code
PermissionManager().printPermissions();
```

Output:
```
=== User Permissions ===
Role: ADMIN
Is Admin: true
Permissions (50):
  - users.create
  - users.read
  - users.update
  - users.delete
  - products.create
  - products.read
  ...
=======================
```

### Check Specific Permission

```dart
final hasPermission = PermissionManager().hasPermission('products.create');
print('Can create products: $hasPermission');
```

## 📚 Additional Resources

- See `permission_usage_examples.dart` for 10+ detailed examples
- Check `app_drawer.dart` for real implementation of filtered navigation
- See `product_screen.dart` for real usage of PermissionWidget

## 🔄 Permission Flow

```
1. User logs in via OTP/Email
   ↓
2. AuthService receives response with user data (role + permissions)
   ↓
3. PermissionManager.updatePermissions() is called automatically
   ↓
4. Permissions are now available app-wide
   ↓
5. UI components use PermissionWidget/PermissionChecker
   ↓
6. Navigation menu auto-filters based on permissions
```

## ❓ FAQ

**Q: How do I add a new permission check?**
A: Use `PermissionWidget` or `PermissionChecker` with the permission string like `'resource.action'`

**Q: What if user is admin?**
A: Admins with `system.admin` permission automatically have access to everything

**Q: How do I test with different permissions?**
A: Login with different user accounts that have different roles/permissions from your backend

**Q: Where are permissions stored?**
A: In `PermissionManager` (in-memory) and `StorageService` (persistent with user data)

**Q: Do I need to manually clear permissions on logout?**
A: No, `AuthService.logout()` automatically calls `PermissionManager().clear()`

## 📞 Support

For issues or questions about the permission system, contact the development team.
