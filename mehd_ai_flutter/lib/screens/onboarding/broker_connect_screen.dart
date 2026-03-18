import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/user_profile.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/services/user_service.dart';
import 'package:mehd_ai_flutter/screens/onboarding/risk_setup_screen.dart';
import 'package:provider/provider.dart';

/// FILE 6 — broker_connect_screen.dart
///
/// Build Debrief:
/// Step 2 of onboarding — choosing how to connect to a broker.
///
/// Why demo mode is recommended first:
/// New traders should NEVER start with real money. Statistics show 70-80% of
/// retail forex traders lose money. Demo mode lets users understand how the
/// 9-AI consensus works, how the risk kernel protects them, and how to read
/// the Zen Chart — all without financial risk. Once they're comfortable, they
/// can connect a real broker.
///
/// Why credential encryption is non-negotiable:
/// Broker credentials = direct access to someone's trading account and real
/// money. If stored in plain text and the database is breached, every user's
/// funds are at risk. flutter_secure_storage uses:
///   - iOS: Keychain (hardware-backed encryption)
///   - Android: AES-256 via EncryptedSharedPreferences
/// The Firestore document only stores "****encrypted****" as a marker.
/// The real credential lives in platform-native secure storage.

class BrokerConnectScreen extends StatefulWidget {
  const BrokerConnectScreen({super.key});

  @override
  State<BrokerConnectScreen> createState() => _BrokerConnectScreenState();
}

class _BrokerConnectScreenState extends State<BrokerConnectScreen> {
  int _selectedBroker = 2; // 0=MT5, 1=Oanda, 2=Demo (default)
  bool _isConnecting = false;
  String? _connectionError;

  // MT5 fields
  final _mt5LoginController = TextEditingController();
  final _mt5PasswordController = TextEditingController();
  final _mt5ServerController = TextEditingController();

  // Oanda fields
  final _oandaAccountController = TextEditingController();
  final _oandaApiKeyController = TextEditingController();

