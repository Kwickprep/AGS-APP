import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

/// Reusable action button widget
/// Used for Edit, Delete, and other action buttons
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  // Factory constructors for common actions
  factory ActionButton.edit({VoidCallback? onTap}) {
    return ActionButton(
      icon: Icons.edit_outlined,
      label: 'Edit',
      color: const Color(0xFF2196F3),
      onTap: onTap,
    );
  }

  factory ActionButton.delete({VoidCallback? onTap}) {
    return ActionButton(
      icon: Icons.delete_outline,
      label: 'Delete',
      color: const Color(0xFFE53935),
      onTap: onTap,
    );
  }

  factory ActionButton.view({VoidCallback? onTap}) {
    return ActionButton(
      icon: Icons.visibility_outlined,
      label: 'View',
      color: AppColors.primary,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color ?? AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color ?? AppColors.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
