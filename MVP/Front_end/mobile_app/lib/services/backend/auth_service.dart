import '../../providers/app_container.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/auth_state.dart';

// re-export 使现有调用方无需修改导入路径
export '../../providers/auth_state.dart' show SessionRestoreResult;

/// 薄门面层 —— 签名与调用约定不变，内部转发到 AuthNotifier。
/// 调用代码（SplashScreen、各登录屏、BackendManager 等）无需修改。
class AuthService {
  static String? get currentUserId => appContainer.read(authProvider).userId;
  static bool get isLoggedIn => appContainer.read(authProvider).isLoggedIn;
  static bool get isRegistered => appContainer.read(authProvider).isRegistered;
  static bool get isAnonymous => appContainer.read(authProvider).isAnonymous;

  static Future<bool> anonymousAuth(String deviceId, {String lang = 'en'}) =>
      appContainer.read(authProvider.notifier).anonymousAuth(deviceId, lang: lang);

  static Future<void> registerStart({required String email}) =>
      appContainer.read(authProvider.notifier).registerStart(email: email);

  static Future<Map<String, dynamic>> registerVerify({
    required String email,
    required String code,
    required String password,
    String? deviceId,
    String? username,
  }) =>
      appContainer.read(authProvider.notifier).registerVerify(
        email: email,
        code: code,
        password: password,
        deviceId: deviceId,
        username: username,
      );

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) =>
      appContainer.read(authProvider.notifier).login(email: email, password: password);

  static Future<Map<String, dynamic>?> signInWithApple() =>
      appContainer.read(authProvider.notifier).signInWithApple();

  static Future<Map<String, dynamic>?> signInWithGoogle() =>
      appContainer.read(authProvider.notifier).signInWithGoogle();

  static Future<void> forgotPassword(String email) =>
      appContainer.read(authProvider.notifier).forgotPassword(email);

  static Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) =>
      appContainer.read(authProvider.notifier).resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );

  static Future<Map<String, dynamic>> getProfile() =>
      appContainer.read(authProvider.notifier).getProfile();

  static Future<void> updateProfile(Map<String, dynamic> fields) =>
      appContainer.read(authProvider.notifier).updateProfile(fields);

  static Future<SessionRestoreResult> restoreSession() =>
      appContainer.read(authProvider.notifier).restoreSession();

  static Future<void> logout() =>
      appContainer.read(authProvider.notifier).logout();

  static Future<void> syncAIDisclosure() =>
      appContainer.read(authProvider.notifier).syncAIDisclosure();
}
