import 'package:flutter/material.dart';
import '../core/theme/city_theme.dart';
import '../services/backend/auth_service.dart';
import '../screens/auth/login_screen.dart';

/// 软登录底部弹窗 — 匿名用户触发核心功能时弹出
class SoftLoginSheet extends StatefulWidget {
  final CityTheme? theme;
  final String feature;

  const SoftLoginSheet({
    super.key,
    this.theme,
    required this.feature,
  });

  @override
  State<SoftLoginSheet> createState() => _SoftLoginSheetState();
}

class _SoftLoginSheetState extends State<SoftLoginSheet> {
  bool _isLoading = false;

  String _getTitle() {
    switch (widget.feature) {
      case 'itinerary_generate':
        return 'Sign in to plan your trip';
      case 'voice_translate':
        return 'Sign in to use voice translation';
      case 'ai_edit':
        return 'Sign in to edit your itinerary';
      default:
        return 'Sign in to continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.theme?.pillActiveColor ?? const Color(0xFF2D6A4F);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(Icons.lock_open_rounded, size: 48, color: color),
          const SizedBox(height: 16),
          Text(
            _getTitle(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a free account to unlock all features',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Apple Sign-In
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: Image.asset(
                'assets/icons/oauth/apple_logo_white.png',
                width: 20,
                height: 20,
              ),
              label: const Text('Continue with Apple', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _handleAppleSignIn,
            ),
          ),
          const SizedBox(height: 12),

          // Email Sign-In
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: Icon(Icons.email_outlined, color: color),
              label: Text('Continue with Email',
                  style: TextStyle(fontSize: 16, color: color)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _handleEmailSignIn,
            ),
          ),
          const SizedBox(height: 16),

          // Skip
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
            child: Text('Skip for now', style: TextStyle(color: Colors.grey[400])),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithApple();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('⚠️ Apple Sign-In failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.toString().substring(0, e.toString().length.clamp(0, 60))}')),
        );
      }
    }
  }

  /// Email 登录：push LoginScreen(fromSoftLogin: true)，等结果返回后关闭 sheet
  Future<void> _handleEmailSignIn() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(fromSoftLogin: true),
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

/// 检查是否已注册用户，未注册则弹软登录 sheet
/// 返回 true = 已注册或刚注册成功，false = 取消/跳过
Future<bool> requireLogin(BuildContext context, String feature, {CityTheme? theme}) async {
  if (AuthService.isRegistered) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SoftLoginSheet(theme: theme, feature: feature),
  );

  return result == true;
}
