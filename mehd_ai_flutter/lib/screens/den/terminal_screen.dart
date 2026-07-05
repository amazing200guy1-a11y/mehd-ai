import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> with TickerProviderStateMixin {
  final List<String> _matrixLogs = [];
  Timer? _matrixTimer;
  final Random _rnd = Random();
  late ScrollController _scrollController;
  late AnimationController _animController;
  
  final List<String> _agentNames = ["DON", "PHANTOM", "ORACLE", "CAESAR", "SAGE", "GUARDIAN", "TITAN", "ATLAS", "FORGE"];
  final List<String> _actions = [
    "Analyzing order book depth at",
    "Detecting anomalous volume near",
    "Cross-referencing Fibonacci resonance at",
    "Validating sentiment delta against",
    "Executing sub-routine calculus on",
    "Overriding threshold limits for"
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _startMatrixFeed();
  }

  void _startMatrixFeed() {
    _matrixTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) return;
      setState(() {
        final agent = _agentNames[_rnd.nextInt(_agentNames.length)];
        final action = _actions[_rnd.nextInt(_actions.length)];
        final val = (1.2000 + _rnd.nextDouble() * 0.1).toStringAsFixed(5);
        final conf = (75 + _rnd.nextDouble() * 24).toStringAsFixed(1);
        
        final timestamp = "${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}:${DateTime.now().second.toString().padLeft(2,'0')}.${DateTime.now().millisecond.toString().padLeft(3,'0')}";
        
        _matrixLogs.add("[$timestamp] $agent: $action $val [CONF: $conf%]");
        
        if (_matrixLogs.length > 100) {
          _matrixLogs.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _matrixTimer?.cancel();
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildGlowOrb(Color color) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_animController.value * 0.2),
          child: Container(
            width: 500,
            height: 500,
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
          // Ambient Glow Orbs for Glassmorphic Depth
          Positioned(
            top: -150,
            left: -150,
            child: _buildGlowOrb(MehdAiTheme.shieldColor.withOpacity(0.12)),
          ),
          Positioned(
            bottom: -200,
            right: -100,
            child: _buildGlowOrb(MehdAiTheme.purple.withOpacity(0.08)),
          ),
          Positioned(
            top: 200,
            right: 200,
            child: _buildGlowOrb(MehdAiTheme.green.withOpacity(0.05)),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeaderRow(),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // On narrow screens, stack vertically instead of side-by-side
                      if (constraints.maxWidth < 600) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              Expanded(flex: 4, child: _buildOrderBook()),
                              const SizedBox(height: 16),
                              Expanded(flex: 6, child: _buildAIIntercom()),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: _buildOrderBook()),
                            const SizedBox(width: 16),
                            Expanded(flex: 7, child: _buildAIIntercom()),
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
              const Icon(Icons.code, color: MehdAiTheme.shieldColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text("QUANTITATIVE TERMINAL", style: MehdAiTheme.headline.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Flexible(child: _buildStatusBadge("LATENCY", "12ms", MehdAiTheme.green)),
              const SizedBox(width: 8),
              Flexible(child: _buildStatusBadge("DATA STREAM", "SECURE", MehdAiTheme.shieldColor)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text("$label: ", style: MehdAiTheme.terminalStyle.copyWith(fontSize: 10, color: MehdAiTheme.textSecondary)),
          Text(value, style: MehdAiTheme.terminalStyle.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOrderBook() {
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
              Text("LEVEL 2 DEPTH", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // ASKS (RED)
              Expanded(
                child: ListView.builder(
                  itemCount: 15,
                  reverse: true, // Asks go up from center
                  itemBuilder: (context, index) {
                    final price = 1.25000 + ((15 - index) * 0.00010);
                    final size = _rnd.nextInt(500) + 10;
                    return _buildBookRow(price, size, MehdAiTheme.red);
                  },
                ),
              ),
              // SPREAD
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MehdAiTheme.gold.withOpacity(0.3)),
                  color: MehdAiTheme.gold.withOpacity(0.05),
                ),
                child: Center(
                  child: Text("SPREAD 0.4 PIP", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.gold, fontSize: 11)),
                ),
              ),
              // BIDS (GREEN)
              Expanded(
                child: ListView.builder(
                  itemCount: 15,
                  itemBuilder: (context, index) {
                    final price = 1.24996 - (index * 0.00010);
                    final size = _rnd.nextInt(500) + 10;
                    return _buildBookRow(price, size, MehdAiTheme.green);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookRow(double price, int size, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(price.toStringAsFixed(5), style: MehdAiTheme.dataMono.copyWith(color: color, fontSize: 13)),
          Text(size.toString().padLeft(4, ' '), style: MehdAiTheme.dataMono.copyWith(color: MehdAiTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAIIntercom() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("THE DEN :: RAW INTERCOM", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.shieldColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Newest at bottom
                  itemCount: _matrixLogs.length,
                  itemBuilder: (context, index) {
                    final log = _matrixLogs[_matrixLogs.length - 1 - index];
                    
                    Color logColor = MehdAiTheme.textSecondary;
                    if (log.contains("TITAN") || log.contains("ATLAS") || log.contains("FORGE")) {
                      logColor = MehdAiTheme.gold;
                    } else if (log.contains("CAESAR") || log.contains("SAGE") || log.contains("GUARDIAN")) {
                      logColor = MehdAiTheme.purple;
                    } else if (log.contains("DON") || log.contains("PHANTOM") || log.contains("ORACLE")) {
                      logColor = MehdAiTheme.shieldColor;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        log,
                        style: MehdAiTheme.terminalStyle.copyWith(color: logColor, fontSize: 13, height: 1.5),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MehdAiTheme.green.withOpacity(0.5)),
                  color: MehdAiTheme.green.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: MehdAiTheme.green, size: 10),
                    const SizedBox(width: 12),
                    Text("SYSTEM ARMED. AWAITING TRADE SIGNAL...", style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
