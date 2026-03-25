import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 将翻译文字渲染为 PNG badge 图片,用于自定义 Marker icon
class MarkerBadgePainter {

  /// 生成 badge 图片的 PNG bytes
  ///
  /// [textEn] 英文名(主文字)
  /// [textZh] 中文名(副文字,较小)
  /// [isHighPriority] 是否高优先级(景点/地铁)
  /// [devicePixelRatio] 设备像素密度(通常 2.0 或 3.0)
  static Future<Uint8List> renderBadge({
    required String textEn,
    required String textZh,
    bool isHighPriority = false,
    double devicePixelRatio = 2.0,
  }) async {
    // ── 尺寸计算 ──
    // 先测量文字宽度来决定 badge 宽度
    const enFontSizeHigh = 13.0;
    const enFontSizeLow = 11.0;
    final enFontSize = isHighPriority ? enFontSizeHigh : enFontSizeLow;
    const zhFontSize = 10.0;
    final maxTextWidth = _measureTextWidth(textEn, enFontSize)
        .clamp(60.0, 180.0); // 最小 60,最大 180

    final badgeWidth = maxTextWidth + 24; // 左右 padding 各 12
    const badgeHeight = 42.0; // 固定高度:英文行 + 中文行
    const arrowHeight = 6.0;
    const totalHeight = badgeHeight + arrowHeight;

    // ── 缩放到设备像素 ──
    final pixelWidth = (badgeWidth * devicePixelRatio).ceil();
    final pixelHeight = (totalHeight * devicePixelRatio).ceil();

    // ── Canvas 绘制 ──
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, pixelWidth.toDouble(), pixelHeight.toDouble()));

    canvas.scale(devicePixelRatio);

    // 颜色定义
    const bgColor = Colors.white;
    final borderColor = isHighPriority
        ? const Color(0xFFE8723A)  // Orange
        : const Color(0xFF9E9E9E); // Gray 500
    final shadowColor = Colors.black.withOpacity(0.15);

    // ── 阴影 ──
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, badgeWidth - 2, badgeHeight - 2),
      const Radius.circular(6),
    );
    canvas.drawRRect(shadowRect.shift(const Offset(0, 1)), shadowPaint);

    // ── 白色背景圆角矩形 ──
    final bgPaint = Paint()..color = bgColor;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, badgeWidth, badgeHeight),
      const Radius.circular(6),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // ── 左侧色条(3px 宽) ──
    final accentPaint = Paint()..color = borderColor;
    final accentRect = RRect.fromRectAndCorners(
      const Rect.fromLTWH(0, 0, 3, badgeHeight),
      topLeft: const Radius.circular(6),
      bottomLeft: const Radius.circular(6),
    );
    canvas.drawRRect(accentRect, accentPaint);

    // ── 英文文字(主) ──
    _drawText(
      canvas,
      textEn.length > 20 ? '${textEn.substring(0, 18)}...' : textEn, // 截断
      const Offset(10, 5),
      enFontSize,
      const Color(0xFF1A1A1A), // 近黑
      FontWeight.w600,
      badgeWidth - 14,
    );

    // ── 中文文字(副,灰色) ──
    _drawText(
      canvas,
      textZh.length > 12 ? '${textZh.substring(0, 10)}...' : textZh,
      const Offset(10, 23),
      zhFontSize,
      const Color(0xFF757575), // Gray 600
      FontWeight.w400,
      badgeWidth - 14,
    );

    // ── 底部三角箭头(指向坐标点) ──
    final arrowPath = Path()
      ..moveTo(badgeWidth / 2 - 5, badgeHeight)
      ..lineTo(badgeWidth / 2, badgeHeight + arrowHeight)
      ..lineTo(badgeWidth / 2 + 5, badgeHeight)
      ..close();
    canvas.drawPath(arrowPath, bgPaint);
    // 三角阴影
    canvas.drawPath(arrowPath.shift(const Offset(0, 1)), shadowPaint);
    canvas.drawPath(arrowPath, bgPaint); // 重画覆盖阴影顶部

    // ── 转为 PNG ──
    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelWidth, pixelHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// 在 Canvas 上绘制文字
  static void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Color color,
    FontWeight weight,
    double maxWidth,
  ) {
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: fontSize,
      fontWeight: weight,
      maxLines: 1,
      ellipsis: '...',
    ))
      ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize, fontWeight: weight))
      ..addText(text);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));

    canvas.drawParagraph(paragraph, offset);
  }

  /// 测量文字渲染宽度
  static double _measureTextWidth(String text, double fontSize) {
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    ))
      ..addText(text);
    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 300));
    return paragraph.longestLine;
  }
}
