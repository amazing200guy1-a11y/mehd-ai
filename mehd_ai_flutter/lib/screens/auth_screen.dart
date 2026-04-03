import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLogin = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleError(String? error) {
    if (error == null) return;
    String displayError = error;
    if (error.toLowerCase().contains("password") || error.toLowerCase().contains("credential")) {
      displayError = "Invalid credentials.\nThe Den does not recognize you.";
    } else if (error.toLowerCase().contains("network") || error.toLowerCase().contains("connection")) {
      displayError = "Connection lost.\nCheck your internet.";
    }
    setState(() => _errorMsg = displayError);
  }

  Future<void> _handleAuth() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isLogin && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMsg = "Passwords do not match.\nThe Den requires exactness.");
      return;
    }

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    
    String? error;
    if (_isLogin) {
      error = await authService.signInWithEmail(_emailController.text, _passwordController.text);
    } else {
      final name = _nameController.text.isNotEmpty ? _nameController.text : _emailController.text.split('@').first;
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
        SnackBar(
          backgroundColor: const Color(0xFFFFB300), // Amber
          content: Text('Password reset email sent. Check your inbox.', style: GoogleFonts.jetBrainsMono(color: Colors.black)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black
      body: Stack(
        children: [
          // Tiger watermark at 5% opacity
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/mehd_logo.png',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top: Small tiger logo
                      Image.asset('assets/images/mehd_logo.png', width: 60, height: 60),
                      const SizedBox(height: 24),
                      // Title: "THE DEN"
                      Text(
                        'THE DEN',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF58A6FF),
                          letterSpacing: 6.0,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        _isLogin ? 'Sign in to continue' : 'Create an account',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF555555),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 48),

                      if (_errorMsg != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300).withOpacity(0.1),
                            border: Border.all(color: const Color(0xFFFFB300)),
                          ),
                          child: Text(
                            _errorMsg!,
                            style: GoogleFonts.jetBrainsMono(color: const Color(0xFFFFB300), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (!_isLogin) ...[
                        _buildTextField(
                          controller: _nameController,
                          hint: "Full Name",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildTextField(
                        controller: _emailController,
                        hint: "Email address",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _passwordController,
                        hint: "Password",
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        onVisibilityToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),

                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: "Confirm Password",
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                        ),
                      ],

                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.jetBrainsMono(color: const Color(0xFF555555), fontSize: 11),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // SIGN IN / CREATE ACCOUNT button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF020810),
                            side: const BorderSide(color: Color(0xFF58A6FF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF58A6FF), strokeWidth: 2))
                              : Text(
                                  _isLogin ? "ENTER THE DEN" : "CREATE ACCOUNT",
                                  style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFF58A6FF),
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: const Color(0xFF111111))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("or", style: GoogleFonts.jetBrainsMono(color: const Color(0xFF333333))),
                          ),
                          Expanded(child: Divider(color: const Color(0xFF111111))),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // GOOGLE SIGN IN button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                          label: Text(
                            "Continue with Google",
                            style: GoogleFonts.jetBrainsMono(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF080808),
                            side: const BorderSide(color: Color(0xFF111111)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Toggle Login/Register
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMsg = null;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Text(
                          _isLogin ? "New to Mehd AI? Create account" : "Already have an account? Sign in",
                          style: GoogleFonts.jetBrainsMono(color: const Color(0xFF555555), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onVisibilityToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.jetBrainsMono(color: const Color(0xFF333333), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF080808),
        prefixIcon: Icon(icon, color: const Color(0xFF333333), size: 18),
        suffixIcon: onVisibilityToggle != null
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF333333), size: 18),
                onPressed: onVisibilityToggle,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF111111)),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF58A6FF)),
          borderRadius: BorderRadius.zero,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return "Required field";
        return null;
      },
    );
  }
}
