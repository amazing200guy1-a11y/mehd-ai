import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/screens/broker_screen.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/screens/splash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _brokerConnected = false; 

  bool _tradeSignals = true;
  bool _autoStopLoss = true;
  bool _guardianAlerts = true;
  bool _showAgentNames = true;
  bool _isDarkMode = true;
  bool _shadowMode = false;
  bool _paperMode = true;
  String _currentLang = 'English 🇬🇧';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future _loadAll() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _tradeSignals = p.getBool('tradeSignals') ?? true;
      _autoStopLoss = p.getBool('autoStopLoss') ?? true;
      _guardianAlerts = p.getBool('guardianAlerts') ?? true;
      _showAgentNames = p.getBool('showAgentNames') ?? true;
      _isDarkMode = p.getBool('isDarkMode') ?? true;
      _shadowMode = p.getBool('shadowMode') ?? false;
      _paperMode = p.getBool('paperMode') ?? true;
      _currentLang = p.getString('language') ?? 'English 🇬🇧';
    });
  }

  Future _save(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('SETTINGS', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        iconTheme: const IconThemeData(color: MehdAiTheme.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Profile
          _buildSectionTitle('PROFILE'),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF111111),
              child: Icon(Icons.person, color: Color(0xFF888888)),
            ),
            title: const Text('Trader', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('trader@mehddigital.com', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('PRO TIER', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const Divider(color: Color(0xFF111111), height: 32),
          
          // Trading Preferences
          _buildSectionTitle('TRADING PREFERENCES'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trading Mode', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      _paperMode
                        ? 'Paper Trading — \$10,000 demo'
                        : 'Live Trading — Real money',
                      style: TextStyle(
                        color: _paperMode
                          ? const Color(0xFF58A6FF)
                          : const Color(0xFFFF3B3B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Switch(
                  value: !_paperMode, // ON = live
                  activeColor: const Color(0xFFFF3B3B),
                  inactiveThumbColor: const Color(0xFF58A6FF),
                  onChanged: (goLive) {
                    if (goLive) {
                      _showLiveTradingWarning(context);
                    } else {
                      _switchToPaper(context);
                    }
                  },
                ),
              ],
            ),
          ),
          _buildListTile('Default Lot Size', '1.00', Icons.pie_chart_outline),
          _buildListTile('Risk Per Trade', '1% Enforced', Icons.security, locked: true),
          _buildSwitchTile('Auto Stop-Loss', _autoStopLoss, Icons.shield_outlined, (v) {
            setState(() => _autoStopLoss = v);
            _save('autoStopLoss', v);
          }),
          
          const Divider(color: Color(0xFF111111), height: 32),
          
          // Notifications
          _buildSectionTitle('NOTIFICATIONS'),
          _buildSwitchTile('Trade Signals', _tradeSignals, Icons.notifications_active_outlined, (v) {
            setState(() => _tradeSignals = v);
            _save('tradeSignals', v);
          }),
          _buildListTile('Black Swan Protocol', 'Always ON', Icons.flash_on, locked: true),
          _buildSwitchTile('Guardian Alerts', _guardianAlerts, Icons.admin_panel_settings_outlined, (v) {
            setState(() => _guardianAlerts = v);
            _save('guardianAlerts', v);
          }),
          
          const Divider(color: Color(0xFF111111), height: 32),
          
          // Broker Connection
          _buildSectionTitle('BROKER CONNECTION'),
          ListTile(
            leading: const Icon(Icons.account_balance, color: Color(0xFF58A6FF)),
            title: const Text('Connect Broker', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
            subtitle: const Text('Manage your API integrations', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF444444)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BrokerScreen())).then((_) {
                 setState((){ _brokerConnected = true; }); 
              });
            },
          ),
          
          const Divider(color: Color(0xFF111111), height: 32),
          
          // Language
          _buildSectionTitle('LANGUAGE'),
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF888888)),
            title: const Text('Language', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
            subtitle: Text(_currentLang, style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF333333)),
            onTap: _showLangSheet,
          ),

          const Divider(color: Color(0xFF111111), height: 32),
          
          // Appearance
          _buildSectionTitle('APPEARANCE'),
          _buildSwitchTile('Dark Mode', _isDarkMode, Icons.dark_mode_outlined, (v) {
            setState(() => _isDarkMode = v);
            _save('isDarkMode', v);
          }),
          _buildSwitchTile('Show Agent Names', _showAgentNames, Icons.visibility_outlined, (v) {
            setState(() => _showAgentNames = v);
            _save('showAgentNames', v);
          }),
          _buildSwitchTile('Shadow Mode', _shadowMode, Icons.nightlight_outlined, (v) {
            setState(() => _shadowMode = v);
            _save('shadowMode', v);
          }),

          const Divider(color: Color(0xFF111111), height: 32),

          // About
          _buildSectionTitle('ABOUT'),
          _buildListTile('Version', '2.0.4 (Institutional)', Icons.info_outline),
          _buildListTile('Built By', 'Usman', Icons.code),
          _buildListTile('Privacy Policy', '', Icons.privacy_tip_outlined, onTap: _showPrivacy),
          _buildListTile('Terms of Service', '', Icons.gavel_outlined, onTap: _showTerms),
          _buildListTile('Rate App', '', Icons.star_border_outlined, onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rate us when we launch! 🐯 Coming to App Store soon.'))
            );
          }),

          const Divider(color: Color(0xFF111111), height: 32),

          // Danger Zone
          _buildSectionTitle('DANGER ZONE', color: const Color(0xFFFF3B3B)),
          _buildDangerTile('Clear Local Data', Icons.delete_outline, onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF080808),
                title: const Text('Clear Data?', style: TextStyle(color: Color(0xFFCCCCCC))),
                content: const Text(
                  'Clears local cache only.\nFirebase data stays safe.',
                  style: TextStyle(color: Color(0xFF666666))
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final scaffoldMsg = ScaffoldMessenger.of(context);
                      final p = await SharedPreferences.getInstance();
                      await p.clear();
                      nav.pop();
                      scaffoldMsg.showSnackBar(
                        const SnackBar(content: Text('Cache cleared.'))
                      );
                    },
                    child: const Text('CLEAR', style: TextStyle(color: Color(0xFFFF3B3B)))
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL', style: TextStyle(color: Color(0xFF444444)))
                  ),
                ],
              ),
            );
          }),
          _buildDangerTile('Sign Out', Icons.logout, onTap: () => _handleSignOut(context)),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF080808),
        title: const Text('Terms of Service', style: TextStyle(color: Color(0xFF58A6FF))),
        content: const SingleChildScrollView(
          child: Text(
            'Mehd AI is for educational purposes only.\n\n'
            'Not financial advice.\n\n'
            'Trade at your own risk.\n\n'
            'Past performance does not guarantee future results.\n\n'
            'Capital is a seed, not a sacrifice.',
            style: TextStyle(color: Color(0xFF666666), height: 1.7)
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF58A6FF)))
          )
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF080808),
        title: const Text('Privacy Policy', style: TextStyle(color: Color(0xFF58A6FF))),
        content: const SingleChildScrollView(
          child: Text(
            'Your data stays yours.\n\n'
            'We collect minimal data needed for the app to function:\n'
            '• Email for authentication\n'
            '• Trade history for your account\n'
            '• App usage patterns to improve the experience\n\n'
            'We never sell your data. Ever.\n\n'
            'Your capital information is encrypted.\n\n'
            'You can delete your data at any time from Settings.',
            style: TextStyle(color: Color(0xFF666666), height: 1.7)
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF58A6FF)))
          )
        ],
      ),
    );
  }

  void _showLangSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF080808),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('LANGUAGE',
              style: TextStyle(
                color: Color(0xFF58A6FF),
                letterSpacing: 2,
                fontSize: 12))),
          ...[
            'English 🇬🇧',
            'Arabic 🇸🇦',
            'French 🇫🇷',
            'Spanish 🇪🇸',
            'Portuguese 🇧🇷',
            'Indonesian 🇮🇩',
            'Mandarin 🇨🇳',
            'Russian 🇷🇺',
          ].map((lang) => ListTile(
            title: Text(lang, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
            onTap: () {
              setState(() => _currentLang = lang);
              Navigator.pop(context);
              SharedPreferences.getInstance().then((p) => p.setString('language', lang));
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color color = const Color(0xFF444444)}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle, IconData icon, {bool locked = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF888888)),
      title: Text(title, style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle.isNotEmpty)
            Text(subtitle, style: TextStyle(color: locked ? const Color(0xFFD4AF37) : const Color(0xFF666666), fontSize: 11)),
          if (locked) const SizedBox(width: 8),
          if (locked) const Icon(Icons.lock, size: 14, color: Color(0xFFD4AF37)),
          if (onTap != null && !locked) const SizedBox(width: 8),
          if (onTap != null && !locked) const Icon(Icons.chevron_right, color: Color(0xFF444444)),
        ],
      ),
      onTap: locked ? null : onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, IconData icon, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: const Color(0xFF888888)),
      title: Text(title, style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
      activeColor: const Color(0xFF58A6FF),
      inactiveThumbColor: const Color(0xFF444444),
      inactiveTrackColor: const Color(0xFF111111),
    );
  }

  Widget _buildDangerTile(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF3B3B)),
      title: Text(title, style: const TextStyle(color: Color(0xFFFF3B3B), fontSize: 13)),
      onTap: onTap,
    );
  }

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MehdAiTheme.bgSecondary,
        title: const Text('SIGN OUT', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2)),
        content: const Text('Are you sure you want to end this session?', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Color(0xFF444444)))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final auth = context.read<AuthService>();
                await auth.signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            }, 
            child: const Text('SIGN OUT', style: TextStyle(color: Color(0xFFFF3B3B)))
          ),
        ],
      ),
    );
  }

  void _showLiveTradingWarning(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF080808),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFFF3B3B), width: 1),
        ),
        title: Row(children: const [
          Icon(Icons.warning_amber, color: Color(0xFFFF3B3B)),
          SizedBox(width: 8),
          Text('LIVE TRADING',
            style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are enabling LIVE trading.\n\n'
              'Real money. Real consequences.\n'
              'The Den enforces 1% risk always.\n'
              'Kill-switch at 3% drawdown.\n\n'
              'Make sure your broker is connected.',
              style: TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.7),
            ),
            const SizedBox(height: 16),
            if (!_brokerConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF100800),
                  border: Border.all(color: const Color(0xFFD29922)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '⚠ No broker connected.\nConnect broker first.',
                  style: TextStyle(color: Color(0xFFD29922), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF444444))),
          ),
          if (_brokerConnected)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF120000),
                side: const BorderSide(color: Color(0xFFFF3B3B)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _switchToLive(context);
              },
              child: const Text('I UNDERSTAND — GO LIVE', style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _switchToLive(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('paperMode', false);
    
    if (context.mounted) {
      setState(() => _paperMode = false);
      context.read<TradingController>().setPaperMode(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1A0000),
          content: Text(
            '⚡ Live trading enabled. The Den is protecting you.',
            style: TextStyle(color: Color(0xFFFF3B3B)),
          ),
        ),
      );
    }
  }

  void _switchToPaper(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('paperMode', true);
    
    if (context.mounted) {
      setState(() => _paperMode = true);
      context.read<TradingController>().setPaperMode(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF020810),
          content: Text(
            '📊 Paper trading enabled. Zero risk. Learn freely.',
            style: TextStyle(color: Color(0xFF58A6FF)),
          ),
        ),
      );
    }
  }
}
