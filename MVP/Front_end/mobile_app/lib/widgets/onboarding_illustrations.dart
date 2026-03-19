import 'package:flutter/material.dart';

/// Translation Illustration Painter
///
/// 翻译插画 - 用于 Onboarding Slide 2
/// 绘制中英文对话气泡表达语言翻译的概念
class TranslationIllustrationPainter extends CustomPainter {
  final Color accentColor;

  TranslationIllustrationPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 中文气泡（左上，accent color 填充）──
    final zhBubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.10, w * 0.47, h * 0.30),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(zhBubble, Paint()..color = accentColor.withOpacity(0.85));

    // 中文气泡尾巴（三角形，指向左下）
    final zhTail = Path()
      ..moveTo(w * 0.23, h * 0.40)
      ..lineTo(w * 0.20, h * 0.48)
      ..lineTo(w * 0.30, h * 0.40);
    canvas.drawPath(zhTail, Paint()..color = accentColor.withOpacity(0.85));

    // "中文" 文字
    final zhPainter = TextPainter(
      text: TextSpan(
        text: '中文',
        style: TextStyle(
          fontSize: w * 0.13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF16162A),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    zhPainter.paint(canvas, Offset(w * 0.17, h * 0.18));

    // ── English 气泡（右下，白色填充）──
    final enBubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.43, h * 0.45, w * 0.50, h * 0.30),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(enBubble, Paint()..color = Colors.white.withOpacity(0.90));

    // English 气泡尾巴
    final enTail = Path()
      ..moveTo(w * 0.60, h * 0.75)
      ..lineTo(w * 0.57, h * 0.83)
      ..lineTo(w * 0.67, h * 0.75);
    canvas.drawPath(enTail, Paint()..color = Colors.white.withOpacity(0.90));

    // "English" 文字
    final enPainter = TextPainter(
      text: TextSpan(
        text: 'English',
        style: TextStyle(
          fontSize: w * 0.12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF16162A),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    enPainter.paint(canvas, Offset(w * 0.50, h * 0.53));

    // ── 翻译过渡圆点（气泡之间的连接暗示）──
    final dotPaint = Paint();
    canvas.drawCircle(Offset(w * 0.45, h * 0.42), w * 0.02,
        dotPaint..color = Colors.white.withOpacity(0.50));
    canvas.drawCircle(Offset(w * 0.50, h * 0.38), w * 0.015,
        dotPaint..color = Colors.white.withOpacity(0.30));
    canvas.drawCircle(Offset(w * 0.42, h * 0.46), w * 0.012,
        dotPaint..color = Colors.white.withOpacity(0.20));
  }

  @override
  bool shouldRepaint(covariant TranslationIllustrationPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}

/// Navigation Illustration Painter
///
/// 导航插画 - 用于 Onboarding Slide 3
/// 绘制地图卡片 + 路线 + 起终点标记
class NavigationIllustrationPainter extends CustomPainter {
  final Color accentColor;

  NavigationIllustrationPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 地图卡片背景 ──
    final mapCard = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.13, w * 0.80, h * 0.60),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(mapCard, Paint()..color = Colors.white.withOpacity(0.08));
    canvas.drawRRect(
        mapCard,
        Paint()
          ..color = Colors.white.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // ── 道路底纹（浅色弯曲线条）──
    final road1 = Path()
      ..moveTo(w * 0.16, h * 0.42)
      ..quadraticBezierTo(w * 0.35, h * 0.25, w * 0.50, h * 0.38)
      ..quadraticBezierTo(w * 0.68, h * 0.50, w * 0.84, h * 0.30);
    canvas.drawPath(
        road1,
        Paint()
          ..color = Colors.white.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);

    final road2 = Path()
      ..moveTo(w * 0.20, h * 0.56)
      ..quadraticBezierTo(w * 0.42, h * 0.46, w * 0.64, h * 0.58);
    canvas.drawPath(
        road2,
        Paint()
          ..color = Colors.white.withOpacity(0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);

    // ── 高亮路线（accent color, 粗线）──
    final route = Path()
      ..moveTo(w * 0.27, h * 0.47)
      ..quadraticBezierTo(w * 0.44, h * 0.30, w * 0.58, h * 0.38)
      ..quadraticBezierTo(w * 0.70, h * 0.45, w * 0.80, h * 0.32);
    canvas.drawPath(
        route,
        Paint()
          ..color = accentColor.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);

    // ── 起点（绿色圆点 + 脉冲圈）──
    final startPt = Offset(w * 0.27, h * 0.47);
    canvas.drawCircle(
        startPt, w * 0.05, Paint()..color = const Color(0xFF1FB368).withOpacity(0.15));
    canvas.drawCircle(
        startPt, w * 0.03, Paint()..color = const Color(0xFF1FB368).withOpacity(0.90));

    // ── 终点 Pin（accent color 水滴形）──
    final pinX = w * 0.80;
    final pinTopY = h * 0.18;
    final pinBottomY = h * 0.35;
    final pinPath = Path()
      ..moveTo(pinX - w * 0.05, pinTopY)
      ..lineTo(pinX + w * 0.05, pinTopY)
      ..lineTo(pinX + w * 0.03, pinBottomY - w * 0.05)
      ..lineTo(pinX, pinBottomY)
      ..lineTo(pinX - w * 0.03, pinBottomY - w * 0.05)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = accentColor.withOpacity(0.90));
    canvas.drawCircle(Offset(pinX, pinBottomY), w * 0.015,
        Paint()..color = Colors.white.withOpacity(0.40));

    // ── 英文地名标注（半透明小字）──
    final label1 = TextPainter(
      text: TextSpan(
        text: 'Tiananmen Square',
        style: TextStyle(
            fontSize: w * 0.058, color: Colors.white.withOpacity(0.30)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label1.paint(canvas, Offset(w * 0.18, h * 0.65));

    final label2 = TextPainter(
      text: TextSpan(
        text: 'The Bund',
        style: TextStyle(
            fontSize: w * 0.050, color: Colors.white.withOpacity(0.20)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label2.paint(canvas, Offset(w * 0.50, h * 0.20));
  }

  @override
  bool shouldRepaint(covariant NavigationIllustrationPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
