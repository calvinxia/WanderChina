import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/backend/auth_service.dart';
import '../../utils/auth_error.dart';
import '../../utils/device_utils.dart';
import '../main/main_screen.dart';

/// 邮箱验证码输入页（两步注册第二步）
///
/// 由 SignupScreen 在调用 register_start 成功后推入。
/// 成功后：fromSoftLogin=true 时 pop(true)；否则 pushAndRemoveUntil 到 MainScreen。
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String password;
  final String? username;
  final bool fromSoftLogin;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.password,
    this.username,
    this.fromSoftLogin = false,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCooldown > 1) {
          _resendCooldown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resend() async {
    if (!_canResend || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.registerStart(email: widget.email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        _startCooldown();
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = authErrorMessage(e);
        });
      }
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await getOrCreateDeviceId(prefs);

      await AuthService.registerVerify(
        email: widget.email,
        code: code,
        password: widget.password,
        deviceId: deviceId,
        username: widget.username,
      );

      if (mounted) {
        if (widget.fromSoftLogin) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainScreen(key: MainScreen.globalKey)),
            (route) => false,
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('🔐 Register verify error: $e');
      Sentry.captureException(e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = (e is ApiException && e.statusCode == 400)
              ? 'Invalid or expired code. Please try again.'
              : authErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFF2A2A4A),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D0D1A),
                  Color(0xFF1A1A35),
                  Color(0xFF2A2A4A),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Verify Your Email',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Code sent to ${widget.email}',
                      style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 16),

                    // 固定文案（规格 4.2.1）
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Text(
                        'Verification code sent to your inbox. If this email was previously registered, we\'ll remind you to sign in directly.',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 验证码输入框
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _verify(),
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 10),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '——————',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 24),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE8D5B0), width: 2),
                        ),
                        counterStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
                    ],

                    const SizedBox(height: 24),

                    // 提交按钮
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8D5B0),
                          foregroundColor: const Color(0xFF16162A),
                          disabledBackgroundColor: const Color(0xFFE8D5B0).withOpacity(0.4),
                          disabledForegroundColor: const Color(0xFF16162A).withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Color(0xFF16162A), strokeWidth: 2),
                              )
                            : const Text(
                                'Verify & Create Account',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 重新发送（带冷却）
                    Center(
                      child: _canResend
                          ? TextButton(
                              onPressed: _isLoading ? null : _resend,
                              child: const Text(
                                'Resend Code',
                                style: TextStyle(color: Color(0xFFE8D5B0), fontSize: 14),
                              ),
                            )
                          : Text(
                              'Resend in ${_resendCooldown}s',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
