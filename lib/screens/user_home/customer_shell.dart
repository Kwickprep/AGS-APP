import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import 'pages/user_home.dart';
import 'pages/search_history.dart';
import 'search_history_bloc.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchHistoryBloc(),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            UserHome(),
            SearchHistory(),
            _AccountTab(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 1 && _currentIndex != 1) {
                // Refresh history when switching to the tab
                context.read<SearchHistoryBloc>().add(RefreshSearchHistory());
              }
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'My Product Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Account Tab (inline - simple screen)
// ============================================================================

class _AccountTab extends StatefulWidget {
  const _AccountTab();

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await GetIt.I<StorageService>().getUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await GetIt.I<AuthService>().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Account',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          _getInitials(),
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user!.fullName.isNotEmpty ? _user!.fullName : 'Customer',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_user!.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _user!.phone,
                          style: TextStyle(fontSize: 14, color: AppColors.grey),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Details card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_user!.userProvidedIndustry != null)
                        _buildInfoTile(Icons.business_outlined, 'Industry', _user!.userProvidedIndustry!),
                      if (_user!.userProvidedCompany != null)
                        _buildInfoTile(Icons.apartment_outlined, 'Company', _user!.userProvidedCompany!),
                      if (_user!.department != null)
                        _buildInfoTile(Icons.group_outlined, 'Department', _user!.department!),
                      if (_user!.division != null)
                        _buildInfoTile(Icons.medication_outlined, 'Division', _user!.division!),
                      if (_user!.email.isNotEmpty)
                        _buildInfoTile(Icons.email_outlined, 'Email', _user!.email),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: TextStyle(fontSize: 12, color: AppColors.grey)),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _getInitials() {
    final first = _user?.firstName.isNotEmpty == true ? _user!.firstName[0] : '';
    final last = _user?.lastName.isNotEmpty == true ? _user!.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}
