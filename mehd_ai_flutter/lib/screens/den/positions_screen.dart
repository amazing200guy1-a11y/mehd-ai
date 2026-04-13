import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'dart:ui';

class PositionsScreen extends StatefulWidget {
  const PositionsScreen({super.key});

  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

  double get _totalPnl {
    final active = context.read<TradingController>().activePositions;
    return active.fold(0.0, (sum, item) => sum + (item['pnl'] as double));
  }

  @override
  Widget build(BuildContext context) {
    final trading = context.watch<TradingController>();
    final activePairs = trading.activePositions;
    final double totalPnl = _totalPnl;
    final bool isOverallProfit = totalPnl >= 0;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient Glow Orbs
          Positioned(
            top: -100,
            right: -50,
            child: _buildGlowOrb((isOverallProfit ? MehdAiTheme.green : MehdAiTheme.red).withOpacity(0.1)),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _buildGlowOrb(MehdAiTheme.shieldColor.withOpacity(0.08)),
          ),
          
          Column(
            children: [
              _buildHeaderRow(),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Top Row Metrics & Kill Switch
                      _buildMetricsRow(isOverallProfit, totalPnl, activePairs.length),
                      const SizedBox(height: 24),
                      // The Ledger
                      Expanded(child: _buildPositionsLedger(activePairs)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            border: const Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              const Icon(Icons.show_chart, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text("ACTIVE RISK LEDGER", style: MehdAiTheme.headline.copyWith(fontSize: 14, color: Colors.white, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(bool isOverallProfit, double totalPnl, int tradeCount) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildMetricCard(
            "FLOATING PNL", 
            "\$${totalPnl.abs().toStringAsFixed(2)}", 
            isOverallProfit ? MehdAiTheme.green : MehdAiTheme.red,
            prefix: isOverallProfit ? "+" : "-"
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard("TOTAL EXPOSURE", "\$${(tradeCount * 125000).toStringAsFixed(2)}", MehdAiTheme.shieldColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard("MARGIN LEVEL", "452.1%", MehdAiTheme.gold),
        ),
        const SizedBox(width: 16),
        // The Kill Switch
        _buildKillSwitch(),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, {String prefix = ""}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (prefix.isNotEmpty)
                    Text(prefix, style: MehdAiTheme.dataMono.copyWith(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(value, style: MehdAiTheme.dataMono.copyWith(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKillSwitch() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: GestureDetector(
          onTap: () {
            context.read<TradingController>().closeAllPositions();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("KILL SWITCH ACTIVATED. All live positions liquidated.", style: MehdAiTheme.terminalStyle),
                backgroundColor: MehdAiTheme.red,
                behavior: SnackBarBehavior.floating,
              )
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: MehdAiTheme.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MehdAiTheme.red.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: MehdAiTheme.red.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: MehdAiTheme.red, size: 28),
                const SizedBox(height: 8),
                Text("CLOSE ALL", style: MehdAiTheme.headline.copyWith(color: MehdAiTheme.red, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionsLedger(List<Map<String, dynamic>> activePositions) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                  color: Colors.white24,
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text("TICKET", style: MehdAiTheme.labelStyle)),
                    Expanded(flex: 3, child: Text("SYMBOL", style: MehdAiTheme.labelStyle)),
                    Expanded(flex: 2, child: Text("TYPE", style: MehdAiTheme.labelStyle)),
                    Expanded(flex: 2, child: Text("ENTRY", style: MehdAiTheme.labelStyle, textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text("CURRENT", style: MehdAiTheme.labelStyle, textAlign: TextAlign.right)),
                    Expanded(flex: 3, child: Text("PROFIT / LOSS", style: MehdAiTheme.labelStyle, textAlign: TextAlign.right)),
                    const SizedBox(width: 48), // Action Space
                  ],
                ),
              ),
              // Body
              Expanded(
                child: activePositions.isEmpty 
                  ? Center(
                      child: Text("NO ACTIVE POSITIONS IN LEDGER", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, letterSpacing: 2)),
                    )
                  : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: activePositions.length,
                  separatorBuilder: (c, i) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final pos = activePositions[index];
                    final pnl = pos['pnl'] as double;
                    final isProfit = pnl >= 0;
                    final pnlColor = isProfit ? MehdAiTheme.green : MehdAiTheme.red;
                    final typeColor = pos['type'] == 'LONG' ? MehdAiTheme.green : MehdAiTheme.red;
                    
                    return InkWell(
                      onTap: () {},
                      hoverColor: Colors.white.withOpacity(0.02),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(pos['id'], style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, fontSize: 12))),
                            Expanded(flex: 3, child: Text(pos['symbol'], style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text(pos['type'], style: MehdAiTheme.terminalStyle.copyWith(color: typeColor, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text((pos['entry'] as double).toStringAsFixed(5), style: MehdAiTheme.dataMono, textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text((pos['current'] as double).toStringAsFixed(5), style: MehdAiTheme.dataMono, textAlign: TextAlign.right)),
                            Expanded(
                              flex: 3, 
                              child: Text(
                                "${isProfit ? '+' : '-'}\$${pnl.abs().toStringAsFixed(2)}", 
                                style: MehdAiTheme.dataMono.copyWith(color: pnlColor, fontWeight: FontWeight.bold, fontSize: 16), 
                                textAlign: TextAlign.right
                              )
                            ),
                            const SizedBox(width: 24),
                            // Close Button
                            IconButton(
                              onPressed: () {
                                context.read<TradingController>().closePosition(pos['id']);
                              },
                              icon: const Icon(Icons.close, color: MehdAiTheme.textSecondary, size: 20),
                              tooltip: "Close Position",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
