import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/widgets/executive_brief_dialog.dart';

class CommunityFundScreen extends StatelessWidget {
  const CommunityFundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('COMMUNITY FUND PUBLIC LEDGER', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
        backgroundColor: MehdAiTheme.bgSecondary,
        iconTheme: const IconThemeData(color: MehdAiTheme.textPrimary),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildMetricsHeader(),
            const SizedBox(height: 32),
            _buildPerformanceChart(),
            const SizedBox(height: 32),
            _buildLedgerList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsHeader() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('AUM (Paper)', '\$14.2M')),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('All-Time Return', '+184.2%', color: MehdAiTheme.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Win Rate', '81.4%')),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Active Den Configs', '24')),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, size: 14, color: MehdAiTheme.textSecondary),
              const SizedBox(width: 6),
              Text(title, style: MehdAiTheme.labelStyle),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: MehdAiTheme.terminalStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: color ?? MehdAiTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      height: 400,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PERFORMANCE VS BENCHMARKS', style: MehdAiTheme.headingStyle),
              const Spacer(),
              _buildLegend('Mehd AI', MehdAiTheme.green),
              const SizedBox(width: 16),
              _buildLegend('S&P 500', MehdAiTheme.blue),
              const SizedBox(width: 16),
              _buildLegend('Gold', MehdAiTheme.yellow),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Stack(
              children: [
                _buildGridLines(),
                _buildPerformanceLine(MehdAiTheme.yellow, [100, 98, 105, 104, 112, 109, 118], 2.0, false),
                _buildPerformanceLine(MehdAiTheme.blue, [100, 105, 102, 110, 108, 115, 122], 2.0, false),
                _buildPerformanceLine(MehdAiTheme.green, [100, 120, 115, 140, 160, 200, 284], 4.0, true), // Main line with gradient
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGridLines() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (_) => const Divider(color: MehdAiTheme.borderColor, thickness: 1)),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: MehdAiTheme.labelStyle),
      ],
    );
  }

  Widget _buildPerformanceLine(Color color, List<double> points, double stroke, bool withGradient) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _SparklinePainter(color: color, points: points, strokeWidth: stroke, withGradient: withGradient),
    );
  }


  Widget _buildLedgerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT PUBLIC EXECUTIONS', style: MehdAiTheme.headingStyle),
        const SizedBox(height: 16),
        Builder(builder: (context) => Column(children: [
          _buildLedgerRow(context, 'EUR/USD', 'BUY', '+42 pips', '2 mins ago', MehdAiTheme.green, 'cf-eurusd-001'),
          _buildLedgerRow(context, 'GBP/JPY', 'SELL', '+114 pips', '1 hour ago', MehdAiTheme.green, 'cf-gbpjpy-002'),
          _buildLedgerRow(context, 'XAU/USD', 'BUY', '-12 pips', '3 hours ago', MehdAiTheme.red, 'cf-xauusd-003'),
          _buildLedgerRow(context, 'BTC/USD', 'SELL', '+850 pips', '5 hours ago', MehdAiTheme.green, 'cf-btcusd-004'),
        ])),
      ],
    );
  }

  Widget _buildLedgerRow(BuildContext context, String pair, String dir, String result, String time, Color color, String tradeId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 80, child: Text(pair, style: MehdAiTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold))),
          SizedBox(width: 60, child: Text(dir, style: MehdAiTheme.labelStyle)),
          Text(result, style: MehdAiTheme.terminalStyle.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(time, style: MehdAiTheme.labelStyle),
          TextButton(
             onPressed: () async {
               final brief = await ApiService().getExecutiveBrief(tradeId);
               if (brief != null && context.mounted) {
                 showDialog(context: context, builder: (_) => ExecutiveBriefDialog(brief: brief));
               }
             },
             child: Text('VIEW BRIEF', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontSize: 12)),
          )
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  final List<double> points;
  final double strokeWidth;
  final bool withGradient;

  _SparklinePainter({required this.color, required this.points, required this.strokeWidth, this.withGradient = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    
    final double maxVal = points.reduce((a, b) => a > b ? a : b) * 1.1;
    final double minVal = points.reduce((a, b) => a < b ? a : b) * 0.9;
    final double stepX = size.width / (points.length - 1);
    
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - ((points[i] - minVal) / (maxVal - minVal) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    if (withGradient) {
      final gradientPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      final paintGradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
        
      canvas.drawPath(gradientPath, paintGradient);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
