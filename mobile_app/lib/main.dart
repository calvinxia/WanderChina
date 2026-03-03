import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/config/amap_config.dart';
import 'services/amap_service.dart'
    if (dart.library.html) 'services/amap_service_stub.dart';
import 'services/poi_translation_service.dart';
import 'services/map_translation_service.dart';
import 'services/map/poi_translation_service.dart' as overlay;
import 'services/voice/voice_translation_service.dart';
import 'core/services/language_manager.dart';
import 'screens/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
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

  print('🚀 开始初始化应用服务...');

  // 1. 初始化语言管理器
  try {
    await LanguageManager().initialize();
    print('✅ 语言管理器初始化成功');
  } catch (e) {
    print('❌ 语言管理器初始化失败: $e');
  }

  // 2. 初始化高德地图SDK
  try {
    if (AMapConfig.isApiKeyConfigured()) {
      await AMapService().initialize();
      print('✅ 高德地图SDK初始化成功');
      print('📍 Android Key: ${AMapConfig.androidApiKey.substring(0, 10)}...');
      print('📍 iOS Key: ${AMapConfig.iosApiKey.substring(0, 10)}...');
    } else {
      print('⚠️ 高德地图API Key未配置，地图功能将不可用');
    }
  } catch (e) {
    print('❌ 高德地图SDK初始化失败: $e');
  }

  // 3. 初始化POI翻译服务
  try {
    await POITranslationService().initialize(
      // baiduAppId: 'YOUR_BAIDU_APP_ID',      // 可选：百度翻译API
      // baiduSecretKey: 'YOUR_BAIDU_SECRET',  // 可选：百度翻译密钥
    );
    print('✅ POI翻译服务初始化成功');
  } catch (e) {
    print('❌ POI翻译服务初始化失败: $e');
  }

  // 4. 初始化地图翻译服务（路线翻译）
  try {
    await MapTranslationService().initialize();
    print('✅ 地图翻译服务初始化成功');
  } catch (e) {
    print('❌ 地图翻译服务初始化失败: $e');
  }

  // 5. 初始化POI翻译服务（地图蒙层）
  try {
    await overlay.POITranslationService().initialize();
    print('✅ POI翻译蒙层服务初始化成功');
  } catch (e) {
    print('❌ POI翻译蒙层服务初始化失败: $e');
  }

  // 6. 初始化语音翻译服务
  try {
    await VoiceTranslationService().initialize();
    print('✅ 语音翻译服务初始化成功');
  } catch (e) {
    print('❌ 语音翻译服务初始化失败: $e');
  }

  print('🎉 应用服务初始化完成！\n');

  runApp(
    ProviderScope(
      child: WanderChinaApp(),
    ),
  );
}

class WanderChinaApp extends StatelessWidget {
  const WanderChinaApp({Key? key}) : super(key: key);

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
      home: SplashScreen(),

      // Routes
      // routes: AppRoutes.routes,

      // Locale
      // localizationsDelegates: AppLocalizations.localizationsDelegates,
      // supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
