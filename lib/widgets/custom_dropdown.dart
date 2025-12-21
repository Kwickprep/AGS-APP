import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool isRequired;
  final VoidCallback? onClear;
  final bool isEnabled;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.onClear,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LABEL
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        /// DROPDOWN
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          alignment: Alignment.topLeft,
          hint: Text(
            hint,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
          icon: value != null && isEnabled
              ? InkWell(
                  onTap: () {
                    if (onClear != null) {
                      onClear!();
                    }
                    onChanged(null);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.clear,
                      size: 20,
                      color: AppColors.grey,
                    ),
                  ),
                )
              : const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.grey,
                ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),

          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),

          onChanged: isEnabled ? onChanged : null,
          validator: validator,
        ),
      ],
    );
  }
}

/// DROPDOWN ITEM MODEL
class DropdownItem<T> {
  final T value;
  final String label;

  DropdownItem({required this.value, required this.label});
}
