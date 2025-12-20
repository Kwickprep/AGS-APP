import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

/// Reusable pagination controls widget
/// Can be used in any paginated list screen
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int? totalItems;
  final int? itemsPerPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onFirst;
  final VoidCallback? onLast;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.totalItems,
    this.itemsPerPage,
    this.onPrevious,
    this.onNext,
    this.onFirst,
    this.onLast,
  });

  @override
  Widget build(BuildContext context) {
    final bool canGoPrevious = currentPage > 1;
    final bool canGoNext = currentPage < totalPages;

    // Calculate item range
    String itemRangeText = '';
    if (totalItems != null && itemsPerPage != null) {
      final startItem = ((currentPage - 1) * itemsPerPage!) + 1;
      final endItem = (currentPage * itemsPerPage! > totalItems!)
          ? totalItems!
          : currentPage * itemsPerPage!;
      itemRangeText = 'Showing $startItem-$endItem of $totalItems items';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Item count info
          if (itemRangeText.isNotEmpty) ...[
            Text(
              itemRangeText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Pagination controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // First page button
              _PaginationButton(
                onTap: canGoPrevious && currentPage > 1 ? onFirst : null,
                icon: Icons.first_page,
                tooltip: 'First page',
              ),
              const SizedBox(width: 8),

              // Previous button
              _PaginationButton(
                onTap: canGoPrevious ? onPrevious : null,
                icon: Icons.chevron_left,
                label: 'Previous',
                tooltip: 'Previous page',
              ),
              const SizedBox(width: 16),

              // Page indicator with modern design
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$currentPage',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'of',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalPages',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Next button
              _PaginationButton(
                onTap: canGoNext ? onNext : null,
                icon: Icons.chevron_right,
                label: 'Next',
                iconRight: true,
                tooltip: 'Next page',
              ),
              const SizedBox(width: 8),

              // Last page button
              _PaginationButton(
                onTap: canGoNext && currentPage < totalPages ? onLast : null,
                icon: Icons.last_page,
                tooltip: 'Last page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom pagination button widget
class _PaginationButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String? label;
  final bool iconRight;
  final String? tooltip;

  const _PaginationButton({
    required this.onTap,
    required this.icon,
    this.label,
    this.iconRight = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 12 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.white
                : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled
                  ? AppColors.border
                  : AppColors.lightGrey,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!iconRight) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isEnabled
                      ? AppColors.textPrimary
                      : AppColors.textLight,
                ),
                if (label != null) const SizedBox(width: 6),
              ],
              if (label != null)
                Text(
                  label!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (iconRight) ...[
                if (label != null) const SizedBox(width: 6),
                Icon(
                  icon,
                  size: 18,
                  color: isEnabled
                      ? AppColors.textPrimary
                      : AppColors.textLight,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
