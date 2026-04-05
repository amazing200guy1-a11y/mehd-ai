import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/screens/home_screen.dart';
import 'package:provider/provider.dart';

/// FILE — auth_screen.dart
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLogin = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleError(String? error) {
    if (error == null) return;
    String displayError = error;
    if (error.toLowerCase().contains("password") || error.toLowerCase().contains("credential")) {
      displayError = "⚠ Invalid credentials.";
    } else if (error.toLowerCase().contains("network") || error.toLowerCase().contains("connection")) {
      displayError = "⚠ Connection lost. Try again.";
    }
    setState(() => _errorMsg = displayError);
  }

  Future<void> _handleAuth() async {
    setState(() => _errorMsg = null);
    
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() => _errorMsg = "Please fill in all fields.");
      return;
    }

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    
    String? error;
    if (_isLogin) {
      error = await authService.signInWithEmail(_emailController.text, _passwordController.text);
    } else {
      final name = _emailController.text.split('@').first;
      error = await authService.signUpWithEmail(_emailController.text, _passwordController.text, name);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _handleError(error);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() { _errorMsg = null; _isLoading = true; });
    final authService = context.read<AuthService>();
    final error = await authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _handleError(error);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Enter your email first, then tap forgot password.');
      return;
    }
    final authService = context.read<AuthService>();
    final error = await authService.resetPassword(_emailController.text);
    if (!mounted) return;

    if (error != null) {
      _handleError(error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFFFB300), // Amber
          content: Text('Password reset email sent. Check your inbox.', style: TextStyle(color: Colors.black)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Tiger watermark background
          Center(
            child: Opacity(
              opacity: 0.04,
              child: MehdLogo(size: 300),
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Tiger logo — visible
                  MehdLogo(size: 80),
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text(
                    'THE DEN',
                    style: TextStyle(
                      color: Color(0xFF58A6FF),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (_errorMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        _errorMsg!,
                        style: TextStyle(
                          color: _errorMsg!.contains("Connection") ? const Color(0xFFFF3B3B) : const Color(0xFFD29922),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // EMAIL FIELD
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      labelStyle: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 12),
                      hintText: 'trader@example.com',
                      hintStyle: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF1A1A1A),
                          width: 1),
                        borderRadius: BorderRadius.circular(4)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF58A6FF),
                          width: 1.5),
                        borderRadius: BorderRadius.circular(4)),
                      filled: true,
                      fillColor: const Color(0xFF080808),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // PASSWORD FIELD
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF1A1A1A),
                          width: 1),
                        borderRadius: BorderRadius.circular(4)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF58A6FF),
                          width: 1.5),
                        borderRadius: BorderRadius.circular(4)),
                      filled: true,
                      fillColor: const Color(0xFF080808),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                          color: const Color(0xFF444444),
                          size: 18),
                        onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 11)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // SIGN IN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF020810),
                        side: const BorderSide(
                          color: Color(0xFF58A6FF),
                          width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      ),
                      child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF58A6FF)))
                        : const Text(
                            'ENTER THE DEN',
                            style: TextStyle(
                              color: Color(0xFF58A6FF),
                              fontSize: 13,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Divider
                  const Row(children: [
                    Expanded(child: Divider(color: Color(0xFF111111))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 11))),
                    Expanded(child: Divider(color: Color(0xFF111111))),
                  ]),
                  const SizedBox(height: 16),
                  
                  // GOOGLE SIGN IN
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF1A1A1A),
                          width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      ),
                      icon: const Text('G',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Create account
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMsg = null;
                      });
                    },
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: _isLogin ? 'New to Mehd AI? ' : 'Already have an account? ',
                          style: const TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 12)),
                        TextSpan(
                          text: _isLogin ? 'Create account' : 'Sign in',
                          style: const TextStyle(
                            color: Color(0xFF58A6FF),
                            fontSize: 12,
                            decoration: TextDecoration.underline)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MehdLogo extends StatelessWidget {
  final double size;
  const MehdLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mehd_logo.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Center(
        child: Text('🐯', style: TextStyle(fontSize: size * 0.6)),
      ),
    );
  }
}

