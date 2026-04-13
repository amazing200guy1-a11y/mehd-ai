import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// Shows a quick-reference help modal explaining core Den concepts.
void showDenHelpModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const DenHelpModal(),
  );
}

class DenHelpModal extends StatelessWidget {
  const DenHelpModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 440,
            constraints: const BoxConstraints(maxHeight: 580),
            decoration: BoxDecoration(
              color: const Color(0xFF080808).withOpacity(0.93),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A2A4A), Color(0xFF0F1A30)],
                          ),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: const Icon(Icons.help_outline_rounded, color: MehdAiTheme.blue, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quick Reference',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Mehd AI Intelligence System',
                              style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.3), size: 20),
                      ),
                    ],
                  ),
                ),
                // Content — 3D Card Grid
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _build3DHelpCard(
                              'THE DEN',
                              Icons.pets_rounded,
                              '11 AI agents hold a boardroom meeting on every trade',
                              const [Color(0xFF3A2A10), Color(0xFF1F1508)],
                              MehdAiTheme.gold,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _build3DHelpCard(
                              '11 AGENTS',
                              Icons.smart_toy_rounded,
                              '3 layers: Underworld, Empire, Olympus',
                              const [Color(0xFF142840), Color(0xFF0B1825)],
                              MehdAiTheme.blue,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _build3DHelpCard(
                              'SOVEREIGN LOCK',
                              Icons.lock_rounded,
                              '7+ agents must agree or the trade button stays locked',
                              const [Color(0xFF2A1540), Color(0xFF150A25)],
                              MehdAiTheme.purple,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _build3DHelpCard(
                              'RISK KERNEL',
                              Icons.shield_rounded,
                              'Max 1% risk per trade. Cannot be bypassed.',
                              const [Color(0xFF0A2A18), Color(0xFF06180E)],
                              MehdAiTheme.green,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _build3DHelpCardWide(
                          'STOP GUARDIAN',
                          Icons.front_hand_rounded,
                          '3 consecutive losses = 24hr account lock. Prevents revenge trading.',
                          const [Color(0xFF3A1515), Color(0xFF200A0A)],
                          MehdAiTheme.red,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Capital is a seed, not a sacrifice.',
                          style: GoogleFonts.outfit(
                            color: MehdAiTheme.gold.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DHelpCard(String title, IconData icon, String desc, List<Color> gradient, Color accent) {
    return Container(
      height: 140,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.03)],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _build3DHelpCardWide(String title, IconData icon, String desc, List<Color> gradient, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.03)],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, height: 1.3)),
            ],
          )),
        ],
      ),
    );
  }
}
