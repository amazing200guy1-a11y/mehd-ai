import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mehd_ai_flutter/screens/help/help_center_screen.dart';
import 'package:mehd_ai_flutter/screens/help/about_screen.dart';
import 'package:mehd_ai_flutter/screens/den_glossary.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: MehdAiTheme.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: MehdAiTheme.borderColor)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPORT A SYSTEM ANOMALY', style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.red)),
              const SizedBox(height: 24),
              Text('What were you trying to do?', style: MehdAiTheme.labelStyle),
              const SizedBox(height: 8),
              TextField(
                maxLines: 2,
                style: MehdAiTheme.terminalStyle,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              Text('What actually happened?', style: MehdAiTheme.labelStyle),
              const SizedBox(height: 8),
              TextField(
                maxLines: 4,
                style: MehdAiTheme.terminalStyle,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.memory, color: MehdAiTheme.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text('Device context will be automatically attached.', style: MehdAiTheme.labelStyle.copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('CANCEL', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: MehdAiTheme.red, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: MehdAiTheme.green,
                          content: Text("Anomaly logged. The Den's engineering team will process this within 24 hours.", style: MehdAiTheme.terminalStyle),
                        )
                      );
                    },
                    child: Text('SUBMIT REPORT', style: MehdAiTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Support Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOW CAN THE DEN ASSIST YOU?', style: MehdAiTheme.headingStyle.copyWith(fontSize: 24)),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.5,
                  children: [
                    _buildSupportCard(
                      context,
                      'Help Center / FAQ',
                      'Search our extensive knowledge base for immediate answers.',
                      Icons.search,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                    ),
                    _buildSupportCard(
                      context,
                      'Den Glossary',
                      'Learn the function of all 11 specialized agents.',
                      Icons.book_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DenGlossary())),
                    ),
                    _buildSupportCard(
                      context,
                      'Video Tutorials',
                      'Watch Institutional trading workflows in action.',
                      Icons.play_circle_outline,
                      onTap: () async {
                        final url = Uri.parse('https://youtube.com');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                    ),
                    _buildSupportCard(
                      context,
                      'Report a Bug',
                      'Found an anomaly? Let our engineering team know.',
                      Icons.bug_report_outlined,
                      onTap: () => _showBugReportDialog(context),
                      color: MehdAiTheme.red,
                    ),
                    _buildSupportCard(
                      context,
                      'Contact Support',
                      'Direct WhatsApp or Email lines to priority support.',
                      Icons.support_agent,
                      onTap: () async {
                        final url = Uri.parse('https://wa.me/2340000000000'); // Priority line
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                      color: MehdAiTheme.blue,
                    ),
                    _buildSupportCard(
                      context,
                      'About Mehd AI',
                      'Version details and legal documents.',
                      Icons.info_outline,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                    ),

                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, String title, String subtitle, IconData icon, {required VoidCallback onTap, Color color = MehdAiTheme.textPrimary}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: MehdAiTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MehdAiTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(title, style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(subtitle, style: MehdAiTheme.labelStyle.copyWith(height: 1.4, color: MehdAiTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
