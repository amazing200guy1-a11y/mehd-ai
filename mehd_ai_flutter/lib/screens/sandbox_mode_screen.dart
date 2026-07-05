import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:mehd_ai_flutter/widgets/mehd_mascot.dart';
import 'package:mehd_ai_flutter/widgets/techno_card.dart';

class SandboxModeScreen extends StatefulWidget {
  const SandboxModeScreen({super.key});

  @override
  State<SandboxModeScreen> createState() => _SandboxModeScreenState();
}

class _SandboxModeScreenState extends State<SandboxModeScreen> with TickerProviderStateMixin {
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  Widget _buildGlowOrb(Color color, {double size = 350}) {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_orbCtrl.value * 0.15),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('DIGITAL TWIN SANDBOX MODE', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
        backgroundColor: MehdAiTheme.bgSecondary,
        iconTheme: const IconThemeData(color: MehdAiTheme.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: Stack(
        children: [
          // Ambient depth
          Positioned(
            top: -80,
            right: -100,
            child: _buildGlowOrb(MehdAiTheme.blue.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: _buildGlowOrb(MehdAiTheme.purple.withOpacity(0.08)),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MehdMascot(isWorking: true, size: 160),
                  const SizedBox(height: 16),
                  Text(
                    '48-Hour Live Market Simulation',
                    style: GoogleFonts.outfit(fontSize: 22, color: MehdAiTheme.textPrimary, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Text(
                            'The Den analyzes live data and executes forward-testing paper trades. If it beats the market by >10%, you earn the CERTIFIED ALPHA badge permanently.',
                            style: MehdAiTheme.labelStyle.copyWith(height: 1.6, color: MehdAiTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const SizedBox(height: 32),

                  _buildRunningState(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningState() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: TechnoCard(
        borderColor: MehdAiTheme.blue,
        child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: MehdAiTheme.blue,
                        shape: BoxShape.circle,
                        boxShadow: MehdAiTheme.blueGlow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('AUTONOMOUS MODE ACTIVE', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Text('The Den is continuously crunching market vectors in the background. You will be notified when high conviction signals arise.', 
                  style: MehdAiTheme.labelStyle.copyWith(height: 1.5, color: MehdAiTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(MehdAiTheme.blue),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
