import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

/// Configuration for a row in the card
class CardRowConfig {
  final IconData icon;
  final String text;
  final String? label;
  final Color? iconColor;
  final Color? textColor;

  CardRowConfig({
    required this.icon,
    required this.text,
    this.label,
    this.iconColor,
    this.textColor,
  });
}

/// Configuration for the status badge
class StatusBadgeConfig {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  StatusBadgeConfig({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });

  /// Factory for creating status badges with predefined colors
  factory StatusBadgeConfig.status(String status) {
    Color bgColor;
    Color txtColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'open':
      case 'active':
        bgColor = const Color(0xFFE3F2FD);
        txtColor = const Color(0xFF2196F3);
        borderColor = const Color(0xFF2196F3);
        break;
      case 'closed':
      case 'completed':
        bgColor = const Color(0xFFE8F5E9);
        txtColor = const Color(0xFF4CAF50);
        borderColor = const Color(0xFF4CAF50);
        break;
      case 'pending':
      case 'on hold':
        bgColor = const Color(0xFFFFF3E0);
        txtColor = const Color(0xFFFFA726);
        borderColor = const Color(0xFFFFA726);
        break;
      case 'cancelled':
      case 'inactive':
        bgColor = const Color(0xFFFFEBEE);
        txtColor = const Color(0xFFF44336);
        borderColor = const Color(0xFFF44336);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        txtColor = AppColors.grey;
        borderColor = AppColors.grey;
    }

    return StatusBadgeConfig(
      text: status,
      backgroundColor: bgColor,
      textColor: txtColor,
      borderColor: borderColor,
    );
  }
}

/// Reusable card widget for list items
class CommonListCard extends StatelessWidget {
  final String title;
  final StatusBadgeConfig? statusBadge;
  final List<CardRowConfig> rows;
  final VoidCallback? onView;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool showViewAction;
  final bool showDeleteAction;
  final bool showColumnLabels;
  final Color? cardHeaderBackgroundColor;
  final bool showActionsDivider;

  const CommonListCard({
    super.key,
    required this.title,
    this.statusBadge,
    required this.rows,
    this.onView,
    this.onDelete,
    this.onTap,
    this.showViewAction = true,
    this.showDeleteAction = true,
    this.showColumnLabels = false,
    this.cardHeaderBackgroundColor,
    this.showActionsDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.5), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status badge
            Container(
              padding:const EdgeInsets.all(12),
              decoration: cardHeaderBackgroundColor != null
                ? BoxDecoration(
                    color: cardHeaderBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  )
                : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Badge
                  if (statusBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBadge!.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusBadge!.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusBadge!.text,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusBadge!.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card rows
            ...rows.map((row) => Padding(
              padding: const EdgeInsets.only(left: 12,right: 12,bottom: 12),
              child: showColumnLabels && row.label != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            row.icon,
                            size: 16,
                            color: row.iconColor ?? AppColors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            row.label!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 22),
                        child: Text(
                          row.text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: row.textColor ?? AppColors.textPrimary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        row.icon,
                        size: 20,
                        color: row.iconColor ?? AppColors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          row.text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: row.textColor ?? AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
            )),

            // Divider above action buttons
            if ((showViewAction || showDeleteAction) && showActionsDivider)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Divider(
                    color: AppColors.lightGrey,
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 8),
                ],
              ),

            // Action buttons at bottom right
            if (showViewAction || showDeleteAction)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showViewAction && onView != null)
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      color: AppColors.primary,
                      iconSize: 20,
                      onPressed: onView,
                      tooltip: 'View',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (showViewAction && showDeleteAction && onView != null && onDelete != null)
                    const SizedBox(width: 12),
                  if (showDeleteAction && onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.error,
                      iconSize: 20,
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
