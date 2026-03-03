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

/// Example: User Authentication
class AuthExample {
  Future<void> signUpExample() async {
    try {
      final result = await backend.auth.signUp(
        email: 'user@example.com',
        password: 'secure-password',
        metadata: {
          'username': 'traveler123',
          'full_name': 'John Doe',
          'nationality': 'USA',
          'languages': ['en', 'zh'],
          'interests': ['food', 'culture', 'nature'],
        },
      );

      debugPrint('User created: ${result['user']['id']}');
      debugPrint('Token: ${result['token']}');

      // Save session
      await backend.saveSession(result['token']);
    } catch (e) {
      debugPrint('Sign up failed: $e');
    }
  }

  Future<void> signInExample() async {
    try {
      final result = await backend.auth.signIn(
        email: 'user@example.com',
        password: 'secure-password',
      );

      debugPrint('User signed in: ${result['user']['id']}');

      // Save session
      await backend.saveSession(result['token']);
    } catch (e) {
      debugPrint('Sign in failed: $e');
    }
  }

  Future<void> signOutExample() async {
    try {
      await backend.auth.signOut();
      await backend.clearSession();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }
}

/// Example: Database Queries
class DatabaseExample {
  Future<void> queryExample() async {
    try {
      // Using Supabase-like API
      final trips = await backend.database
          .from('trips')
          .select()
          .eq('status', 'planning')
          .order('created_at', ascending: false)
          .limit(10)
          .get();

      debugPrint('Found ${trips.length} trips');

      // Using raw SQL
      final result = await backend.database.query('''
        SELECT * FROM trips
        WHERE user_id = @userId
        ORDER BY created_at DESC
        LIMIT 10
      ''', parameters: {
        'userId': backend.auth.currentUserId,
      });

      debugPrint('Query result: ${result.length} rows');
    } catch (e) {
      debugPrint('Query failed: $e');
    }
  }

  Future<void> insertExample() async {
    try {
      final trip = await backend.database.from('trips').insert({
        'user_id': backend.auth.currentUserId,
        'title': 'Beijing Adventure',
        'description': 'Exploring the capital city',
        'start_date': '2026-03-01',
        'end_date': '2026-03-07',
        'budget': 5000.0,
        'cities': '["Beijing"]',
        'status': 'planning',
      });

      debugPrint('Trip created: ${trip?['id']}');
    } catch (e) {
      debugPrint('Insert failed: $e');
    }
  }

  Future<void> updateExample() async {
    try {
      await backend.database
          .from('trips')
          .eq('id', 'trip-uuid-here')
          .update({
        'status': 'ongoing',
        'total_spent': 1250.50,
      });

      debugPrint('Trip updated');
    } catch (e) {
      debugPrint('Update failed: $e');
    }
  }

  Future<void> deleteExample() async {
    try {
      await backend.database
          .from('trips')
          .eq('id', 'trip-uuid-here')
          .delete();

      debugPrint('Trip deleted');
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }
}

/// Example: File Storage
class StorageExample {
  Future<void> uploadAvatarExample(String filePath) async {
    try {
      final url = await backend.storage.uploadAvatar(
        userId: backend.auth.currentUserId!,
        filePath: filePath,
      );

      debugPrint('Avatar uploaded: $url');

      // Update user profile with avatar URL
      await backend.database.from('users').eq('id', backend.auth.currentUserId!).update({
        'profile_picture': url,
      });
    } catch (e) {
      debugPrint('Upload failed: $e');
    }
  }

  Future<void> uploadPostImageExample(String filePath, String postId) async {
    try {
      final url = await backend.storage.uploadPostImage(
        userId: backend.auth.currentUserId!,
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
        bucket: 'post-images',
        objectName: 'user-id/post-id/timestamp.jpg',
      );

      debugPrint('File deleted');
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }
}
