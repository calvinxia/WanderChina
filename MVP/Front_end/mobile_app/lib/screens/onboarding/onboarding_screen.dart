import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/city_theme.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/mountain_silhouette.dart';
import '../../widgets/onboarding_illustrations.dart';
import '../auth/login_screen.dart';

/// WanderChina Onboarding Screen - MVP v2.0
///
/// 三屏 Onboarding 流程，深色墨底+山水剪影风格
/// Slide 1: App Logo (Biscuit accent)
/// Slide 2: Translation Illustration (Warm Gold accent)
/// Slide 3: Navigation Illustration (Orange accent)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedCityKey; // 'BJ', 'SH', 'GZ', 'SZ', 'CD', 'XA'

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Discover China\nYour Way',
      description:
          'Your AI-powered companion for exploring China\'s wonders with offline maps and smart recommendations',
      visualType: OnboardingVisualType.logo,
      accentColor: AppColors.logoBiscuit, // #E8D5C4
    ),
    OnboardingSlide(
      title: 'Break Language\nBarriers',
      description:
          'Real-time translation with your camera, comprehensive phrasebook, and voice assistance',
      visualType: OnboardingVisualType.translation,
      accentColor: AppColors.warmGold, // #D4A853
    ),
    OnboardingSlide(
      title: 'Navigate with\nConfidence',
      description:
          'Bilingual maps, offline navigation, and step-by-step directions to help you explore fearlessly',
      visualType: OnboardingVisualType.navigation,
      accentColor: AppColors.orange, // #E8723A
    ),
    OnboardingSlide(
      title: 'Where Are You\nHeaded?',
      description:
          'Pick your first destination — we\'ll customize everything for that city',
      visualType: OnboardingVisualType.citySelection,
      accentColor: const Color(0xFF7EC8C8), // 天青色
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() async {
    if (_currentPage < _slides.length - 1) {
      // 从第 3 屏（index 2）过渡时，尝试 GPS 检测
      if (_currentPage == 2) {
        final detected = await _tryDetectCity();
        if (detected) {
          // GPS 匹配到六城，跳过第 4 屏直接完成
          _finishOnboarding();
          return;
        }
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() async {
    // 保存用户选择的目的地城市
    if (_selectedCityKey != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('destination_city', _selectedCityKey!);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  /// 尝试 GPS 检测，返回 true 表示匹配到六城
  Future<bool> _tryDetectCity() async {
    try {
      // 请求定位权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false; // 权限拒绝，显示第 4 屏
      }

      // 获取位置（5 秒超时）
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 5));

      final theme = CityTheme.fromCoordinates(
        position.latitude,
        position.longitude,
      );

      // 检查是否真的匹配到六城（而不是 fallback 到 defaultTheme）
      if (theme != CityTheme.defaultTheme ||
          _isInDefaultCity(position.latitude, position.longitude)) {
        return true; // 匹配到六城，跳过第 4 屏
      }

      return false; // 不在六城范围，显示第 4 屏
    } catch (_) {
      return false; // GPS 超时或其他错误，显示第 4 屏
    }
  }

  bool _isInDefaultCity(double lat, double lng) {
    return lat > 22.5 && lat < 23.6 && lng > 112.9 && lng < 114.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink900,
      body: Stack(
        children: [
          // ── Background Stack: INK 900 + RadialGradient + Mountain Silhouette ──
          _buildBackgroundLayer(),

          // ── Content Layer ──
          SafeArea(
            child: Column(
              children: [
                // Skip button
                _buildSkipButton(),

                // Page slides
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(_slides[index], index);
                    },
                  ),
                ),

                // Page indicators
                _buildPageIndicators(),

                AppSpacing.gapHeightL,

                // Next button
                _buildNextButton(),

                AppSpacing.gapHeightXL,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Background layer with INK 900, radial gradient, and mountain silhouettes
  Widget _buildBackgroundLayer() {
    final currentSlide = _slides[_currentPage];
    // 第 4 屏：如果用户已选城市，用该城市主题色替代默认 accent
    Color bgAccent = currentSlide.accentColor;
    if (_currentPage == 3 && _selectedCityKey != null) {
      bgAccent = CityTheme.fromCityKey(_selectedCityKey!).pillActiveColor;
    }

    return Stack(
      children: [
        // Base INK 900 background
        Container(color: AppColors.ink900),

        // Radial gradient with accent color
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.5),
              radius: 1.2,
              colors: [
                bgAccent.withOpacity(0.12),
                AppColors.ink900.withOpacity(0),
              ],
              stops: const [0, 0.7],
            ),
          ),
        ),

        // Mountain silhouette - back layer
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: MountainSilhouette(
            color: AppColors.ink700,
            opacity: 0.15,
            height: 140,
          ),
        ),

        // Mountain silhouette - front layer
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: MountainSilhouette(
            color: AppColors.ink600,
            opacity: 0.10,
            height: 100,
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: TextButton(
          onPressed: _skipOnboarding,
          child: Text(
            'Skip',
            style: AppTextStyles.button(color: Colors.white.withOpacity(0.60)),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, int index) {
    final isActive = index == _currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Visual element (logo or illustration)
          _buildVisual(slide, isActive, index),

          AppSpacing.gapHeightXL,

          // Title
          Text(
            slide.title,
            style: AppTextStyles.h1(color: Colors.white.withOpacity(0.95)),
            textAlign: TextAlign.center,
          )
              .animate(
                key: ValueKey('title_$index'),
              )
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 200.ms),

          AppSpacing.gapHeightM,

          // Description
          Text(
            slide.description,
            style: AppTextStyles.body(color: Colors.white.withOpacity(0.65)),
            textAlign: TextAlign.center,
          )
              .animate(
                key: ValueKey('desc_$index'),
              )
              .fadeIn(duration: 500.ms, delay: 400.ms)
              .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildVisual(OnboardingSlide slide, bool isActive, int index) {
    switch (slide.visualType) {
      case OnboardingVisualType.logo:
        // Slide 1: App Logo with Biscuit accent
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 140 : 120,
          height: isActive ? 140 : 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isActive ? 30 : 26),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: slide.accentColor.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ]
                : [],
          ),
          child: AppLogo(
            size: isActive ? 140 : 120,
            backgroundColor: AppColors.logoDark,
            strokeColor: AppColors.logoBiscuit,
          ),
        )
            .animate(
              key: ValueKey('visual_$index'),
            )
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 500.ms,
              curve: Curves.elasticOut,
            );

      case OnboardingVisualType.translation:
        // Slide 2: Translation Illustration with Warm Gold accent
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 240 : 220,
          height: isActive ? 240 : 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(120),
            gradient: RadialGradient(
              colors: [
                slide.accentColor.withOpacity(0.15),
                slide.accentColor.withOpacity(0.02),
              ],
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: slide.accentColor.withOpacity(0.20),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ]
                : [],
          ),
          child: CustomPaint(
            painter: TranslationIllustrationPainter(
              accentColor: slide.accentColor,
            ),
          ),
        )
            .animate(
              key: ValueKey('visual_$index'),
            )
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 500.ms,
              curve: Curves.elasticOut,
            );

      case OnboardingVisualType.navigation:
        // Slide 3: Navigation Illustration with Orange accent
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 240 : 220,
          height: isActive ? 240 : 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(120),
            gradient: RadialGradient(
              colors: [
                slide.accentColor.withOpacity(0.15),
                slide.accentColor.withOpacity(0.02),
              ],
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: slide.accentColor.withOpacity(0.20),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ]
                : [],
          ),
          child: CustomPaint(
            painter: NavigationIllustrationPainter(
              accentColor: slide.accentColor,
            ),
          ),
        )
            .animate(
              key: ValueKey('visual_$index'),
            )
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 500.ms,
              curve: Curves.elasticOut,
            );

      case OnboardingVisualType.citySelection:
        return _buildCitySelectionGrid(slide, isActive, index);
    }
  }

  Widget _buildCitySelectionGrid(OnboardingSlide slide, bool isActive, int index) {
    final cities = [
      {'key': 'BJ', 'zh': '北京', 'en': 'Beijing', 'emoji': '🏛'},
      {'key': 'SH', 'zh': '上海', 'en': 'Shanghai', 'emoji': '🌃'},
      {'key': 'GZ', 'zh': '广州', 'en': 'Guangzhou', 'emoji': '🌺'},
      {'key': 'SZ', 'zh': '深圳', 'en': 'Shenzhen', 'emoji': '🏙'},
      {'key': 'CD', 'zh': '成都', 'en': 'Chengdu', 'emoji': '🐼'},
      {'key': 'XA', 'zh': '西安', 'en': "Xi'an", 'emoji': '⚔️'},
    ];

    return SizedBox(
      width: 280,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: cities.map((city) {
          final isSelected = _selectedCityKey == city['key'];
          final cityTheme = CityTheme.fromCityKey(city['key'] as String);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCityKey = city['key'] as String;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 130,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? cityTheme.pillActiveColor.withOpacity(0.20)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? cityTheme.pillActiveColor
                      : Colors.white.withOpacity(0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    city['emoji'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    city['zh'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? cityTheme.pillActiveColor
                          : Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city['en'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? cityTheme.pillActiveColor.withOpacity(0.8)
                          : Colors.white.withOpacity(0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    )
        .animate(key: ValueKey('visual_$index'))
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildPageIndicators() {
    final currentSlide = _slides[_currentPage];
    Color indicatorColor = currentSlide.accentColor;
    if (_currentPage == 3 && _selectedCityKey != null) {
      indicatorColor = CityTheme.fromCityKey(_selectedCityKey!).pillActiveColor;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slides.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? indicatorColor.withOpacity(0.90)
                : Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final currentSlide = _slides[_currentPage];
    final isLastPage = _currentPage == _slides.length - 1;
    final canProceed = !isLastPage || _selectedCityKey != null;

    // 第 4 屏选中城市后，按钮颜色跟随城市主题
    Color buttonColor = currentSlide.accentColor;
    if (isLastPage && _selectedCityKey != null) {
      buttonColor = CityTheme.fromCityKey(_selectedCityKey!).pillActiveColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: AnimatedOpacity(
        opacity: canProceed ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: PrimaryButton(
          text: isLastPage ? 'Get Started' : 'Next',
          onPressed: canProceed ? _nextPage : () {},
          isFullWidth: true,
          size: ButtonSize.large,
          backgroundColor: buttonColor,
          textColor: isLastPage ? Colors.white : AppColors.ink900,
          icon: isLastPage ? Icons.arrow_forward : Icons.navigate_next,
        ),
      ),
    );
  }
}

/// Onboarding slide visual type
enum OnboardingVisualType {
  logo,
  translation,
  navigation,
  citySelection,
}

/// Onboarding slide data model
class OnboardingSlide {
  final String title;
  final String description;
  final OnboardingVisualType visualType;
  final Color accentColor;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.visualType,
    required this.accentColor,
  });
}
