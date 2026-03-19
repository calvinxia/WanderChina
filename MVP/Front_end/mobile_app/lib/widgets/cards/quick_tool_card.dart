import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// Quick Tool Card - Used in Home Dashboard
/// Based on Figma design - Components/Quick Tools
class QuickToolCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isEnabled;

  const QuickToolCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  State<QuickToolCard> createState() => _QuickToolCardState();
}

class _QuickToolCardState extends State<QuickToolCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isEnabled
                        ? [widget.color, widget.color.withOpacity(0.7)]
                        : [AppColors.gray300, AppColors.gray200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                  boxShadow: widget.isEnabled
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),

              AppSpacing.gapHeightS,

              // Label
              Text(
                widget.label,
                style: AppTextStyles.bodySmall(
                  color: widget.isEnabled ? AppColors.gray800 : AppColors.gray400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
