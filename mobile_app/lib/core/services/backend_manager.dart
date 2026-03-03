import 'package:flutter/foundation.dart';
import '../../services/backend/database_service.dart';
import '../../services/backend/auth_service.dart';
import '../../services/backend/storage_service.dart';
import '../config/backend_config.dart';

/// Backend Manager - Initializes all backend services
/// Replaces Supabase initialization
class BackendManager {
  static BackendManager? _instance;
  bool _isInitialized = false;

  // Services
  final DatabaseService database = DatabaseService();
  final AuthService auth = AuthService();
  final StorageService storage = StorageService();

  // Singleton pattern
  BackendManager._();

  factory BackendManager() {
    _instance ??= BackendManager._();
    return _instance!;
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize all backend services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Backend already initialized');
      return;
    }

    debugPrint('=== Initializing Backend ===');
    BackendConfig.printStatus();

    try {
      // Initialize database
      if (BackendConfig.isDatabaseConfigured) {
        await database.initialize();
      } else {
        debugPrint('⚠️ Database not configured, skipping initialization');
      }

      // Initialize storage
      if (BackendConfig.isStorageConfigured) {
        await storage.initialize();
      } else {
        debugPrint('⚠️ Storage not configured, skipping initialization');
      }

      // Try to restore previous session
      await _restoreSession();

      _isInitialized = true;
      debugPrint('=== Backend Initialized ✅ ===');
    } catch (e) {
      debugPrint('❌ Backend initialization failed: $e');
      rethrow;
    }
  }

  /// Check if backend is initialized
  bool get isInitialized => _isInitialized;

  /// Check if backend is fully configured
  bool get isFullyConfigured => BackendConfig.isFullyConfigured;

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Restore previous session if exists
  Future<void> _restoreSession() async {
    try {
      // TODO: Implement session persistence using shared_preferences
      // For now, just skip session restoration
      debugPrint('⏭️ Session restoration not implemented yet');
    } catch (e) {
      debugPrint('⚠️ Failed to restore session: $e');
    }
  }

  /// Save current session
  Future<void> saveSession(String token) async {
    try {
      // TODO: Save token to shared_preferences
      debugPrint('💾 Session saved');
    } catch (e) {
      debugPrint('❌ Failed to save session: $e');
    }
  }

  /// Clear saved session
  Future<void> clearSession() async {
    try {
      // TODO: Clear token from shared_preferences
      debugPrint('🗑️ Session cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear session: $e');
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose all backend services
  Future<void> dispose() async {
    debugPrint('=== Disposing Backend ===');

    try {
      await auth.signOut();
      await database.close();
      _isInitialized = false;
      debugPrint('=== Backend Disposed ✅ ===');
    } catch (e) {
      debugPrint('❌ Backend disposal failed: $e');
    }
  }
}

/// Global backend instance
final backend = BackendManager();
