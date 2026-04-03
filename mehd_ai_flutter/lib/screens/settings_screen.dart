import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/services/language_service.dart';
import 'package:mehd_ai_flutter/screens/language_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mehd_ai_flutter/screens/help/about_screen.dart' as mehd_about;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isOandaConnected = false;
  bool _isEightcapConnected = true;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageService>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text(l10n.settings, style: MehdAiTheme.headingStyle),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        iconTheme: const IconThemeData(color: MehdAiTheme.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // LANGUAGE PREFERENCES
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language, color: MehdAiTheme.purple),
            title: Text(l10n.language, style: MehdAiTheme.terminalStyle),
            subtitle: Text(
              LanguageService.supportedLanguages.firstWhere(
                (l) => l['code'] == loc.currentLocale.languageCode,
                orElse: () => LanguageService.supportedLanguages[0],
              )['name']!,
              style: MehdAiTheme.labelStyle.copyWith(fontSize: 12, color: MehdAiTheme.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: MehdAiTheme.textSecondary),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
            },
          ),

          const SizedBox(height: 32),
          
          // API INTEGRATIONS
          Text('BROKER API INTEGRATIONS', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.blue)),
          const SizedBox(height: 16),
          
          _buildBrokerConnectionTile('OANDA V2 REST API', _isOandaConnected, () {
            setState(() => _isOandaConnected = !_isOandaConnected);
          }),
          const SizedBox(height: 12),
          _buildBrokerConnectionTile('EIGHTCAP MT5 BRIDGE', _isEightcapConnected, () {
            setState(() => _isEightcapConnected = !_isEightcapConnected);
          }),
          
          const SizedBox(height: 48),
          
          // ABOUT & SYSTEM INFO
          Text('SYSTEM INFORMATION', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.gold)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline, color: MehdAiTheme.textSecondary),
            title: Text('About Mehd AI', style: MehdAiTheme.terminalStyle),
            trailing: const Icon(Icons.chevron_right, color: MehdAiTheme.textSecondary),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const mehd_about.AboutScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerConnectionTile(String name, bool isConnected, VoidCallback onToggle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.check_circle : Icons.error_outline,
                color: isConnected ? MehdAiTheme.green : MehdAiTheme.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(name, style: MehdAiTheme.headingStyle.copyWith(fontSize: 16)),
            ],
          ),
          ElevatedButton(
            onPressed: onToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? MehdAiTheme.red.withOpacity(0.2) : MehdAiTheme.blue.withOpacity(0.2),
              foregroundColor: isConnected ? MehdAiTheme.red : MehdAiTheme.blue,
              side: BorderSide(color: isConnected ? MehdAiTheme.red : MehdAiTheme.blue),
            ),
            child: Text(isConnected ? 'DISCONNECT' : 'CONNECT VIA OAUTH'),
          ),
        ],
      ),
    );
  }
}
