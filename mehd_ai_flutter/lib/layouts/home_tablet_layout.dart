import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:mehd_ai_flutter/widgets/den_chart.dart';
import 'package:mehd_ai_flutter/widgets/consensus_bar.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';
import 'package:mehd_ai_flutter/screens/settings_screen.dart';
import 'package:mehd_ai_flutter/utils/titan_animations.dart';

class HomeTabletLayout extends StatefulWidget {
  final TradingController trading;
  final MarketDataController market;

  const HomeTabletLayout({super.key, required this.trading, required this.market});

  @override
  State<HomeTabletLayout> createState() => _HomeTabletLayoutState();
}

class _HomeTabletLayoutState extends State<HomeTabletLayout> {
  final GlobalKey<DenChartState> _chartKey = GlobalKey<DenChartState>();

  @override
  Widget build(BuildContext context) {
    final market = widget.market;
    final trading = widget.trading;
    
    return Row(
      children: [
        Container(
          width: 60,
          color: MehdAiTheme.surface(context),
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
        VerticalDivider(width: 1, color: MehdAiTheme.border(context)),
        Expanded(
          child: Column(
            children: [
              Container(
                color: MehdAiTheme.surface(context),
                child: Column(
                  children: [
                    _buildTopHeader(market),
                    if (market.drawingMode == "MANUAL")
                      _buildManualToolbar(),
                  ],
                ),
              ),
              Expanded(
                child: market.activeSymbol == null 
                  ? Center(child: Text('Empty', style: TextStyle(color: MehdAiTheme.text(context))))
                  : (market.latestSnapshot == null 
                    ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                    : AnimatedSwitcher(
                        duration: TitanAnimations.medium,
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
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

  Widget _buildTopHeader(MarketDataController market) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: MehdAiTheme.border(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(market.activeSymbol ?? 'Workspace', style: MehdAiTheme.headingStyle),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleBtn("AUTO", market),
              const SizedBox(width: 8),
              _buildToggleBtn("MANUAL", market),
              const SizedBox(width: 12),
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
    );
  }

  Widget _buildManualToolbar() {
    return Container(
      height: 36,
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

  Widget _buildToggleBtn(String mode, MarketDataController market) {
    final isSelected = market.drawingMode == mode;
    return GestureDetector(
      onTap: () => market.toggleDrawingMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF58A6FF).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? const Color(0xFF58A6FF) : MehdAiTheme.border(context)),
        ),
        child: Text(
          mode, 
          style: TextStyle(
            color: isSelected ? const Color(0xFF58A6FF) : MehdAiTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
