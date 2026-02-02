import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import 'action_button.dart';
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

  CardField.title({required this.label, required this.value, this.maxLines})
    : isTitle = true,
      isDescription = false;

  CardField.description({
    required this.label,
    required this.value,
    this.maxLines = 2,
  }) : isTitle = false,
       isDescription = true;

  CardField.regular({required this.label, required this.value, this.maxLines})
    : isTitle = false,
      isDescription = false;
}

/// Reusable record card widget with compact design
class RecordCard extends StatelessWidget {
  final String? id;
  final int? serialNumber;
  final String? status;
  final bool? isActive;
  final List<CardField> fields;
  final String? createdBy;
  final String? createdAt;
  final String? updatedBy;
  final String? updatedAt;
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
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Separate title fields from regular fields
    final titleFields = fields.where((f) => f.isTitle).toList();
    final regularFields = fields.where((f) => !f.isTitle).toList();
    final hasMetadata = createdBy != null || createdAt != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: SR badge + status
            if (serialNumber != null || status != null || isActive != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (serialNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$serialNumber',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (status != null || isActive != null)
                      StatusBadge(
                        status: status ?? (isActive == true ? 'Active' : 'Inactive'),
                        isActive: isActive,
                      ),
                  ],
                ),
              ),

            // Title fields
            for (final field in titleFields)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      field.value,
                      style: AppTextStyles.cardTitle,
                      maxLines: field.maxLines ?? 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // Divider before regular fields
            if (regularFields.isNotEmpty)
              const Divider(height: 1, thickness: 1, color: AppColors.border),

            // Regular fields in 2-column grid
            if (regularFields.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: _buildFieldGrid(regularFields),
              ),

            // Metadata footer (created/updated)
            if (hasMetadata) ...[
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _buildMetadataFooter(),
            ],

            // Action buttons
            if (onView != null || onEdit != null || onDelete != null) ...[
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildFieldGrid(List<CardField> regularFields) {
    final List<Widget> rows = [];
    for (int i = 0; i < regularFields.length; i += 2) {
      final left = regularFields[i];
      final right = (i + 1 < regularFields.length) ? regularFields[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCompactField(left)),
              const SizedBox(width: 16),
              Expanded(
                child: right != null
                    ? _buildCompactField(right)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildCompactField(CardField field) {
    if (field.isDescription) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            field.value,
            style: AppTextStyles.cardDescription,
            maxLines: field.maxLines ?? 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          field.value.isNotEmpty ? field.value : 'N/A',
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          maxLines: field.maxLines ?? 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetadataFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          if (createdBy != null || createdAt != null)
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Created${createdBy != null && createdBy!.isNotEmpty ? ' by $createdBy' : ''}${createdAt != null && createdAt!.isNotEmpty ? '  ·  $createdAt' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (updatedBy != null || updatedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.edit_outlined, size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Updated${updatedBy != null && updatedBy!.isNotEmpty ? ' by $updatedBy' : ''}${updatedAt != null && updatedAt!.isNotEmpty ? '  ·  $updatedAt' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
