import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Transit Connector Widget - displays transit info between activities
///
/// Specifications from FLUTTER_UI_REDESIGN_INSTRUCTIONS.md:
/// - Icon: arrow or transit icon
/// - Text: Caption, Gray 500 (e.g., "→ Walk 10 min (0.8 km)")
/// - 左侧: 1px dashed vertical line, Gray 200
class TransitConnector extends StatelessWidget {
  final String transitText;
  final IconData? icon;

  const TransitConnector({
    super.key,
    required this.transitText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Left dashed line
          SizedBox(
            width: 20,
            child: CustomPaint(
              painter: _DashedLinePainter(),
              size: const Size(1, 24),
            ),
          ),
          const SizedBox(width: 8),

          // Arrow or transit icon
          Icon(
            icon ?? Icons.arrow_forward,
            size: 16,
            color: AppColors.gray500,
          ),
          const SizedBox(width: 8),

          // Transit text
          Expanded(
            child: Text(
              transitText,
              style: AppTextStyles.caption(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dashed vertical line
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray200
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
