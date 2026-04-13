import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class LicensingScreen extends StatefulWidget {
  const LicensingScreen({super.key});

  @override
  State<LicensingScreen> createState() => _LicensingScreenState();
}

class _LicensingScreenState extends State<LicensingScreen> {
  Future<void> _requestLicense(String tier) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/license-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tier': tier}),
      );
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: MehdAiTheme.green,
            content: Text('Request sent. Our institutional team will contact you.', style: MehdAiTheme.terminalStyle),
          ),
        );
      }
    } catch (e) {
      debugPrint('License request error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Enterprise Licensing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Live Moat Health Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: MehdAiTheme.shieldColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MehdAiTheme.shieldColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_moon, color: MehdAiTheme.shieldColor, size: 20),
                  const SizedBox(width: 12),
                  Text('LIVE DATA MOAT:', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
                  const SizedBox(width: 8),
                  Text('1,540 ALPHA SNAPSHOTS SECURED', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.shieldColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            Text(
              'WHITE-LABEL INSTITUTIONAL ACCESS',
              style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.gold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Deploy the Mehd AI ecosystem on your own servers. Integrate our Den Analysis™ engine directly into your prop firm or hedge fund infrastructure.',
              style: MehdAiTheme.labelStyle.copyWith(fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _buildTierCard('PROP FIRM', '\$50,000 / yr', ['10k API Requests/mo', 'API & Webhooks', 'Standard Support'])),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTierCard('HEDGE FUND', '\$125,000 / yr', ['Unlimited API Requests', 'Dedicated Chairman Model', '24/7 Priority Support'], isPopular: true)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTierCard('SOVEREIGN WEALTH', '\$250,000 / yr', ['On-Premises Deployment', 'Custom Data Moat Intakes', 'Bespoke Constitution Rules'])),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTierCard('PROP FIRM', '\$50,000 / yr', ['10k API Requests/mo', 'API & Webhooks', 'Standard Support']),
                      const SizedBox(height: 24),
                      _buildTierCard('HEDGE FUND', '\$125,000 / yr', ['Unlimited API Requests', 'Dedicated Chairman Model', '24/7 Priority Support'], isPopular: true),
                      const SizedBox(height: 24),
                      _buildTierCard('SOVEREIGN WEALTH', '\$250,000 / yr', ['On-Premises Deployment', 'Custom Data Moat Intakes', 'Bespoke Constitution Rules']),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 48),
            // Contact Sales Button
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.email_outlined, color: MehdAiTheme.gold),
                label: Text('CONTACT SALES', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.gold, fontWeight: FontWeight.bold, letterSpacing: 2)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: MehdAiTheme.gold),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final url = Uri.parse('mailto:enterprise@mehdai.com?subject=Enterprise%20Licensing%20Inquiry');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: MehdAiTheme.gold,
                        content: Text('Email enterprise@mehdai.com for licensing inquiries.', style: MehdAiTheme.terminalStyle.copyWith(color: Colors.black)),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(String title, String price, List<String> features, {bool isPopular = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPopular ? MehdAiTheme.purple : MehdAiTheme.borderColor, width: isPopular ? 2 : 1),
        boxShadow: isPopular ? [BoxShadow(color: MehdAiTheme.purple.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: MehdAiTheme.purple, borderRadius: BorderRadius.circular(12)),
              child: Text('RECOMMENDED', style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white, fontSize: 10)),
            ),
          Text(title, style: MehdAiTheme.labelStyle),
          const SizedBox(height: 16),
          Text(price, style: MehdAiTheme.priceStyle.copyWith(color: Colors.white, fontSize: 32)),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check, color: MehdAiTheme.green, size: 16),
                const SizedBox(width: 8),
                Text(f, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
              ],
            ),
          )),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? MehdAiTheme.purple : const Color(0xFF30363D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _requestLicense(title),
              child: Text('REQUEST ACCESS', style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
