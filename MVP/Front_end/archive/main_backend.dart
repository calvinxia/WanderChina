/// Example integration of backend services in main.dart
///
/// This file demonstrates how to initialize and use the new backend services
/// Copy the relevant parts to your main.dart file

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/config/amap_config.dart';
import 'core/services/backend_manager.dart';
import 'services/backend/auth_service.dart';
import 'services/api_client.dart';
import 'services/amap_service.dart'
    if (dart.library.html) 'services/amap_service_stub.dart';
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
  // INITIALIZE BACKEND (Tencent Cloud + Cloudflare R2)
  // ============================================================================
  try {
    debugPrint('🚀 Initializing WanderChina Backend...');
    await backend.initialize();
  } catch (e) {
    debugPrint('❌ Backend initialization error: $e');
    // App can still run without backend (with limited functionality)
  }

  // ============================================================================
  // INITIALIZE AMAP
  // ============================================================================
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
      themeMode: ThemeMode.light,

      // Initial route
      home: SplashScreen(),
    );
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/// Example: User Authentication (Cloud Functions)
class AuthExample {
  Future<void> signUpExample() async {
    try {
      final result = await AuthService.register(
        email: 'user@example.com',
        password: 'secure-password',
        username: 'traveler123',
      );

      debugPrint('User created: ${result['user_id']}');
      debugPrint('Token: ${result['token']}');
    } catch (e) {
      debugPrint('Sign up failed: $e');
    }
  }

  Future<void> signInExample() async {
    try {
      final result = await AuthService.login(
        email: 'user@example.com',
        password: 'secure-password',
      );

      debugPrint('User signed in: ${result['user_id']}');
    } catch (e) {
      debugPrint('Sign in failed: $e');
    }
  }

  Future<void> signOutExample() async {
    try {
      await AuthService.logout();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }
}

/// Example: Trip Data (Cloud Functions)
class TripExample {
  Future<void> createTripExample() async {
    try {
      final result = await ApiClient.post(ApiClient.tripUrl, {
        'action': 'create_trip',
        'user_id': AuthService.currentUserId,
        'title': 'Beijing Adventure',
        'description': 'Exploring the capital city',
        'start_date': '2026-03-01',
        'end_date': '2026-03-07',
        'budget': 5000.0,
        'cities': ['Beijing'],
        'status': 'planning',
      });

      debugPrint('Trip created: ${result['trip_id']}');
    } catch (e) {
      debugPrint('Create trip failed: $e');
    }
  }

  Future<void> getTripExample() async {
    try {
      final result = await ApiClient.post(ApiClient.tripUrl, {
        'action': 'get_user_trips',
        'user_id': AuthService.currentUserId,
        'status': 'planning',
      });

      debugPrint('Found ${result['trips'].length} trips');
    } catch (e) {
      debugPrint('Get trips failed: $e');
    }
  }

  Future<void> updateTripExample() async {
    try {
      await ApiClient.post(ApiClient.tripUrl, {
        'action': 'update_trip',
        'trip_id': 'trip-uuid-here',
        'user_id': AuthService.currentUserId,
        'status': 'ongoing',
        'total_spent': 1250.50,
      });

      debugPrint('Trip updated');
    } catch (e) {
      debugPrint('Update trip failed: $e');
    }
  }

  Future<void> deleteTripExample() async {
    try {
      await ApiClient.post(ApiClient.tripUrl, {
        'action': 'delete_trip',
        'trip_id': 'trip-uuid-here',
        'user_id': AuthService.currentUserId,
      });

      debugPrint('Trip deleted');
    } catch (e) {
      debugPrint('Delete trip failed: $e');
    }
  }
}

/// Example: File Storage (COS with STS)
class StorageExample {
  Future<void> uploadAvatarExample(String filePath) async {
    try {
      final url = await backend.storage.uploadAvatar(
        userId: AuthService.currentUserId!,
        filePath: filePath,
      );

      debugPrint('Avatar uploaded: $url');

      // Update user profile with avatar URL via cloud function
      await AuthService.updateProfile({
        'profile_picture': url,
      });
    } catch (e) {
      debugPrint('Upload failed: $e');
    }
  }

  Future<void> uploadPostImageExample(String filePath, String postId) async {
    try {
      final url = await backend.storage.uploadPostImage(
        userId: AuthService.currentUserId!,
        postId: postId,
        filePath: filePath,
      );

      debugPrint('Post image uploaded: $url');
    } catch (e) {
      debugPrint('Upload failed: $e');
    }
  }

  Future<void> deleteFileExample() async {
    try {
      await backend.storage.deleteFile(
        objectName: 'posts/user-id/post-id/timestamp.jpg',
      );

      debugPrint('File deleted');
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }
}
