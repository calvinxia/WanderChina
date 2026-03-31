import 'package:flutter/material.dart';
import '../../core/theme/city_theme.dart';
import 'city_silhouette_painter.dart';

/// Shared city-themed background wrapper.
/// Wraps any page content with gradient + silhouette.
class CityBackground extends StatelessWidget {
  final Widget child;
  final CityTheme theme;
  /// Height of the silhouette area at the bottom (default 35% of screen)
  final double silhouetteHeightFraction;
  /// Whether to render the background (gradient + silhouette). Set to false for Map page.
  final bool enabled;

  const CityBackground({
    super.key,
    required this.child,
    required this.theme,
    this.silhouetteHeightFraction = 0.35,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // If disabled (e.g., Map page), just return the child without background
    if (!enabled) {
      return child;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: theme.backgroundGradient,
      ),
      child: Stack(
        children: [
          // Silhouette at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * silhouetteHeightFraction,
            child: CustomPaint(
              painter: CitySilhouettePainter(
                cityKey: theme.cityKey,
                color: theme.primaryTextColor.withOpacity(0.08),
              ),
              size: Size.infinite,
            ),
          ),
          // Page content on top
          child,
        ],
      ),
    );
  }
}
