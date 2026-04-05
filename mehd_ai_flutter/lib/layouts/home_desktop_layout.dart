import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/widgets/symbol_sidebar.dart';
import 'package:mehd_ai_flutter/widgets/zen_chart.dart';
import 'package:mehd_ai_flutter/widgets/consensus_bar.dart';
import 'package:mehd_ai_flutter/widgets/ai_terminal.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';

class HomeDesktopLayout extends StatelessWidget {
  final TradingController trading;
  final MarketDataController market;

  const HomeDesktopLayout({super.key, required this.trading, required this.market});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SymbolSidebar(
          activeSymbol: market.activeSymbol ?? '', 
          onSymbolSelected: (s) => market.selectSymbol(s, onStatusMsg: (_) {})
        ),
        const VerticalDivider(width: 1, color: MehdAiTheme.borderColor),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              Expanded(
                child: market.activeSymbol == null 
                  ? const Center(child: Text('Select Symbol', style: TextStyle(color: Colors.white))) // placeholder EmptyState
                  : (market.latestSnapshot == null 
                    ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                    : ZenChart(
                        currentPrice: market.latestSnapshot!, 
                        currentConsensus: market.consensus,
                        onDrawingsUpdated: (d) {},
                      )),
              ),
              if (market.activeSymbol != null)
                ConsensusBar(
                  consensus: market.consensus,
                  buttonState: trading.btnState,
                  onTradePressed: () => trading.executeTrade(
                    context: context,
                    consensus: market.consensus,
                    latestSnapshot: market.latestSnapshot,
                    showError: (err) {},
                    onSuccess: () {},
                    onShowBrief: (b) {},
                    onShowAudit: (a) {},
                  ),
                  currentSpread: market.latestSnapshot?.spread ?? 0.0,
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: MehdAiTheme.borderColor),
        Expanded(
          flex: 3,
          child: AiTerminal(
            consensusResult: market.consensus, 
            isAnalyzing: market.isAnalyzing, 
            drawings: const []
          ),
        ),
      ],
    );
  }
}
