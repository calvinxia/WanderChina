// lib/services/backend/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';

class AuthService {
  static String? _currentUserId;
  static String? _currentToken;

  static String? get currentUserId => _currentUserId;
  static bool get isLoggedIn => _currentToken != null;

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
      await _saveSession();
      return true;
    } catch (e) {
      print('[AUTH] Anonymous auth failed: $e');
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
    await _saveSession();
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
    await _saveSession();
    return result;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  static Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentToken != null) await prefs.setString('auth_token', _currentToken!);
    if (_currentUserId != null) await prefs.setString('user_id', _currentUserId!);
  }
}
