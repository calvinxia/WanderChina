import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/analytics_service.dart';
import '../services/api_client.dart';
import '../services/app_event_bus.dart';
import 'auth_state.dart';
import 'subscription_notifier.dart';

class AuthNotifier extends Notifier<AuthState> {
  // Google Sign-In 实例（serverClientId 用 Web Client，以便后端验证 id_token）
  // 类级字段，不属于 AuthState，provider 生命周期内复用
  static final _googleSignIn = GoogleSignIn(
    serverClientId: '641720570444-ilmrpkcu3161kmh59jbk2algc1h4p9dq.apps.googleusercontent.com',
    scopes: ['email', 'profile', 'openid'],
  );

  @override
  AuthState build() => const AuthState();

  /// 匿名认证（App 首次启动时调用）
  Future<bool> anonymousAuth(String deviceId, {String lang = 'en'}) async {
    try {
      final result = await ApiClient.post(ApiClient.authUrl, {
        'action': 'anonymous_auth',
        'device_id': deviceId,
        'preferred_lang': lang,
      });
      state = AuthState(
        userId: result['user_id'] as String?,
        token: result['token'] as String?,
        loginType: 'anonymous',
      );
      if (state.userId != null) AnalyticsService.instance.setUser(state.userId!);
      await _saveSession();
      ApiClient.resetSessionExpiry();
      return true;
    } catch (e) {
      debugPrint('[AUTH] Anonymous auth failed: $e');
      return false;
    }
  }

  /// 邮箱注册第一步：发送验证码（不重试，重试会使第一封邮件失效）
  Future<void> registerStart({required String email}) async {
    await ApiClient.post(ApiClient.authUrl, {
      'action': 'register_start',
      'email': email,
    });
  }

  /// 邮箱注册第二步：验证码 + 密码（不重试，已消耗的验证码重试会误报无效）
  Future<Map<String, dynamic>> registerVerify({
    required String email,
    required String code,
    required String password,
    String? deviceId,
    String? username,
  }) async {
    final result = await ApiClient.post(ApiClient.authUrl, {
      'action': 'register_verify',
      'email': email,
      'code': code,
      'password': password,
      if (deviceId != null) 'device_id': deviceId,
      if (username != null) 'username': username,
    });
    state = AuthState(
      userId: result['user_id'] as String?,
      token: result['token'] as String?,
      loginType: 'registered',
    );
    if (state.userId != null) AnalyticsService.instance.setUser(state.userId!);
    await _saveSession();
    ref.read(subscriptionProvider.notifier).updateFromServer(result);
    syncAIDisclosure(); // fire-and-forget
    ApiClient.resetSessionExpiry();
    AppEventBus.instance.fire(LoginStatusChangedEvent());
    return result;
  }

