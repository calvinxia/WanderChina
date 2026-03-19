import 'package:flutter/material.dart';

/// WanderChina App Logo - Interlocking WW Mark
///
/// 双 W 交织纹样
/// 代表 Wander + WanderChina，象征文化交融、中外连接
class AppLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color strokeColor;

  const AppLogo({
    super.key,
    this.size = 80,
    this.backgroundColor = const Color(0xFF1A1A1E),
    this.strokeColor = const Color(0xFFE8D5C4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22), // iOS-style roundrect
        color: backgroundColor,
      ),
      child: CustomPaint(
        painter: _WWLogoPainter(color: strokeColor),
      ),
    );
  }
}

class _WWLogoPainter extends CustomPainter {
  final Color color;

  _WWLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 归一化坐标，原始 viewBox 1024x1024
    double x(double v) => v / 1024 * w;
    double y(double v) => v / 1024 * h;

    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.029 // ≈30/1024
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // W1: 上方 W（peaks up）
    final w1 = Path()
      ..moveTo(x(218), y(362))
      ..lineTo(x(402), y(768))
      ..lineTo(x(512), y(472))
      ..lineTo(x(622), y(768))
      ..lineTo(x(806), y(362));

    // W2: 下方 W（peaks down, 与 W1 交织）
    final w2 = Path()
      ..moveTo(x(290), y(768))
      ..lineTo(x(402), y(472))
      ..lineTo(x(512), y(768))
      ..lineTo(x(622), y(472))
      ..lineTo(x(734), y(768));

    canvas.drawPath(w1, paint);
    canvas.drawPath(w2, paint);
  }

  @override
  bool shouldRepaint(covariant _WWLogoPainter old) => old.color != color;
}
