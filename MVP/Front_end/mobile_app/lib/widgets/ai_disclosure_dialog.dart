import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/city_theme.dart';
import '../services/backend/auth_service.dart';
import '../services/api_client.dart';
import '../core/config/backend_config.dart';

/// AI 数据处理披露弹窗（Apple 2026 Guideline 5.1.2(i) 强制要求）
///
/// 性质：disclosure（知情权），不是 consent（同意权）。
/// 用户必须看到，但不需要选择同意/拒绝。
/// 只有 "I Understand & Continue" 按钮。
class AIDisclosureDialog extends StatelessWidget {
  final CityTheme theme;
  final VoidCallback onContinue;

  const AIDisclosureDialog({
    super.key,
    required this.theme,
    required this.onContinue,
  });

  Widget _buildItem(IconData icon, String dataType, String partner, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dataType,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '→ $partner',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.pillActiveColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How WanderChina Uses Your Data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'To provide AI-powered features, we share specific information with trusted partners:',
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildItem(
                Icons.edit_note_rounded,
                'Trip preferences (cities, dates, interests)',
                'DeepSeek AI for itinerary generation',
                accentColor,
              ),
              _buildItem(
                Icons.mic_rounded,
                'Voice recordings',
                'Baidu Cloud for real-time translation',
                accentColor,
              ),
              _buildItem(
                Icons.location_on_rounded,
                'Location & POI queries',
                'Amap / Gaode for mapping and navigation',
                accentColor,
              ),
              _buildItem(
                Icons.photo_camera_rounded,
                'AI-generated keywords',
                'Unsplash for travel photography',
                accentColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Your personal information is never sold and not used for advertising.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Understand & Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse('https://wanderchina.app/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 检查是否需要显示 AI disclosure，如果需要则弹出
///
/// 触发时机：Onboarding 完成后进入 MainScreen 之前，以及 SplashScreen restoreSession 后
/// 存储：SharedPreferences 本地标记 + 后端 user 表标记
Future<void> showAIDisclosureIfNeeded(BuildContext context, CityTheme theme) async {
  final prefs = await SharedPreferences.getInstance();
  final alreadyShown = prefs.getBool('ai_disclosure_shown') ?? false;

  if (alreadyShown) return;

  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AIDisclosureDialog(
      theme: theme,
      onContinue: () {
        Navigator.of(context).pop();

        prefs.setBool('ai_disclosure_shown', true);

        final userId = AuthService.currentUserId;
        if (userId != null) {
          ApiClient.post(BackendConfig.authUrl, {
            'action': 'mark_ai_disclosure_shown',
            'user_id': userId,
          }).catchError((e) {
            debugPrint('⚠️ Failed to mark AI disclosure on server: $e');
            return <String, dynamic>{};
          });
        }
      },
    ),
  );
}
