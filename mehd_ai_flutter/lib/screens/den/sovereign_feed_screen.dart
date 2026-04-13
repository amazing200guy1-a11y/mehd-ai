import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui';

class SovereignFeedScreen extends StatefulWidget {
  const SovereignFeedScreen({super.key});

  @override
  State<SovereignFeedScreen> createState() => _SovereignFeedScreenState();
}

class _SovereignFeedScreenState extends State<SovereignFeedScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _alphaSnapshots = 1540;
  final List<String> _logs = [
    "[15:42:01] SYSTEM INIT: Global Consensus Stream Online.",
    "[15:42:05] DATA MOAT: Fetching verified signatures...",
  ];
  Timer? _simTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _startSimulation();
  }

  void _startSimulation() {
    // Simulating the Firebase stream for now
    _simTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        if (_logs.length > 20) _logs.removeAt(0); // Keep log short
        
        // Random intelligence events
        final events = [
            "Auditor fixed FOMO paradox in GBP/USD Constitution.",
            "Alpha Snapshot Secured: 98.7% Consensus Reached.",
            "Sentinel blocked anomalous volatility in Gold.",
            "Titan backtest completed: 14 new vectors added to Moat.",
            "Data Purity Score at 99.1%. Synchronizing layers..."
        ];
        
        final evt = events[DateTime.now().millisecond % events.length];
        final timeStr = "${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}:${DateTime.now().second.toString().padLeft(2,'0')}";
        
        _logs.add("[$timeStr] $evt");
        
        if (evt.contains("Snapshot")) {
            _alphaSnapshots += 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlowOrb(MehdAiTheme.shieldColor.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -150,
            left: -50,
            child: _buildGlowOrb(MehdAiTheme.purple.withOpacity(0.15)),
          ),
          
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Top Row Metrics
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildCounterCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatusCard("SENTINEL", "ACTIVE", MehdAiTheme.green)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatusCard("AUDITOR", "SYNCING", MehdAiTheme.gold)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // The Live Log
                  Text("GLOBAL INTELLIGENCE LEDGER", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildLogTerminal(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb(Color color) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_animController.value * 0.1),
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, Colors.transparent],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.hub, color: MehdAiTheme.shieldColor, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SOVEREIGN STREAM", style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text("Institutional Data Moat View", style: MehdAiTheme.labelStyle),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("GLOBAL ALPHA SNAPSHOTS", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.shieldColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, -0.5), end: Offset.zero).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Text(
                  _alphaSnapshots.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                  key: ValueKey<int>(_alphaSnapshots),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusCard(String title, String val, Color color) {
     return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 140, // Match height of counter
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.memory, color: color, size: 24),
               const SizedBox(height: 8),
               Text(title, style: MehdAiTheme.terminalStyle.copyWith(fontSize: 10, color: MehdAiTheme.textSecondary)),
               const SizedBox(height: 4),
               Text(val, style: MehdAiTheme.terminalStyle.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogTerminal() {
     return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MehdAiTheme.borderColor),
          ),
          child: ListView.builder(
            itemCount: _logs.length,
            itemBuilder: (context, index) {
               // Reverse list so newest is at top visually
               final log = _logs[_logs.length - 1 - index];
               
               Color textColor = MehdAiTheme.textPrimary;
               if (log.contains("Auditor")) textColor = MehdAiTheme.gold;
               if (log.contains("Secured")) textColor = MehdAiTheme.shieldColor;
               if (log.contains("Sentinel")) textColor = MehdAiTheme.purple;
               
               return Padding(
                 padding: const EdgeInsets.only(bottom: 8.0),
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(">", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(log, style: MehdAiTheme.terminalStyle.copyWith(color: textColor))),
                   ],
                 ),
               );
            },
          ),
        ),
      ),
    );
  }
}
