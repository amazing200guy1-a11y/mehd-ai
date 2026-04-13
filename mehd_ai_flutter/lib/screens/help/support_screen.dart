import 'dart:ui';
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
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A).withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MehdAiTheme.red.withOpacity(0.2)),
              ),
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
                      Expanded(child: Text('Device context will be automatically attached.', style: MehdAiTheme.labelStyle.copyWith(fontStyle: FontStyle.italic))),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Explore', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: MehdAiTheme.bgPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Intelligence
            _buildSectionHeader('Intelligence'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _build3DCard(
                  context,
                  'Help Center',
                  Icons.search_rounded,
                  const [Color(0xFF2A5298), Color(0xFF1E3A6E)],
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                )),
                const SizedBox(width: 16),
                Expanded(child: _build3DCard(
                  context,
                  'Den Glossary',
                  Icons.auto_stories_rounded,
                  const [Color(0xFF1A3A4A), Color(0xFF0F2530)],
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DenGlossary())),
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _build3DCard(
                  context,
                  'Video Tutorials',
                  Icons.play_circle_rounded,
                  const [Color(0xFF2D1B4E), Color(0xFF1A0F30)],
                  () async {
                    final url = Uri.parse('https://youtube.com');
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                )),
                const SizedBox(width: 16),
                Expanded(child: _build3DCard(
                  context,
                  'About\nMehd AI',
                  Icons.info_rounded,
                  const [Color(0xFF1A3040), Color(0xFF0F1F2A)],
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                )),
              ],
            ),

            const SizedBox(height: 36),

            // Section: Support
            _buildSectionHeader('Support'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _build3DCard(
                  context,
                  'Report a Bug',
                  Icons.bug_report_rounded,
                  const [Color(0xFF4A1A1A), Color(0xFF2A0F0F)],
                  () => _showBugReportDialog(context),
                  glowColor: MehdAiTheme.red,
                )),
                const SizedBox(width: 16),
                Expanded(child: _build3DCard(
                  context,
                  'Contact Support',
                  Icons.headset_mic_rounded,
                  const [Color(0xFF1A2A4A), Color(0xFF0F1A30)],
                  () async {
                    final url = Uri.parse('https://wa.me/2340000000000');
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  glowColor: MehdAiTheme.blue,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white.withOpacity(0.6),
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
    );
  }

  Widget _build3DCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap, {
    Color glowColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // 3D-style icon container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.04),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 1,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 26),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
