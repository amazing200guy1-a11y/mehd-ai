import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/layouts/home_desktop_layout.dart';
import 'package:mehd_ai_flutter/layouts/home_tablet_layout.dart';
import 'package:mehd_ai_flutter/layouts/home_mobile_layout.dart';
import 'package:mehd_ai_flutter/screens/den/the_den_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): const SearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyH, control: true, shift: true): const HelpIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => null),
          SearchIntent: CallbackAction<SearchIntent>(onInvoke: (_) => null),
          HelpIntent: CallbackAction<HelpIntent>(onInvoke: (_) => null),
        },
        child: Focus(
          autofocus: true,
          child: Consumer2<TradingController, MarketDataController>(
            builder: (ctx, trading, market, _) {
              return Scaffold(
                backgroundColor: MehdAiTheme.bgPrimary,
                body: SafeArea(
                  child: Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 1200) {
                            return HomeDesktopLayout(trading: trading, market: market);
                          }
                          if (constraints.maxWidth > 768) {
                            return HomeTabletLayout(trading: trading, market: market);
                          }
                          return HomeMobileLayout(trading: trading, market: market);
                        },
                      ),
                      Positioned(
                        bottom: 60, // above bottom nav
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => TheDenScreen(
                              consensusResult: market.consensus,
                              isAnalyzing: market.isAnalyzing,
                              activeSymbol: market.activeSymbol,
                              onClose: () => Navigator.pop(context),
                            )));
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF000000),
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
                              child: Image.asset(
                                'assets/images/mehd_logo.png',
                                width: 48,
                                height: 48,
                                errorBuilder: (_, __, ___) => const Center(child: Text('🐯', style: TextStyle(fontSize: 24))),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ActivateIntent extends Intent { const ActivateIntent(); }
class SearchIntent extends Intent { const SearchIntent(); }
class HelpIntent extends Intent { const HelpIntent(); }
