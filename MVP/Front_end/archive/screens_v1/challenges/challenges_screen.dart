import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/challenge.dart';
import '../../widgets/cards/challenge_card.dart';
import 'challenge_detail_screen.dart';

/// Challenges Screen - Browse and manage challenges
/// 挑战主屏幕
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCity = 'All Cities';
  String _selectedCategory = 'All';

  // Mock data - will be replaced with API calls
  final List<Challenge> _mockChallenges = [
    Challenge(
      id: '1',
      title: 'Forbidden City Explorer',
      description:
          'Visit 5 key locations in the Forbidden City and learn about Chinese imperial history',
      city: 'Beijing',
      category: 'heritage',
      difficulty: 'intermediate',
      totalPoints: 500,
      estimatedTimeHours: 4,
      completionCount: 3245,
      checkpoints: [
        Checkpoint(
          id: 'cp1',
          order: 1,
          placeId: 'place1',
          placeName: 'Meridian Gate',
          latitude: 39.9163,
          longitude: 116.3972,
          points: 100,
        ),
        Checkpoint(
          id: 'cp2',
          order: 2,
          placeId: 'place2',
          placeName: 'Hall of Supreme Harmony',
          latitude: 39.9175,
          longitude: 116.3971,
          points: 100,
        ),
        Checkpoint(
          id: 'cp3',
          order: 3,
          placeId: 'place3',
          placeName: 'Imperial Garden',
          latitude: 39.9188,
          longitude: 116.3969,
          points: 100,
        ),
        Checkpoint(
          id: 'cp4',
          order: 4,
          placeId: 'place4',
          placeName: 'Palace of Heavenly Purity',
          latitude: 39.9180,
          longitude: 116.3970,
          points: 100,
        ),
        Checkpoint(
          id: 'cp5',
          order: 5,
          placeId: 'place5',
          placeName: 'Nine Dragon Wall',
          latitude: 39.9170,
          longitude: 116.3965,
          points: 100,
        ),
      ],
      userStatus: UserChallengeStatus(
        userChallengeId: 'uc1',
        status: 'in_progress',
        progress: 60,
        checkpointsCompleted: 3,
        pointsEarned: 300,
        startedAt: DateTime.now().subtract(Duration(days: 2)),
        nextCheckpointId: 'cp4',
        nextCheckpointDistance: 450.0,
      ),
    ),
    Challenge(
      id: '2',
      title: 'Great Wall Master',
      description:
          'Hike different sections of the Great Wall and collect rare badges',
      city: 'Beijing',
      category: 'nature',
      difficulty: 'advanced',
      totalPoints: 1000,
      estimatedTimeHours: 8,
      completionCount: 892,
      checkpoints: List.generate(
        8,
        (i) => Checkpoint(
          id: 'gw$i',
          order: i + 1,
          placeId: 'gw_place$i',
          placeName: 'Great Wall Section ${i + 1}',
          latitude: 40.4319 + (i * 0.01),
          longitude: 116.5704 + (i * 0.01),
          points: 125,
        ),
      ),
    ),
    Challenge(
      id: '3',
      title: 'Beijing Street Food Tour',
      description: 'Try 10 authentic Beijing street foods and local snacks',
      city: 'Beijing',
      category: 'food',
      difficulty: 'beginner',
      totalPoints: 300,
      estimatedTimeHours: 3,
      completionCount: 5621,
      checkpoints: List.generate(
        10,
        (i) => Checkpoint(
          id: 'food$i',
          order: i + 1,
          placeId: 'food_place$i',
          placeName: 'Food Location ${i + 1}',
          latitude: 39.9042 + (i * 0.005),
          longitude: 116.4074 + (i * 0.005),
          points: 30,
        ),
      ),
    ),
    Challenge(
      id: '4',
      title: 'Temple Hopping Challenge',
      description: 'Visit and photograph 6 ancient temples in Beijing',
      city: 'Beijing',
      category: 'culture',
      difficulty: 'intermediate',
      totalPoints: 450,
      estimatedTimeHours: 5,
      completionCount: 1789,
      checkpoints: List.generate(
        6,
        (i) => Checkpoint(
          id: 'temple$i',
          order: i + 1,
          placeId: 'temple_place$i',
          placeName: 'Temple ${i + 1}',
          latitude: 39.9 + (i * 0.01),
          longitude: 116.4 + (i * 0.01),
          points: 75,
        ),
      ),
      userStatus: UserChallengeStatus(
        userChallengeId: 'uc4',
        status: 'completed',
        progress: 100,
        checkpointsCompleted: 6,
        pointsEarned: 450,
        startedAt: DateTime.now().subtract(Duration(days: 30)),
        completedAt: DateTime.now().subtract(Duration(days: 25)),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Challenges',
          style: AppTextStyles.h3(color: AppColors.gray900),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.emoji_events, color: AppColors.warning500),
            onPressed: () {
              // Navigate to achievements
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Achievements coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.leaderboard, color: AppColors.primary),
            onPressed: () {
              // Navigate to leaderboard
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Leaderboard coming soon!')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray500,
          labelStyle: AppTextStyles.button(color: AppColors.primary),
          unselectedLabelStyle: AppTextStyles.button(color: AppColors.gray500),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableTab(),
                _buildActiveTab(),
                _buildCompletedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // City filter
          Expanded(
            child: _buildFilterChip(
              label: _selectedCity,
              icon: Icons.location_city,
              onTap: () => _showCityFilter(),
            ),
          ),
          SizedBox(width: AppSpacing.s),
          // Category filter
          Expanded(
            child: _buildFilterChip(
              label: _selectedCategory,
              icon: Icons.category,
              onTap: () => _showCategoryFilter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.gray700),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall(color: AppColors.gray700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 20, color: AppColors.gray700),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab() {
    final available = _mockChallenges
        .where((c) => c.userStatus == null || c.userStatus!.status == 'available')
        .toList();

    if (available.isEmpty) {
      return _buildEmptyState(
        icon: Icons.explore,
        title: 'No Available Challenges',
        description: 'Check back later for new challenges!',
      );
    }

    return _buildChallengeGrid(available);
  }

  Widget _buildActiveTab() {
    final active = _mockChallenges
        .where((c) => c.userStatus?.status == 'in_progress')
        .toList();

    if (active.isEmpty) {
      return _buildEmptyState(
        icon: Icons.flag,
        title: 'No Active Challenges',
        description: 'Start a challenge to begin your adventure!',
      );
    }

    return _buildChallengeGrid(active);
  }

  Widget _buildCompletedTab() {
    final completed = _mockChallenges
        .where((c) => c.userStatus?.status == 'completed')
        .toList();

    if (completed.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events,
        title: 'No Completed Challenges',
        description: 'Complete challenges to earn rewards!',
      );
    }

    return _buildChallengeGrid(completed);
  }

  Widget _buildChallengeGrid(List<Challenge> challenges) {
    return GridView.builder(
      padding: AppSpacing.screenPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.m,
        mainAxisSpacing: AppSpacing.m,
        childAspectRatio: 0.65,
      ),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return ChallengeCard(
          title: challenge.title,
          description: challenge.description,
          points: challenge.totalPoints,
          difficulty: challenge.difficulty,
          totalSteps: challenge.totalSteps,
          completedSteps: challenge.completedSteps,
          timeRemaining: challenge.isActive ? _calculateTimeRemaining(challenge) : null,
          isActive: challenge.isActive,
          isCompleted: challenge.isCompleted,
          onTap: () => _viewChallengeDetail(challenge),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (50 * index).ms)
            .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: (50 * index).ms);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.primary),
            ),
            AppSpacing.gapHeightL,
            Text(
              title,
              style: AppTextStyles.h3(color: AppColors.gray900),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapHeightS,
            Text(
              description,
              style: AppTextStyles.body(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCityFilter() {
    // TODO: Implement city filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('City filter coming soon!')),
    );
  }

  void _showCategoryFilter() {
    // TODO: Implement category filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category filter coming soon!')),
    );
  }

  void _viewChallengeDetail(Challenge challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeDetailScreen(challenge: challenge),
      ),
    );
  }

  String? _calculateTimeRemaining(Challenge challenge) {
    if (challenge.userStatus?.startedAt == null) return null;

    final daysSinceStart = DateTime.now().difference(challenge.userStatus!.startedAt!).inDays;
    final daysRemaining = 7 - daysSinceStart; // Assuming 7-day limit

    if (daysRemaining <= 0) return 'Expired';
    if (daysRemaining == 1) return '1 day';
    return '$daysRemaining days';
  }
}
