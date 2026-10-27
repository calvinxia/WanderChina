/// Session 恢复结果。调用方通过此枚举区分"已验证"和"离线保留"两种成功路径。
enum SessionRestoreResult {
  verified, // 后端确认有效，订阅状态已更新
  offline,  // 网络不通/超时，凭据保留，以离线态继续
  notFound, // prefs 中无 token（首次启动或已主动登出）
  invalid,  // 后端明确拒绝（valid:false / 401），凭据已清空
}

class AuthState {
  final String? userId;
  final String? token;
  final String? loginType; // 'anonymous' | 'registered'

  const AuthState({this.userId, this.token, this.loginType});

  bool get isLoggedIn => token != null;
  bool get isRegistered => loginType == 'registered';
  bool get isAnonymous => loginType == 'anonymous';
}
