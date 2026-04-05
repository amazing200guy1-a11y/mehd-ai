import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/widgets/symbol_sidebar.dart';
import 'package:mehd_ai_flutter/widgets/zen_chart.dart';
import 'package:mehd_ai_flutter/widgets/consensus_bar.dart';
import 'package:mehd_ai_flutter/widgets/ai_terminal.dart';
import 'package:mehd_ai_flutter/screens/history_screen.dart';
import 'package:mehd_ai_flutter/screens/war_room_screen.dart';
import 'package:mehd_ai_flutter/screens/war_room_community_screen.dart';
import 'package:mehd_ai_flutter/screens/settings_screen.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';
import 'package:mehd_ai_flutter/widgets/den_animation.dart';
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
               Navigator.push(context, MaterialPageRoute(builder: (_) => const WarRoomCommunityScreen()));
            } else if (index == 6) {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }
          },
          labelType: NavigationRailLabelType.none,
          backgroundColor: MehdAiTheme.bgSecondary,
          selectedIconTheme: const IconThemeData(color: Color(0xFF58A6FF)),
          unselectedIconTheme: const IconThemeData(color: MehdAiTheme.textSecondary),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.candlestick_chart_outlined), selectedIcon: Icon(Icons.candlestick_chart), label: Text('Terminal')),
            NavigationRailDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: Text('Markets')),
            NavigationRailDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: Text('Positions')),
            NavigationRailDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: Text('History')),
            NavigationRailDestination(icon: Icon(Icons.radar), selectedIcon: Icon(Icons.radar), label: Text('War Room')),
            NavigationRailDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: Text('Platoon')),
            NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
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
                    : AnimatedSwitcher(
                        duration: TitanAnimations.medium,
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                        child: ZenChart(
                          key: ValueKey(widget.market.activeSymbol),
                          currentPrice: widget.market.latestSnapshot!, 
                          currentConsensus: widget.market.consensus,
                          denState: widget.market.isAnalyzing ? DenState.activation : DenState.idle,
                          onDrawingsUpdated: (d) {},
                        ),
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
                    showError: (err) {},
                    onSuccess: () {},
                    onShowBrief: (b) {},
                    onShowAudit: (a) {},
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
}
