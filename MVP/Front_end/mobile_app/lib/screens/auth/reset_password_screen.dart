import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    if (code.length != 6) {
      setState(() => _errorMessage = 'Verification code must be 6 digits');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Call AuthService.resetPassword() when backend is ready
      // For now, simulate a delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Show success and pop back to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('🔐 Reset password error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to reset password. Please check your code and try again.';
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
                    'Reset Password',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the verification code sent to ${widget.email}',
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
                  ),

                  const SizedBox(height: 40),

                  // Verification Code
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      counterText: '',
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

                  // New Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'New Password',
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _resetPassword(),
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
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
                  ],

                  const SizedBox(height: 24),

                  // Reset Password button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8D5B0),
                        foregroundColor: const Color(0xFF16162A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF16162A), strokeWidth: 2))
                          : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
