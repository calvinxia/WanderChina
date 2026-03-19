import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// Primary button with jade green background
/// Based on Figma design system
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonSize size;
  final IconData? icon;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = ButtonSize.large,
    this.icon,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = !widget.isDisabled && !widget.isLoading;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.isFullWidth ? double.infinity : null,
              height: _getHeight(),
              constraints: BoxConstraints(
                minWidth: widget.isFullWidth ? double.infinity : 120,
              ),
              decoration: BoxDecoration(
                gradient: isEnabled && widget.backgroundColor == null
                    ? _isPressed
                        ? const LinearGradient(
                            colors: [AppColors.jade900, AppColors.jade900],
                          )
                        : AppColors.primaryGradient
                    : null,
                color: isEnabled
                    ? widget.backgroundColor
                    : AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                boxShadow: isEnabled && !_isPressed
                    ? widget.backgroundColor != null
                        ? [
                            BoxShadow(
                              color: widget.backgroundColor!.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            )
                          ]
                        : [AppColors.jadeShadow]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  onTap: null, // Handled by GestureDetector
                  child: Padding(
                    padding: _getPadding(),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final effectiveTextColor = widget.isDisabled
        ? AppColors.gray400
        : (widget.textColor ?? Colors.white);

    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: _getLoaderSize(),
          height: _getLoaderSize(),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            color: effectiveTextColor,
            size: _getIconSize(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            widget.text,
            style: _getTextStyle().copyWith(
              color: effectiveTextColor,
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        widget.text,
        style: _getTextStyle().copyWith(
          color: effectiveTextColor,
        ),
      ),
    );
  }

  double _getHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppSpacing.buttonHeightSmall;
      case ButtonSize.medium:
        return AppSpacing.buttonHeightMedium;
      case ButtonSize.large:
        return AppSpacing.buttonHeightLarge;
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppSpacing.buttonPaddingSmall;
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
      case ButtonSize.large:
        return AppSpacing.buttonPadding;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppTextStyles.buttonSmall();
      case ButtonSize.medium:
        return AppTextStyles.button();
      case ButtonSize.large:
        return AppTextStyles.buttonLarge();
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getLoaderSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

enum ButtonSize { small, medium, large }
