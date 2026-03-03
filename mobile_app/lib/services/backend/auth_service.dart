import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../../core/config/backend_config.dart';
import 'database_service.dart';

/// Authentication Service
/// Replaces Supabase Auth
class AuthService {
  static AuthService? _instance;
  final DatabaseService _db = DatabaseService();

  // Current user data
  String? _userId;
  String? _email;
  Map<String, dynamic>? _userData;
  String? _sessionToken;

  // Singleton pattern
  AuthService._();

  factory AuthService() {
    _instance ??= AuthService._();
    return _instance!;
  }

  // ============================================================================
  // AUTHENTICATION STATE
  // ============================================================================

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null && _sessionToken != null;

  /// Get current user ID
  String? get currentUserId => _userId;

  /// Get current user email
  String? get currentUserEmail => _email;

  /// Get current user data
  Map<String, dynamic>? get currentUser => _userData;

  /// Get current session token
  String? get sessionToken => _sessionToken;

  // ============================================================================
  // SIGN UP
  // ============================================================================

  /// Sign up a new user
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate email and password
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }

      // Hash password
      final passwordHash = _hashPassword(password);

      // Create user
      final userData = {
        'email': email,
        'password_hash': passwordHash,
        'username': metadata?['username'],
        'full_name': metadata?['full_name'],
        'nationality': metadata?['nationality'],
        'languages': jsonEncode(metadata?['languages'] ?? []),
        'interests': jsonEncode(metadata?['interests'] ?? []),
      };

      final user = await _db.from('users').insert(userData);

      if (user == null) {
        throw Exception('Failed to create user');
      }

      debugPrint('✅ User created: ${user['id']}');

      // Automatically sign in
      return await signIn(email: email, password: password);
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SIGN IN
  // ============================================================================

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Find user by email
      final user = await _db
          .from('users')
          .select()
          .eq('email', email)
          .single();

      if (user == null) {
        throw Exception('User not found');
      }

      // Verify password
      final passwordHash = user['password_hash'] as String;
      if (!_verifyPassword(password, passwordHash)) {
        throw Exception('Invalid password');
      }

      // Check if user is active
      if (user['is_active'] != true) {
        throw Exception('Account is deactivated');
      }

      // Create session
      final session = await _createSession(user);

      // Update last login
      await _db.from('users').eq('id', user['id']).update({
        'last_login': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ User signed in: ${user['id']}');

      return session;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Create a new session
  Future<Map<String, dynamic>> _createSession(
    Map<String, dynamic> user,
  ) async {
    final userId = user['id'] as String;

    // Generate JWT token
    final jwt = JWT({
      'sub': userId,
      'email': user['email'],
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    final token = jwt.sign(
      SecretKey(BackendConfig.jwtSecret),
      expiresIn: BackendConfig.jwtExpiration,
      issuer: BackendConfig.jwtIssuer,
    );

    // Store session in database
    final tokenHash = _hashToken(token);
    final expiresAt = DateTime.now().add(BackendConfig.jwtExpiration);

    await _db.from('user_sessions').insert({
      'user_id': userId,
      'token_hash': tokenHash,
      'expires_at': expiresAt.toIso8601String(),
    });

    // Set user context in database for RLS
    await _db.setCurrentUser(userId);

    // Update local state
    _userId = userId;
    _email = user['email'] as String;
    _userData = user;
    _sessionToken = token;

    return {
      'user': user,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  /// Restore session from stored token
  Future<bool> restoreSession(String token) async {
    try {
      // Verify JWT token
      final jwt = JWT.verify(token, SecretKey(BackendConfig.jwtSecret));
      final userId = jwt.payload['sub'] as String;

      // Check if session exists and is valid
      final tokenHash = _hashToken(token);
      final session = await _db
          .from('user_sessions')
          .select()
          .eq('token_hash', tokenHash)
          .eq('user_id', userId)
          .single();

      if (session == null) {
        throw Exception('Session not found');
      }

      final expiresAt = DateTime.parse(session['expires_at'] as String);
      if (expiresAt.isBefore(DateTime.now())) {
        throw Exception('Session expired');
      }

      // Get user data
      final user = await _db
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (user == null) {
        throw Exception('User not found');
      }

      // Set user context in database for RLS
      await _db.setCurrentUser(userId);

      // Update local state
      _userId = userId;
      _email = user['email'] as String;
      _userData = user;
      _sessionToken = token;

      // Update last activity
      await _db.from('user_sessions').eq('token_hash', tokenHash).update({
        'last_activity': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Session restored: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to restore session: $e');
      return false;
    }
  }

  // ============================================================================
  // SIGN OUT
  // ============================================================================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      if (_sessionToken != null) {
        final tokenHash = _hashToken(_sessionToken!);

        // Delete session from database
        await _db
            .from('user_sessions')
            .eq('token_hash', tokenHash)
            .delete();
      }

      // Clear user context in database
      await _db.clearCurrentUser();

      // Clear local state
      _userId = null;
      _email = null;
      _userData = null;
      _sessionToken = null;

      debugPrint('✅ User signed out');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PASSWORD MANAGEMENT
  // ============================================================================

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    if (newPassword.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    // Verify current password
    final user = await _db
        .from('users')
        .select()
        .eq('id', _userId!)
        .single();

    if (user == null) {
      throw Exception('User not found');
    }

    final passwordHash = user['password_hash'] as String;
    if (!_verifyPassword(currentPassword, passwordHash)) {
      throw Exception('Current password is incorrect');
    }

    // Update password
    final newPasswordHash = _hashPassword(newPassword);
    await _db.from('users').eq('id', _userId!).update({
      'password_hash': newPasswordHash,
    });

    debugPrint('✅ Password changed');
  }

  /// Request password reset (placeholder - requires email service)
  Future<void> resetPassword(String email) async {
    // TODO: Implement password reset email
    // 1. Generate reset token
    // 2. Send email with reset link
    // 3. Store token in database
    throw UnimplementedError('Password reset not implemented yet');
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password against hash
  bool _verifyPassword(String password, String hash) {
    final passwordHash = _hashPassword(password);
    return passwordHash == hash;
  }

  /// Hash token for storage
  String _hashToken(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
