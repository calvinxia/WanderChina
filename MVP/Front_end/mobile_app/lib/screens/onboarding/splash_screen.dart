import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../services/backend/auth_service.dart';
import '../../widgets/app_logo.dart';
import '../main/main_screen.dart';
import 'onboarding_screen.dart';

/// Splash Screen with beautiful animations
/// Based on Figma design - Screen 1
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

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
    // 并行执行：最少显示 2 秒 + 同时检查 session
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      AuthService.restoreSession(),
    ]);

    if (!mounted) return;

    final isLoggedIn = results[1] as bool;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(key: MainScreen.globalKey)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer to push content to center
              const Expanded(child: SizedBox()),

              // Logo Section
              _buildLogo(),

              AppSpacing.gapHeightL,

              // Tagline
              _buildTagline(),

              const Expanded(child: SizedBox()),

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
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const AppLogo(size: 60),
      )
          .animate()
          .fadeIn(
            duration: 500.ms,
            curve: Curves.easeOut,
          )
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
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
    return const SizedBox(
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
