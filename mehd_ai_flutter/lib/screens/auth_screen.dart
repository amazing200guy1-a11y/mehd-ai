import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/screens/home_screen.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMsg;
  bool _obscurePass = true;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
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

  void _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = "Please enter your email and password.";
      });
      return;
    }

    final authService = context.read<AuthService>();
    
    String? error;
    if (_isLogin) {
      error = await authService.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text.trim());
    } else {
      final name = _emailCtrl.text.trim().split('@').first;
      error = await authService.signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text.trim(), name);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _handleError(error);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  void _signInGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    
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

  void _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Enter your email first, then tap forgot password.');
      return;
    }
    final authService = context.read<AuthService>();
    final error = await authService.resetPassword(_emailCtrl.text.trim());
    if (!mounted) return;

    if (error != null) {
      _handleError(error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD29922),
          content: Text('Password reset email sent. Check your inbox.', style: TextStyle(color: Colors.black)),
        ),
      );
    }
  }

  void _switchToSignUp() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMsg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(children: [
        // Subtle tiger background
        Center(child: Opacity(
          opacity: 0.03,
          child: Image.asset('assets/images/mehd_logo.png', width: 400, height: 400))),
        
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const SizedBox(height: 48),
              
              // Logo
              Image.asset('assets/images/mehd_logo.png', width: 64, height: 64),
              const SizedBox(height: 20),
              
              // Title
              const Text('THE DEN',
                style: TextStyle(
                  color: Color(0xFF58A6FF),
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Sign in to continue',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  letterSpacing: 0.5)),
              const SizedBox(height: 40),
              
              // Email field
              _field(
                controller: _emailCtrl,
                label: 'Email address',
                hint: 'trader@example.com',
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              
              // Password field
              _passField(),
              const SizedBox(height: 6),
              
              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 11)))),
              const SizedBox(height: 16),
              
              // Error message
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_errorMsg!,
                    style: const TextStyle(
                      color: Color(0xFFD29922),
                      fontSize: 11),
                    textAlign: TextAlign.center)),
              
              // ENTER THE DEN button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF020810),
                    side: const BorderSide(
                      color: Color(0xFF58A6FF),
                      width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4))),
                  child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF58A6FF)))
                    : const Text('ENTER THE DEN',
                        style: TextStyle(
                          color: Color(0xFF58A6FF),
                          fontSize: 13,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              
              // OR divider
              Row(children: const [
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
              
              // Google button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _signInGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A1A1A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('G',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                      SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12)),
                    ]),
                ),
              ),
              const SizedBox(height: 24),
              
              // Create account link
              GestureDetector(
                onTap: _switchToSignUp,
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
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(
        color: Color(0xFFCCCCCC),
        fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF2A2A2A),
          fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
          borderRadius: BorderRadius.circular(4)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF58A6FF), width: 1.5),
          borderRadius: BorderRadius.circular(4)),
        filled: true,
        fillColor: const Color(0xFF080808),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
    );
  }

  Widget _passField() {
    return TextField(
      controller: _passCtrl,
      obscureText: _obscurePass,
      style: const TextStyle(
        color: Color(0xFFCCCCCC),
        fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
          borderRadius: BorderRadius.circular(4)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF58A6FF), width: 1.5),
          borderRadius: BorderRadius.circular(4)),
        filled: true,
        fillColor: const Color(0xFF080808),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePass ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF444444),
            size: 18,
          ),
          onPressed: () {
            setState(() {
              _obscurePass = !_obscurePass;
            });
          },
        ),
      ),
    );
  }
}
