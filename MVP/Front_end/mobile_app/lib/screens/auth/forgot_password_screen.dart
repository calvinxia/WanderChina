import 'package:flutter/material.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Call AuthService.forgotPassword() when backend is ready
      // For now, simulate a delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: email),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔐 Forgot password error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to send reset code. Please try again.';
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(height: 40),

                  // Header
                  const Text(
                    'Forgot Password',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email to receive a verification code',
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
                  ),

                  const SizedBox(height: 40),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _sendResetCode(),
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

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
                  ],

                  const SizedBox(height: 24),

                  // Send Code button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8D5B0),
                        foregroundColor: const Color(0xFF16162A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF16162A), strokeWidth: 2))
                          : const Text('Send Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),

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
