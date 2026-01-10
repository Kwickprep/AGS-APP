/// This file contains examples of how to use the Permission system in your app
/// DO NOT import this file in production code - it's for reference only

import 'package:flutter/material.dart';
import '../../widgets/permission_widget.dart';
import 'permission_checker.dart';
import 'permission_manager.dart';

// ========================================================================
// EXAMPLE 1: Simple Permission Check - Hide/Show Create Button
// ========================================================================
class Example1_SimplePermissionWidget extends StatelessWidget {
  const Example1_SimplePermissionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Only show "Add Product" button if user has create permission
          PermissionWidget(
            permission: 'products.create',
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Navigate to create product screen
              },
            ),
          ),
        ],
      ),
      body: const Center(child: Text('Product List')),
    );
  }
}

// ========================================================================
// EXAMPLE 2: Multiple Permissions - Show if ANY permission matches
// ========================================================================
class Example2_AnyPermission extends StatelessWidget {
  const Example2_AnyPermission({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Show edit section if user can create OR update products
          PermissionWidget(
            anyPermissions: ['products.create', 'products.update'],
            child: Card(
              child: ListTile(
                title: const Text('Edit Product'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // Navigate to edit screen
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// EXAMPLE 3: All Permissions Required - Show if ALL permissions match
// ========================================================================
class Example3_AllPermissions extends StatelessWidget {
  const Example3_AllPermissions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Show advanced settings only if user has BOTH read AND update
          PermissionWidget(
            allPermissions: ['products.read', 'products.update'],
            child: const Card(
              child: ListTile(
                title: Text('Advanced Product Settings'),
                trailing: Icon(Icons.settings),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// EXAMPLE 4: With Fallback Widget - Show alternative if no permission
// ========================================================================
class Example4_WithFallback extends StatelessWidget {
  const Example4_WithFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Show delete button OR message if no permission
          PermissionWidget(
            permission: 'products.delete',
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Delete Product'),
              onPressed: () {
                // Delete product
              },
            ),
            fallback: const Text(
              'You don\'t have permission to delete products',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// EXAMPLE 5: Using PermissionBuilder for Complex Logic
// ========================================================================
class Example5_PermissionBuilder extends StatelessWidget {
  const Example5_PermissionBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PermissionBuilder(
            permission: 'products.update',
            builder: (context, hasPermission) {
              return ElevatedButton(
                onPressed: hasPermission
                    ? () {
                        // Update product
                      }
                    : null, // Disabled if no permission
                child: Text(
                  hasPermission ? 'Edit Product' : 'View Product (Read Only)',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// EXAMPLE 6: Using PermissionChecker - Programmatic Checks
// ========================================================================
class Example6_PermissionChecker extends StatelessWidget {
  const Example6_PermissionChecker({super.key});

  void _handleAction() {
    // Check permission before performing action
    if (PermissionChecker.canDeleteProduct) {
      // Delete product
      print('Deleting product...');
    } else {
      // Show error message
      print('No permission to delete');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _handleAction,
          child: const Text('Delete Product'),
        ),
      ),
    );
  }
}

// ========================================================================
// EXAMPLE 7: Action Buttons Row with Permissions
// ========================================================================
class Example7_ActionButtons extends StatelessWidget {
  const Example7_ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // View button (always visible if user has read permission)
        PermissionWidget(
          permission: 'products.read',
          child: TextButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text('View'),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        // Edit button (only if has update permission)
        PermissionWidget(
          permission: 'products.update',
          child: TextButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        // Delete button (only if has delete permission)
        PermissionWidget(
          permission: 'products.delete',
          child: TextButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

// ========================================================================
// EXAMPLE 8: Using PermissionManager Directly
// ========================================================================
class Example8_PermissionManager extends StatelessWidget {
  const Example8_PermissionManager({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionManager = PermissionManager();

    return Scaffold(
      body: Column(
        children: [
          Text('Role: ${permissionManager.role}'),
          Text('Is Admin: ${permissionManager.isAdmin}'),
          Text('Total Permissions: ${permissionManager.permissions.length}'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Print all permissions to console
              permissionManager.printPermissions();
            },
            child: const Text('Print Permissions to Console'),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// EXAMPLE 9: Data Table with Permission-based Actions
// ========================================================================
class Example9_DataTableWithPermissions extends StatelessWidget {
  const Example9_DataTableWithPermissions({super.key});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Actions')),
      ],
      rows: [
        DataRow(
          cells: [
            const DataCell(Text('Product 1')),
            const DataCell(Text('\$100')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PermissionWidget(
                    permission: 'products.update',
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {},
                    ),
                  ),
                  PermissionWidget(
                    permission: 'products.delete',
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ========================================================================
// EXAMPLE 10: Floating Action Button with Permission
// ========================================================================
class Example10_FABWithPermission extends StatelessWidget {
  const Example10_FABWithPermission({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: const Center(child: Text('Product List')),
      floatingActionButton: PermissionWidget(
        permission: 'products.create',
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to create product
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
