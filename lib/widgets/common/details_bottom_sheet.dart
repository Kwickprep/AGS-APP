import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../config/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import 'status_badge.dart';
import '../../widgets/custom_button.dart';

/// Detail field model
class DetailField {
  final String label;
  final String value;

  const DetailField({
    required this.label,
    required this.value,
  });
}

/// Generic details bottom sheet
class DetailsBottomSheet extends StatelessWidget {
  final String title;
  final String? status;
  final bool? isActive;
  final List<DetailField> fields;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DetailsBottomSheet({
    super.key,
    required this.title,
    this.status,
    this.isActive,
    required this.fields,
    this.onEdit,
    this.onDelete,
  });

  /// Helper method to show the bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? status,
    bool? isActive,
    required List<DetailField> fields,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailsBottomSheet(
        title: title,
        status: status,
        isActive: isActive,
        fields: fields,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.9;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    if (status != null || isActive != null) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: StatusBadge(
                          status: status ?? (isActive == true ? 'Active' : 'Inactive'),
                          isActive: isActive,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Fields
                    ...fields.map((field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildField(
                        label: field.label,
                        value: field.value,
                      ),
                    )),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Action buttons
            if (onEdit != null || onDelete != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: Row(
                  children: [
                    if (onEdit != null)
                      Expanded(
                        child: CustomButton(
                          text: 'Edit',
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit?.call();
                          },
                          icon: Icons.edit_outlined,
                        ),
                      ),
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 12),
                    if (onDelete != null)
                      Expanded(
                        child: CustomButton(
                          text: 'Delete',
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete?.call();
                          },
                          icon: Icons.delete_outline,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
