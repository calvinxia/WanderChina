import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/backend/auth_service.dart';
import '../main/main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String? _errorMessage;
  String? _confirmPasswordError;

  late final TapGestureRecognizer _privacyTapRecognizer;
  late final TapGestureRecognizer _termsTapRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyTapRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(
            Uri.parse('https://wanderchina.app/privacy'),
            mode: LaunchMode.externalApplication,
          );
    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(
            Uri.parse('https://wanderchina.app/terms'),
            mode: LaunchMode.externalApplication,
          );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _privacyTapRecognizer.dispose();
    _termsTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
        _errorMessage = null;
      });
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please agree to the Privacy Policy and Terms of Service');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _confirmPasswordError = null;
    });

    try {
      await AuthService.register(
        email: email,
        password: password,
        username: name,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainScreen(key: MainScreen.globalKey)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('🔐 Register error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Registration failed: $e';
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'auth',
        message: 'apple_sign_in_attempt',
      ));

      final result = await AuthService.signInWithApple();

      // User cancelled - silent return
      if (result == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainScreen(key: MainScreen.globalKey)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('🔐 Apple Sign-In error: $e');
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'auth',
        message: 'apple_sign_in_failed',
        data: {'error': e.toString()},
      ));
      await Sentry.captureException(e, stackTrace: StackTrace.current);

      if (mounted) {
        setState(() => _isLoading = false);
        _showVpnAwareErrorDialog(
          title: 'Sign in failed',
          body: 'If you\'re in mainland China:\n'
                '• Make sure your VPN is on\n'
                '• Try Smart Mode or Split Tunnel\n'
                '• Or use Email sign-up instead',
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'auth',
        message: 'google_sign_in_attempt',
      ));

      final result = await AuthService.signInWithGoogle();

      // User cancelled - silent return
      if (result == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainScreen(key: MainScreen.globalKey)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('🔐 Google Sign-In error: $e');
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'auth',
        message: 'google_sign_in_failed',
        data: {'error': e.toString()},
      ));
      await Sentry.captureException(e, stackTrace: StackTrace.current);

      if (mounted) {
        setState(() => _isLoading = false);
        _showVpnAwareErrorDialog(
          title: 'Sign in failed',
          body: 'If you\'re in mainland China:\n'
                '• Make sure your VPN is on\n'
                '• Try Smart Mode or Split Tunnel\n'
                '• Or use Email sign-up instead',
        );
      }
    }
  }

  void _showVpnAwareErrorDialog({required String title, required String body}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                  // 自定义返回按钮（替代 AppBar）
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your China adventure',
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
                  ),

                  const SizedBox(height: 32),

                  // Name
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.6)),
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.6)),
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.6)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white.withOpacity(0.6)),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
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
                      helperText: 'At least 8 characters',
                      helperStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signup(),
                    onChanged: (val) {
                      if (val.isNotEmpty && val != _passwordController.text) {
                        if (_confirmPasswordError == null) {
                          setState(() => _confirmPasswordError = 'Passwords do not match');
                        }
                      } else if (_confirmPasswordError != null) {
                        setState(() => _confirmPasswordError = null);
                      }
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.6)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white.withOpacity(0.6)),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
                      ),
                      errorText: _confirmPasswordError,
                      errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
                    ),
                  ),

                  // General error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
                  ],

                  const SizedBox(height: 20),

                  // Terms of Service & Privacy Policy agreement
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                        activeColor: const Color(0xFFE8D5B0),
                        checkColor: const Color(0xFF16162A),
                        side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: Color(0xFFE8D5B0),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFFE8D5B0),
                                ),
                                recognizer: _privacyTapRecognizer,
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  color: Color(0xFFE8D5B0),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFFE8D5B0),
                                ),
                                recognizer: _termsTapRecognizer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Register button — disabled until terms are accepted
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_agreedToTerms) ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8D5B0),
                        foregroundColor: const Color(0xFF16162A),
                        disabledBackgroundColor: const Color(0xFFE8D5B0).withOpacity(0.4),
                        disabledForegroundColor: const Color(0xFF16162A).withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF16162A), strokeWidth: 2))
                          : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Apple Sign-In (iOS only)
                  if (Platform.isIOS) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithApple,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.8),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Image.asset(
                          'assets/icons/oauth/apple_logo_white.png',
                          width: 20,
                          height: 20,
                        ),
                        label: const Text('Continue with Apple', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                  // Google Sign-In (Android only)
                  if (Platform.isAndroid) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F1F1F),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFDADCE0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Image.asset(
                          'assets/icons/oauth/google_logo.png',
                          width: 20,
                          height: 20,
                        ),
                        label: const Text('Continue with Google', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(color: Color(0xFFE8D5B0), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
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
