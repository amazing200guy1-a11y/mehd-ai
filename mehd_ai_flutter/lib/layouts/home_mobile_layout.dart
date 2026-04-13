import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:mehd_ai_flutter/widgets/den_chart.dart';
import 'package:mehd_ai_flutter/widgets/consensus_bar.dart';
import 'package:mehd_ai_flutter/widgets/ai_terminal.dart';
import 'package:mehd_ai_flutter/screens/settings_screen.dart';
import 'package:mehd_ai_flutter/screens/war_room_community_screen.dart';
import 'package:mehd_ai_flutter/screens/den/the_den_screen.dart';
import 'package:mehd_ai_flutter/widgets/account_health_widget.dart';
import 'package:mehd_ai_flutter/utils/titan_animations.dart';
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

  @override
  Widget build(BuildContext context) {
    final trading = widget.trading;
    final market = widget.market;

    return Stack(
      children: [
        Column(
          children: [
            // Symbol Bar
            Container(
              height: 60,
              color: MehdAiTheme.surface(context),
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
                if (i == 3) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                } else {
                  setState(() => _mobileTab = i);
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'AI TERMINAL'),
                BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'THE DEN'),
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'ACCOUNT'),
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
    return AccountHealthWidget(
      key: const ValueKey('tab2'),
      health: null,
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
                                basePrice: market.latestSnapshot!.close,
                                isAutoMode: market.drawingMode != 'MANUAL',
                                activeTool: market.activeTool,
                                commands: market.aiCommands,
                                onEvent: (data) async {
                                  if (data['type'] == 'validate_request') {
                                    final price = (data['price'] as num).toDouble();
                                    await market.validateManualLevel(price);
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
          ),
        ),
      ],
    );
  }

  void _showDenActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: MehdAiTheme.surface(context).withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: MehdAiTheme.border(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: MehdAiTheme.textDim(context).withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              _buildMenuAction(
                context, 
                'WAR ROOM COMMUNITY', 
                Icons.groups, 
                MehdAiTheme.purple,
                () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WarRoomCommunityScreen()));
                }
              ),
              _buildMenuAction(
                context, 
                'THE DEN (ROOMS)', 
                Icons.account_tree, 
                MehdAiTheme.blue,
                () {
                  Navigator.pop(context);
                  setState(() => _mobileTab = 1);
                }
              ),
              _buildMenuAction(
                context, 
                'GLOBAL SETTINGS', 
                Icons.settings, 
                MehdAiTheme.textPrimary,
                () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuAction(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: MehdAiTheme.headingStyle.copyWith(fontSize: 14, color: color)),
      onTap: onTap,
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
