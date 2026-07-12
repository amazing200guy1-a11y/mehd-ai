import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/screens/broker_screen.dart';
import 'package:mehd_ai_flutter/services/language_service.dart';
import 'package:mehd_ai_flutter/services/settings_service.dart';
import 'package:mehd_ai_flutter/screens/help/about_screen.dart';
import 'package:mehd_ai_flutter/screens/den/tutorial_blueprint_screen.dart';
import 'package:mehd_ai_flutter/screens/constitution_screen.dart';
import 'package:mehd_ai_flutter/screens/compliance_screen.dart';
import 'package:mehd_ai_flutter/screens/security_screen.dart';
import 'package:mehd_ai_flutter/services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'core':
        return MehdAiTheme.blue;
      case 'precision':
        return const Color(0xFFBB00FF);
      case 'institutional':
        return MehdAiTheme.gold;
      case 'tiger':
        return const Color(0xFFFF3B3B);
      default:
        return const Color(0xFF888888);
    }
  }

  String _getTierName(String tier) {
    switch (tier.toLowerCase()) {
      case 'core':
        return 'CORE TRADER';
      case 'precision':
        return 'PRECISION TRADER';
      case 'institutional':
        return 'INSTITUTIONAL';
      case 'tiger':
        return 'TIGER MODE';
      default:
        return 'OBSERVER';
    }
  }

  String _getTierPrice(String tier) {
    switch (tier.toLowerCase()) {
      case 'core':        return '29.99';
      case 'precision':   return '59.99';
      case 'institutional': return '99.99';
      default:            return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentService>();
    final tier = payment.currentTier;
    final tierColor = _getTierColor(tier);
    final tierName = _getTierName(tier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('SETTINGS', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyMedium?.color ?? MehdAiTheme.white),
      ),
      body: Consumer<SettingsService>(
        builder: (ctx, settings, _) => ListView(
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
                          color: tierColor.withOpacity(0.4),
                          width: 2)),
                      child: Center(
                        child: Text(initials,
                          style: TextStyle(
                            color: tierColor,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF020810),
                      border: Border.all(
                        color: tierColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(tierName,
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
                        settings.paperMode
                          ? 'Paper Trading — \$10,000 demo'
                          : 'Live Trading — Real money',
                        style: TextStyle(
                          color: settings.paperMode
                            ? const Color(0xFF58A6FF)
                            : const Color(0xFFFF3B3B),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Switch(
                    value: !settings.paperMode, // ON = live
                    activeColor: const Color(0xFFFF3B3B),
                    inactiveThumbColor: const Color(0xFF58A6FF),
                    onChanged: (goLive) {
                      if (goLive) {
                        _showLiveTradingWarning(context, settings);
                      } else {
                        _switchToPaper(context, settings);
                      }
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart_outline, color: Color(0xFF888888)),
              title: const Text('Default Lot Size', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
              trailing: const Text('1.00', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
            ),
              SwitchListTile(
                title: const Text('Auto Stop-Loss', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
                subtitle: const Text('Den sets SL automatically', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
                value: settings.autoStopLoss,
                secondary: const Icon(Icons.shield_outlined, color: Color(0xFF888888)),
                activeColor: const Color(0xFF58A6FF),
                inactiveThumbColor: const Color(0xFF444444),
                inactiveTrackColor: const Color(0xFF111111),
                onChanged: settings.setAutoStopLoss,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Minimum Conviction Threshold', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
                        Text('${settings.convictionThreshold.toInt()}%', style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Agent consensus required to broadcast trade', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFF58A6FF),
                        inactiveTrackColor: const Color(0xFF111111),
                        thumbColor: const Color(0xFF58A6FF),
                        overlayColor: const Color(0xFF58A6FF).withOpacity(0.2),
                        trackHeight: 4.0,
                      ),
                      child: Slider(
                        value: settings.convictionThreshold,
                        min: 50,
                        max: 100,
                        divisions: 50,
                        onChanged: settings.setConvictionThreshold,
                      ),
                    ),
                  ],
                ),
              ),
            
            const Divider(color: Color(0xFF111111), height: 32),
            
            _buildSectionTitle('RISK MANAGEMENT'),
            _GlobalRiskSlider(settings: settings),

            const Divider(color: Color(0xFF111111), height: 32),
            
            // Notifications
            _buildSectionTitle('NOTIFICATIONS'),
            SwitchListTile(
              title: const Text('Trade Signals', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
              subtitle: const Text('Notifications when Den finds setup', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
              value: settings.tradeSignals,
              secondary: const Icon(Icons.notifications_active_outlined, color: Color(0xFF888888)),
              activeColor: const Color(0xFF58A6FF),
              inactiveThumbColor: const Color(0xFF444444),
              inactiveTrackColor: const Color(0xFF111111),
              onChanged: settings.setTradeSignals,
            ),
            SwitchListTile(
              title: const Text('Guardian Alerts', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
              value: settings.guardianAlerts,
              secondary: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF888888)),
              activeColor: const Color(0xFF58A6FF),
              inactiveThumbColor: const Color(0xFF444444),
              inactiveTrackColor: const Color(0xFF111111),
              onChanged: settings.setGuardianAlerts,
            ),
            
            const Divider(color: Color(0xFF111111), height: 32),
            
            // Subscription & Billing
            _buildSectionTitle('SUBSCRIPTION & BILLING'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<PaymentService>(
                builder: (ctx, payment, _) {
                  final tier = payment.currentTier;
                  final tierColor = _getTierColor(tier);
                  final tierName = _getTierName(tier);
                  final isObserver = tier == 'observer' && !payment.isOnTrial;
                  final portalUrl = payment.portalUrl ?? 'https://mehdai.com/#pricing';

                  return Column(
                    children: [
                      // Trial banner
                      if (payment.isOnTrial) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: MehdAiTheme.gold.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MehdAiTheme.gold.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: MehdAiTheme.gold, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('FREE TRIAL ACTIVE',
                                      style: TextStyle(color: MehdAiTheme.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    Text('${payment.trialDaysRemaining} day${payment.trialDaysRemaining == 1 ? '' : 's'} remaining — Institutional access',
                                      style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Current plan card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tierColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CURRENT PLAN', style: TextStyle(color: tierColor.withOpacity(0.6), fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(tierName, style: TextStyle(color: tierColor, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(
                              isObserver ? 'FREE' : '\$${_getTierPrice(tier)}/mo',
                              style: TextStyle(color: tierColor, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Manage billing button
                      _build3DSettingsCard(
                        context,
                        isObserver ? 'Upgrade Account' : 'Manage Billing',
                        isObserver ? 'View plans on the Mehd AI website' : 'Update payment method or cancel',
                        isObserver ? Icons.rocket_launch_rounded : Icons.credit_card_rounded,
                        isObserver
                          ? const [Color(0xFF0A2040), Color(0xFF051020)]
                          : const [Color(0xFF1A2030), Color(0xFF0F1520)],
                        isObserver ? MehdAiTheme.blue : tierColor,
                        () async {
                          final uri = Uri.parse(portalUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Could not open billing page. Visit mehdai.com'))
                              );
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            const Divider(color: Color(0xFF111111), height: 32),

            // Broker Connection
            _buildSectionTitle('BROKER CONNECTION'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _build3DSettingsCard(
                    context,
                    'Connect Broker',
                    'Manage your API integrations',
                    Icons.account_balance_rounded,
                    const [Color(0xFF142840), Color(0xFF0B1825)],
                    MehdAiTheme.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrokerScreen())),
                  ),
                  const SizedBox(height: 12),
                  _build3DSettingsCard(
                    context,
                    'Security Promise & Manifesto',
                    'Unbreakable anti-broker defenses',
                    Icons.security_rounded,
                    const [Color(0xFF0F2C24), Color(0xFF071B16)],
                    const Color(0xFF00FF88),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Color(0xFF111111), height: 32),
            
            // Language
            _buildSectionTitle('LANGUAGE'),
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF444444), size: 20),
              title: const Text('Language', style: TextStyle(color: Color(0xFF888888))),
              subtitle: Text(settings.language, style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF333333)),
              onTap: () => _openLanguageSheet(context, settings),
            ),

            const Divider(color: Color(0xFF111111), height: 32),
            
            // Appearance
            _buildSectionTitle('APPEARANCE'),
            SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(color: Color(0xFF888888))),
              subtitle: Text(
                settings.darkMode
                  ? 'Pure black — easy on eyes'
                  : 'Light theme active',
                style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
              value: settings.darkMode,
              activeColor: const Color(0xFF58A6FF),
              onChanged: (v) {
                settings.setDarkMode(v);
                context.read<ThemeProvider>().setDark(v);
              },
            ),
            SwitchListTile(
              title: const Text('Show Agent Names', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
              subtitle: const Text('Shows DON, ORACLE etc. in terminal', style: TextStyle(color: Color(0xFF444444), fontSize: 10)),
              value: settings.showAgentNames,
              secondary: const Icon(Icons.visibility_outlined, color: Color(0xFF888888)),
              activeColor: const Color(0xFF58A6FF),
              onChanged: settings.setShowAgentNames,
            ),
            SwitchListTile(
              title: const Text('Sandbox Mode', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
              subtitle: const Text('Your trades invisible to others', style: TextStyle(color: Color(0xFF444444), fontSize: 10)),
              value: settings.sandboxMode,
              secondary: const Icon(Icons.nightlight_outlined, color: Color(0xFF888888)),
              activeColor: const Color(0xFF58A6FF),
              onChanged: settings.setSandboxMode,
            ),

            const Divider(color: Color(0xFF111111), height: 32),

            // About
            _buildSectionTitle('ABOUT'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _build3DSettingsCard(
                context,
                'About Mehd AI',
                'v1.0.0 — The Den',
                Icons.info_rounded,
                const [Color(0xFF1A2030), Color(0xFF0F1520)],
                Colors.white70,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
              ),
            ),

            const Divider(color: Color(0xFF111111), height: 32),

            // Tutorial & Legal
            _buildSectionTitle('TUTORIALS & LEGAL'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _build3DSettingsCard(
                        context,
                        'Tutorial\nBlueprint',
                        'CyberSpace walkthrough',
                        Icons.school_rounded,
                        const [Color(0xFF0A2040), Color(0xFF051020)],
                        const Color(0xFF00D1FF),
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialBlueprintScreen())),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _build3DSettingsCard(
                        context,
                        'Holy Trinity\nConstitution',
                        'The Den\'s laws',
                        Icons.menu_book_rounded,
                        const [Color(0xFF1A2A3A), Color(0xFF0D1520)],
                        MehdAiTheme.blue,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConstitutionScreen())),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _build3DSettingsCard(
                    context,
                    'Compliance & Risk Protocol',
                    'Institutional safety standards',
                    Icons.gavel_rounded,
                    const [Color(0xFF2A2A1A), Color(0xFF15150D)],
                    const Color(0xFFD29922),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplianceScreen())),
                  ),
                ],
              ),
            ),

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
                        await settings.clearLocal();
                        if (context.mounted) {
                          Navigator.pop(context);
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
                          // FIX C2: '/auth' was not a registered route. Correct route is '/login'.
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
      ),
    );
  }

  void _openLanguageSheet(BuildContext context, SettingsService settings) {
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
                    color: settings.language == lang['name'] ? const Color(0xFF58A6FF) : const Color(0xFF888888),
                    fontSize: 13)),
                trailing: settings.language == lang['name']
                  ? const Icon(Icons.check, color: Color(0xFF58A6FF), size: 16)
                  : null,
                onTap: () {
                  settings.setLanguage(lang['name']!);
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

  Widget _build3DSettingsCard(
    BuildContext context, String title, String subtitle,
    IconData icon, List<Color> gradient, Color accent, VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            height: 90,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
              boxShadow: [
                BoxShadow(color: gradient[0].withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.03)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
                  ],
                )),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.15), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLiveTradingWarning(BuildContext context, SettingsService settings) {
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
        content: Text(
          'You are enabling LIVE trading.\n\n'
          'Real money. Real consequences.\n'
          'Your current risk is locked at ${settings.riskPerTrade.toStringAsFixed(1)}% per trade.\n'
          'Kill-switch at 3% drawdown.',
          style: const TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.7),
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
              _switchToLive(context, settings);
            },
            child: const Text('I UNDERSTAND — GO LIVE', style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _switchToLive(BuildContext context, SettingsService settings) async {
    settings.setPaperMode(false);
    if (context.mounted) {
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

  void _switchToPaper(BuildContext context, SettingsService settings) async {
    settings.setPaperMode(true);
    if (context.mounted) {
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

class _GlobalRiskSlider extends StatefulWidget {
  final SettingsService settings;
  const _GlobalRiskSlider({required this.settings});

  @override
  State<_GlobalRiskSlider> createState() => _GlobalRiskSliderState();
}

class _GlobalRiskSliderState extends State<_GlobalRiskSlider> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.settings.riskPerTrade.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_GlobalRiskSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.riskPerTrade != widget.settings.riskPerTrade) {
      if (double.tryParse(_controller.text) != widget.settings.riskPerTrade) {
        _controller.text = widget.settings.riskPerTrade.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRiskColor(double risk) {
    if (risk > 7.0) return const Color(0xFFFF3B3B); // Red
    if (risk > 3.0) return const Color(0xFFD29922); // Yellow
    return const Color(0xFF58A6FF); // Blue
  }

  @override
  Widget build(BuildContext context) {
    final risk = widget.settings.riskPerTrade;
    final color = _getRiskColor(risk);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Global Risk Protocol', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    risk > 7.0 ? 'Aggressive exposure' : risk > 3.0 ? 'Moderate exposure' : 'Conservative exposure',
                    style: TextStyle(color: color, fontSize: 10),
                  ),
                ],
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: color.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    final newRisk = double.tryParse(val);
                    if (newRisk != null && newRisk >= 0.1 && newRisk <= 10.0) {
                      widget.settings.setRiskPerTrade(newRisk);
                    } else {
                      _controller.text = widget.settings.riskPerTrade.toStringAsFixed(2);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.1),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 4.0,
            ),
            child: Slider(
              value: risk,
              min: 0.1,
              max: 10.0,
              divisions: 99,
              onChanged: (val) {
                widget.settings.setRiskPerTrade(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
