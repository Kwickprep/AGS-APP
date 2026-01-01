import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../config/app_colors.dart';
import '../config/routes.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = GetIt.I<AuthService>();
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Profile Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 45, color: AppColors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user?.fullName ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu Items
            _buildMenuItem(Icons.branding_watermark, 'Brands', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.brands);
            }),
            _buildMenuItem(Icons.category, 'Categories', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.categories);
            }),
            _buildMenuItem(Icons.palette, 'Themes', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.themes);
            }),
            _buildMenuItem(Icons.tag, 'Tags', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.tags);
            }),
            _buildMenuItem(Icons.inventory_2_outlined, 'Products', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.products);
            }),
            _buildMenuItem(Icons.event_note, 'Activities', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.activities);
            }),
            _buildMenuItem(Icons.assignment_outlined, 'Inquiries', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.inquiries);
            }),
            _buildMenuItem(Icons.group_outlined, 'Groups', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.groups);
            }),
            _buildMenuItem(Icons.person, 'Users', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.users);
            }),

            const Spacer(),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: InkWell(
                onTap: () async {
                  await _authService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Sign out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
