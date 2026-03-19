import 'package:flutter/material.dart';

/// Mountain Silhouette - Visual motif for WanderChina
///
/// 山水剪影 - WanderChina 的视觉记忆点
/// 用于 Onboarding、Auth、Home、Me 页面的装饰性背景元素
class MountainSilhouette extends StatelessWidget {
  final Color color;
  final double opacity;
  final double height;

  const MountainSilhouette({
    super.key,
    this.color = const Color(0xFF2A2A48),
    this.opacity = 0.15,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _MountainPainter(color: color, opacity: opacity),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _MountainPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 后层山脉（较高、较淡）
    final backPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.67)
      ..quadraticBezierTo(w * 0.11, h * 0.29, w * 0.21, h * 0.46)
      ..quadraticBezierTo(w * 0.29, h * 0.13, w * 0.39, h * 0.33)
      ..quadraticBezierTo(w * 0.45, h * 0.04, w * 0.53, h * 0.25)
      ..quadraticBezierTo(w * 0.61, 0, w * 0.69, h * 0.21)
      ..quadraticBezierTo(w * 0.77, h * 0.08, w * 0.85, h * 0.29)
      ..quadraticBezierTo(w * 0.93, h * 0.17, w, h * 0.38)
      ..lineTo(w, h)
      ..close();

    // 前层山脉（较矮、较深）
    final frontPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.75)
      ..quadraticBezierTo(w * 0.13, h * 0.50, w * 0.27, h * 0.63)
      ..quadraticBezierTo(w * 0.37, h * 0.38, w * 0.48, h * 0.50)
      ..quadraticBezierTo(w * 0.59, h * 0.25, w * 0.69, h * 0.42)
      ..quadraticBezierTo(w * 0.80, h * 0.29, w * 0.91, h * 0.46)
      ..quadraticBezierTo(w * 0.96, h * 0.38, w, h * 0.50)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      backPath,
      Paint()..color = color.withOpacity(opacity),
    );
    canvas.drawPath(
      frontPath,
      Paint()..color = color.withOpacity(opacity * 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _MountainPainter old) =>
      old.color != color || old.opacity != opacity;
}
