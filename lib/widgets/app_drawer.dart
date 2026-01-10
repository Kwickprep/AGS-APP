import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../config/app_colors.dart';
import '../config/routes.dart';
import '../config/huge_icons.dart';
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
      child: Column(
        children: [
          // Simple Profile Header
          _buildProfileHeader(),

          // Scrollable Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildMenuItem(
                  icon: HugeIcons.award03,
                  title: 'Brands',
                  route: AppRoutes.brands,
                ),
                _buildMenuItem(
                  icon: HugeIcons.orthogonalEdge,
                  title: 'Categories',
                  route: AppRoutes.categories,
                ),
                _buildMenuItem(
                  icon: HugeIcons.colors,
                  title: 'Themes',
                  route: AppRoutes.themes,
                ),
                _buildMenuItem(
                  icon: HugeIcons.tag01,
                  title: 'Tags',
                  route: AppRoutes.tags,
                ),
                _buildMenuItem(
                  icon: HugeIcons.package,
                  title: 'Products',
                  route: AppRoutes.products,
                ),
                _buildMenuItem(
                  icon: HugeIcons.chartColumn,
                  title: 'Activities',
                  route: AppRoutes.activities,
                ),
                _buildMenuItem(
                  icon: HugeIcons.share07,
                  title: 'Activity Types',
                  route: AppRoutes.activityTypes,
                ),
                _buildMenuItem(
                  icon: HugeIcons.messageQuestion,
                  title: 'Inquiries',
                  route: AppRoutes.inquiries,
                ),
                _buildMenuItem(
                  icon: HugeIcons.userGroup,
                  title: 'Groups',
                  route: AppRoutes.groups,
                ),
                _buildMenuItem(
                  icon: HugeIcons.userMultiple02,
                  title: 'Users',
                  route: AppRoutes.users,
                ),
                _buildMenuItem(
                  icon: HugeIcons.bandage,
                  title: 'Companies',
                  route: AppRoutes.companies,
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Logout Button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      _user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.role ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey[700],
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      dense: true,
    );
  }

  Widget _buildLogoutButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await _authService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