  /// 邮箱登录（依赖 2.4 幂等，开启 5xx 重试）
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id');
    final result = await ApiClient.post(
      ApiClient.authUrl,
      {
        'action': 'login',
        'email': email,
        'password': password,
        if (deviceId != null) 'device_id': deviceId,
      },
      retry5xx: true,
    );
    state = AuthState(
      userId: result['user_id'] as String?,
      token: result['token'] as String?,
      loginType: 'registered',
    );
    if (state.userId != null) AnalyticsService.instance.setUser(state.userId!);
    await _saveSession();
    ref.read(subscriptionProvider.notifier).updateFromServer(result);
    syncAIDisclosure(); // fire-and-forget
    ApiClient.resetSessionExpiry();
    AppEventBus.instance.fire(LoginStatusChangedEvent());
    return result;
  }

  /// Apple Sign-In 登录（依赖 2.4 幂等，开启 5xx 重试）
  ///
  /// 返回 null 表示用户取消，throw Exception 表示技术错误
  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id');

      final result = await ApiClient.post(
        ApiClient.authUrl,
        {
          'action': 'apple_sign_in',
          'apple_user_id': credential.userIdentifier,
          'id_token': credential.identityToken,
          'email': credential.email,
          'given_name': credential.givenName,
          'family_name': credential.familyName,
          if (deviceId != null) 'device_id': deviceId,
        },
        retry5xx: true,
      );
      state = AuthState(
        userId: result['user_id'] as String?,
        token: result['token'] as String?,
        loginType: 'registered',
      );
      if (state.userId != null) AnalyticsService.instance.setUser(state.userId!);
      await _saveSession();
      ref.read(subscriptionProvider.notifier).updateFromServer(result);
      syncAIDisclosure(); // fire-and-forget
      ApiClient.resetSessionExpiry();
      AppEventBus.instance.fire(LoginStatusChangedEvent());
      return result;
    } on SignInWithAppleAuthorizationException catch (e) {
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

  /// Google Sign-In 登录（依赖 2.4 幂等，开启 5xx 重试）
  ///
  /// 返回 null 表示用户取消，throw Exception 表示技术错误
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AUTH] Google Sign-In cancelled by user');
        return null;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        debugPrint('[AUTH] Google Sign-In: idToken is null');
        throw Exception('Google Sign-In failed: no id token returned');
      }

      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id');

      final result = await ApiClient.post(
        ApiClient.authUrl,
        {
          'action': 'google_sign_in',
          'id_token': idToken,
          'email': googleUser.email,
          'display_name': googleUser.displayName,
          if (deviceId != null) 'device_id': deviceId,
        },
        retry5xx: true,
      );
      state = AuthState(
        userId: result['user_id'] as String?,
        token: result['token'] as String?,
        loginType: 'registered',
      );
      if (state.userId != null) AnalyticsService.instance.setUser(state.userId!);
      await _saveSession();
      ref.read(subscriptionProvider.notifier).updateFromServer(result);
      syncAIDisclosure(); // fire-and-forget
      ApiClient.resetSessionExpiry();
      AppEventBus.instance.fire(LoginStatusChangedEvent());
      return result;
    } catch (e) {
      debugPrint('[AUTH] Google Sign-In failed: $e');
      rethrow;
    }
  }

  /// 发送密码重置验证码
  Future<void> forgotPassword(String email) async {
    await ApiClient.post(ApiClient.authUrl, {
      'action': 'forgot_password',
      'email': email,
    });
  }

  /// 重置密码（token 为后端发送的 6 位验证码）
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await ApiClient.post(ApiClient.authUrl, {
      'action': 'reset_password',
      'email': email,
      'token': token,
      'new_password': newPassword,
    });
  }

  /// 获取用户资料
  Future<Map<String, dynamic>> getProfile() async {
    return ApiClient.post(ApiClient.authUrl, {
      'action': 'get_profile',
      'user_id': state.userId,
    });
  }

  /// 更新用户资料
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    await ApiClient.post(ApiClient.authUrl, {
      'action': 'update_profile',
      'user_id': state.userId,
      ...fields,
    });
  }

  /// 恢复 session（App 启动时由 SplashScreen 调用，开启 5xx 重试）
  Future<SessionRestoreResult> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');
    final loginType = prefs.getString('login_type');

    state = AuthState(userId: userId, token: token, loginType: loginType);
    if (token == null) return SessionRestoreResult.notFound;

    try {
      final result = await ApiClient.post(
        ApiClient.authUrl,
        {'action': 'restore_session', 'token': token},
        handle401: false, // restore_session 内部自行处理 401，不触发全局失效流程
        retry5xx: true,
      );
      if (result['user_id'] != null) {
        final verifiedUserId = (result['user_id'] as String?) ?? userId;
        state = AuthState(userId: verifiedUserId, token: token, loginType: loginType);
        ref.read(subscriptionProvider.notifier).updateFromServer(result);
        ApiClient.resetSessionExpiry();
        if (verifiedUserId != null) AnalyticsService.instance.setUser(verifiedUserId);
        return SessionRestoreResult.verified;
      }
      // 后端明确返回 valid: false — token 已失效，清空全部凭据
      state = const AuthState();
      AnalyticsService.instance.clearUser();
      return SessionRestoreResult.invalid;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // HTTP 401 — 后端明确拒绝，清空全部凭据
        state = const AuthState();
        AnalyticsService.instance.clearUser();
        return SessionRestoreResult.invalid;
      }
      // 5xx 或其他服务端错误 — 无法判断有效性，保留凭据以离线态继续
      if (userId != null) AnalyticsService.instance.setUser(userId);
      return SessionRestoreResult.offline;
    } catch (e) {
      // TimeoutException / SocketException 等网络异常 — 保留凭据
      if (userId != null) AnalyticsService.instance.setUser(userId);
      return SessionRestoreResult.offline;
    }
  }

  /// 退出登录（不清除订阅状态 — 行为约束 #6）
  Future<void> logout() async {
    state = const AuthState();
    AnalyticsService.instance.clearUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('login_type');
  }

  /// 登录/注册成功后，把本地 AI disclosure 状态同步到注册用户（fire-and-forget）
  Future<void> syncAIDisclosure() async {
    final userId = state.userId; // snapshot，防止异步期间 state 变化
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('ai_disclosure_shown') ?? false;
      if (!shown || userId == null) return;

      final syncKey = 'ai_disclosure_synced_$userId';
      if (prefs.getBool(syncKey) == true) return;

      await ApiClient.post(ApiClient.authUrl, {
        'action': 'mark_ai_disclosure_shown',
        'user_id': userId,
      });
      await prefs.setBool(syncKey, true);
      debugPrint('[AUTH] AI disclosure synced to user: $userId');
    } catch (e) {
      debugPrint('[AUTH] AI disclosure sync failed (non-blocking): $e');
    }
  }

  Future<void> _saveSession() async {
    final s = state; // snapshot，防止异步写入期间 state 被再次更新
    final prefs = await SharedPreferences.getInstance();
    if (s.token != null) await prefs.setString('auth_token', s.token!);
    if (s.userId != null) await prefs.setString('user_id', s.userId!);
    if (s.loginType != null) await prefs.setString('login_type', s.loginType!);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
