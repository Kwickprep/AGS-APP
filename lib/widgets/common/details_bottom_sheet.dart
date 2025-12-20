import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import 'status_badge.dart';

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
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
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
                      style: AppTextStyles.heading3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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
                      const SizedBox(height: 24),
                    ],

                    // Fields
                    ...fields.map((field) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildField(
                        label: field.label,
                        value: field.value,
                      ),
                    )),
                  ],
                ),
              ),
            ),

            // Action buttons
            if (onEdit != null || onDelete != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: Row(
                  children: [
                    if (onEdit != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit?.call();
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label:  Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 12),
                    if (onDelete != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete?.call();
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
