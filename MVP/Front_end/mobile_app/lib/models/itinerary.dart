/// Itinerary Models for Trip Planning
/// 行程规划数据模型
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';

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
  final String imageKeyword;
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
    this.imageKeyword = '',
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
      imageKeyword: json['imageKeyword'] as String? ?? '',
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      isBooked: json['isBooked'] as bool? ?? false,
      bookingReference: json['bookingReference'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// 从云函数/DeepSeek 格式构造
  factory Activity.fromCloudData(Map<String, dynamic> json, {required DateTime dayDate, int index = 0}) {
    debugPrint('🎯 Activity.fromCloudData [$index] - JSON keys: ${json.keys.toList()}');

    // 如果数据已经是 toJson 格式（从数据库读取的已保存行程），用 fromJson 解析
    if (json.containsKey('startTime') && json.containsKey('endTime')) {
      debugPrint('🎯 Detected toJson format, using fromJson');
      return Activity.fromJson(json);
    }

    // 否则是 DeepSeek 原始格式，手动解析
    debugPrint('🎯 Detected DeepSeek format, parsing manually');

    // 解析时间 "09:00" → DateTime
    final timeStr = json['time'] as String? ?? '09:00';
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final startTime = DateTime(dayDate.year, dayDate.month, dayDate.day, hour, minute);

    // 解析 duration "2 hrs" → 结束时间
    final durationStr = json['duration'] as String? ?? '1 hrs';
    final durationHours = double.tryParse(durationStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1;
    final endTime = startTime.add(Duration(minutes: (durationHours * 60).round()));

    // 解析费用 "¥60" → double
    final costStr = json['cost'] as String? ?? '¥0';
    final cost = double.tryParse(costStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    final title = json['name'] as String? ?? json['title'] as String? ?? '';
    debugPrint('🎯 Activity: $title, time: $timeStr, duration: $durationStr, cost: $costStr');

    return Activity(
      id: json['id'] as String? ?? 'act_$index',
      title: title,
      description: json['description'] as String? ?? '',
      location: json['name_zh'] as String? ?? json['location'] as String? ?? '',
      address: json['address'] as String?,
      startTime: startTime,
      endTime: endTime,
      category: json['category'] as String? ?? 'sightseeing',
      imageKeyword: json['imageKeyword'] as String? ?? '',
      estimatedCost: cost,
      currency: 'CNY',
      notes: json['name_zh'] as String?,
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
      'imageKeyword': imageKeyword,
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
      dayNumber: (json['day_number'] ?? json['dayNumber'] ?? 1) as int,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String?,
      activities: (json['activities'] as List<dynamic>)
          .map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  /// 从云函数/DeepSeek 格式构造
  factory ItineraryDay.fromCloudData(Map<String, dynamic> json, {required DateTime startDate}) {
    debugPrint('📅 ItineraryDay.fromCloudData - Input JSON keys: ${json.keys.toList()}');

    // 如果数据已经是 toJson 格式（从数据库读取的已保存行程），用 fromJson 解析
    if (json.containsKey('date') && json.containsKey('id')) {
      debugPrint('📅 Detected toJson format, using fromJson');
      return ItineraryDay.fromJson(json);
    }

    // 否则是 DeepSeek/云函数格式
    debugPrint('📅 Detected DeepSeek/cloud format, parsing manually');

    final dayNumber = (json['day_number'] ?? json['dayNumber'] ?? 1) as int;
    final dayDate = startDate.add(Duration(days: dayNumber - 1));
    debugPrint('📅 Day $dayNumber, Date: $dayDate');

    // activities 可能是 String（JSON）或 List
    var activitiesRaw = json['activities'];
    debugPrint('📅 activities type: ${activitiesRaw.runtimeType}, value: $activitiesRaw');

    if (activitiesRaw is String) {
      debugPrint('📅 Decoding activities from JSON string');
      activitiesRaw = jsonDecode(activitiesRaw) as List;
    }
    activitiesRaw ??= [];

    final activities = (activitiesRaw as List).asMap().entries.map((entry) {
      final actData = entry.value;
      debugPrint('📅 Activity ${entry.key} type: ${actData.runtimeType}');
      return Activity.fromCloudData(
        actData is String ? jsonDecode(actData) as Map<String, dynamic> : actData as Map<String, dynamic>,
        dayDate: dayDate,
        index: entry.key,
      );
    }).toList();

    debugPrint('📅 ItineraryDay created with ${activities.length} activities');
    return ItineraryDay(
      id: json['id'] as String? ?? 'day_$dayNumber',
      dayNumber: dayNumber,
      date: dayDate,
      title: json['title'] as String? ?? json['summary'] as String?,
      activities: activities,
      notes: json['summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_number': dayNumber,
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
  List<ItineraryDay> days; // Remove final to allow activity deletion
  final String status; // draft, planned, ongoing, completed, cancelled
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? tags;
  final bool isPublic; // For sharing with community
  final int? likes;
  final int? saves;

  Itinerary({
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

  /// 从云函数/DeepSeek 格式构造
  factory Itinerary.fromCloudData(Map<String, dynamic> json) {
    debugPrint('🗺️ Itinerary.fromCloudData - Input JSON keys: ${json.keys.toList()}');

    final now = DateTime.now();
    final totalDays = (json['totalDays'] ?? json['duration_days'] ?? 3) as int;
    final startDate = now;
    final endDate = startDate.add(Duration(days: totalDays - 1));
    debugPrint('🗺️ Total days: $totalDays, startDate: $startDate, endDate: $endDate');

    final daysRaw = json['days'] as List? ?? [];
    debugPrint('🗺️ Processing ${daysRaw.length} days');
    final days = daysRaw.map((day) {
      return ItineraryDay.fromCloudData(
        day as Map<String, dynamic>,
        startDate: startDate,
      );
    }).toList();

    final citiesRaw = json['cities'];
    debugPrint('🗺️ cities type: ${citiesRaw.runtimeType}, value: $citiesRaw');
    final cities = citiesRaw is String
        ? [citiesRaw]
        : (citiesRaw as List?)?.map((c) => c.toString()).toList();
    final destination = cities != null && cities.isNotEmpty
        ? cities.first.toString()
        : 'Unknown';

    final title = json['title'] as String? ?? 'My Trip';
    debugPrint('🗺️ Itinerary created: $title, destination: $destination, ${days.length} days');

    return Itinerary(
      id: json['trip_id'] as String? ?? 'preview_${now.millisecondsSinceEpoch}',
      title: title,
      description: json['description'] as String?,
      destination: destination,
      cities: cities,
      startDate: startDate,
      endDate: endDate,
      coverImageUrl: json['coverImageUrl'] as String?,
      days: days,
      status: json['status'] as String? ?? 'draft',
      createdAt: now,
      updatedAt: now,
      tags: (json['interests'] as List<dynamic>?)?.map((t) => t.toString()).toList(),
      isPublic: false,
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
