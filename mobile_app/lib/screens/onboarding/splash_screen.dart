import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import 'onboarding_screen.dart';

/// Splash Screen with beautiful animations
/// Based on Figma design - Screen 1
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // Navigate to onboarding or home based on user state
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer to push content to center
              Expanded(child: SizedBox()),

              // Logo Section
              _buildLogo(),

              AppSpacing.gapHeightL,

              // Tagline
              _buildTagline(),

              Expanded(child: SizedBox()),

              // Loading Indicator
              _buildLoadingIndicator(),

              AppSpacing.gapHeightXXL,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.explore,
            size: 60,
            color: AppColors.primary,
          ),
        ),
      )
          .animate()
          .fadeIn(
            duration: 500.ms,
            curve: Curves.easeOut,
          )
          .scale(
            begin: Offset(0.8, 0.8),
            end: Offset(1.0, 1.0),
            duration: 500.ms,
            curve: Curves.elasticOut,
          )
          .then(delay: 200.ms) // Wait before shimmer
          .shimmer(
            duration: 1500.ms,
            color: Colors.white.withOpacity(0.3),
          ),
    );
  }

  Widget _buildTagline() {
    return Column(
      children: [
        Text(
          'WanderChina',
          style: AppTextStyles.h1(color: AppColors.primary),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(
              duration: 500.ms,
              delay: 300.ms,
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.3,
              end: 0,
              duration: 500.ms,
              delay: 300.ms,
              curve: Curves.easeOut,
            ),
        AppSpacing.gapHeightS,
        Text(
          'Discover China Your Way',
          style: AppTextStyles.body(color: AppColors.gray700),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(
              duration: 500.ms,
              delay: 500.ms,
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.3,
              end: 0,
              duration: 500.ms,
              delay: 500.ms,
              curve: Curves.easeOut,
            ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .fadeIn(
          duration: 500.ms,
          delay: 1000.ms,
        );
  }
}

/// Alternative Splash Screen with Lottie Animation
/// Uncomment when you have Lottie assets
/*
class SplashScreenWithLottie extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Lottie.asset(
                'assets/animations/splash_animation.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              AppSpacing.gapHeightL,
              Text(
                'WanderChina',
                style: AppTextStyles.h1(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
