import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import '../main/main_screen.dart';

/// Onboarding Screen with swipeable slides
/// Based on Figma design - Screen 2
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Discover China\nYour Way',
      description:
          'Your AI-powered companion for exploring China\'s wonders with offline maps and smart recommendations',
      icon: Icons.explore,
      color: AppColors.jade500,
      gradient: AppColors.primaryGradient,
    ),
    OnboardingSlide(
      title: 'Break Language\nBarriers',
      description:
          'Real-time translation with your camera, comprehensive phrasebook, and voice assistance',
      icon: Icons.translate,
      color: AppColors.info500,
      gradient: const LinearGradient(
        colors: [AppColors.info500, AppColors.info300],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingSlide(
      title: 'Stay Safe,\nExplore Confidently',
      description:
          'Emergency SOS, live location sharing, and community safety tips to keep you secure',
      icon: Icons.security,
      color: AppColors.error500,
      gradient: const LinearGradient(
        colors: [AppColors.error500, AppColors.error300],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingSlide(
      title: 'Join the\nCommunity',
      description:
          'Find travel companions, connect with local guides, and share your adventure',
      icon: Icons.people,
      color: AppColors.success500,
      gradient: const LinearGradient(
        colors: [AppColors.success500, AppColors.success300],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
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

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
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

  void _finishOnboarding() {
    // Navigate to main screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
            style: AppTextStyles.button(color: AppColors.gray600),
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
          // Icon with animated container
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 200 : 180,
            height: isActive ? 200 : 180,
            decoration: BoxDecoration(
              gradient: slide.gradient,
              borderRadius: BorderRadius.circular(100),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: slide.color.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              slide.icon,
              size: isActive ? 100 : 90,
              color: Colors.white,
            ),
          )
              .animate(
                key: ValueKey(index),
              )
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),

          AppSpacing.gapHeightXL,

          // Title
          Text(
            slide.title,
            style: AppTextStyles.h1(color: AppColors.gray900),
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
            style: AppTextStyles.body(color: AppColors.gray700),
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

  Widget _buildPageIndicators() {
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
                ? AppColors.primary
                : AppColors.gray300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: PrimaryButton(
        text: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
        onPressed: _nextPage,
        isFullWidth: true,
        size: ButtonSize.large,
        icon: _currentPage == _slides.length - 1
            ? Icons.arrow_forward
            : Icons.navigate_next,
      ),
    );
  }
}

/// Onboarding slide data model
class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}
