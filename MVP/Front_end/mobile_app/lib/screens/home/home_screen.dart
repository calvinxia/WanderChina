import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/mountain_silhouette.dart';
import '../voice/voice_translation_screen.dart';
import '../../services/backend/auth_service.dart';
import '../../services/amap_service.dart';
import '../main/main_screen.dart';

/// Home Dashboard Screen - MVP v2.0
/// Three core tools: Translated Maps, Voice Translation, AI Trip Planner
class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCity = 'BJ'; // Default: Beijing
  String _userName = 'Traveler';
  String _currentCity = 'China';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCurrentCity();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final profile = await AuthService.getProfile();
      if (mounted) {
        setState(() {
          _userName = profile['username'] ?? profile['display_name'] ?? 'Traveler';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCurrentCity() async {
    try {
      final amapService = AMapService();
      await amapService.initialize();
      final location = await amapService.getLocation();
      if (location != null && mounted) {
        // 用经纬度反查城市（简单方案：根据坐标范围判断）
        final lat = double.tryParse(location['latitude'].toString()) ?? 0;
        final lng = double.tryParse(location['longitude'].toString()) ?? 0;
        setState(() {
          _currentCity = _detectCity(lat, lng);
        });
      }
    } catch (_) {}
  }

  String _detectCity(double lat, double lng) {
    // 简单经纬度范围判断
    if (lat > 39.4 && lat < 40.4 && lng > 115.7 && lng < 117.0) return 'Beijing, China';
    if (lat > 30.8 && lat < 31.8 && lng > 120.8 && lng < 122.0) return 'Shanghai, China';
    if (lat > 22.5 && lat < 23.6 && lng > 112.9 && lng < 114.0) return 'Guangzhou, China';
    if (lat > 22.3 && lat < 22.9 && lng > 113.7 && lng < 114.5) return 'Shenzhen, China';
    if (lat > 30.0 && lat < 31.0 && lng > 103.5 && lng < 104.8) return 'Chengdu, China';
    if (lat > 33.8 && lat < 34.6 && lng > 108.5 && lng < 109.5) return "Xi'an, China";
    return 'China';
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _navigateToTab(int tabIndex) {
    // Use GlobalKey to directly call MainScreen method
    MainScreen.globalKey.currentState?.switchToTab(tabIndex);
  }

  void _navigateToPlannerWithCity(String cityCode) {
    setState(() {
      _selectedCity = cityCode;
    });
    MainScreen.globalKey.currentState?.switchToTab(2);
  }

  /// 根据城市名识别城市短码
  String? _detectCityShort(String cityName) {
    if (cityName.contains('Guangzhou') || cityName.contains('广州')) return 'GZ';
    if (cityName.contains('Beijing') || cityName.contains('北京')) return 'BJ';
    if (cityName.contains('Shanghai') || cityName.contains('上海')) return 'SH';
    if (cityName.contains('Shenzhen') || cityName.contains('深圳')) return 'SZ';
    if (cityName.contains('Chengdu') || cityName.contains('成都')) return 'CD';
    if (cityName.contains("Xi'an") || cityName.contains('西安')) return 'XA';
    return null;
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
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.jade500,
                              child: Icon(Icons.person, color: Colors.white, size: 18),
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
                        '📍 $_currentCity',
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
                    '$_greeting, $_userName!',
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
                  description: 'Maps in your language',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.jade600, AppColors.jade400],
                  ),
                  onTap: () => _navigateToTab(1), // Map tab index = 1
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
                  description: 'Speak & be understood',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.orange, Color(0xFFF09040)],
                  ),
                  onTap: () {
                    // Open VoiceTranslationScreen as fullscreen dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoiceTranslationScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
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
                  description: 'Itinerary in seconds',
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
                    color: Colors.white.withOpacity(0.7),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          constraints: const BoxConstraints(minHeight: 90),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.jade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.jade200, width: 1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [AppColors.shadowSm],
          ),
          child: Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✨ Plan Your Next Trip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask AI: "3 days in Chengdu for food lovers"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
    final allCities = [
      {'short': 'BJ', 'full': 'Beijing'},
      {'short': 'SH', 'full': 'Shanghai'},
      {'short': 'GZ', 'full': 'Guangzhou'},
      {'short': 'SZ', 'full': 'Shenzhen'},
      {'short': 'CD', 'full': 'Chengdu'},
      {'short': 'XA', 'full': "Xi'an"},
    ];

    // 把当前城市排到第一位
    final currentShort = _detectCityShort(_currentCity);
    if (currentShort != null) {
      allCities.sort((a, b) {
        if (a['short'] == currentShort) return -1;
        if (b['short'] == currentShort) return 1;
        return 0;
      });
    }

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
            children: allCities.asMap().entries.map((entry) {
              final index = entry.key;
              final city = entry.value;
              final isSelected = _selectedCity == city['short'];

              return Padding(
                padding: EdgeInsets.only(right: index < allCities.length - 1 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => _navigateToPlannerWithCity(city['short'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.jade500 : AppColors.jade100,
                      borderRadius: BorderRadius.circular(20),
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
                    child: Text(
                      city['full'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.gray800,
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
