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
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.all(20),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).viewPadding.top),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.white,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_user?.fullName} (${_user?.email})' ?? 'User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    _user?.role.toLowerCase() ?? '',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user?.phone ?? '',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.branding_watermark),
            title: const Text('Brands'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.brands);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.categories);
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Themes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.themes);
            },
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text('Tags'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.tags);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Products'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.products);
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Activities'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.activities);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Inquiries'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.inquiries);
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Groups'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.groups);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Users'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.users);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
