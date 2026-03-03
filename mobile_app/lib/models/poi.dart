/// POI（Point of Interest）兴趣点模型
///
/// 表示地图上的兴趣点，如景点、餐厅、酒店等
class POI {
  /// POI唯一标识
  final String id;

  /// 名称
  final String name;

  /// 地址
  final String address;

  /// 纬度
  final double latitude;

  /// 经度
  final double longitude;

  /// 类别（如：景点、餐厅、酒店等）
  final POICategory category;

  /// 评分（0-5）
  final double? rating;

  /// 评论数
  final int? reviewCount;

  /// 距离（米）
  final double? distance;

  /// 电话
  final String? phone;

  /// 营业时间
  final String? openingHours;

  /// 价格等级（1-4个$符号）
  final int? priceLevel;

  /// 图片URL列表
  final List<String>? photos;

  /// 描述
  final String? description;

  /// 是否营业
  final bool? isOpen;

  /// 标签
  final List<String>? tags;

  POI({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.rating,
    this.reviewCount,
    this.distance,
    this.phone,
    this.openingHours,
    this.priceLevel,
    this.photos,
    this.description,
    this.isOpen,
    this.tags,
  });

  /// 从JSON创建POI对象
  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      category: POICategory.fromString(json['category'] ?? 'other'),
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount']?.toInt(),
      distance: json['distance']?.toDouble(),
      phone: json['phone'],
      openingHours: json['openingHours'],
      priceLevel: json['priceLevel']?.toInt(),
      photos: json['photos'] != null ? List<String>.from(json['photos']) : null,
      description: json['description'],
      isOpen: json['isOpen'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'category': category.value,
      'rating': rating,
      'reviewCount': reviewCount,
      'distance': distance,
      'phone': phone,
      'openingHours': openingHours,
      'priceLevel': priceLevel,
      'photos': photos,
      'description': description,
      'isOpen': isOpen,
      'tags': tags,
    };
  }

  /// 获取价格等级符号
  String get priceLevelSymbol {
    if (priceLevel == null) return '';
    return '\$' * priceLevel!;
  }

  /// 获取评分星级文本
  String get ratingStars {
    if (rating == null) return '';
    return '★' * rating!.round() + '☆' * (5 - rating!.round());
  }

  /// 格式化距离
  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.toStringAsFixed(0)}m';
    } else {
      return '${(distance! / 1000).toStringAsFixed(1)}km';
    }
  }
}

/// POI类别枚举
enum POICategory {
  attraction('景点', 'attraction'),
  restaurant('餐厅', 'restaurant'),
  hotel('酒店', 'hotel'),
  shopping('购物', 'shopping'),
  transport('交通', 'transport'),
  hospital('医院', 'hospital'),
  bank('银行', 'bank'),
  cafe('咖啡厅', 'cafe'),
  bar('酒吧', 'bar'),
  park('公园', 'park'),
  museum('博物馆', 'museum'),
  temple('寺庙', 'temple'),
  emergency('紧急服务', 'emergency'),
  other('其他', 'other');

  final String label;
  final String value;

  const POICategory(this.label, this.value);

  /// 从字符串创建类别
  static POICategory fromString(String value) {
    return POICategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => POICategory.other,
    );
  }

  /// 获取图标
  String get icon {
    switch (this) {
      case POICategory.attraction:
        return '🏛️';
      case POICategory.restaurant:
        return '🍜';
      case POICategory.hotel:
        return '🏨';
      case POICategory.shopping:
        return '🛍️';
      case POICategory.transport:
        return '🚇';
      case POICategory.hospital:
        return '🏥';
      case POICategory.bank:
        return '🏦';
      case POICategory.cafe:
        return '☕';
      case POICategory.bar:
        return '🍺';
      case POICategory.park:
        return '🌳';
      case POICategory.museum:
        return '🏛️';
      case POICategory.temple:
        return '⛩️';
      case POICategory.emergency:
        return '🚨';
      default:
        return '📍';
    }
  }
}
