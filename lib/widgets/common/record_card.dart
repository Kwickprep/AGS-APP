import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import 'action_button.dart';
import 'labeled_field.dart';
import 'status_badge.dart';

/// Configuration for a field to display in the card
class CardField {
  final String label;
  final String value;
  final bool isTitle;
  final bool isDescription;
  final int? maxLines;

  CardField({
    required this.label,
    required this.value,
    this.isTitle = false,
    this.isDescription = false,
    this.maxLines,
  });

  CardField.title({
    required this.label,
    required this.value,
    this.maxLines,
  })  : isTitle = true,
        isDescription = false;

  CardField.description({
    required this.label,
    required this.value,
    this.maxLines = 2,
  })  : isTitle = false,
        isDescription = true;

  CardField.regular({
    required this.label,
    required this.value,
    this.maxLines,
  })  : isTitle = false,
        isDescription = false;
}

/// Reusable record card widget
/// Displays record information with edit and delete actions
/// Can be used in any screen that displays record-based data
class RecordCard extends StatelessWidget {
  final String? id;
  final int? serialNumber;
  final String? status;
  final bool? isActive;
  final List<CardField> fields;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final VoidCallback? onTap;

  const RecordCard({
    super.key,
    this.id,
    this.serialNumber,
    this.status,
    this.isActive,
    required this.fields,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with SR, ID and status
            if (serialNumber != null || id != null || status != null || isActive != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (serialNumber != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'SR $serialNumber',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (id != null)
                          Text(
                            id!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    if (status != null || isActive != null)
                      StatusBadge(
                        status: status ?? (isActive == true ? 'Active' : 'Inactive'),
                        isActive: isActive,
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],

            // Fields with dividers
            for (int i = 0; i < fields.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: fields[i].isTitle
                    ? LabeledFieldTitle(
                        label: fields[i].label,
                        value: fields[i].value,
                        maxLines: fields[i].maxLines,
                      )
                    : fields[i].isDescription
                        ? LabeledFieldDescription(
                            label: fields[i].label,
                            value: fields[i].value,
                            maxLines: fields[i].maxLines ?? 2,
                          )
                        : LabeledField(
                            label: fields[i].label,
                            value: fields[i].value,
                            maxLines: fields[i].maxLines,
                          ),
              ),
              if (i < fields.length - 1)
                const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],

            // Action buttons with divider
            if (onView != null || onEdit != null || onDelete != null) ...[
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onView != null) ...[
                      ActionButton.view(onTap: onView),
                      const SizedBox(width: 12),
                    ],
                    if (onEdit != null) ...[
                      ActionButton.edit(onTap: onEdit),
                      const SizedBox(width: 12),
                    ],
                    if (onDelete != null) ActionButton.delete(onTap: onDelete),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
