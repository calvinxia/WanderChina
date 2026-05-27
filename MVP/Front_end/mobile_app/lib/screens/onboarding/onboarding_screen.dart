import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/city_theme.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/mountain_silhouette.dart';
import '../../widgets/onboarding_illustrations.dart';
import '../../services/backend/auth_service.dart';
import '../../widgets/ai_disclosure_dialog.dart';
import '../main/main_screen.dart';

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
  String? _selectedCityKey;   // 用户手动选择的城市 key
  String? _detectedCityKey;   // GPS 检测到的城市 key
  bool _isDetectingCity = false; // 防重复 GPS 检测
  bool _isFinishing = false;  // 防重入 _finishOnboarding

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Discover China\nYour Way',
      description:
          'Your AI-powered companion for exploring China\'s wonders with offline maps and smart recommendations',
      visualType: OnboardingVisualType.logo,
      accentColor: const Color(0xFFE8D5B0), // Biscuit — 深色背景上可见
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
    setState(() => _currentPage = page);

    // 进入第3页时，后台启动 GPS 检测（不阻塞 UI）
    if (page == 2 && _detectedCityKey == null) {
      _tryDetectCityInBackground();
    }

    // 滑动到第4页时，GPS 已检测到城市 → 直接完成，跳过手动选择
    if (page == 3 && _detectedCityKey != null) {
      _finishOnboarding();
    }
  }

  Future<void> _nextPage() async {
    if (_currentPage < _slides.length - 1) {
      // 从第3页点 Next 时，GPS 结果已就绪 → 直接完成，跳过第4页
      if (_currentPage == 2 && _detectedCityKey != null) {
        await _finishOnboarding();
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  /// 后台 GPS 检测 — 不阻塞 UI，结果存入 _detectedCityKey
  Future<void> _tryDetectCityInBackground() async {
    if (_isDetectingCity) return;
    _isDetectingCity = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _isDetectingCity = false;
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 5));

      final cityKey = CityTheme.keyFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (cityKey != null && mounted) {
        setState(() {
          _detectedCityKey = cityKey;
          _selectedCityKey = cityKey; // 预选，让第4页城市卡高亮
        });
      }
    } catch (_) {
      // GPS 失败，不影响用户继续滑动
    }
    _isDetectingCity = false;
  }

  /// 完成 Onboarding — 防重入 + anonymousAuth 最多重试 2 次
  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    _isFinishing = true;

    final prefs = await SharedPreferences.getInstance();

    // 城市优先级：手动选择 > GPS 检测 > 默认广州
    final cityKey = _selectedCityKey ?? _detectedCityKey ?? 'guangzhou';
    await prefs.setString('destination_city', cityKey);
    await prefs.setBool('onboarding_done', true);

    // 生成或读取 device_id
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      final random = Random.secure();
      deviceId = List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
      await prefs.setString('device_id', deviceId);
    }

    // 匿名登录，最多重试 2 次，失败也进（离线模式）
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final ok = await AuthService.anonymousAuth(deviceId);
        if (ok) break;
        debugPrint('[AUTH] Anonymous auth attempt ${attempt + 1} returned false');
      } catch (e) {
        debugPrint('[AUTH] Anonymous auth attempt ${attempt + 1} failed: $e');
      }
    }

    if (!mounted) return;

    final cityTheme = CityTheme.fromCityKey(cityKey);
    await showAIDisclosureIfNeeded(context, cityTheme);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainScreen(key: MainScreen.globalKey)),
      (route) => false,
    );
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

          const SizedBox(height: 56),

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
          width: isActive ? 200 : 180,
          height: isActive ? 200 : 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isActive ? 30 : 26),
            boxShadow: [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isActive ? 30 : 26),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: isActive ? 200 : 180,
              height: isActive ? 200 : 180,
              fit: BoxFit.cover,
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
      {'key': 'BJ', 'zh': '北京', 'en': 'Beijing', 'emoji': '🏯'},
      {'key': 'SH', 'zh': '上海', 'en': 'Shanghai', 'emoji': '🌃'},
      {'key': 'GZ', 'zh': '广州', 'en': 'Guangzhou', 'emoji': '🍵'},
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
