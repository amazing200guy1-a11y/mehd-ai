import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/services/settings_service.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'dart:ui';
import 'dart:math';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final Random _rnd = Random();

  final List<Map<String, dynamic>> _generals = [
    {"rank": 1, "name": "Vanguard Capital", "winRate": 94.2, "pnl": 1250430.50},
    {"rank": 2, "name": "Apex Quant", "winRate": 91.8, "pnl": 984200.00},
    {"rank": 3, "name": "Sandbox Node 0x9", "winRate": 89.5, "pnl": 850100.25},
    {"rank": 4, "name": "Citadel Alpha", "winRate": 88.1, "pnl": 720050.00},
    {"rank": 5, "name": "Retail Killer", "winRate": 85.0, "pnl": 450000.00},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
          scale: 1.0 + (_animController.value * 0.15),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.background(context),
      body: Stack(
        children: [
          // Ambient Glow Orbs
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlowOrb(MehdAiTheme.gold.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildGlowOrb(MehdAiTheme.shieldColor.withOpacity(0.08)),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeaderRow(),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              Expanded(flex: 4, child: _buildLeaderboard()),
                              const SizedBox(height: 16),
                              Expanded(flex: 6, child: _buildAlphaFeed()),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(flex: 4, child: _buildLeaderboard()),
                            const SizedBox(width: 16),
                            Expanded(flex: 6, child: _buildAlphaFeed()),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
            color: MehdAiTheme.text(context).withOpacity(0.02),
            border: Border(bottom: BorderSide(color: MehdAiTheme.border(context))),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: MehdAiTheme.gold, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const Icon(Icons.groups, color: MehdAiTheme.gold, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text("NETWORK COMMUNITY NETWORK", style: MehdAiTheme.headline.copyWith(fontSize: 14, color: MehdAiTheme.gold), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MehdAiTheme.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MehdAiTheme.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.leaderboard, color: MehdAiTheme.gold, size: 18),
                  const SizedBox(width: 8),
                  Text("GLOBAL GENERALS", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.gold, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Expanded(flex: 1, child: Text("RANK", style: MehdAiTheme.labelStyle)),
                  Expanded(flex: 4, child: Text("NODE", style: MehdAiTheme.labelStyle)),
                  Expanded(flex: 2, child: Text("WIN %", style: MehdAiTheme.labelStyle)),
                  Expanded(flex: 3, child: Text("TOTAL PNL", style: MehdAiTheme.labelStyle, textAlign: TextAlign.right)),
                ],
              ),
              Divider(color: MehdAiTheme.border(context), height: 16),
              // List
              Expanded(
                child: ListView.separated(
                  itemCount: _generals.length,
                  separatorBuilder: (c, i) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final gen = _generals[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Text("#${gen['rank']}", style: MehdAiTheme.terminalStyle.copyWith(color: index == 0 ? MehdAiTheme.gold : MehdAiTheme.textDim(context)))),
                          Expanded(flex: 4, child: Text(gen['name'], style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.text(context), fontWeight: index == 0 ? FontWeight.bold : null))),
                          Expanded(flex: 2, child: Text("${gen['winRate']}%", style: MehdAiTheme.dataMono.copyWith(color: MehdAiTheme.green))),
                          Expanded(flex: 3, child: Text("\$${(gen['pnl'] as double).toStringAsFixed(0)}", style: MehdAiTheme.dataMono.copyWith(color: MehdAiTheme.gold), textAlign: TextAlign.right)),
                        ],
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

  Widget _buildAlphaFeed() {
    final isSandbox = context.watch<SettingsService>().sandboxMode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MehdAiTheme.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MehdAiTheme.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar, color: MehdAiTheme.shieldColor, size: 18),
                      const SizedBox(width: 8),
                      Text("LIVE SANDBOX FEED", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.shieldColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSandbox)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: MehdAiTheme.purple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text("SANDBOX ON", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.purple, fontSize: 10)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MehdAiTheme.shieldColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text("SYNCED", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.shieldColor, fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 15,
                  itemBuilder: (context, index) {
                    final isBuy = _rnd.nextBool();
                    final symbol = ["EUR/USD", "GBP/USD", "XAU/USD", "BTC/USD"][_rnd.nextInt(4)];
                    final general = isSandbox
                        ? 'Anonymous Trader'
                        : _generals[_rnd.nextInt(_generals.length)]['name'] as String;
                    final latestPrice = symbol == "BTC/USD" ? 64000.0 : (symbol == "XAU/USD" ? 2400.0 : 1.2500);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MehdAiTheme.text(context).withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MehdAiTheme.border(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 30,
                            color: isBuy ? MehdAiTheme.green : MehdAiTheme.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("$general executed a consensus trade", style: MehdAiTheme.labelStyle),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(isBuy ? "LONG" : "SHORT", style: MehdAiTheme.terminalStyle.copyWith(color: isBuy ? MehdAiTheme.green : MehdAiTheme.red, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text(symbol, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.text(context))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Output Sandbox Button
                          _buildSandboxButton(symbol, isBuy ? "LONG" : "SHORT", latestPrice),
                        ],
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

  Widget _buildSandboxButton(String symbol, String direction, double entryPrice) {
    return GestureDetector(
      onTap: () {
        context.read<TradingController>().executeSandboxTrade(symbol, direction, entryPrice);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sandbox Trade queued for execution.", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.text(context))),
            backgroundColor: MehdAiTheme.surface(context),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          )
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: MehdAiTheme.purple.withOpacity(0.1),
          border: Border.all(color: MehdAiTheme.purple.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: MehdAiTheme.purple.withOpacity(0.2), blurRadius: 8),
          ],
        ),
        child: Text("SANDBOX", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.purple, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
