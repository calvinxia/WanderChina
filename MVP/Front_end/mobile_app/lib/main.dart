import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/config/amap_config.dart';
import 'core/config/backend_config.dart';
import 'services/amap_service.dart'
    if (dart.library.html) 'services/amap_service_stub.dart';
import 'services/map_translation_service.dart';
import 'services/voice/voice_translation_service.dart';
import 'services/backend/auth_service.dart';
import 'core/services/language_manager.dart';
import 'screens/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ============================================================================
  // 服务初始化
  // ============================================================================

  debugPrint('🚀 开始初始化应用服务...');

  // 1. 验证后端配置
  if (!BackendConfig.isConfigured) {
    debugPrint('⚠️ Backend not configured. Run with --dart-define-from-file=.env');
    debugPrint('⚠️ Cloud functions will not be available.');
  } else {
    debugPrint('✅ 后端配置已加载（云函数模式）');
  }

  // 2. 初始化语言管理器
  try {
    await LanguageManager().initialize();
    debugPrint('✅ 语言管理器初始化成功');
  } catch (e) {
    debugPrint('❌ 语言管理器初始化失败: $e');
  }

  // 3. 初始化高德地图SDK
  try {
    if (AMapConfig.isApiKeyConfigured()) {
      await AMapService().initialize();
      debugPrint('✅ 高德地图SDK初始化成功');
      debugPrint('📍 Android Key: ${AMapConfig.androidApiKey.substring(0, 10)}...');
      debugPrint('📍 iOS Key: ${AMapConfig.iosApiKey.substring(0, 10)}...');
    } else {
      debugPrint('⚠️ 高德地图API Key未配置，地图功能将不可用');
    }
  } catch (e) {
    debugPrint('❌ 高德地图SDK初始化失败: $e');
  }

  // 4. 初始化地图翻译服务（路线翻译，本地词典模式）
  try {
    await MapTranslationService().initialize();
    debugPrint('✅ 地图翻译服务初始化成功');
  } catch (e) {
    debugPrint('❌ 地图翻译服务初始化失败: $e');
  }

  // 5. 初始化语音翻译服务
  try {
    await VoiceTranslationService().initialize();
    debugPrint('✅ 语音翻译服务初始化成功');
  } catch (e) {
    debugPrint('❌ 语音翻译服务初始化失败: $e');
  }

  // 6. 恢复用户 session
  try {
    final restored = await AuthService.restoreSession();
    if (restored) {
      debugPrint('✅ 用户 session 已恢复');
    } else {
      debugPrint('ℹ️  未找到已保存的 session（首次启动或已登出）');
    }
  } catch (e) {
    debugPrint('❌ 恢复 session 失败: $e');
  }

  debugPrint('🎉 应用服务初始化完成！\n');

  runApp(
    const ProviderScope(
      child: WanderChinaApp(),
    ),
  );
}

class WanderChinaApp extends StatelessWidget {
  const WanderChinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WanderChina',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // TODO: Make this dynamic

      // Initial route
      home: const SplashScreen(),

      // Routes
      // routes: AppRoutes.routes,

      // Locale
      // localizationsDelegates: AppLocalizations.localizationsDelegates,
      // supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
