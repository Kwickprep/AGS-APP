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

  const CustomDropdown({
    Key? key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 200,
            maxWidth: double.infinity,
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.grey,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
              suffixIcon: value != null && onClear != null
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: onClear,
                color: AppColors.grey,
              )
                  : const Icon(Icons.arrow_drop_down, color: AppColors.grey),
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
            onChanged: onChanged,
            validator: validator,
            isExpanded: true,
            icon: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class DropdownItem<T> {
  final T value;
  final String label;

  DropdownItem({
    required this.value,
    required this.label,
  });
}
