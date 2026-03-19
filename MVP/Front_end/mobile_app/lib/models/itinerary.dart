/// Itinerary Models for Trip Planning
/// 行程规划数据模型
library;

/// Activity/Event in a day
/// 单日活动/事件
class Activity {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final String? address;
  final DateTime startTime;
  final DateTime endTime;
  final String category; // sightseeing, food, transport, accommodation, shopping, etc.
  final String? imageUrl;
  final double? estimatedCost;
  final String? currency;
  final bool isBooked;
  final String? bookingReference;
  final String? notes;

  const Activity({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.address,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.imageUrl,
    this.estimatedCost,
    this.currency,
    this.isBooked = false,
    this.bookingReference,
    this.notes,
  });

  Duration get duration => endTime.difference(startTime);

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String?,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      isBooked: json['isBooked'] as bool? ?? false,
      bookingReference: json['bookingReference'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'address': address,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'category': category,
      'imageUrl': imageUrl,
      'estimatedCost': estimatedCost,
      'currency': currency,
      'isBooked': isBooked,
      'bookingReference': bookingReference,
      'notes': notes,
    };
  }
}

/// Day in itinerary
/// 行程中的一天
class ItineraryDay {
  final String id;
  final int dayNumber;
  final DateTime date;
  final String? title; // e.g., "Exploring the Forbidden City"
  final List<Activity> activities;
  final String? notes;

  const ItineraryDay({
    required this.id,
    required this.dayNumber,
    required this.date,
    this.title,
    required this.activities,
    this.notes,
  });

  double get totalEstimatedCost {
    return activities.fold(0.0, (sum, activity) => sum + (activity.estimatedCost ?? 0));
  }

  int get activityCount => activities.length;

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      id: json['id'] as String,
      dayNumber: json['dayNumber'] as int,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String?,
      activities: (json['activities'] as List<dynamic>)
          .map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayNumber': dayNumber,
      'date': date.toIso8601String(),
      'title': title,
      'activities': activities.map((a) => a.toJson()).toList(),
      'notes': notes,
    };
  }
}

/// Complete trip itinerary
/// 完整行程
class Itinerary {
  final String id;
  final String title;
  final String? description;
  final String destination; // Main destination
  final List<String>? cities; // Cities to visit
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImageUrl;
  final List<ItineraryDay> days;
  final String status; // draft, planned, ongoing, completed, cancelled
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? tags;
  final bool isPublic; // For sharing with community
  final int? likes;
  final int? saves;

  const Itinerary({
    required this.id,
    required this.title,
    this.description,
    required this.destination,
    this.cities,
    required this.startDate,
    required this.endDate,
    this.coverImageUrl,
    required this.days,
    this.status = 'draft',
    required this.createdAt,
    this.updatedAt,
    this.tags,
    this.isPublic = false,
    this.likes,
    this.saves,
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;

  int get daysUntilStart {
    final now = DateTime.now();
    if (now.isAfter(startDate)) return 0;
    return startDate.difference(now).inDays;
  }

  double get totalEstimatedCost {
    return days.fold(0.0, (sum, day) => sum + day.totalEstimatedCost);
  }

  int get totalActivities {
    return days.fold(0, (sum, day) => sum + day.activityCount);
  }

  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isOngoing => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isPast => DateTime.now().isAfter(endDate);

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      destination: json['destination'] as String,
      cities: (json['cities'] as List<dynamic>?)?.map((c) => c as String).toList(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      coverImageUrl: json['coverImageUrl'] as String?,
      days: (json['days'] as List<dynamic>)
          .map((d) => ItineraryDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? 'draft',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t as String).toList(),
      isPublic: json['isPublic'] as bool? ?? false,
      likes: json['likes'] as int?,
      saves: json['saves'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'destination': destination,
      'cities': cities,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'days': days.map((d) => d.toJson()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
      'isPublic': isPublic,
      'likes': likes,
      'saves': saves,
    };
  }
}

/// Activity categories with icons and colors
/// 活动分类
class ActivityCategory {
  final String id;
  final String name;
  final String icon;
  final int color;

  const ActivityCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<ActivityCategory> defaults = [
    ActivityCategory(
      id: 'sightseeing',
      name: 'Sightseeing',
      icon: '🏛️',
      color: 0xFF45B7D1,
    ),
    ActivityCategory(
      id: 'food',
      name: 'Food & Dining',
      icon: '🍜',
      color: 0xFFFF6B6B,
    ),
    ActivityCategory(
      id: 'transport',
      name: 'Transportation',
      icon: '🚇',
      color: 0xFF4ECDC4,
    ),
    ActivityCategory(
      id: 'accommodation',
      name: 'Accommodation',
      icon: '🏨',
      color: 0xFF95E1D3,
    ),
    ActivityCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: '🛍️',
      color: 0xFFFECEA8,
    ),
    ActivityCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: '🎭',
      color: 0xFFFF8B94,
    ),
    ActivityCategory(
      id: 'nature',
      name: 'Nature & Parks',
      icon: '🌳',
      color: 0xFF96CEB4,
    ),
    ActivityCategory(
      id: 'culture',
      name: 'Culture & Arts',
      icon: '🎨',
      color: 0xFFDDA15E,
    ),
    ActivityCategory(
      id: 'other',
      name: 'Other',
      icon: '📍',
      color: 0xFFDFE4EA,
    ),
  ];
}
