import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme/city_theme.dart';

/// 将翻译文字渲染为 PNG badge 图片,用于自定义 Marker icon
class MarkerBadgePainter {

  /// 生成 badge 图片的 PNG bytes
  ///
  /// [textEn] 英文名(主文字)
  /// [textZh] 中文名(副文字,较小)
  /// [isHighPriority] 是否高优先级(景点/地铁)
  /// [devicePixelRatio] 设备像素密度(通常 2.0 或 3.0)
  /// [theme] 城市主题，用于配置颜色
  static Future<Uint8List> renderBadge({
    required String textEn,
    required String textZh,
    bool isHighPriority = false,
    double devicePixelRatio = 2.0,
    CityTheme? theme,
  }) async {
    final currentTheme = theme ?? CityTheme.defaultTheme;
    // ── 尺寸计算 ──
    // 先测量文字宽度来决定 badge 宽度
    const enFontSize = 12.0;
    const zhFontSize = 10.0;
    final maxTextWidth = _measureTextWidth(textEn, enFontSize)
        .clamp(60.0, 200.0); // 最小 60,最大 200

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

    // 颜色定义 - 使用城市主题色
    final bgColor = Color.lerp(Colors.white, currentTheme.pillActiveColor, 0.08)!.withOpacity(0.85);
    final borderColor = currentTheme.pillActiveColor;
    final shadowColor = Colors.black.withOpacity(0.15);
    final enTextColor = currentTheme.primaryTextColor;
    final zhTextColor = currentTheme.secondaryTextColor;

    // ── 阴影 ──
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, badgeWidth - 2, badgeHeight - 2),
      const Radius.circular(6),
    );
    canvas.drawRRect(shadowRect.shift(const Offset(0, 1)), shadowPaint);

    // ── 背景圆角矩形 ──
    final bgPaint = Paint()..color = bgColor;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, badgeWidth, badgeHeight),
      const Radius.circular(6),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // ── 边框 ──
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(bgRect, borderPaint);

    // ── 英文文字(主) ──
    _drawText(
      canvas,
      textEn.length > 22 ? '${textEn.substring(0, 20)}...' : textEn, // 截断
      const Offset(10, 5),
      enFontSize,
      enTextColor,
      FontWeight.w600,
      badgeWidth - 14,
    );

    // ── 中文文字(副) ──
    _drawText(
      canvas,
      textZh.length > 14 ? '${textZh.substring(0, 12)}...' : textZh,
      const Offset(10, 23),
      zhFontSize,
      zhTextColor,
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
