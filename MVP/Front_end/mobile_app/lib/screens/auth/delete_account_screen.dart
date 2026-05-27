import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../services/backend/auth_service.dart';
import '../../services/api_client.dart';
import '../onboarding/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Delete Account Screen with Multi-Factor Identity Verification
///
/// User Types:
/// - Email users: Password verification
/// - Apple OAuth users: Re-authenticate with Apple
/// - Hybrid accounts: Any verification method (password priority)
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // User verification options
  bool _hasEmail = false;
  bool _hasApple = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'account',
        message: 'delete_account_screen_opened',
      ));

      final profile = await AuthService.getProfile();

      if (mounted) {
        setState(() {
          _userEmail = profile['email'];
          _hasEmail = profile['email'] != null && profile['email'].toString().isNotEmpty;
          _hasApple = profile['has_apple_login'] == true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load profile error: $e');
      await Sentry.captureException(e, stackTrace: StackTrace.current);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = (e is SocketException || e.toString().contains('host lookup'))
              ? 'No internet connection. Please check your network and try again.'
              : 'Failed to load account information.';
        });
      }
    }
  }

  Future<void> _verifyWithPassword() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'account',
        message: 'delete_account_password_verification_attempt',
      ));

      // Verify password by attempting login
      await AuthService.login(email: _userEmail!, password: password);

      // If login succeeds, proceed to delete
      await _deleteAccount('password');
    } catch (e) {
      debugPrint('🔐 Password verification failed: $e');
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'account',
        message: 'delete_account_password_verification_failed',
        data: {'error': e.toString()},
      ));

      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = (e is SocketException || e.toString().contains('host lookup'))
              ? 'No internet connection. Account deletion requires network.'
              : 'Incorrect password. Please try again.';
        });
      }
    }
  }

  Future<void> _verifyWithApple() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'account',
        message: 'delete_account_apple_verification_attempt',
      ));

      final result = await AuthService.signInWithApple();

      // User cancelled
      if (result == null) {
        if (mounted) setState(() => _isDeleting = false);
        return;
      }

      // Verify userIdentifier matches
      // TODO: Compare result['apple_user_id'] with stored apple_user_id
      await _deleteAccount('apple');
    } catch (e) {
      debugPrint('🔐 Apple verification failed: $e');
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'account',
        message: 'delete_account_apple_verification_failed',
        data: {'error': e.toString()},
      ));
      await Sentry.captureException(e, stackTrace: StackTrace.current);

      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'Apple verification failed. Please try again.';
        });
      }
    }
  }

  Future<void> _deleteAccount(String verificationMethod) async {
    try {
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'account',
        message: 'delete_account_request',
        data: {'verification_method': verificationMethod},
      ));

      final userId = AuthService.currentUserId;
      await ApiClient.post(ApiClient.authUrl, {
        'action': 'delete_account',
        'user_id': userId,
      });

      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'account',
        message: 'delete_account_success',
      ));

      // Clear session
      await AuthService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Delete account failed: $e');
      await Sentry.addBreadcrumb(Breadcrumb(
        category: 'account',
        message: 'delete_account_failed',
        data: {'error': e.toString()},
      ));
      await Sentry.captureException(e, stackTrace: StackTrace.current);

      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = (e is SocketException || e.toString().contains('host lookup'))
              ? 'No internet connection. Account deletion requires network.'
              : 'Failed to delete account. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
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
                          'Delete Account',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please verify your identity to continue',
                          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
                        ),

                        const SizedBox(height: 32),

                        // Warning Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'This action is permanent',
                                      style: TextStyle(
                                        color: Color(0xFFFF6B6B),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'All your data will be permanently deleted:\n'
                                      '• Trip plans and itineraries\n'
                                      '• Saved places and favorites\n'
                                      '• Translation history\n'
                                      '• Profile and account settings',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Verification Section
                        Text(
                          'Verify your identity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email + Password Verification
                        if (_hasEmail) ...[
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _verifyWithPassword(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Enter your password',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.6)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white.withOpacity(0.6),
                                ),
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
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Delete button (for password verification)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isDeleting ? null : _verifyWithPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isDeleting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Permanently Delete My Account',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ],

                        // OAuth Verification (if no email or as alternative)
                        if (_hasApple && _hasEmail) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or verify with',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Apple verification button
                        if (_hasApple) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _isDeleting ? null : _verifyWithApple,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white.withOpacity(0.8),
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Verify with Apple', style: TextStyle(fontSize: 15)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // OAuth-only users (no email)
                        if (!_hasEmail && _hasApple) ...[
                          Text(
                            'Re-authenticate to delete your account',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
