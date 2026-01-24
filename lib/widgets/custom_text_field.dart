import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final VoidCallback? onSuffixTap;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;
  final bool isRequired;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.prefixIcon,
    this.focusNode,
    this.suffixIcon,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.errorText,
    this.onSuffixTap,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.isRequired = false,
    this.hint,
    this.textInputAction,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
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
        ],
        TextFormField(
          focusNode: focusNode,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: maxLines,
          textInputAction: textInputAction,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label',
            hintStyle: const TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
            errorText: errorText,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 14 : 16,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.grey, size: 20)
                : null,
            suffixIcon: suffixWidget ?? (suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, color: AppColors.grey, size: 20),
                    onPressed: onSuffixTap,
                  )
                : null),
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
        ),
      ],
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}
