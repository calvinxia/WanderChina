import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/cards/place_card.dart';

/// Discover Screen - Search and explore places
/// Based on Figma design - Screen 4 (Discover)
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search
            _buildHeader(),

            // Category Tabs
            _buildCategoryTabs(),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTab(),
                  _buildCategoryTab('Historic'),
                  _buildCategoryTab('Nature'),
                  _buildCategoryTab('Food'),
                  _buildCategoryTab('Shopping'),
                  _buildCategoryTab('Cultural'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover',
            style: AppTextStyles.h2(color: AppColors.gray900),
          ),
          AppSpacing.gapHeightM,
          // Search Bar
          Container(
            height: AppSpacing.searchBarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray900.withOpacity(0.06),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search places, food, activities...',
                hintStyle: AppTextStyles.body(color: AppColors.gray400),
                prefixIcon: Icon(Icons.search, color: AppColors.gray500),
                suffixIcon: IconButton(
                  icon: Icon(Icons.tune, color: AppColors.primary),
                  onPressed: () {
                    // Show filters
                  },
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildCategoryTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.gray600,
        labelStyle: AppTextStyles.button(),
        unselectedLabelStyle: AppTextStyles.body(),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
        tabs: [
          Tab(text: 'All'),
          Tab(text: 'Historic'),
          Tab(text: 'Nature'),
          Tab(text: 'Food'),
          Tab(text: 'Shopping'),
          Tab(text: 'Cultural'),
        ],
      ),
    ).animate().slideY(begin: -0.5, end: 0, duration: 300.ms, delay: 100.ms);
  }

  Widget _buildAllTab() {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.m),
      children: [
        // Featured Section
        Text(
          'Featured',
          style: AppTextStyles.h3(color: AppColors.gray900),
        ),
        AppSpacing.gapHeightM,
        PlaceCard(
          name: 'Forbidden City',
          location: 'Dongcheng District, Imperial palace complex',
          rating: 4.9,
          reviewCount: 5678,
          category: 'Historic',
          distance: '3.2 km',
          tags: ['UNESCO', 'Must-See'],
          size: PlaceCardSize.large,
          isFavorite: true,
          onTap: () {},
          onFavorite: () {},
        ),
        AppSpacing.gapHeightM,

        // Popular Section
        Text(
          'Popular Near You',
          style: AppTextStyles.h3(color: AppColors.gray900),
        ),
        AppSpacing.gapHeightM,
        _buildPlaceList(),
      ],
    );
  }

  Widget _buildCategoryTab(String category) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.m),
      children: [
        Text(
          '$category Places',
          style: AppTextStyles.h3(color: AppColors.gray900),
        ),
        AppSpacing.gapHeightM,
        _buildPlaceList(),
      ],
    );
  }

  Widget _buildPlaceList() {
    return Column(
      children: [
        PlaceCard(
          name: 'Temple of Heaven',
          location: 'Dongcheng District',
          rating: 4.9,
          reviewCount: 3120,
          category: 'Cultural',
          distance: '3.7 km',
          tags: ['UNESCO', 'Temple'],
          size: PlaceCardSize.large,
          onTap: () {},
          onFavorite: () {},
        ),
        AppSpacing.gapHeightM,
        PlaceCard(
          name: 'Summer Palace',
          location: 'Haidian District',
          rating: 4.8,
          reviewCount: 2340,
          category: 'Historic',
          distance: '2.3 km',
          tags: ['UNESCO', 'Garden'],
          size: PlaceCardSize.large,
          onTap: () {},
          onFavorite: () {},
        ),
        AppSpacing.gapHeightM,
        PlaceCard(
          name: 'Beihai Park',
          location: 'Xicheng District',
          rating: 4.6,
          reviewCount: 1890,
          category: 'Nature',
          distance: '1.8 km',
          tags: ['Park', 'Lake'],
          size: PlaceCardSize.large,
          onTap: () {},
          onFavorite: () {},
        ),
      ],
    );
  }
}
