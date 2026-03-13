/// Achievement Model
/// 成就模型
class Achievement {
  final String id;
  final String name;
  final String description;
  final String category; // 'explorer', 'foodie', 'social', 'cultural', 'master'
  final String rarity; // 'common', 'uncommon', 'rare', 'epic', 'legendary'
  final String badgeImageUrl;
  final int pointsReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final AchievementProgress? progress;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.badgeImageUrl,
    required this.pointsReward,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress,
  });

  double get progressPercentage {
    if (progress == null || progress!.target == 0) return 0.0;
    return (progress!.current / progress!.target).clamp(0.0, 1.0);
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      rarity: json['rarity'],
      badgeImageUrl: json['badge_image'],
      pointsReward: json['points_reward'] ?? 0,
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'])
          : null,
      progress: json['progress'] != null
          ? AchievementProgress.fromJson(json['progress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'rarity': rarity,
      'badge_image': badgeImageUrl,
      'points_reward': pointsReward,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'progress': progress?.toJson(),
    };
  }
}

/// Achievement Progress
/// 成就进度
class AchievementProgress {
  final int current;
  final int target;

  AchievementProgress({
    required this.current,
    required this.target,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      current: json['current'] ?? 0,
      target: json['target'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'target': target,
    };
  }
}

/// Leaderboard Entry
/// 排行榜条目
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final int points;
  final int challengesCompleted;
  final int badgesCount;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.points,
    required this.challengesCompleted,
    required this.badgesCount,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      userId: json['user']?['id'] ?? json['user_id'] ?? '',
      username: json['user']?['username'] ?? json['username'] ?? 'Unknown',
      avatarUrl: json['user']?['avatar'] ?? json['avatar'],
      points: json['points'] ?? 0,
      challengesCompleted: json['challenges_completed'] ?? 0,
      badgesCount: json['badges_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user_id': userId,
      'username': username,
      'avatar': avatarUrl,
      'points': points,
      'challenges_completed': challengesCompleted,
      'badges_count': badgesCount,
    };
  }
}
