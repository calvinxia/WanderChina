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

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = ButtonSize.large,
    this.icon,
    this.isDisabled = false,
  }) : super(key: key);

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
                gradient: isEnabled
                    ? _isPressed
                        ? LinearGradient(
                            colors: [AppColors.jade900, AppColors.jade900],
                          )
                        : AppColors.primaryGradient
                    : null,
                color: isEnabled ? null : AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                boxShadow: isEnabled && !_isPressed
                    ? [AppColors.jadeShadow]
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
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: _getLoaderSize(),
          height: _getLoaderSize(),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            color: widget.isDisabled ? AppColors.gray400 : Colors.white,
            size: _getIconSize(),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            widget.text,
            style: _getTextStyle().copyWith(
              color: widget.isDisabled ? AppColors.gray400 : Colors.white,
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        widget.text,
        style: _getTextStyle().copyWith(
          color: widget.isDisabled ? AppColors.gray400 : Colors.white,
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
        return EdgeInsets.symmetric(horizontal: 20, vertical: 10);
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
