import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/models/account_health.dart';
import 'package:mehd_ai_flutter/widgets/den_chart.dart';
import 'package:mehd_ai_flutter/widgets/consensus_bar.dart';
import 'package:mehd_ai_flutter/widgets/ai_terminal.dart';
import 'package:mehd_ai_flutter/screens/settings_screen.dart';
import 'package:mehd_ai_flutter/screens/war_room_community_screen.dart';
import 'package:mehd_ai_flutter/screens/den/the_den_screen.dart';
import 'package:mehd_ai_flutter/widgets/account_health_widget.dart';
import 'package:mehd_ai_flutter/widgets/den_help_modal.dart';
import 'package:mehd_ai_flutter/utils/titan_animations.dart';
import 'package:mehd_ai_flutter/screens/den/strategy_room.dart';
import 'package:mehd_ai_flutter/screens/den/research_room.dart';
import 'package:mehd_ai_flutter/screens/den/positions_screen.dart' as den_pos;
import 'package:mehd_ai_flutter/screens/journey_screen.dart';
import 'package:mehd_ai_flutter/screens/calculators_screen.dart';
import 'package:mehd_ai_flutter/screens/data_moat_screen.dart';
import 'package:mehd_ai_flutter/screens/war_room_screen.dart';
import 'package:mehd_ai_flutter/screens/den/sovereign_feed_screen.dart';
import 'package:mehd_ai_flutter/screens/scoreboard_screen.dart';
import 'package:mehd_ai_flutter/screens/autopilot_command_center.dart';
import 'package:mehd_ai_flutter/screens/den/network_screen.dart';
import 'package:mehd_ai_flutter/screens/sandbox_mode_screen.dart';
import 'package:mehd_ai_flutter/screens/pulse_trading_screen.dart';
import 'package:mehd_ai_flutter/screens/broker_screen.dart';
class HomeMobileLayout extends StatefulWidget {
  final TradingController trading;
  final MarketDataController market;

  const HomeMobileLayout({super.key, required this.trading, required this.market});

  @override
  State<HomeMobileLayout> createState() => _HomeMobileLayoutState();
}

class _HomeMobileLayoutState extends State<HomeMobileLayout> {
  int _mobileTab = 0;
  final GlobalKey<DenChartState> _chartKey = GlobalKey<DenChartState>();
  AccountHealth? _accountHealth;
  bool _healthLoading = false;

