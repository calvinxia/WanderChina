import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/mountain_silhouette.dart';
import '../main/main_screen.dart';

/// Home Dashboard Screen - MVP v2.0
/// Three core tools: Translated Maps, Voice Translation, AI Trip Planner
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCity = 'BJ'; // Default: Beijing

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _navigateToTab(int tabIndex) {
    // Navigate to specific tab in MainScreen
    if (context.findAncestorWidgetOfExactType<MainScreen>() != null) {
      // Use callback or state management to switch tabs
      // For now, show a snackbar
      final tabNames = ['Map', 'Voice', 'Planner'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigate to ${tabNames[tabIndex]} tab')),
      );
    }
  }

  void _navigateToPlannerWithCity(String cityCode) {
    setState(() {
      _selectedCity = cityCode;
    });
    _navigateToTab(2); // Navigate to Planner tab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom Header with INK 900 background + Mountain Silhouette
          _buildCustomHeader(),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.gapHeightL,

                // Quick Tools Section - 3 gradient cards
                _buildQuickToolsSection(),

                AppSpacing.gapHeightXL,

                // Plan Your Next Trip AI Entry
                _buildAIPlannerEntry(),

                AppSpacing.gapHeightXL,

                // Supported Cities Pills
                _buildSupportedCities(),

                AppSpacing.gapHeightXXL,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Custom Header with INK 900 gradient, mountain silhouette, and WW logo
  Widget _buildCustomHeader() {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          // Background layer
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.2, -1),
                end: Alignment(-0.2, 1),
                colors: [AppColors.ink900, AppColors.ink700],
              ),
            ),
          ),

          // Mountain silhouette
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MountainSilhouette(
              color: AppColors.ink600,
              opacity: 0.20,
              height: 80,
            ),
          ),

          // Content layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: Menu, Search, Profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menu icon
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                        onPressed: () {},
                      ),

                      // Title + Logo
                      Row(
                        children: [
                          Text(
                            'WanderChina',
                            style: AppTextStyles.h4(
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const AppLogo(
                            size: 40,
                            backgroundColor: AppColors.logoDark,
                            strokeColor: AppColors.logoBiscuit,
                          ),
                        ],
                      ),

                      // Search & Profile
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white, size: 24),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {},
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.jade500,
                              child: const Icon(Icons.person, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Location indicator
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white.withOpacity(0.75),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Beijing, China',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Greeting
                  Text(
                    '${_getGreeting()}, Traveler!',
                    style: AppTextStyles.h2(
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  /// Quick Tools Section - 3 gradient cards (Map / Voice / Planner)
  Widget _buildQuickToolsSection() {
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
          child: Row(
            children: [
              // Map Card
              Expanded(
                child: _buildToolCard(
                  icon: Icons.map,
                  title: 'Translated\nMaps',
                  description: 'Maps in\nyour lang',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.jade600, AppColors.jade400],
                  ),
                  onTap: () => _navigateToTab(0),
                ).animate().fadeIn(duration: 300.ms, delay: 50.ms).slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 300.ms,
                      delay: 50.ms,
                    ),
              ),
              const SizedBox(width: 10),
              // Voice Card
              Expanded(
                child: _buildToolCard(
                  icon: Icons.mic,
                  title: 'Voice\nTranslation',
                  description: 'Speak & be\nunderstood',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.orange, Color(0xFFF09040)],
                  ),
                  onTap: () => _navigateToTab(1),
                ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 300.ms,
                      delay: 100.ms,
                    ),
              ),
              const SizedBox(width: 10),
              // Planner Card
              Expanded(
                child: _buildToolCard(
                  icon: Icons.event_note,
                  title: 'AI Trip\nPlanner',
                  description: 'Itinerary\nin seconds',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.ink600, AppColors.ink500],
                  ),
                  onTap: () => _navigateToTab(2),
                ).animate().fadeIn(duration: 300.ms, delay: 150.ms).slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 300.ms,
                      delay: 150.ms,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Individual Tool Card with gradient background
  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle (top right)
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Plan Your Next Trip AI Entry Card
  Widget _buildAIPlannerEntry() {
    return Padding(
      padding: AppSpacing.screenPaddingH,
      child: GestureDetector(
        onTap: () => _navigateToTab(2),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.jade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.jade200, width: 1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AppColors.shadowSm],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 18, color: AppColors.jade600),
                        const SizedBox(width: 6),
                        Text(
                          'Plan Your Next Trip',
                          style: AppTextStyles.h4(color: AppColors.gray900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask AI: "3 days in Chengdu for food lovers"',
                      style: AppTextStyles.caption(color: AppColors.gray600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.jade500,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Start',
                  style: AppTextStyles.button(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(
            begin: 0.2,
            end: 0,
            duration: 400.ms,
            delay: 200.ms,
          ),
    );
  }

  /// Supported Cities Pills
  Widget _buildSupportedCities() {
    final cities = [
      {'code': 'BJ', 'name': 'Beijing'},
      {'code': 'SH', 'name': 'Shanghai'},
      {'code': 'GZ', 'name': 'Guangzhou'},
      {'code': 'SZ', 'name': 'Shenzhen'},
      {'code': 'CD', 'name': 'Chengdu'},
      {'code': 'XA', 'name': 'Xi\'an'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenPaddingH,
          child: Text(
            'Supported Cities',
            style: AppTextStyles.h3(color: AppColors.gray900),
          ),
        ),
        AppSpacing.gapHeightM,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: AppSpacing.screenPaddingH,
          child: Row(
            children: cities.asMap().entries.map((entry) {
              final index = entry.key;
              final city = entry.value;
              final isSelected = _selectedCity == city['code'];

              return Padding(
                padding: EdgeInsets.only(right: index < cities.length - 1 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => _navigateToPlannerWithCity(city['code'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.jade500 : AppColors.jade100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.jade500.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        city['code'] as String,
                        style: AppTextStyles.caption(
                          color: isSelected ? Colors.white : AppColors.gray800,
                        ).copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                    .slideX(
                      begin: 0.2,
                      end: 0,
                      duration: 300.ms,
                      delay: (50 * index).ms,
                    ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
