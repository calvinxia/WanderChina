import 'dart:ui';
import 'package:amap_flutter_base/amap_flutter_base.dart';

class POITranslation {
  final String gaodePoiId;
  final String nameZh;
  final String nameEn;
  final String? nameFr;
  final String? nameEs;
  final String? categoryEn;
  final String city;
  final LatLng coordinates;
  final TranslationSource source;
  final DateTime cachedAt;

  const POITranslation({
    required this.gaodePoiId,
    required this.nameZh,
    required this.nameEn,
    this.nameFr,
    this.nameEs,
    this.categoryEn,
    required this.city,
    required this.coordinates,
    required this.source,
    required this.cachedAt,
  });

  String localizedName(AppLanguage language) {
    switch (language) {
      case AppLanguage.french:
        return nameFr ?? nameEn;
      case AppLanguage.spanish:
        return nameEs ?? nameEn;
      case AppLanguage.english:
        return nameEn;
    }
  }

  factory POITranslation.fromJson(Map<String, dynamic> json) {
    return POITranslation(
      gaodePoiId: json['gaode_poi_id'] as String,
      nameZh: json['name_zh'] as String,
      nameEn: json['name_en'] as String,
      nameFr: json['name_fr'] as String?,
      nameEs: json['name_es'] as String?,
      categoryEn: json['category_en'] as String?,
      city: json['city'] as String,
      coordinates: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      source: TranslationSource.values.firstWhere(
        (e) => e.name == (json['source'] ?? 'database'),
        orElse: () => TranslationSource.database,
      ),
      cachedAt: DateTime.parse(
          json['cached_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'gaode_poi_id': gaodePoiId,
    'name_zh': nameZh,
    'name_en': nameEn,
    'name_fr': nameFr,
    'name_es': nameEs,
    'category_en': categoryEn,
    'city': city,
    'lat': coordinates.latitude,
    'lng': coordinates.longitude,
    'source': source.name,
    'cached_at': cachedAt.toIso8601String(),
  };
}

enum TranslationSource { database, deepseek, manual, fallback }

enum AppLanguage { english, french, spanish }

class OverlayLabel {
  final POITranslation translation;
  final Offset screenPosition;
  final bool isHighPriority;

  const OverlayLabel({
    required this.translation,
    required this.screenPosition,
    required this.isHighPriority,
  });
}
