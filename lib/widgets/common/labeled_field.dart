import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

/// Reusable labeled field widget
/// Displays a label with a value in a consistent format
/// Can be used anywhere you need to show labeled data
class LabeledField extends StatelessWidget {
  final String label;
  final String value;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const LabeledField({
    super.key,
    required this.label,
    required this.value,
    this.maxLines,
    this.overflow,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: labelStyle ??
              AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ??
              AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
          maxLines: maxLines,
          overflow: overflow,
        ),
      ],
    );
  }
}

/// Variant for larger/title fields
class LabeledFieldTitle extends StatelessWidget {
  final String label;
  final String value;
  final int? maxLines;

  const LabeledFieldTitle({
    super.key,
    required this.label,
    required this.value,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      value: value,
      maxLines: maxLines,
      valueStyle: AppTextStyles.cardTitle,
    );
  }
}

/// Variant for description fields
class LabeledFieldDescription extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;

  const LabeledFieldDescription({
    super.key,
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      value: value,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      valueStyle: AppTextStyles.cardDescription,
    );
  }
}
