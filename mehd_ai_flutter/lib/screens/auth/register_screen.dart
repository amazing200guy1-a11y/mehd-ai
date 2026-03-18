import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/screens/auth/login_screen.dart';
import 'package:mehd_ai_flutter/screens/onboarding/broker_connect_screen.dart';
import 'package:provider/provider.dart';

/// FILE 5b — register_screen.dart
///
/// Build Debrief:
/// Registration screen with a mandatory terms checkbox. This is not just a UX
/// choice — it's a legal necessity.
///
/// Why the terms checkbox matters legally for a financial app:
/// 1. Financial apps that involve real money trading MUST have legal disclaimers.
/// 2. The checkbox creates a digital record that the user acknowledged they
///    trade at their own risk — this protects the developer from liability.
/// 3. "Educational purposes" language is critical because Mehd AI is not a
///    licensed financial advisor. Without this, regulators could classify the
///    app as providing unlicensed financial advice.
/// 4. FINRA, SEC, and FCA all require clear risk disclosures for trading tools.
/// 5. The checkbox is required — users physically cannot create an account
///    without agreeing. This is evidence in any legal dispute.

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  String? _error;

  // Password strength tracking
  int _passwordStrength = 0; // 0-4

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    setState(() => _passwordStrength = strength);
  }

  Future<void> _handleRegister() async {
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      setState(() => _error = 'You must agree to the terms to continue.');
      return;
    }

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final error = await authService.signUpWithEmail(
      _emailController.text,
      _passwordController.text,
      _nameController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _error = error);
    } else {
      // Navigate to onboarding flow
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BrokerConnectScreen()),
          (route) => false,
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
                const SizedBox(height: 10),

                // ── HEADER ──────────────────────────────────
                Text(
                  'Create Account',
                  style: MehdAiTheme.headingStyle.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the AI-powered trading terminal',
                  style: MehdAiTheme.labelStyle.copyWith(fontSize: 14),
                ),

                const SizedBox(height: 32),

                // ── ERROR ───────────────────────────────────
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MehdAiTheme.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MehdAiTheme.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _error!,
                      style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── NAME FIELD ──────────────────────────────
                _buildLabel('DISPLAY NAME'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: MehdAiTheme.terminalStyle.copyWith(fontSize: 14),
                  decoration: _inputDecoration('Your name'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

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

                const SizedBox(height: 18),

                // ── PASSWORD FIELD ──────────────────────────
                _buildLabel('PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: MehdAiTheme.terminalStyle.copyWith(fontSize: 14),
                  onChanged: _updatePasswordStrength,
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
                    if (v.length < 6) return 'At least 6 characters required';
                    return null;
                  },
                ),

                // ── PASSWORD STRENGTH INDICATOR ─────────────
                const SizedBox(height: 10),
                Row(
                  children: List.generate(4, (index) {
                    Color color;
                    if (index < _passwordStrength) {
                      switch (_passwordStrength) {
                        case 1:
                          color = MehdAiTheme.red;
                          break;
                        case 2:
                          color = MehdAiTheme.yellow;
                          break;
                        case 3:
                          color = MehdAiTheme.blue;
                          break;
                        case 4:
                          color = MehdAiTheme.green;
                          break;
                        default:
                          color = MehdAiTheme.borderColor;
                      }
                    } else {
                      color = MehdAiTheme.borderColor;
                    }
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  _passwordStrengthLabel,
                  style: MehdAiTheme.labelStyle.copyWith(fontSize: 11),
                ),

                const SizedBox(height: 18),

                // ── CONFIRM PASSWORD FIELD ──────────────────
                _buildLabel('CONFIRM PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: MehdAiTheme.terminalStyle.copyWith(fontSize: 14),
                  decoration: _inputDecoration('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: MehdAiTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── TERMS CHECKBOX ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MehdAiTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _termsAccepted
                          ? MehdAiTheme.green.withOpacity(0.3)
                          : MehdAiTheme.borderColor,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) =>
                              setState(() => _termsAccepted = v ?? false),
                          activeColor: MehdAiTheme.green,
                          checkColor: Colors.black,
                          side: const BorderSide(color: MehdAiTheme.textSecondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I understand Mehd AI is for educational purposes. '
                          'I trade at my own risk.',
                          style: MehdAiTheme.labelStyle.copyWith(
                            fontSize: 12,
                            height: 1.5,
                            color: MehdAiTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── CREATE ACCOUNT BUTTON ───────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _termsAccepted ? MehdAiTheme.green : MehdAiTheme.bgTertiary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: MehdAiTheme.bgTertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: Opacity(opacity: 0.5, child: Image.asset('assets/images/mehd_logo.png')),
                          )
                        : Text(
                            'Create Account',
                            style: MehdAiTheme.headingStyle.copyWith(
                              fontSize: 16,
                              color:
                                  _termsAccepted ? Colors.black : MehdAiTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── LOGIN LINK ──────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: MehdAiTheme.labelStyle.copyWith(fontSize: 13),
                        children: const [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign in',
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

  String get _passwordStrengthLabel {
    switch (_passwordStrength) {
      case 0:
        return '';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
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
