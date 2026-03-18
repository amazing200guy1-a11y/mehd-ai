import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/screens/auth/register_screen.dart';
import 'package:mehd_ai_flutter/screens/onboarding/broker_connect_screen.dart';
import 'package:provider/provider.dart';

/// FILE 5a — login_screen.dart
///
/// Build Debrief:
/// Clean, minimal login screen matching the IDE dark theme. Monospace font on
/// input fields reinforces the "terminal" vibe. Inline error messages appear
/// directly under the field that caused the error — much better UX than a
/// generic toast. The loading spinner replaces the button text during auth
/// to prevent double-taps.


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final error = await authService.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() {
        if (error.toLowerCase().contains('email')) {
          _emailError = error;
        } else if (error.toLowerCase().contains('password')) {
          _passwordError = error;
        } else {
          _generalError = error;
        }
      });
    } else {
      // Navigate to onboarding or home based on profile state
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BrokerConnectScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _generalError = null;
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    final error = await authService.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _generalError = error);
    } else {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BrokerConnectScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = 'Enter your email first, then tap forgot password.');
      return;
    }

    final authService = context.read<AuthService>();
    final error = await authService.resetPassword(_emailController.text);

    if (!mounted) return;

    if (error != null) {
      setState(() => _emailError = error);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: MehdAiTheme.green,
            content: Text(
              'Password reset email sent. Check your inbox.',
              style: MehdAiTheme.terminalStyle.copyWith(color: Colors.black),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MehdAiTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── HEADER ──────────────────────────────────
                Text(
                  'Welcome back',
                  style: MehdAiTheme.headingStyle.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your trading terminal',
                  style: MehdAiTheme.labelStyle.copyWith(fontSize: 14),
                ),

                const SizedBox(height: 40),

                // ── GENERAL ERROR ───────────────────────────
                if (_generalError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MehdAiTheme.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MehdAiTheme.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _generalError!,
                      style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── EMAIL FIELD ─────────────────────────────
                _buildLabel('EMAIL'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: MehdAiTheme.terminalStyle.copyWith(fontSize: 14),
                  decoration: _inputDecoration('trader@example.com'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                if (_emailError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_emailError!,
                        style: MehdAiTheme.labelStyle
                            .copyWith(color: MehdAiTheme.red, fontSize: 12)),
                  ),

                const SizedBox(height: 20),

                // ── PASSWORD FIELD ──────────────────────────
                _buildLabel('PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: MehdAiTheme.terminalStyle.copyWith(fontSize: 14),
                  decoration: _inputDecoration('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: MehdAiTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                if (_passwordError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_passwordError!,
                        style: MehdAiTheme.labelStyle
                            .copyWith(color: MehdAiTheme.red, fontSize: 12)),
                  ),

                // ── FORGOT PASSWORD ─────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: MehdAiTheme.labelStyle.copyWith(
                        color: MehdAiTheme.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── SIGN IN BUTTON ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MehdAiTheme.green,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: MehdAiTheme.green.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: MehdAiTheme.headingStyle.copyWith(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── DIVIDER ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: MehdAiTheme.borderColor.withOpacity(0.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR',
                          style: MehdAiTheme.labelStyle.copyWith(fontSize: 11)),
                    ),
                    Expanded(
                      child: Divider(color: MehdAiTheme.borderColor.withOpacity(0.5)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── GOOGLE SIGN IN ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata,
                        size: 28, color: MehdAiTheme.textPrimary),
                    label: Text(
                      'Sign in with Google',
                      style: MehdAiTheme.headingStyle.copyWith(
                        fontSize: 14,
                        color: MehdAiTheme.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: MehdAiTheme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── REGISTER LINK ───────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: MehdAiTheme.labelStyle.copyWith(fontSize: 13),
                        children: const [
                          TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Create one',
                            style: TextStyle(color: MehdAiTheme.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: MehdAiTheme.labelStyle.copyWith(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: MehdAiTheme.terminalStyle.copyWith(
        color: MehdAiTheme.textSecondary.withOpacity(0.4),
        fontSize: 14,
      ),
      filled: true,
      fillColor: MehdAiTheme.bgSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: MehdAiTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: MehdAiTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: MehdAiTheme.blue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
