import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

/// Reusable filter and sort bar widget
/// Can be used in any list screen that needs filtering/sorting
class FilterSortBar extends StatelessWidget {
  final VoidCallback? onFilterTap;
  final VoidCallback? onSortTap;

  const FilterSortBar({
    super.key,
    this.onFilterTap,
    this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.tune,
          label: 'Filter',
          onTap: onFilterTap,
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.sort,
          label: 'Sort',
          onTap: onSortTap,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.iconPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.buttonSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
