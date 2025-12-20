import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

/// Reusable status badge widget
/// Can be used across different screens to display status
class StatusBadge extends StatelessWidget {
  final String status;
  final bool? isActive;

  const StatusBadge({
    super.key,
    required this.status,
    this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status, isActive);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config.label,
        style: AppTextStyles.label.copyWith(
          color: config.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status, bool? isActive) {
    // Handle boolean status
    if (isActive != null) {
      if (isActive) {
        return _StatusConfig(
          label: 'Active',
          backgroundColor: AppColors.activeBackground,
          textColor: AppColors.activeText,
        );
      } else {
        return _StatusConfig(
          label: 'Inactive',
          backgroundColor: AppColors.inactiveBackground,
          textColor: AppColors.inactiveText,
        );
      }
    }

    // Handle string status
    final statusLower = status.toLowerCase();
    if (statusLower == 'active' || statusLower == 'open') {
      return _StatusConfig(
        label: status,
        backgroundColor: AppColors.activeBackground,
        textColor: AppColors.activeText,
      );
    } else if (statusLower == 'pending' || statusLower == 'on hold') {
      return _StatusConfig(
        label: status,
        backgroundColor: AppColors.pendingBackground,
        textColor: AppColors.pendingText,
      );
    } else if (statusLower == 'completed' || statusLower == 'closed') {
      return _StatusConfig(
        label: status,
        backgroundColor: AppColors.completedBackground,
        textColor: AppColors.completedText,
      );
    } else if (statusLower == 'cancelled' || statusLower == 'inactive') {
      return _StatusConfig(
        label: status,
        backgroundColor: AppColors.cancelledBackground,
        textColor: AppColors.cancelledText,
      );
    } else {
      return _StatusConfig(
        label: status,
        backgroundColor: AppColors.lightGrey,
        textColor: AppColors.textSecondary,
      );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}
