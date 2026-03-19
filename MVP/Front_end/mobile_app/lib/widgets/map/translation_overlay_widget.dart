import 'package:flutter/material.dart';
import 'package:amap_map/amap_map.dart';
import '../../models/poi_translation.dart';
import '../../services/map/poi_translation_service.dart';

enum LabelStyle { badge, minimal, floating }

class TranslationOverlayConfig {
  final AppLanguage language;
  final LabelStyle  labelStyle;
  final bool        showCategory;
  final double      minZoomToShow;
  final int         maxLabelsOnScreen;

  const TranslationOverlayConfig({
    this.language          = AppLanguage.english,
    this.labelStyle        = LabelStyle.badge,
    this.showCategory      = false,
    this.minZoomToShow     = 14.0,
    this.maxLabelsOnScreen = 12,
  });
}

class TranslationOverlay extends StatefulWidget {
  final AMapController              mapController;
  final List<Map<String, dynamic>>  visiblePOIs;
  final TranslationOverlayConfig    config;
  final double                      currentZoom;

  const TranslationOverlay({
    super.key,
    required this.mapController,
    required this.visiblePOIs,
    required this.config,
    required this.currentZoom,
  });

  @override
  State<TranslationOverlay> createState() => _TranslationOverlayState();
}

class _TranslationOverlayState extends State<TranslationOverlay>
    with AutomaticKeepAliveClientMixin {

  final POITranslationService _svc = POITranslationService();
  List<OverlayLabel> _labels   = [];
  bool               _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(TranslationOverlay old) {
    super.didUpdateWidget(old);
    if (old.visiblePOIs != widget.visiblePOIs ||
        old.config.language != widget.config.language) {
      _rebuildLabels();
    }
  }

  Future<void> _rebuildLabels() async {
    if (_isLoading) return;
    if (widget.currentZoom < widget.config.minZoomToShow) {
      setState(() => _labels = []);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final ids = widget.visiblePOIs
          .map((p) => p['id'] as String? ?? p['poiId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .take(widget.config.maxLabelsOnScreen * 2)
          .toList();

      if (ids.isEmpty) {
        setState(() { _labels = []; _isLoading = false; });
        return;
      }

      // ignore: unused_local_variable
      final translations = await _svc.getTranslations(
        gaodePoiIds: ids,
        language:    widget.config.language,
      );

      // TODO: 重构为使用 Marker 方案
      // AMapController 在 3.0.0 版本中没有 convertCoordinate() 方法
      // 推荐方案：将翻译标签改为使用 Marker + 自定义 InfoWindow
      // 参考 AMAP_FIX_INSTRUCTIONS.md 的"修复2"部分

      final labels = <OverlayLabel>[];

      // 暂时禁用坐标转换功能，等待重构为 Marker 方案
      // for (final poi in widget.visiblePOIs) {
      //   final id    = poi['id'] as String? ?? poi['poiId'] as String? ?? '';
      //   final trans = translations[id];
      //   if (trans == null) continue;
      //
      //   // convertCoordinate 不存在，需要改用 Marker 方案
      //   // final pt = await widget.mapController.convertCoordinate(trans.coordinates);
      //   // if (pt == null) continue;
      //
      //   labels.add(OverlayLabel(
      //     translation:   trans,
      //     screenPosition: Offset(pt.x, pt.y),
      //     isHighPriority: _isHighPriority(trans.categoryEn),
      //   ));
      // }

      labels.sort((a, b) => b.isHighPriority ? 1 : -1);
      final filtered = _deduplicate(labels);

      if (mounted) {
        setState(() {
          _labels    = filtered.take(widget.config.maxLabelsOnScreen).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ 翻译蒙层重建失败: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OverlayLabel> _deduplicate(List<OverlayLabel> labels) {
    const minDist = 80.0;
    final result  = <OverlayLabel>[];
    for (final label in labels) {
      final tooClose = result.any((e) {
        final dx = e.screenPosition.dx - label.screenPosition.dx;
        final dy = e.screenPosition.dy - label.screenPosition.dy;
        return (dx * dx + dy * dy) < (minDist * minDist);
      });
      if (!tooClose) result.add(label);
    }
    return result;
  }

  // ignore: unused_element
  bool _isHighPriority(String? cat) => const [
    'Attraction', 'Museum', 'Park', 'Metro Station', 'Transport Hub',
  ].contains(cat);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.currentZoom < widget.config.minZoomToShow) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Stack(
        children: [
          for (final label in _labels)
            Positioned(
              left: label.screenPosition.dx,
              top:  label.screenPosition.dy,
              child: _buildLabel(label),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(OverlayLabel label) {
    switch (widget.config.labelStyle) {
      case LabelStyle.badge:
        return _BadgeLabel(label: label, config: widget.config);
      case LabelStyle.minimal:
        return _MinimalLabel(label: label, config: widget.config);
      case LabelStyle.floating:
        return _FloatingLabel(label: label, config: widget.config);
    }
  }
}

// ─── Badge样式 ─────────────────────────────────────────────────

class _BadgeLabel extends StatelessWidget {
  final OverlayLabel             label;
  final TranslationOverlayConfig config;
  const _BadgeLabel({required this.label, required this.config});

  @override
  Widget build(BuildContext context) {
    final name = label.translation.localizedName(config.language);
    return Transform.translate(
      offset: Offset(-(name.length * 3.0 + 6), -36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: label.isHighPriority
                  ? const Color(0xE6FF6B35)
                  : const Color(0xE6FFFFFF),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: label.isHighPriority ? FontWeight.w700 : FontWeight.w500,
                    color:      label.isHighPriority ? Colors.white : const Color(0xFF1A1A1A),
                    letterSpacing: 0.2,
                  ),
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                ),
                if (config.showCategory && label.translation.categoryEn != null)
                  Text(
                    label.translation.categoryEn!,
                    style: TextStyle(
                      fontSize: 8,
                      color: label.isHighPriority ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(8, 5),
            painter: _PointerPainter(
              color: label.isHighPriority
                  ? const Color(0xE6FF6B35)
                  : const Color(0xE6FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalLabel extends StatelessWidget {
  final OverlayLabel             label;
  final TranslationOverlayConfig config;
  const _MinimalLabel({required this.label, required this.config});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-30, -28),
      child: Text(
        label.translation.localizedName(config.language),
        style: TextStyle(
          fontSize:   9,
          fontWeight: FontWeight.w600,
          color: label.isHighPriority
              ? const Color(0xFFE55A2B)
              : const Color(0xFF333333),
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 3),
            Shadow(color: Colors.white, blurRadius: 3),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _FloatingLabel extends StatelessWidget {
  final OverlayLabel             label;
  final TranslationOverlayConfig config;
  const _FloatingLabel({required this.label, required this.config});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-40, -50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xF0FF6B35), Color(0xF0FF8C42)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x44FF6B35), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.translation.localizedName(config.language),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              label.translation.nameZh,
              style: const TextStyle(fontSize: 8, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}
