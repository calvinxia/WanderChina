/// Challenge Model
/// 挑战数据模型
class Challenge {
  final String id;
  final String title;
  final String description;
  final String city;
  final String category; // 'heritage', 'food', 'nature', 'culture'
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final int totalPoints;
  final int estimatedTimeHours;
  final List<Checkpoint> checkpoints;
  final String? badgeImageUrl;
  final String? coverImageUrl;
  final int completionCount;

  // User-specific data
  final UserChallengeStatus? userStatus;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.city,
    required this.category,
    required this.difficulty,
    required this.totalPoints,
    required this.estimatedTimeHours,
    required this.checkpoints,
    this.badgeImageUrl,
    this.coverImageUrl,
    required this.completionCount,
    this.userStatus,
  });

  int get totalSteps => checkpoints.length;

  bool get isAvailable => userStatus == null || userStatus!.status == 'available';
  bool get isActive => userStatus?.status == 'in_progress';
  bool get isCompleted => userStatus?.status == 'completed';

  int get completedSteps => userStatus?.checkpointsCompleted ?? 0;
  double get progress => totalSteps > 0 ? completedSteps / totalSteps : 0.0;
  int get pointsEarned => userStatus?.pointsEarned ?? 0;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      city: json['city'],
      category: json['category'],
      difficulty: json['difficulty'],
      totalPoints: json['total_points'],
      estimatedTimeHours: json['estimated_time_hours'],
      checkpoints: (json['checkpoints'] as List?)
          ?.map((cp) => Checkpoint.fromJson(cp))
          .toList() ?? [],
      badgeImageUrl: json['badge_image'],
      coverImageUrl: json['cover_image'],
      completionCount: json['completion_count'] ?? 0,
      userStatus: json['user_status'] != null
          ? UserChallengeStatus.fromJson(json['user_status'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'city': city,
      'category': category,
      'difficulty': difficulty,
      'total_points': totalPoints,
      'estimated_time_hours': estimatedTimeHours,
      'checkpoints': checkpoints.map((cp) => cp.toJson()).toList(),
      'badge_image': badgeImageUrl,
      'cover_image': coverImageUrl,
      'completion_count': completionCount,
      'user_status': userStatus?.toJson(),
    };
  }

  // Copy with method for updates
  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    String? city,
    String? category,
    String? difficulty,
    int? totalPoints,
    int? estimatedTimeHours,
    List<Checkpoint>? checkpoints,
    String? badgeImageUrl,
    String? coverImageUrl,
    int? completionCount,
    UserChallengeStatus? userStatus,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      totalPoints: totalPoints ?? this.totalPoints,
      estimatedTimeHours: estimatedTimeHours ?? this.estimatedTimeHours,
      checkpoints: checkpoints ?? this.checkpoints,
      badgeImageUrl: badgeImageUrl ?? this.badgeImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      completionCount: completionCount ?? this.completionCount,
      userStatus: userStatus ?? this.userStatus,
    );
  }
}

/// Checkpoint Model
/// 检查点模型
class Checkpoint {
  final String id;
  final int order;
  final String placeId;
  final String placeName;
  final String? placePhoto;
  final double latitude;
  final double longitude;
  final int points;
  final String? instructions;
  final bool isCompleted;
  final DateTime? completedAt;

  Checkpoint({
    required this.id,
    required this.order,
    required this.placeId,
    required this.placeName,
    this.placePhoto,
    required this.latitude,
    required this.longitude,
    required this.points,
    this.instructions,
    this.isCompleted = false,
    this.completedAt,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      id: json['id'] ?? json['checkpoint_id'] ?? '',
      order: json['order'],
      placeId: json['place_id'] ?? json['place']?['id'] ?? '',
      placeName: json['place_name'] ?? json['place']?['name'] ?? '',
      placePhoto: json['place_photo'] ?? json['place']?['photo'],
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      points: json['points'] ?? 0,
      instructions: json['instructions'],
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'place_id': placeId,
      'place_name': placeName,
      'place_photo': placePhoto,
      'latitude': latitude,
      'longitude': longitude,
      'points': points,
      'instructions': instructions,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Checkpoint copyWith({
    String? id,
    int? order,
    String? placeId,
    String? placeName,
    String? placePhoto,
    double? latitude,
    double? longitude,
    int? points,
    String? instructions,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Checkpoint(
      id: id ?? this.id,
      order: order ?? this.order,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placePhoto: placePhoto ?? this.placePhoto,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      points: points ?? this.points,
      instructions: instructions ?? this.instructions,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// User Challenge Status
/// 用户挑战状态
class UserChallengeStatus {
  final String userChallengeId;
  final String status; // 'available', 'in_progress', 'completed'
  final int progress; // 0-100
  final int checkpointsCompleted;
  final int pointsEarned;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? nextCheckpointId;
  final double? nextCheckpointDistance; // in meters

  UserChallengeStatus({
    required this.userChallengeId,
    required this.status,
    required this.progress,
    required this.checkpointsCompleted,
    required this.pointsEarned,
    this.startedAt,
    this.completedAt,
    this.nextCheckpointId,
    this.nextCheckpointDistance,
  });

  factory UserChallengeStatus.fromJson(Map<String, dynamic> json) {
    return UserChallengeStatus(
      userChallengeId: json['user_challenge_id'] ?? '',
      status: json['status'],
      progress: json['progress'] ?? 0,
      checkpointsCompleted: json['checkpoints_completed'] ?? 0,
      pointsEarned: json['points_earned'] ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      nextCheckpointId: json['next_checkpoint']?['id'],
      nextCheckpointDistance: json['next_checkpoint']?['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_challenge_id': userChallengeId,
      'status': status,
      'progress': progress,
      'checkpoints_completed': checkpointsCompleted,
      'points_earned': pointsEarned,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'next_checkpoint': nextCheckpointId != null
          ? {
              'id': nextCheckpointId,
              'distance': nextCheckpointDistance,
            }
          : null,
    };
  }
}
