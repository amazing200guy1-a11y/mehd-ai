import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:mehd_ai_flutter/widgets/zen_chart.dart';
import 'package:mehd_ai_flutter/widgets/consensus_bar.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';
import 'package:mehd_ai_flutter/widgets/ai_terminal.dart';
import 'package:mehd_ai_flutter/screens/den/the_den_screen.dart';
import 'package:mehd_ai_flutter/widgets/account_health_widget.dart';
import 'package:mehd_ai_flutter/screens/settings_screen.dart';

class HomeMobileLayout extends StatefulWidget {
  final TradingController trading;
  final MarketDataController market;

  const HomeMobileLayout({super.key, required this.trading, required this.market});

  @override
  State<HomeMobileLayout> createState() => _HomeMobileLayoutState();
}

class _HomeMobileLayoutState extends State<HomeMobileLayout> {
  int _mobileTab = 0;

  @override
  Widget build(BuildContext context) {
    final trading = widget.trading;
    final market = widget.market;

    return Column(
      children: [
        Container(
          height: 60,
          color: MehdAiTheme.bgSecondary,
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
                backgroundColor: MehdAiTheme.bgPrimary,
                selectedColor: MehdAiTheme.blue.withOpacity(0.2),
              ),
            )).toList(),
          ),
        ),
        
        Expanded(
          child: IndexedStack(
            index: _mobileTab,
            children: [
              // Tab 0
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: market.activeSymbol == null 
                      ? const Center(child: Text('Empty', style: TextStyle(color: Colors.white)))
                      : (market.latestSnapshot == null 
                        ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                        : ZenChart(
                            currentPrice: market.latestSnapshot!, 
                            currentConsensus: market.consensus, 
                            onDrawingsUpdated: (d) {},
                          )),
                  ),
                  Expanded(
                    child: AiTerminal(
                      consensusResult: market.consensus, 
                      isAnalyzing: market.isAnalyzing, 
                      drawings: const []
                    ),
                  ),
                ],
              ),
              // Tab 1
              TheDenScreen(
                consensusResult: market.consensus,
                isAnalyzing: market.isAnalyzing,
                activeSymbol: market.activeSymbol,
                onClose: () => setState(() => _mobileTab = 0),
              ),
              // Tab 2
              AccountHealthWidget(
                health: null, // Account health wrapper
                recentTrades: trading.recentTrades,
              ),
            ],
          ),
        ),
        
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
        
        BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: MehdAiTheme.bgSecondary,
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
    );
  }
}
