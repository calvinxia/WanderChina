import 'package:flutter/foundation.dart';
// lib/services/backend/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../api_client.dart';
import '../app_event_bus.dart';
import '../subscription_service.dart';

class AuthService {
  static String? _currentUserId;
  static String? _currentToken;
  static String? _loginType;  // 'anonymous' | 'registered'

  static String? get currentUserId => _currentUserId;
  static bool get isLoggedIn => _currentToken != null;
  static bool get isRegistered => _loginType == 'registered';
  static bool get isAnonymous => _loginType == 'anonymous';

  /// 匿名认证（App 首次启动时调用）
  static Future<bool> anonymousAuth(String deviceId, {String lang = 'en'}) async {
    try {
      final result = await ApiClient.post(ApiClient.authUrl, {
        'action': 'anonymous_auth',
        'device_id': deviceId,
        'preferred_lang': lang,
      });
      _currentUserId = result['user_id'];
      _currentToken = result['token'];
      _loginType = 'anonymous';
      await _saveSession();
      return true;
    } catch (e) {
      debugPrint('[AUTH] Anonymous auth failed: $e');
      return false;
    }
  }

  /// 邮箱注册
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? username,
    String? deviceId,
  }) async {
    final result = await ApiClient.post(ApiClient.authUrl, {
      'action': 'register',
      'email': email,
      'password': password,
      'username': username,
      'device_id': deviceId,
    });
    _currentUserId = result['user_id'];
    _currentToken = result['token'];
    _loginType = 'registered';
    AppEventBus.instance.fire(LoginStatusChangedEvent());
    await _saveSession();
    syncAIDisclosure(); // fire-and-forget
    return result;
  }

  /// 邮箱登录
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await ApiClient.post(ApiClient.authUrl, {
      'action': 'login',
      'email': email,
      'password': password,
    });
    _currentUserId = result['user_id'];
    _currentToken = result['token'];
    _loginType = 'registered';
    AppEventBus.instance.fire(LoginStatusChangedEvent());
    await _saveSession();
    SubscriptionService.instance.updateFromServer(result);
    syncAIDisclosure(); // fire-and-forget
    return result;
  }

  /// Apple Sign-In 登录
  ///
  /// ⚠️ 关键：使用 userIdentifier 作为主键，不依赖 email
  /// Apple 首次登录返回 email，后续返回 relay email 或不返回
  /// 返回 null 表示用户取消，throw Exception 表示技术错误
  static Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 使用 userIdentifier (稳定) 而不是 email (不稳定)
      final result = await ApiClient.post(ApiClient.authUrl, {
        'action': 'apple_sign_in',
        'apple_user_id': credential.userIdentifier,  // 主键
        'id_token': credential.identityToken,
        'email': credential.email,  // 可能为 null
        'given_name': credential.givenName,  // 可能为 null
        'family_name': credential.familyName,  // 可能为 null
      });

      _currentUserId = result['user_id'];
      _currentToken = result['token'];
      _loginType = 'registered';
      AppEventBus.instance.fire(LoginStatusChangedEvent());
      await _saveSession();
      SubscriptionService.instance.updateFromServer(result);
      syncAIDisclosure(); // fire-and-forget
      return result;
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled authorization
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[AUTH] Apple Sign-In cancelled by user');
        return null;
      }
      debugPrint('[AUTH] Apple Sign-In authorization error: $e');
      rethrow;
    } catch (e) {
      debugPrint('[AUTH] Apple Sign-In failed: $e');
      rethrow;
    }
  }

  /// 获取用户资料
  static Future<Map<String, dynamic>> getProfile() async {
    return ApiClient.post(ApiClient.authUrl, {
      'action': 'get_profile',
      'user_id': _currentUserId,
    });
  }

  /// 更新用户资料
  static Future<void> updateProfile(Map<String, dynamic> fields) async {
    await ApiClient.post(ApiClient.authUrl, {
      'action': 'update_profile',
      'user_id': _currentUserId,
      ...fields,
    });
  }

  /// 恢复 session（App 启动时调用）
  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentToken = prefs.getString('auth_token');
    _currentUserId = prefs.getString('user_id');
    _loginType = prefs.getString('login_type');
    if (_currentToken == null) return false;

    try {
      final result = await ApiClient.post(ApiClient.authUrl, {
        'action': 'verify',
        'token': _currentToken,
      });
      return result['valid'] == true;
    } catch (e) {
      _currentToken = null;
      _currentUserId = null;
      return false;
    }
  }

  /// 退出登录
  static Future<void> logout() async {
    _currentToken = null;
    _currentUserId = null;
    _loginType = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('login_type');
  }

  static Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentToken != null) await prefs.setString('auth_token', _currentToken!);
    if (_currentUserId != null) await prefs.setString('user_id', _currentUserId!);
    if (_loginType != null) await prefs.setString('login_type', _loginType!);
  }

  /// 登录/注册成功后，把本地 AI disclosure 状态同步到注册用户（fire-and-forget）
  static Future<void> syncAIDisclosure() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('ai_disclosure_shown') ?? false;
      if (!shown || _currentUserId == null) return;

      // 检查是否已为当前用户同步过，避免重复调用后端
      final syncKey = 'ai_disclosure_synced_$_currentUserId';
      if (prefs.getBool(syncKey) == true) return;

      await ApiClient.post(ApiClient.authUrl, {
        'action': 'mark_ai_disclosure_shown',
        'user_id': _currentUserId,
      });

      // 标记已同步
      await prefs.setBool(syncKey, true);
      debugPrint('[AUTH] AI disclosure synced to user: $_currentUserId');
    } catch (e) {
      debugPrint('[AUTH] AI disclosure sync failed (non-blocking): $e');
    }
  }
}
