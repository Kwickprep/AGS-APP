import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
    this.height,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CustomButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled =
        widget.isDisabled || widget.isLoading || widget.onPressed == null;

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isButtonDisabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _getBackgroundColor(isButtonDisabled),
              borderRadius: BorderRadius.circular(12),
              border: widget.variant == ButtonVariant.outline
                  ? Border.all(
                      color: isButtonDisabled
                          ? AppColors.lightGrey
                          : AppColors.primary,
                      width: 1.5,
                    )
                  : null,
              boxShadow: widget.variant == ButtonVariant.primary &&
                      !isButtonDisabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: _buildButtonChild(isButtonDisabled),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isButtonDisabled) {
    if (widget.variant == ButtonVariant.outline) {
      return Colors.transparent;
    }
    return isButtonDisabled ? AppColors.lightGrey : AppColors.primary;
  }

  Widget _buildButtonChild(bool isButtonDisabled) {
    if (widget.isLoading) {
      return _buildLoader();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 20,
            color: _getTextColor(isButtonDisabled),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getTextColor(isButtonDisabled),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Color _getTextColor(bool isButtonDisabled) {
    if (widget.variant == ButtonVariant.outline) {
      return isButtonDisabled ? AppColors.grey : AppColors.primary;
    }
    return isButtonDisabled ? AppColors.grey : AppColors.white;
  }

  Widget _buildLoader() {
    final loaderColor = widget.variant == ButtonVariant.outline
        ? AppColors.primary
        : AppColors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsating circles (3 dots like Blinkit/Swiggy)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
                final scale = Tween<double>(begin: 0.0, end: 1.0)
                    .transform(animationValue > 0.5 ? 1.0 - animationValue : animationValue * 2);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.scale(
                    scale: 0.6 + (scale * 0.4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: loaderColor.withValues(alpha: 0.6 + (scale * 0.4)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

enum ButtonVariant { primary, outline }
