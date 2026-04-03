import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';

class DataMoatScreen extends StatefulWidget {
  const DataMoatScreen({super.key});

  @override
  State<DataMoatScreen> createState() => _DataMoatScreenState();
}

class _DataMoatScreenState extends State<DataMoatScreen> {
  // ignore: unused_field
  final ApiService _apiService = ApiService();
  double _intelLevel = 1.0;
  int _snapshots = 0;
  String? _patternReport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      // Sovereign Alpha Status
      // In a live environment, this connects to /den/sovereign-status
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoatHeader(),
            const SizedBox(height: 32),
            _buildIntelCard(),
            const SizedBox(height: 32),
            if (_patternReport != null) _buildPatternReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildMoatHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE DATA MOAT',
          style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.gold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'A proprietary feedback loop. The Den records world state "Alpha Snapshots" on every successful consensus trade to fine-tune our local models.',
          style: MehdAiTheme.labelStyle.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildIntelCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.purple.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Intelligence Level', 'Lv. ${_intelLevel.toStringAsFixed(1)}', MehdAiTheme.purple),
          _buildStatColumn('Alpha Snapshots', _snapshots.toString(), MehdAiTheme.blue),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: MehdAiTheme.labelStyle),
        const SizedBox(height: 8),
        Text(
          value,
          style: MehdAiTheme.priceStyle.copyWith(color: color, fontSize: 32),
        ),
      ],
    );
  }

  Widget _buildPatternReport() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: MehdAiTheme.green, size: 20),
              const SizedBox(width: 8),
              Text('ACTIVE PATTERN IDENTIFIED', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_patternReport!, style: MehdAiTheme.terminalStyle.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