  void _fetchAccountHealth() async {
    if (_healthLoading) return;
    setState(() => _healthLoading = true);
    try {
      final health = await ApiService().getAccountHealth();
      if (mounted) setState(() => _accountHealth = health);
    } catch (e) {
      debugPrint('Failed to fetch account health: $e');
    } finally {
      if (mounted) setState(() => _healthLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trading = widget.trading;
    final market = widget.market;

    return Stack(
      children: [
        Column(
          children: [
            // Symbol Bar with Help Icon
            Container(
              height: 60,
              color: MehdAiTheme.surface(context),
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      children: AppConstants.symbols.map((s) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(s, style: MehdAiTheme.labelStyle),
                          selected: s == market.activeSymbol,
                          onSelected: (val) {
                            if (val) market.selectSymbol(s, onStatusMsg: (_) {});
                          },
                          backgroundColor: MehdAiTheme.background(context),
                          selectedColor: MehdAiTheme.blue.withOpacity(0.2),
                        ),
                      )).toList(),
                    ),
                  ),
                  // Help ? Icon
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => showDenHelpModal(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MehdAiTheme.blue.withOpacity(0.1),
                          border: Border.all(color: MehdAiTheme.blue.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.help_outline, color: MehdAiTheme.blue, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Body
            Expanded(
              child: AnimatedSwitcher(
                duration: TitanAnimations.medium,
                switchInCurve: TitanAnimations.emphasized,
                switchOutCurve: TitanAnimations.smooth,
                child: _buildBody(market, trading),
              ),
            ),
            
            // Consensus Action Bar (Terminal only)
            if (_mobileTab == 0 && market.activeSymbol != null) 
              ConsensusBar(
                consensus: market.consensus,
                buttonState: trading.btnState,
                onTradePressed: () => trading.executeTrade(
                  context: context,
                  consensus: market.consensus,
                  latestSnapshot: market.latestSnapshot,
                  showError: (_) {},
                  onSuccess: () {},
                  onShowBrief: (_) {},
                  onShowAudit: (_) {},
                ),
                currentSpread: market.latestSnapshot?.spread ?? 0.0,
              ),
            
            // Navigation
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: MehdAiTheme.surface(context),
              selectedItemColor: MehdAiTheme.blue,
              unselectedItemColor: MehdAiTheme.textSecondary,
              currentIndex: _mobileTab,
              onTap: (i) {
                if (i == 4) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                } else {
                  setState(() => _mobileTab = i);
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'AI TERMINAL'),
                BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'THE DEN'),
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'ACCOUNT'),
                BottomNavigationBarItem(icon: Icon(Icons.scoreboard), label: 'SCOREBOARD'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          ],
        ),
        
        // Floating Action Button (Tiger Circle)
        if (_mobileTab == 0)
          Positioned(
            bottom: 60,
            right: 12,
            child: Tooltip(
              message: 'The Den Action Menu',
              child: GestureDetector(
                onTap: () => _showDenActionMenu(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MehdAiTheme.background(context),
                    border: Border.all(
                      color: const Color(0xFF58A6FF).withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF58A6FF).withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/images/mehd_logo.png', width: 48, height: 48),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(MarketDataController market, TradingController trading) {
    if (_mobileTab == 0) return _buildTerminalTab(market);
    if (_mobileTab == 1) {
      return TheDenScreen(
        key: const ValueKey('tab1'),
        consensusResult: market.consensus,
        isAnalyzing: market.isAnalyzing,
        activeSymbol: market.activeSymbol,
        onClose: () => setState(() => _mobileTab = 0),
      );
    }
    if (_mobileTab == 3) {
      return const ScoreboardScreen();
    }
    // Fetch health data when this tab is first shown
    if (_accountHealth == null && !_healthLoading) {
      _fetchAccountHealth();
    }
    if (_healthLoading && _accountHealth == null) {
      return const Center(child: CircularProgressIndicator(color: MehdAiTheme.blue));
    }
    return AccountHealthWidget(
      key: const ValueKey('tab2'),
      health: _accountHealth,
      recentTrades: trading.recentTrades,
    );
  }

  Widget _buildTerminalTab(MarketDataController market) {
    return Column(
      key: const ValueKey('tab0'),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: market.activeSymbol == null
              ? Center(child: Text('Empty', style: TextStyle(color: MehdAiTheme.text(context))))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(market.activeSymbol!, style: MehdAiTheme.labelStyle.copyWith(fontSize: 10)),
                          Row(
                            children: [
                              _buildToggleBtn("AUTO", market),
                              const SizedBox(width: 8),
                              _buildToggleBtn("MANUAL", market),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          if (market.drawingMode == "MANUAL") _buildManualToolbar(),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: TitanAnimations.medium,
                              child: DenChart(
                                key: _chartKey,
                                symbol: market.activeSymbol!,
                                interval: widget.market.activeInterval,
                                basePrice: market.latestSnapshot?.close ?? 0.0,
                                isAutoMode: market.drawingMode != 'MANUAL',
                                activeTool: market.activeTool,
                                commands: market.aiCommands,
                                onEvent: (data) async {
                                  if (data['type'] == 'price_update') {
                                    final price = (data['price'] as num).toDouble();
                                    widget.market.updatePriceFromChart(price);
                                  }
                                  if (data['type'] == 'validate_request') {
                                    final price = (data['price'] as num).toDouble();
                                    await widget.market.validateManualLevel(price);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        Expanded(
          child: AiTerminal(
            consensusResult: market.consensus,
            isAnalyzing: market.isAnalyzing,
            drawings: const [],
            onStrikeComplete: () => market.executeDrawings(),
          ),
        ),
      ],
    );
  }

  void _showDenActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: MehdAiTheme.surface(context).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: MehdAiTheme.border(context).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: MehdAiTheme.textDim(context).withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('INSTITUTIONAL HUB', 
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 3)),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width < 400 ? 2 : 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                    children: [
                      _buildMenuCard(context, 'WAR ROOM', Icons.radar_rounded, const [Color(0xFF3A0E0E), Color(0xFF1F0707)], const Color(0xFFFF4444),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => WarRoomScreen(isAnalyzing: widget.market.isAnalyzing, consensus: widget.market.consensus))); }),

                      _buildMenuCard(context, 'BROKER SHIELD', Icons.shield_rounded, const [Color(0xFF0E3A18), Color(0xFF061A0C)], const Color(0xFF00FF88),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const BrokerScreen())); }),
                        
                      _buildMenuCard(context, 'SCOREBOARD', Icons.emoji_events_rounded, const [Color(0xFF0E3A18), Color(0xFF061A0C)], const Color(0xFF00FF88),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ScoreboardScreen())); }),
                        
                      _buildMenuCard(context, 'AUTOPILOT', Icons.precision_manufacturing_rounded, const [Color(0xFF0E2A3A), Color(0xFF061520)], const Color(0xFF58A6FF),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AutopilotCommandCenter())); }),
                        
                      _buildMenuCard(context, 'NETWORK', Icons.group_work_rounded, const [Color(0xFF3A2B0E), Color(0xFF1A1306)], const Color(0xFFFFD700),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NetworkScreen())); }),
                        
                      _buildMenuCard(context, 'DATA MOAT', Icons.hub_rounded, const [Color(0xFF0F3D4A), Color(0xFF061A21)], const Color(0xFF00E5FF),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DataMoatScreen())); }),
                        
                      _buildMenuCard(context, 'POSITIONS', Icons.show_chart_rounded, const [Color(0xFF4A3A0E), Color(0xFF211A06)], const Color(0xFFFFD700),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const den_pos.PositionsScreen())); }),
                        
                      _buildMenuCard(context, 'STRATEGY', Icons.account_balance_rounded, const [Color(0xFF0E3A4A), Color(0xFF061A21)], const Color(0xFF00FFCC),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('STRATEGY STRATEGY')), backgroundColor: MehdAiTheme.bgPrimary, body: StrategyRoom(activeSymbol: widget.market.activeSymbol, consensusResult: widget.market.consensus, isAnalyzing: widget.market.isAnalyzing)))); }),
                        
                      _buildMenuCard(context, 'RESEARCH', Icons.travel_explore_rounded, const [Color(0xFF2D1B4E), Color(0xFF1A0F30)], const Color(0xFFBC8CFF),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('RESEARCH INTELLIGENCE')), backgroundColor: MehdAiTheme.bgPrimary, body: ResearchRoom(activeSymbol: widget.market.activeSymbol, consensusResult: widget.market.consensus, isAnalyzing: widget.market.isAnalyzing)))); }),
                        
                      _buildMenuCard(context, 'PULSE', Icons.psychology_rounded, const [Color(0xFF0A2A18), Color(0xFF06180E)], const Color(0xFF00FF88),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PulseTradingScreen())); }),
                        
                      _buildMenuCard(context, 'SANDBOX', Icons.visibility_rounded, const [Color(0xFF1A1040), Color(0xFF0D0820)], const Color(0xFFBC8CFF),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SandboxModeScreen())); }),
                        
                      _buildMenuCard(context, 'JOURNEY', Icons.rocket_launch, const [Color(0xFF4A0E4E), Color(0xFF220526)], const Color(0xFF9E00FF),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const JourneyScreen())); }),
                        
                      _buildMenuCard(context, 'CALCULATOR', Icons.calculate_rounded, const [Color(0xFF2A1C0E), Color(0xFF140D07)], MehdAiTheme.gold,
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorsScreen())); }),
                        
                      _buildMenuCard(context, 'SOVEREIGN', Icons.hub_outlined, const [Color(0xFF0E2A3A), Color(0xFF061520)], const Color(0xFF58A6FF),
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SovereignFeedScreen())); }),
                        
                      _buildMenuCard(context, 'COMMUNITY', Icons.groups_rounded, const [Color(0xFF3A1B5E), Color(0xFF1F0F35)], MehdAiTheme.purple,
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WarRoomCommunityScreen())); }),
                        
                      _buildMenuCard(context, 'SETTINGS', Icons.settings_rounded, const [Color(0xFF1A2030), Color(0xFF0F1520)], Colors.white70,
                        () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, List<Color> gradient, Color accentColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.5),
          boxShadow: [
            BoxShadow(color: gradient[0].withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String mode, MarketDataController market) {
    final isSelected = market.drawingMode == mode;
    return GestureDetector(
      onTap: () => market.toggleDrawingMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF58A6FF).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? const Color(0xFF58A6FF) : MehdAiTheme.border(context)),
        ),
        child: Text(
          mode, 
          style: TextStyle(
            color: isSelected ? const Color(0xFF58A6FF) : MehdAiTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildManualToolbar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MehdAiTheme.surface(context),
        border: Border(bottom: BorderSide(color: MehdAiTheme.border(context))),
      ),
      child: Row(
        children: [
          _buildToolBtn('H-LINE', 'hline'),
          _buildToolBtn('FIB', 'fib'),
          _buildToolBtn('TREND', 'trend'),
          const Spacer(),
          GestureDetector(
            onTap: () {
              _chartKey.currentState?.clearDrawings();
              widget.market.clearConsensus();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1A0000)),
                borderRadius: BorderRadius.circular(3)
              ),
              child: const Text('CLR', style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn(String label, String tool) {
    final isActive = widget.market.activeTool == tool;
    return GestureDetector(
      onTap: () => widget.market.setActiveTool(tool),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF222222)),
          color: isActive ? const Color(0xFF020810) : Colors.transparent,
          borderRadius: BorderRadius.circular(3)
        ),
        child: Text(label, style: TextStyle(color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF666666), fontSize: 9, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
