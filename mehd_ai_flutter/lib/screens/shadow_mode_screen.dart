import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mehd_ai_flutter/core/constants.dart';

class ShadowModeScreen extends StatefulWidget {
  const ShadowModeScreen({super.key});

  @override
  State<ShadowModeScreen> createState() => _ShadowModeScreenState();
}

class _ShadowModeScreenState extends State<ShadowModeScreen> with SingleTickerProviderStateMixin {
  bool _isRunning = false;
  Map<String, dynamic>? _report;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _runShadowSimulation() async {
    setState(() => _isRunning = true);
    _animCtrl.repeat();
    
    try {
      final response = await http.post(Uri.parse('${AppConstants.baseUrl}/den/shadow'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _report = jsonDecode(response.body);
            _isRunning = false;
            _animCtrl.stop();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _animCtrl.stop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('DIGITAL TWIN SHADOW MODE', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
        backgroundColor: MehdAiTheme.bgSecondary,
        iconTheme: const IconThemeData(color: MehdAiTheme.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animCtrl,
                builder: (_, child) {
                  return Transform.rotate(
                    angle: _isRunning ? _animCtrl.value * 2 * 3.14159 : 0,
                    child: child,
                  );
                },
                child: const Icon(Icons.hub, size: 80, color: MehdAiTheme.blue),
              ),
              const SizedBox(height: 24),
              Text(
                '48-Hour Live Market Simulation',
                style: MehdAiTheme.terminalStyle.copyWith(fontSize: 18, color: MehdAiTheme.textPrimary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: Text(
                  'The Den analyzes live data and executes forward-testing paper trades. If it beats exactly the market by >10%, you natively earn the CERTIFIED ALPHA badge permanently on your profile.',
                  style: MehdAiTheme.labelStyle.copyWith(height: 1.5, color: MehdAiTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              if (_isRunning)
                Column(
                  children: [
                    const CircularProgressIndicator(color: MehdAiTheme.blue),
                    const SizedBox(height: 16),
                    Text('Crunching 48-Hour Vectors...', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue)),
                  ],
                )
              else if (_report == null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MehdAiTheme.blue.withOpacity(0.1),
                    side: const BorderSide(color: MehdAiTheme.blue),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  icon: const Icon(Icons.play_arrow, color: MehdAiTheme.blue),
                  label: Text('ACTIVATE SHADOW MODE', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold)),
                  onPressed: _runShadowSimulation,
                )
              else
                _buildReportCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.yellow),
        boxShadow: [
           BoxShadow(
             color: MehdAiTheme.yellow.withOpacity(0.1),
             blurRadius: 30,
             spreadRadius: 2,
           )
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium, color: MehdAiTheme.yellow),
              const SizedBox(width: 8),
              Text('SHADOW REPORT', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text('48-HOUR ANALYSIS COMPLETE', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textSecondary)),
          const Divider(color: MehdAiTheme.borderColor, height: 32),
          _buildStatRow('Total Signals Processed', _report!['total_signals'].toString()),
          _buildStatRow('Win Rate', '${_report!['win_rate']}%'),
          _buildStatRow('Return vs Market Average', '+${_report!['return_vs_market']}%', color: MehdAiTheme.green),
          _buildStatRow('Best Performing Room', _report!['best_performing_room']),
          _buildStatRow('Worst Performing Pair', _report!['worst_performing_pair']),
          const SizedBox(height: 24),
          if (_report!['certified_alpha'] == true)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MehdAiTheme.green.withOpacity(0.1),
                border: Border.all(color: MehdAiTheme.green),
                borderRadius: BorderRadius.circular(4)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield, color: MehdAiTheme.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'CERTIFIED ALPHA EARNED',
                    style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: MehdAiTheme.labelStyle),
          Text(value, style: MehdAiTheme.terminalStyle.copyWith(color: color ?? MehdAiTheme.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
