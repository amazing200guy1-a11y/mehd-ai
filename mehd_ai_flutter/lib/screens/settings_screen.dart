import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/screens/broker_screen.dart';
import 'package:mehd_ai_flutter/services/language_service.dart';
import 'package:mehd_ai_flutter/services/app_settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // All settings with defaults
  bool _darkMode = true;
  bool _tradeSignals = true;
  bool _autoStopLoss = true;
  bool _guardianAlerts = true;
  bool _showAgentNames = true;
  bool _shadowMode = false;
  bool _paperMode = true;
  String _language = 'English';
  final String _defaultLot = '1.00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = p.getBool('darkMode') ?? true;
      _tradeSignals = p.getBool('tradeSignals') ?? true;
      _autoStopLoss = p.getBool('autoStopLoss') ?? true;
      _guardianAlerts = p.getBool('guardianAlerts') ?? true;
      _showAgentNames = p.getBool('showAgentNames') ?? true;
      _shadowMode = p.getBool('shadowMode') ?? false;
      _paperMode = p.getBool('paperMode') ?? true;
      _language = p.getString('language') ?? 'English';
    });
  }
  
  Future<void> _savePref(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    if (value is bool) {
      await p.setBool(key, value);
    } else if (value is String) {
      await p.setString(key, value);
    }
    // Also sync to Firebase if logged in:
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('prefs')
          .set({key: value}, SetOptions(merge: true));
      } catch (e) {
        // Ignored
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Honest dark/light adherence
      appBar: AppBar(
        title: Text('SETTINGS', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
        // In honest dark mode we might use transparent or bgSecondary, sticking to theme.
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyMedium?.color ?? MehdAiTheme.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Profile
          _buildSectionTitle('PROFILE'),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (ctx, snapshot) {
              final user = snapshot.data;
              final name = user?.displayName ?? 'Trader';
              final email = user?.email ?? 'Not signed in';
              final initials = name.isNotEmpty ? name[0].toUpperCase() : 'T';
              
              return Column(children: [
                // Avatar circle
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Profile editing coming soon')
                    ));
                  },
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF020810),
                      border: Border.all(
                        color: const Color(0xFF58A6FF).withOpacity(0.4),
                        width: 2)),
                    child: Center(
                      child: Text(initials,
                        style: const TextStyle(
                          color: Color(0xFF58A6FF),
                          fontSize: 24,
                          fontWeight: FontWeight.bold)))),
                ),
                const SizedBox(height: 8),
                Text(name,
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(email,
                  style: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 11)),
                const SizedBox(height: 8),
                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020810),
                    border: Border.all(
                      color: const Color(0xFF58A6FF).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('CIVILIAN',
                    style: TextStyle(
                      color: Color(0xFF58A6FF),
                      fontSize: 10,
                      letterSpacing: 1.5))),
              ]);
            },
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
          _buildListTile('Default Lot Size', _defaultLot, Icons.pie_chart_outline),
          _buildSwitchTile('Auto Stop-Loss', _autoStopLoss, Icons.shield_outlined, (v) {
            setState(() => _autoStopLoss = v);
            _savePref('autoStopLoss', v);
          }),
          
          const Divider(color: Color(0xFF111111), height: 32),
          
          // Notifications
          _buildSectionTitle('NOTIFICATIONS'),
          _buildSwitchTile('Trade Signals', _tradeSignals, Icons.notifications_active_outlined, (v) {
            setState(() => _tradeSignals = v);
            _savePref('tradeSignals', v);
          }),
          _buildSwitchTile('Guardian Alerts', _guardianAlerts, Icons.admin_panel_settings_outlined, (v) {
            setState(() => _guardianAlerts = v);
            _savePref('guardianAlerts', v);
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BrokerScreen()));
            },
          ),
          
          const Divider(color: Color(0xFF111111), height: 32),
          
          // Language
          _buildSectionTitle('LANGUAGE'),
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF444444), size: 20),
            title: const Text('Language', style: TextStyle(color: Color(0xFF888888))),
            subtitle: Text(_language, style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF333333)),
            onTap: _openLanguageSheet,
          ),

          const Divider(color: Color(0xFF111111), height: 32),
          
          // Appearance
          _buildSectionTitle('APPEARANCE'),
          SwitchListTile(
            title: const Text('Dark Mode', style: TextStyle(color: Color(0xFF888888))),
            subtitle: Text(
              _darkMode
                ? 'Pure black — easy on eyes'
                : 'Light theme active',
              style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
            value: _darkMode,
            activeColor: const Color(0xFF58A6FF),
            onChanged: (v) {
              setState(() => _darkMode = v);
              _savePref('darkMode', v);
              // THIS actually changes the app:
              context.read<ThemeProvider>().setDark(v);
            },
          ),
          _buildSwitchTile('Show Agent Names', _showAgentNames, Icons.visibility_outlined, (v) {
            setState(() => _showAgentNames = v);
            _savePref('showAgentNames', v);
            context.read<AppSettingsProvider>().setShowAgentNames(v);
          }),
          _buildSwitchTile('Shadow Mode', _shadowMode, Icons.nightlight_outlined, (v) {
            setState(() => _shadowMode = v);
            _savePref('shadowMode', v);
          }),

          const Divider(color: Color(0xFF111111), height: 32),

          // Danger Zone
          _buildSectionTitle('DANGER ZONE', color: const Color(0xFFFF3B3B)),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFFF3B3B), size: 20),
            title: const Text('Clear Local Data', style: TextStyle(color: Color(0xFFFF3B3B))),
            subtitle: const Text('Resets cached settings only', style: TextStyle(color: Color(0xFF444444), fontSize: 10)),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF080808),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF1A0000))),
                title: const Text('Clear Local Data?', style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 14)),
                content: const Text(
                  'This clears cached settings.\n\n'
                  'Your account and trades\n'
                  'on Firebase stay safe.',
                  style: TextStyle(color: Color(0xFF666666), height: 1.7)),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final p = await SharedPreferences.getInstance();
                      await p.clear();
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadSettings(); // reload
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            backgroundColor: Color(0xFF001208),
                            content: Text('✓ Local data cleared',
                              style: TextStyle(color: Color(0xFF00FF88)))));
                      }
                    },
                    child: const Text('CLEAR', style: TextStyle(color: Color(0xFFFF3B3B)))),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL', style: TextStyle(color: Color(0xFF444444)))),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF3B3B), size: 20),
            title: const Text('Sign Out', style: TextStyle(color: Color(0xFFFF3B3B))),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF080808),
                title: const Text('Sign Out?', style: TextStyle(color: Color(0xFFCCCCCC))),
                content: const Text(
                  'The Den goes dark until\n'
                  'you return.',
                  style: TextStyle(color: Color(0xFF666666))),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
                      }
                    },
                    child: const Text('SIGN OUT', style: TextStyle(color: Color(0xFFFF3B3B)))),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL', style: TextStyle(color: Color(0xFF444444)))),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF080808),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) {
        final langs = [
          {'name': 'English',   'flag': '🇬🇧', 'code': 'en'},
          {'name': 'Arabic',    'flag': '🇸🇦', 'code': 'ar'},
          {'name': 'French',    'flag': '🇫🇷', 'code': 'fr'},
          {'name': 'Spanish',   'flag': '🇪🇸', 'code': 'es'},
          {'name': 'Portuguese','flag': '🇧🇷', 'code': 'pt'},
          {'name': 'Indonesian','flag': '🇮🇩', 'code': 'id'},
          {'name': 'Mandarin',  'flag': '🇨🇳', 'code': 'zh'},
          {'name': 'Russian',   'flag': '🇷🇺', 'code': 'ru'},
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2))),
            const Text('SELECT LANGUAGE',
              style: TextStyle(
                color: Color(0xFF58A6FF),
                fontSize: 12,
                letterSpacing: 2)),
            const SizedBox(height: 12),
            ...langs.map((lang) =>
              ListTile(
                leading: Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                title: Text(lang['name']!,
                  style: TextStyle(
                    color: _language == lang['name'] ? const Color(0xFF58A6FF) : const Color(0xFF888888),
                    fontSize: 13)),
                trailing: _language == lang['name']
                  ? const Icon(Icons.check, color: Color(0xFF58A6FF), size: 16)
                  : null,
                onTap: () {
                  setState(() => _language = lang['name']!);
                  _savePref('language', lang['name']!);
                  // Change app locale:
                  context.read<LanguageService>().setLocale(Locale(lang['code']!));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Language set to ${lang['name']}'),
                    backgroundColor: const Color(0xFF020810)));
                },
              )
            ),
            const SizedBox(height: 20),
          ],
        );
      },
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

  Widget _buildListTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF888888)),
      title: Text(title, style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
        ],
      ),
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
        content: const Text(
          'You are enabling LIVE trading.\n\n'
          'Real money. Real consequences.\n'
          'The Den enforces 1% risk always.\n'
          'Kill-switch at 3% drawdown.',
          style: TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF444444))),
          ),
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
    _savePref('paperMode', false);
    if (context.mounted) {
      setState(() => _paperMode = false);
      context.read<TradingController>().setPaperMode(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1A0000),
          content: Text(
            '⚡ Live trading enabled.',
            style: TextStyle(color: Color(0xFFFF3B3B)),
          ),
        ),
      );
    }
  }

  void _switchToPaper(BuildContext context) async {
    _savePref('paperMode', true);
    if (context.mounted) {
      setState(() => _paperMode = true);
      context.read<TradingController>().setPaperMode(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF020810),
          content: Text(
            '📊 Paper trading enabled. Zero risk.',
            style: TextStyle(color: Color(0xFF58A6FF)),
          ),
        ),
      );
    }
  }
}
