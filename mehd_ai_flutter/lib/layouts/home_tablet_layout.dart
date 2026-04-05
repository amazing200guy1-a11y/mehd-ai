import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:mehd_ai_flutter/widgets/zen_chart.dart';
import 'package:mehd_ai_flutter/widgets/consensus_bar.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';
import 'package:mehd_ai_flutter/widgets/den_animation.dart';
import 'package:mehd_ai_flutter/screens/settings_screen.dart';
import 'package:mehd_ai_flutter/utils/titan_animations.dart';

class HomeTabletLayout extends StatelessWidget {
  final TradingController trading;
  final MarketDataController market;

  const HomeTabletLayout({super.key, required this.trading, required this.market});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          color: MehdAiTheme.bgSecondary,
          child: ListView(
            children: AppConstants.symbols.map((s) => InkWell(
              onTap: () => market.selectSymbol(s, onStatusMsg: (_) {}),
              child: Container(
                height: 60,
                alignment: Alignment.center,
                color: s == market.activeSymbol ? MehdAiTheme.blue.withOpacity(0.1) : Colors.transparent,
                child: Text(
                  s.replaceAll('/', '').substring(0, 3),
                  style: MehdAiTheme.terminalStyle.copyWith(
                    color: s == market.activeSymbol ? MehdAiTheme.blue : MehdAiTheme.textSecondary,
                    fontWeight: s == market.activeSymbol ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
        const VerticalDivider(width: 1, color: MehdAiTheme.borderColor),
        Expanded(
          child: Column(
            children: [
              Container(
                height: 50,
                color: MehdAiTheme.bgSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(market.activeSymbol ?? 'Workspace', style: MehdAiTheme.headingStyle),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.terminal, color: MehdAiTheme.blue),
                            onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, size: 16, color: Color(0xFF333333)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: market.activeSymbol == null 
                  ? const Center(child: Text('Empty', style: TextStyle(color: Colors.white)))
                  : (market.latestSnapshot == null 
                    ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                    : AnimatedSwitcher(
                        duration: TitanAnimations.medium,
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                        child: ZenChart(
                          key: ValueKey(market.activeSymbol),
                          currentPrice: market.latestSnapshot!, 
                          currentConsensus: market.consensus,
                          denState: market.isAnalyzing ? DenState.activation : DenState.idle,
                          onDrawingsUpdated: (d) {},
                        ),
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
                    showError: (_) {},
                    onSuccess: () {},
                    onShowBrief: (_) {},
                    onShowAudit: (_) {},
                  ),
                  currentSpread: market.latestSnapshot?.spread ?? 0.0,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
