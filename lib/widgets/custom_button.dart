import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled = isDisabled || isLoading || onPressed == null;

    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: variant == ButtonVariant.outline
          ? OutlinedButton(
              onPressed: isButtonDisabled ? null : onPressed,
              style: _getOutlineButtonStyle(isButtonDisabled),
              child: _buildButtonChild(),
            )
          : ElevatedButton(
              onPressed: isButtonDisabled ? null : onPressed,
              style: _getElevatedButtonStyle(isButtonDisabled),
              child: _buildButtonChild(),
            ),
    );
  }

  Widget _buildButtonChild() {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.outline
                ? AppColors.primary
                : AppColors.white,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  ButtonStyle _getElevatedButtonStyle(bool isButtonDisabled) {
    return ElevatedButton.styleFrom(
      backgroundColor: isButtonDisabled
          ? AppColors.lightGrey
          : AppColors.primary,
      foregroundColor: isButtonDisabled
          ? AppColors.grey
          : AppColors.white,
      disabledBackgroundColor: AppColors.lightGrey,
      disabledForegroundColor: AppColors.grey,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  ButtonStyle _getOutlineButtonStyle(bool isButtonDisabled) {
    return OutlinedButton.styleFrom(
      foregroundColor: isButtonDisabled
          ? AppColors.grey
          : AppColors.primary,
      disabledForegroundColor: AppColors.grey,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(
        color: isButtonDisabled
            ? AppColors.lightGrey
            : AppColors.primary,
        width: 1.5,
      ),
    );
  }
}

enum ButtonVariant { primary, outline }
