import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../home_bloc.dart';

class DashboardWidgetCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final WidgetStatus status;
  final Widget child;
  final Widget? trailing;

  const DashboardWidgetCard({
    super.key,
    required this.title,
    required this.icon,
    required this.status,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 20, thickness: 0.5, color: AppColors.divider),
          // Body
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (status) {
      case WidgetStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case WidgetStatus.error:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, color: AppColors.error.withValues(alpha: 0.6), size: 28),
                const SizedBox(height: 8),
                const Text(
                  'Failed to load data',
                  style: TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
        );
      case WidgetStatus.loaded:
        return child;
    }
  }
}
