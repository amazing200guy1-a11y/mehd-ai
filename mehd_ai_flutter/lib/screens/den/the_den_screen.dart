import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/screens/den/research_room.dart';
import 'package:mehd_ai_flutter/screens/den/strategy_room.dart';
import 'package:mehd_ai_flutter/screens/den/math_room.dart';
import 'package:mehd_ai_flutter/screens/vibe_trading_screen.dart';
import 'package:mehd_ai_flutter/screens/journey_screen.dart';
import 'package:mehd_ai_flutter/utils/titan_animations.dart';

/// FILE — the_den_screen.dart
///
/// Build Debrief:
/// This is the master container for The Den. We use a PageView to allow the 
/// trader to seamlessly swipe between the three specialized rooms: Research, 
/// Strategy, and Math. 
///
/// Why? 11 agents talking at once is overwhelming. By separating them into rooms, 
/// the user can focus purely on news/sentiment (Research), risk/technical (Strategy),
/// or strict quantitative calculus (Math) without cognitive overload.

class TheDenScreen extends StatefulWidget {
  final ConsensusResult? consensusResult;
  final bool isAnalyzing;
  final String? activeSymbol;
  final VoidCallback onClose;
  
  const TheDenScreen({
    super.key, 
    this.consensusResult,
    this.isAnalyzing = false,
    this.activeSymbol,
    required this.onClose,
  });

  @override
  State<TheDenScreen> createState() => _TheDenScreenState();
}

class _TheDenScreenState extends State<TheDenScreen> {
  final PageController _pageController = PageController(initialPage: 1); // Start in Strategy Room
  int _currentIndex = 1;
  int _bottomIndex = 0; // 0: The Den, 1: Journey

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _navTo(int index) {
    _pageController.animateToPage(
      index, 
      duration: TitanAnimations.medium, 
      curve: TitanAnimations.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bottomIndex == 1) {
      return Scaffold(
        backgroundColor: MehdAiTheme.bgPrimary,
        appBar: AppBar(
          backgroundColor: MehdAiTheme.bgSecondary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: MehdAiTheme.textSecondary),
            onPressed: widget.onClose,
          ),
          title: Text('JOURNEY', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 3)),
          centerTitle: true,
        ),
        body: const JourneyScreen(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: MehdAiTheme.textSecondary),
          onPressed: widget.onClose,
        ),
        title: Row(
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SIMULATED DATA badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD29922)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'SIMULATED DATA',
                      style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFFD29922),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'THE DEN',
                      style: TextStyle(
                        color: const Color(0xFF58A6FF),
                        letterSpacing: 3,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            // DEN READY indicator — fixed right
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF88),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'DEN READY',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: _buildRoomTabs(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: [
          ResearchRoom(consensusResult: widget.consensusResult, isAnalyzing: widget.isAnalyzing, activeSymbol: widget.activeSymbol),
          StrategyRoom(consensusResult: widget.consensusResult, isAnalyzing: widget.isAnalyzing, activeSymbol: widget.activeSymbol),
          MathRoom(consensusResult: widget.consensusResult, isAnalyzing: widget.isAnalyzing, activeSymbol: widget.activeSymbol),
          const VibeTradingScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: MehdAiTheme.bgSecondary,
      selectedItemColor: MehdAiTheme.blue,
      unselectedItemColor: MehdAiTheme.textSecondary,
      currentIndex: _bottomIndex,
      onTap: (i) => setState(() => _bottomIndex = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'The Den'),
        BottomNavigationBarItem(icon: Icon(Icons.rocket_launch), label: 'Journey'),
      ],
    );
  }

  Widget _buildRoomTabs() {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        border: Border(bottom: BorderSide(color: MehdAiTheme.borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTabItem(0, 'UNDERWORLD', Icons.travel_explore),
            _buildTabItem(1, 'THE EMPIRE', Icons.account_tree),
            _buildTabItem(2, 'OLYMPUS', Icons.calculate),
            _buildTabItem(3, 'VIBE', Icons.psychology),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isActive = _currentIndex == index;
    final color = isActive ? MehdAiTheme.blue : MehdAiTheme.textSecondary;
    
    return GestureDetector(
      onTap: () => _navTo(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? MehdAiTheme.blue : Colors.transparent, 
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: MehdAiTheme.labelStyle.copyWith(
                color: color, 
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
