import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/widgets/symbol_sidebar.dart';
import 'package:mehd_ai_flutter/widgets/den_chart.dart';
import 'package:mehd_ai_flutter/widgets/consensus_bar.dart';
import 'package:mehd_ai_flutter/widgets/ai_terminal.dart';
import 'package:mehd_ai_flutter/screens/history_screen.dart';
import 'package:mehd_ai_flutter/screens/war_room_screen.dart';

import 'package:mehd_ai_flutter/screens/settings_screen.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';
import 'package:mehd_ai_flutter/utils/titan_animations.dart';

class HomeDesktopLayout extends StatefulWidget {
  final TradingController trading;
  final MarketDataController market;

  const HomeDesktopLayout({super.key, required this.trading, required this.market});

  @override
  State<HomeDesktopLayout> createState() => _HomeDesktopLayoutState();
}

class _HomeDesktopLayoutState extends State<HomeDesktopLayout> {
  int _selectedIndex = 0;
  final GlobalKey<DenChartState> _chartKey = GlobalKey<DenChartState>();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() => _selectedIndex = index);
            if (index == 2) {
               // Positions - maybe open bottom sheet or sidebar? no specific screen given.
            } else if (index == 3) {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            } else if (index == 4) {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const WarRoomScreen(isAnalyzing: false)));
            } else if (index == 5) {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }
          },
          labelType: NavigationRailLabelType.none,
          backgroundColor: MehdAiTheme.bgSecondary,
          selectedIconTheme: const IconThemeData(color: Color(0xFF58A6FF)),
          unselectedIconTheme: const IconThemeData(color: MehdAiTheme.textSecondary),
          destinations: [
            NavigationRailDestination(icon: _buildSideIcon('Terminal', Icons.terminal), selectedIcon: const Icon(Icons.terminal), label: const Text('Terminal')),
            NavigationRailDestination(icon: _buildSideIcon('Markets', Icons.candlestick_chart_outlined), selectedIcon: const Icon(Icons.candlestick_chart), label: const Text('Markets')),
            NavigationRailDestination(icon: _buildSideIcon('Positions', Icons.show_chart_rounded), selectedIcon: const Icon(Icons.show_chart_rounded), label: const Text('Positions')),
            NavigationRailDestination(icon: _buildSideIcon('History', Icons.history_rounded), selectedIcon: const Icon(Icons.history_rounded), label: const Text('History')),
            NavigationRailDestination(icon: _buildSideIcon('War Room', Icons.radar_rounded), selectedIcon: const Icon(Icons.radar_rounded), label: const Text('War Room')),
            NavigationRailDestination(icon: _buildSideIcon('Settings', Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: const Text('Settings')),
          ],
        ),
        const VerticalDivider(width: 1, color: MehdAiTheme.borderColor),
        if (_selectedIndex == 0 || _selectedIndex == 1) ...[
          SymbolSidebar(
            activeSymbol: widget.market.activeSymbol ?? '', 
            onSymbolSelected: (s) => widget.market.selectSymbol(s, onStatusMsg: (_) {})
          ),
          const VerticalDivider(width: 1, color: MehdAiTheme.borderColor),
        ],
        Expanded(
          flex: 7,
          child: Column(
            children: [
              Expanded(
                child: widget.market.activeSymbol == null 
                  ? const Center(child: Text('Select Symbol', style: TextStyle(color: Colors.white))) // placeholder EmptyState
                  : (widget.market.latestSnapshot == null 
                    ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                    : Column(
                        children: [
                          _buildChartHeaderArea(),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: TitanAnimations.medium,
                              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                              child: DenChart(
                                key: _chartKey,
                                symbol: widget.market.activeSymbol!,
                                basePrice: widget.market.latestSnapshot!.close,
                                isAutoMode: widget.market.drawingMode != 'MANUAL',
                                activeTool: widget.market.activeTool,
                                commands: widget.market.aiCommands,
                                onEvent: (data) async {
                                   if (data['type'] == 'validate_request') {
                                      final price = (data['price'] as num).toDouble();
                                      await widget.market.validateManualLevel(price);
                                   }
                                },
                              ),
                            ),
                          ),
                        ],
                      )),
              ),
              if (widget.market.activeSymbol != null)
                ConsensusBar(
                  consensus: widget.market.consensus,
                  buttonState: widget.trading.btnState,
                  onTradePressed: () => widget.trading.executeTrade(
                    context: context,
                    consensus: widget.market.consensus,
                    latestSnapshot: widget.market.latestSnapshot,
                    showError: (_) {},
                    onSuccess: () {},
                    onShowBrief: (_) {},
                    onShowAudit: (_) {},
                  ),
                  currentSpread: widget.market.latestSnapshot?.spread ?? 0.0,
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: MehdAiTheme.borderColor),
        Expanded(
          flex: 3,
          child: AiTerminal(
            consensusResult: widget.market.consensus, 
            isAnalyzing: widget.market.isAnalyzing, 
            drawings: const []
          ),
        ),
      ],
    );
  }

  Widget _buildSideIcon(String tooltip, IconData icon) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        color: Color(0xFF58A6FF),
        fontSize: 10,
        letterSpacing: 1,
      ),
      child: Icon(icon),
    );
  }

  Widget _buildChartHeaderArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        border: Border(bottom: BorderSide(color: MehdAiTheme.borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _buildChartHeader(),
          if (widget.market.drawingMode == "MANUAL") ...[
            const SizedBox(height: 8),
            _buildManualToolbar(),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChartHeader() {
    return Row(
      children: [
        Text(widget.market.activeSymbol ?? '', style: MehdAiTheme.labelStyle),
        const Spacer(),
        _buildToggleBtn("AUTO"),
        const SizedBox(width: 8),
        _buildToggleBtn("MANUAL"),
      ],
    );
  }

  Widget _buildManualToolbar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgPrimary.withOpacity(0.5),
        border: const Border(bottom: BorderSide(color: MehdAiTheme.borderColor)),
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

  Widget _buildToggleBtn(String mode) {
    final isSelected = widget.market.drawingMode == mode;
    return GestureDetector(
      onTap: () => widget.market.toggleDrawingMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF58A6FF).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? const Color(0xFF58A6FF) : MehdAiTheme.borderColor),
        ),
        child: Text(
          mode, 
          style: TextStyle(
            color: isSelected ? const Color(0xFF58A6FF) : MehdAiTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
