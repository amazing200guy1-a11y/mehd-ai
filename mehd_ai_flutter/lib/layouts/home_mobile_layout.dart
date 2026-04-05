import 'dart:ui';
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
import 'package:mehd_ai_flutter/widgets/den_animation.dart';
import 'package:mehd_ai_flutter/screens/war_room_community_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final trading = widget.trading;
    final market = widget.market;

    return Stack(
      children: [
        Column(
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
              child: AnimatedSwitcher(
                duration: TitanAnimations.medium,
                switchInCurve: TitanAnimations.emphasized,
                switchOutCurve: TitanAnimations.smooth,
                child: _mobileTab == 0
                    ? Column(
                        key: const ValueKey('tab0'),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: market.activeSymbol == null 
                              ? const Center(child: Text('Empty', style: TextStyle(color: Colors.white)))
                              : (market.latestSnapshot == null 
                                ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                                : AnimatedSwitcher(
                                    duration: TitanAnimations.medium,
                                    switchInCurve: TitanAnimations.emphasized,
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
                          Expanded(
                            child: AiTerminal(
                              consensusResult: market.consensus, 
                              isAnalyzing: market.isAnalyzing, 
                              drawings: const []
                            ),
                          ),
                        ],
                      )
                    : _mobileTab == 1
                        ? TheDenScreen(
                            key: const ValueKey('tab1'),
                            consensusResult: market.consensus,
                            isAnalyzing: market.isAnalyzing,
                            activeSymbol: market.activeSymbol,
                            onClose: () => setState(() => _mobileTab = 0),
                          )
                        : AccountHealthWidget(
                            key: const ValueKey('tab2'),
                            health: null, // Account health wrapper
                            recentTrades: trading.recentTrades,
                          ),
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
        ),
        
        // ── TIGER CIRCLE (DenAnimation) Floating Trigger ──
        if (_mobileTab == 0)
          Positioned(
            bottom: 60, // above bottom nav
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
                  color: const Color(0xFF000000),
                  border: Border.all(
                    color: const Color(0xFF58A6FF).withOpacity(0.4),
                    width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF58A6FF).withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 2),
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

  void _showDenActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: MehdAiTheme.bgSecondary.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: MehdAiTheme.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: MehdAiTheme.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
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
}
