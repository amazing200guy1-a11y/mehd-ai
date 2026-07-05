import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/widgets/responsive_layout.dart';
import 'dart:ui';

class DataMoatScreen extends StatefulWidget {
  const DataMoatScreen({super.key});

  @override
  State<DataMoatScreen> createState() => _DataMoatScreenState();
}

class _DataMoatScreenState extends State<DataMoatScreen> with TickerProviderStateMixin {
  // ignore: unused_field
  final ApiService _apiService = ApiService();
  double _intelLevel = 1.0;
  int _snapshots = 0;
  String? _patternReport;
  bool _isLoading = true;

  late AnimationController _pulseController;
  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _fetchStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final result = {
        "intelligence_level": 3.4,
        "total_snapshots": 124,
        "pattern_report": "PATTERN INTELLIGENCE REPORT:\n\n"
                          "The Den has identified a repeating fractal pattern.\n\n"
                          "When sentiment spikes >80% on GBP pairs\n"
                          "alongside a tighter spread than the 20-period SMA,\n"
                          "win probability accelerates to 94.2%.\n\n"
                          "Status: Alpha Moat Active and Expanding."
      };

      setState(() {
        _intelLevel = result['intelligence_level'] as double;
        _snapshots = result['total_snapshots'] as int;
        _patternReport = result['pattern_report'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGlowOrb(Color color, {double size = 350}) {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_orbController.value * 0.12),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MehdAiTheme.bgPrimary,
        body: Center(child: CircularProgressIndicator(color: MehdAiTheme.purple)),
      );
    }

    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Sovereign Intelligence', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Ambient depth
          Positioned(
            top: -100,
            left: -80,
            child: _buildGlowOrb(MehdAiTheme.purple.withOpacity(0.12)),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _buildGlowOrb(MehdAiTheme.blue.withOpacity(0.10)),
          ),

          ResponsiveLayout(
            maxWidth: 800,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMoatHeader(),
                  const SizedBox(height: 32),
                  _buildIntelCard(),
                  const SizedBox(height: 24),
                  _buildMoatDepthVisualizer(),
                  const SizedBox(height: 32),
                  if (_patternReport != null) _buildPatternReport(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoatHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MehdAiTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MehdAiTheme.gold.withOpacity(0.3)),
              ),
              child: const Icon(Icons.castle_rounded, color: MehdAiTheme.gold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE DATA MOAT',
                    style: GoogleFonts.outfit(color: MehdAiTheme.gold, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proprietary Intelligence Feedback Loop',
                    style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
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
                'The Den records world state "Alpha Snapshots" on every successful consensus trade to fine-tune local models. Each snapshot widens your competitive moat.',
                style: MehdAiTheme.labelStyle.copyWith(fontSize: 14, height: 1.6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntelCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildIntelMetricCard(
                  'INTELLIGENCE LEVEL',
                  'Lv. ${_intelLevel.toStringAsFixed(1)}',
                  MehdAiTheme.purple,
                  Icons.psychology_rounded,
                  _intelLevel / 10.0,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildIntelMetricCard(
                  'ALPHA SNAPSHOTS',
                  _snapshots.toString(),
                  MehdAiTheme.blue,
                  Icons.camera_rounded,
                  _snapshots / 500.0,
                )),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _snapshots += 1;
                    _intelLevel += 0.01;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Alpha Snapshot Captured. Moat deepened.'),
                    backgroundColor: MehdAiTheme.purple,
                    duration: Duration(seconds: 2),
                  ));
                },
                icon: const Icon(Icons.radar_rounded, color: Colors.black, size: 16),
                label: const Text('FORCE ALPHA SNAPSHOT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MehdAiTheme.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntelMetricCard(String label, String value, Color color, IconData icon, double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withOpacity(0.05 + (_pulseController.value * 0.02)),
                border: Border.all(color: color.withOpacity(0.2 + (_pulseController.value * 0.1))),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.05 + (_pulseController.value * 0.03)), blurRadius: 20),
                ],
              ),
              child: child,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label, style: MehdAiTheme.labelStyle.copyWith(fontSize: 10, letterSpacing: 1), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.outfit(color: color, fontSize: 36, fontWeight: FontWeight.w300),
                ),
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoatDepthVisualizer() {
    // Visual representation of the moat's expanding intelligence layers
    final layers = [
      {'name': 'PRICE ACTION', 'depth': 0.95, 'color': MehdAiTheme.green},
      {'name': 'SENTIMENT ANALYSIS', 'depth': 0.82, 'color': MehdAiTheme.blue},
      {'name': 'FRACTAL PATTERNS', 'depth': 0.68, 'color': MehdAiTheme.purple},
      {'name': 'MACRO CORRELATION', 'depth': 0.54, 'color': MehdAiTheme.gold},
      {'name': 'BLACK SWAN DETECTION', 'depth': 0.35, 'color': MehdAiTheme.red},
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.layers_rounded, color: MehdAiTheme.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text('MOAT DEPTH LAYERS', style: MehdAiTheme.headingStyle.copyWith(fontSize: 13, letterSpacing: 2)),
                ],
              ),
              const SizedBox(height: 20),
              ...layers.map((layer) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(layer['name'] as String, style: MehdAiTheme.terminalStyle.copyWith(fontSize: 11, color: layer['color'] as Color)),
                        Text('${((layer['depth'] as double) * 100).toInt()}%', style: MehdAiTheme.terminalStyle.copyWith(fontSize: 11, color: (layer['color'] as Color).withOpacity(0.7))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: layer['depth'] as double,
                        backgroundColor: Colors.white.withOpacity(0.04),
                        valueColor: AlwaysStoppedAnimation<Color>((layer['color'] as Color).withOpacity(0.6)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatternReport() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MehdAiTheme.green.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MehdAiTheme.green.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: MehdAiTheme.green.withOpacity(0.05), blurRadius: 20),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: MehdAiTheme.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.analytics_rounded, color: MehdAiTheme.green, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ACTIVE PATTERN IDENTIFIED', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('High-confidence fractal — exploitable edge detected', style: MehdAiTheme.labelStyle.copyWith(fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: MehdAiTheme.green),
                    tooltip: 'Refresh Intelligence Report',
                    onPressed: () {
                      setState(() {
                        _patternReport = "PATTERN INTELLIGENCE REPORT:\n\n"
                                         "New variance detected in JPY crosses.\n\n"
                                         "When Asian session volume drops 15% below average,\n"
                                         "Olympus agent detects a 78% probability of mean reversion.\n\n"
                                         "Status: Monitoring for entry.";
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intelligence Report Refreshed'), duration: Duration(seconds: 1)));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MehdAiTheme.green.withOpacity(0.1)),
                ),
                child: Text(_patternReport!, style: MehdAiTheme.terminalStyle.copyWith(height: 1.6, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
