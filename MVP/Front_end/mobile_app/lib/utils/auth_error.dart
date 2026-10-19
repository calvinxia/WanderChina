import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';

/// 认证操作的统一错误文案。
///
/// [isCredentialError] 传 true 时将 HTTP 401 映射为凭据错误文案（仅邮箱登录场景）。
/// 验证码类 400 由调用方先行拦截，不经过本函数。
String authErrorMessage(Object e, {bool isCredentialError = false}) {
  if (e is SocketException || e is http.ClientException) {
    return "Can't connect. Please check your internet connection and try again.";
  }
  if (e is TimeoutException || (e is ApiException && e.statusCode >= 500)) {
    return 'Service temporarily unavailable. Please try again later.';
  }
  if (e is ApiException) {
    if (e.statusCode == 429) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (e.statusCode == 401 && isCredentialError) {
      return 'Login failed. Please check your email and password.';
    }
  }
  return 'Something went wrong. Please try again.';
}