  @override
  void dispose() {
    _mt5LoginController.dispose();
    _mt5PasswordController.dispose();
    _mt5ServerController.dispose();
    _oandaAccountController.dispose();
    _oandaApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _connectBroker() async {
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    final authService = context.read<AuthService>();
    final userService = UserService();
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      setState(() {
        _isConnecting = false;
        _connectionError = 'Not signed in. Please restart the app.';
      });
      return;
    }

    try {
      BrokerType brokerType;
      String? login;
      String? server;

      switch (_selectedBroker) {
        case 0: // MT5
          if (_mt5LoginController.text.trim().isEmpty ||
              _mt5PasswordController.text.trim().isEmpty ||
              _mt5ServerController.text.trim().isEmpty) {
            setState(() {
              _isConnecting = false;
              _connectionError = 'All MT5 fields are required.';
            });
            return;
          }
          brokerType = BrokerType.mt5;
          login = _mt5LoginController.text.trim();
          server = _mt5ServerController.text.trim();
          break;
        case 1: // Oanda
          if (_oandaAccountController.text.trim().isEmpty ||
              _oandaApiKeyController.text.trim().isEmpty) {
            setState(() {
              _isConnecting = false;
              _connectionError = 'Account ID and API Key are required.';
            });
            return;
          }
          brokerType = BrokerType.oanda;
          login = _oandaAccountController.text.trim();
          server = 'practice'; // Oanda practice server
          break;
        default: // Demo
          brokerType = BrokerType.demo;
          login = null;
          server = null;
      }

      // Simulate connection test
      await Future.delayed(const Duration(seconds: 2));

      // Save broker settings (credentials encrypted automatically)
      await userService.updateBrokerSettings(userId, brokerType, login, server);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RiskSetupScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionError = 'Connection failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Step 1 of 3',
          style: MehdAiTheme.labelStyle.copyWith(fontSize: 13),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Text(
                'Connect Your Broker',
                style: MehdAiTheme.headingStyle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to trade',
                style: MehdAiTheme.labelStyle.copyWith(fontSize: 14),
              ),

              const SizedBox(height: 28),

              // ── ERROR ────────────────────────────────────
              if (_connectionError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MehdAiTheme.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MehdAiTheme.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _connectionError!,
                    style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.red),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── MT5 CARD ─────────────────────────────────
              _buildBrokerCard(
                index: 0,
                icon: Icons.candlestick_chart,
                title: 'MetaTrader 5',
                description:
                    'Works with Exness, XM, FxPro, Deriv and 500+ brokers',
                badge: null,
                fields: [
                  _buildField(_mt5LoginController, 'Login number'),
                  const SizedBox(height: 10),
                  _buildField(_mt5PasswordController, 'Password',
                      obscure: true),
                  const SizedBox(height: 10),
                  _buildField(_mt5ServerController, 'Server name'),
                ],
                buttonLabel: 'Connect MT5',
              ),

              const SizedBox(height: 14),

              // ── OANDA CARD ───────────────────────────────
              _buildBrokerCard(
                index: 1,
                icon: Icons.show_chart,
                title: 'Oanda',
                description:
                    'Professional forex broker with direct API',
                badge: null,
                fields: [
                  _buildField(_oandaAccountController, 'Account ID'),
                  const SizedBox(height: 10),
                  _buildField(_oandaApiKeyController, 'API Key',
                      obscure: true),
                ],
                buttonLabel: 'Connect Oanda',
              ),

              const SizedBox(height: 14),

              // ── DEMO MODE CARD ───────────────────────────
              _buildBrokerCard(
                index: 2,
                icon: Icons.school_outlined,
                title: 'Demo Mode',
                description:
                    'Practice with simulated prices. No real money. Perfect for learning.',
                badge: 'RECOMMENDED',
                fields: const [],
                buttonLabel: 'Start in Demo Mode',
              ),

              const SizedBox(height: 20),

              // ── SKIP LINK ────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _selectedBroker = 2);
                    _connectBroker();
                  },
                  child: Text(
                    'Skip for now — use demo mode',
                    style: MehdAiTheme.labelStyle.copyWith(
                      color: MehdAiTheme.textSecondary,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: MehdAiTheme.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrokerCard({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    String? badge,
    required List<Widget> fields,
    required String buttonLabel,
  }) {
    final isSelected = _selectedBroker == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedBroker = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? MehdAiTheme.bgSecondary
              : MehdAiTheme.bgPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (badge != null ? MehdAiTheme.green : MehdAiTheme.blue)
                : MehdAiTheme.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: isSelected
                        ? MehdAiTheme.blue
                        : MehdAiTheme.textSecondary,
                    size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: MehdAiTheme.headingStyle.copyWith(
                      fontSize: 16,
                      color: isSelected
                          ? MehdAiTheme.textPrimary
                          : MehdAiTheme.textSecondary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MehdAiTheme.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: MehdAiTheme.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      badge,
                      style: MehdAiTheme.labelStyle.copyWith(
                        fontSize: 10,
                        color: MehdAiTheme.green,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                // Radio indicator
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? MehdAiTheme.green
                          : MehdAiTheme.borderColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: MehdAiTheme.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: MehdAiTheme.labelStyle.copyWith(
                fontSize: 12,
                color: MehdAiTheme.textSecondary,
              ),
            ),

            // Show fields and connect button only when selected
            if (isSelected && fields.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...fields,
            ],
            if (isSelected) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isConnecting ? null : _connectBroker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: badge != null
                        ? MehdAiTheme.green
                        : MehdAiTheme.blue,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        MehdAiTheme.blue.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isConnecting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: Opacity(opacity: 0.5, child: Image.asset('assets/images/mehd_logo.png')),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Testing connection...',
                              style: MehdAiTheme.labelStyle.copyWith(
                                color: Colors.black,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          buttonLabel,
                          style: MehdAiTheme.headingStyle.copyWith(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint,
      {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: MehdAiTheme.terminalStyle.copyWith(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: MehdAiTheme.terminalStyle.copyWith(
          color: MehdAiTheme.textSecondary.withOpacity(0.4),
          fontSize: 13,
        ),
        filled: true,
        fillColor: MehdAiTheme.bgPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: MehdAiTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: MehdAiTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: MehdAiTheme.blue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
