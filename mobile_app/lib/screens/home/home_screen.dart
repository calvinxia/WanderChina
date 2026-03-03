import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/cards/place_card.dart';
import '../../widgets/cards/challenge_card.dart';
import '../../widgets/cards/quick_tool_card.dart';
import '../budget/budget_screen.dart';
import '../planner/planner_screen.dart';
import '../challenges/challenges_screen.dart';

/// Home Dashboard Screen
/// Based on Figma design - Screen 3 (Home)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showElevation = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 10 && !_showElevation) {
      setState(() => _showElevation = true);
    } else if (_scrollController.offset <= 10 && _showElevation) {
      setState(() => _showElevation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          _buildAppBar(),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.gapHeightM,

                // Weather Card
                _buildWeatherCard(),

                AppSpacing.gapHeightXL,

                // Quick Tools Section
                _buildQuickToolsSection(),

                AppSpacing.gapHeightXL,

                // Active Challenge Section
                _buildActiveChallengeSection(),

                AppSpacing.gapHeightXL,

                // Nearby Highlights Section
                _buildNearbySection(),

                AppSpacing.gapHeightXL,

                // Recommended Places Section
                _buildRecommendedSection(),

                AppSpacing.gapHeightXL,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      elevation: _showElevation ? 4 : 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, Traveler!',
            style: AppTextStyles.h3(color: AppColors.gray900),
          ),
          Text(
            'Beijing, China',
            style: AppTextStyles.bodySmall(color: AppColors.gray600),
          ),
        ],
      ),
      actions: [
        // Notifications
        IconButton(
          icon: Stack(
            children: [
              Icon(Icons.notifications_outlined, color: AppColors.gray700),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {},
        ),
        // Profile
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.m),
          child: GestureDetector(
            onTap: () {},
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    return Padding(
      padding: AppSpacing.screenPaddingH,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.info500, AppColors.info300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          boxShadow: [
            BoxShadow(
              color: AppColors.info500.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Weather icon and temp
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wb_sunny,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(width: AppSpacing.s),
                      Text(
                        '24°C',
                        style: AppTextStyles.h1(color: Colors.white),
                      ),
                    ],
                  ),
                  AppSpacing.gapHeightS,
                  Text(
                    'Sunny',
                    style: AppTextStyles.h4(color: Colors.white),
                  ),
                  Text(
                    'Perfect day for exploring!',
                    style: AppTextStyles.bodySmall(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Weather details
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildWeatherDetail(Icons.water_drop, '65%'),
                AppSpacing.gapHeightS,
                _buildWeatherDetail(Icons.air, '12 km/h'),
                AppSpacing.gapHeightS,
                _buildWeatherDetail(Icons.visibility, '10 km'),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 100.ms)
          .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 100.ms),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
        SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.caption(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  void _navigateToTool(String toolLabel) {
    switch (toolLabel) {
      case 'Planner':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlannerScreen()),
        );
        break;
      case 'Budget':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetScreen()),
        );
        break;
      case 'Map':
        // TODO: Navigate to Map screen
        break;
      case 'Translate':
        // TODO: Navigate to Translate screen
        break;
      case 'Phrasebook':
        // TODO: Navigate to Phrasebook screen
        break;
      case 'Challenges':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChallengesScreen()),
        );
        break;
      case 'Community':
        // TODO: Navigate to Community screen
        break;
    }
  }

  Widget _buildQuickToolsSection() {
    final tools = [
      {'label': 'Planner', 'icon': Icons.event_note, 'color': AppColors.primary},
      {'label': 'Map', 'icon': Icons.map, 'color': AppColors.info500},
      {'label': 'Budget', 'icon': Icons.account_balance_wallet, 'color': AppColors.success500},
      {'label': 'Translate', 'icon': Icons.translate, 'color': AppColors.warning500},
      {'label': 'Phrasebook', 'icon': Icons.book, 'color': AppColors.error500},
      {'label': 'Community', 'icon': Icons.people, 'color': AppColors.jade700},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenPaddingH,
          child: Text(
            'Quick Tools',
            style: AppTextStyles.h3(color: AppColors.gray900),
          ),
        ),
        AppSpacing.gapHeightM,
        Padding(
          padding: AppSpacing.screenPaddingH,
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.s,
              mainAxisSpacing: AppSpacing.s,
              childAspectRatio: 1,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return QuickToolCard(
                label: tool['label'] as String,
                icon: tool['icon'] as IconData,
                color: tool['color'] as Color,
                onTap: () => _navigateToTool(tool['label'] as String),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 300.ms,
                    delay: (50 * index).ms,
                  );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallengeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenPaddingH,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Challenge',
                style: AppTextStyles.h3(color: AppColors.gray900),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChallengesScreen()),
                  );
                },
                child: Text(
                  'View All',
                  style: AppTextStyles.button(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapHeightM,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: AppSpacing.screenPaddingH,
          child: Row(
            children: [
              ChallengeCard(
                title: 'Forbidden City Explorer',
                description:
                    'Visit 5 key locations in the Forbidden City and learn about Chinese imperial history',
                points: 500,
                difficulty: 'medium',
                totalSteps: 5,
                completedSteps: 3,
                timeRemaining: '2 days',
                isActive: true,
                onTap: () {},
              ),
              SizedBox(width: AppSpacing.m),
              ChallengeCard(
                title: 'Great Wall Master',
                description:
                    'Hike different sections of the Great Wall and collect rare badges',
                points: 1000,
                difficulty: 'hard',
                totalSteps: 8,
                completedSteps: 0,
                onTap: () {},
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideX(begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenPaddingH,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Highlights',
                style: AppTextStyles.h3(color: AppColors.gray900),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See More',
                  style: AppTextStyles.button(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapHeightM,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: AppSpacing.screenPaddingH,
          child: Row(
            children: [
              PlaceCard(
                name: 'Summer Palace',
                location: 'Haidian District',
                rating: 4.8,
                reviewCount: 2340,
                category: 'Historic',
                distance: '2.3 km',
                tags: ['UNESCO', 'Garden'],
                size: PlaceCardSize.medium,
                onTap: () {},
                onFavorite: () {},
              ),
              SizedBox(width: AppSpacing.m),
              PlaceCard(
                name: 'Temple of Heaven',
                location: 'Dongcheng District',
                rating: 4.9,
                reviewCount: 3120,
                category: 'Cultural',
                distance: '3.7 km',
                tags: ['UNESCO', 'Temple'],
                isFavorite: true,
                size: PlaceCardSize.medium,
                onTap: () {},
                onFavorite: () {},
              ),
              SizedBox(width: AppSpacing.m),
              PlaceCard(
                name: 'Beihai Park',
                location: 'Xicheng District',
                rating: 4.6,
                reviewCount: 1890,
                category: 'Nature',
                distance: '1.8 km',
                tags: ['Park', 'Lake'],
                size: PlaceCardSize.medium,
                onTap: () {},
                onFavorite: () {},
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideX(begin: 0.1, end: 0, duration: 400.ms, delay: 300.ms),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenPaddingH,
          child: Text(
            'Recommended for You',
            style: AppTextStyles.h3(color: AppColors.gray900),
          ),
        ),
        AppSpacing.gapHeightM,
        Padding(
          padding: AppSpacing.screenPaddingH,
          child: Column(
            children: [
              PlaceCard(
                name: 'Jingshan Park',
                location: 'Xicheng District, Best sunset view of Forbidden City',
                rating: 4.7,
                reviewCount: 1560,
                category: 'Nature',
                distance: '1.2 km',
                tags: ['Viewpoint', 'Park'],
                size: PlaceCardSize.large,
                onTap: () {},
                onFavorite: () {},
              ),
              AppSpacing.gapHeightM,
              PlaceCard(
                name: 'Nanluoguxiang',
                location: 'Dongcheng District, Historic alley with shops and cafes',
                rating: 4.5,
                reviewCount: 2890,
                category: 'Shopping',
                distance: '2.1 km',
                tags: ['Hutong', 'Food'],
                size: PlaceCardSize.large,
                onTap: () {},
                onFavorite: () {},
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 400.ms)
            .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 400.ms),
      ],
    );
  }
}
