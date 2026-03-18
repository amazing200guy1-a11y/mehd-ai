import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/account_health.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/models/market_snapshot.dart';
import 'package:mehd_ai_flutter/widgets/account_health_widget.dart';
import 'package:mehd_ai_flutter/widgets/ai_terminal.dart';
import 'package:mehd_ai_flutter/widgets/consensus_bar.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart'; // Phase 7
import 'package:mehd_ai_flutter/widgets/den_animation.dart'; // Phase 8
import 'package:mehd_ai_flutter/screens/den/the_den_screen.dart'; // Phase 8 Container
import 'package:mehd_ai_flutter/widgets/symbol_sidebar.dart';
import 'package:mehd_ai_flutter/widgets/zen_chart.dart';
import 'package:mehd_ai_flutter/widgets/executive_brief_dialog.dart';
import 'package:mehd_ai_flutter/screens/war_room_screen.dart';
import 'package:mehd_ai_flutter/screens/marketplace_screen.dart';
import 'package:mehd_ai_flutter/screens/community_fund_screen.dart';
import 'package:mehd_ai_flutter/screens/shadow_mode_screen.dart';
import 'package:mehd_ai_flutter/widgets/trade_history_item.dart';

/// FILE 5 — home_screen.dart
///
/// Build Debrief: VS Code style empty state built into LayoutBuilder.
/// Added MehdLoadingIndicator. Handled null _activeSymbol gracefully.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  String? _activeSymbol;
  MarketSnapshot? _latestSnapshot;
  ConsensusResult? _consensus;
  AccountHealth? _accountHealth;
  
  StreamSubscription<MarketSnapshot>? _priceSub;
  Timer? _pollingTimer;
  
  bool _isAnalyzing = false;
  bool _isBackendOffline = false;
  bool _isSentinelFrozen = false;
  ButtonState _btnState = ButtonState.locked;
  int _mobileTab = 0; // 0: Chart, 1: Terminal, 2: Account
  
  // Phase 5 mock ledger
  final List<Trade> _recentTrades = [];
  
  // Phase 8 sliding den
  bool _isDenOpen = false;

  void _startPolling(int seconds) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      if (_activeSymbol != null && !_isAnalyzing) {
        _triggerAnalysis(_activeSymbol!);
      }
    });
  }

  void _toggleDen() {
    setState(() => _isDenOpen = !_isDenOpen);
  }

  // Phase 8 Den Animation State Mapping
  DenState get _currentDenState {
    if (_activeSymbol == null) return DenState.hidden;
    
    // Safety check first - if we ever triggered kill switch (for now we use mock state, but usually tied to account health)
    if (_accountHealth != null && _accountHealth!.isLocked) return DenState.killSwitch;

    if (_isAnalyzing) return DenState.activation;
    if (_consensus == null) return DenState.idle;
    
    // Post-analysis states
    if (_consensus!.proceed) return DenState.unlocked;
    return DenState.locked;
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final isAlive = await _apiService.healthCheck();
    if (isAlive) {
      if (mounted) setState(() => _isBackendOffline = false);
      _fetchAccountHealth();
    } else {
      if (mounted) setState(() => _isBackendOffline = true);
      _retryConnection();
    }
  }

  void _retryConnection() {
    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;
      final isAlive = await _apiService.healthCheck();
      if (isAlive) {
        setState(() => _isBackendOffline = false);
        _fetchAccountHealth();
      } else {
        _retryConnection();
      }
    });
  }

  void _showErrorBanner(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: MehdAiTheme.red, content: Text(msg, style: MehdAiTheme.terminalStyle)),
    );
  }

  void _fetchAccountHealth() async {
    final health = await _apiService.getAccountHealth();
    setState(() => _accountHealth = health);
  }

  void _selectSymbol(String rawSymbol) {
    final symbol = rawSymbol.replaceAll('/', '');
    setState(() {
      _activeSymbol = rawSymbol;
      _consensus = null; // Clear old consensus
      _btnState = ButtonState.locked;
      _latestSnapshot = null;
    });

    _pollingTimer?.cancel();

    // 1. Swap SSE Stream
    _priceSub?.cancel();
    _priceSub = _apiService.streamPrices(symbol).listen((snapshot) {
      setState(() => _latestSnapshot = snapshot);
    });

    // 2. Trigger The Den
    _triggerAnalysis(symbol);
  }

  Future<void> _triggerAnalysis(String symbol) async {
    setState(() => _isAnalyzing = true);
    
    // Call the real Den backend via ApiService
    final result = await _apiService.analyzeSymbol(symbol);
    
    if (mounted) {
      // Check if it's 6/9
      int maxVotes = 0;
      for (var dir in ['BUY', 'SELL', 'HOLD']) {
        int count = result.votes.where((v) => v.direction == dir).length;
        if (count > maxVotes) maxVotes = count;
      }
      
      bool isDeveloping = maxVotes == 6 && !result.proceed;
      bool isVetoed = !result.proceed && result.rejectionReason != null && result.rejectionReason!.contains("Math Layer Veto");
      bool isFrozen = !result.proceed && result.rejectionReason != null && result.rejectionReason!.contains("SENTINEL_HARD_FREEZE");

      // Check if it was developing and just flipped to 7
      bool justFlipped = _btnState == ButtonState.developing && result.proceed;

      setState(() {
        _consensus = result;
        _isAnalyzing = false;
        _isSentinelFrozen = isFrozen;
        
        if (isFrozen) {
          _btnState = ButtonState.locked;
          _startPolling(5 * 60);
        } else if (isVetoed) {
          _btnState = ButtonState.vetoed;
          _startPolling(5 * 60);
        } else if (isDeveloping) {
          _btnState = ButtonState.developing;
          _startPolling(30);
        } else if (result.proceed) {
          _btnState = result.finalDirection == 'BUY' 
              ? ButtonState.readyBuy 
              : ButtonState.readySell;
          _startPolling(5 * 60);
          
          if (justFlipped) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: MehdAiTheme.green, 
                content: Text("The Den agrees. Strike now.", style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          _btnState = ButtonState.locked;
          _startPolling(5 * 60);
        }
      });
    }
  }

  Future<void> _handleTrade() async {
    if (_consensus == null || _latestSnapshot == null) return;
    
    setState(() => _btnState = ButtonState.executing);
    
    final order = TradeOrder(
      symbol: _latestSnapshot!.symbol,
      direction: _consensus!.finalDirection,
      lotSize: 1.0, 
      stopLoss: _consensus!.finalDirection == 'BUY' ? _latestSnapshot!.bid - 0.0050 : _latestSnapshot!.ask + 0.0050,
      votes: _consensus!.votes,
    );
    
    final decision = await _apiService.executeTrade(order);
    
    if (mounted) {
      setState(() {
        _btnState = decision.approved ? ButtonState.filled : ButtonState.locked;
      });
      
      if (!decision.approved) {
        _showErrorBanner('Trade Rejected: ${decision.rejectionReason}');
      } else {
        // Mock a successful trade execution for Phase 5 UI demonstrations
        final bool isWin = DateTime.now().millisecond % 2 == 0; // 50/50 mock outcome
        final double entry = _latestSnapshot!.bid;
        final double exit = isWin 
            ? (_consensus!.finalDirection == 'BUY' ? entry + 0.0050 : entry - 0.0050)
            : (_consensus!.finalDirection == 'BUY' ? entry - 0.0020 : entry + 0.0020);

        _recentTrades.add(Trade(
          symbol: _latestSnapshot!.symbol,
          direction: _consensus!.finalDirection,
          entryPrice: entry,
          latestPrice: exit,
          timestamp: DateTime.now(),
          consensusScore: _consensus!.consensusPercentage,
        ));
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _btnState = ButtonState.locked); // reset
        });

        // Trigger Executive Brief
        Future.delayed(const Duration(seconds: 1), () async {
          final brief = await _apiService.getExecutiveBrief(decision.id);
          if (brief != null && mounted) {
            showDialog(
              context: context, 
              builder: (ctx) => ExecutiveBriefDialog(brief: brief),
            );
          }
        });
      }
      
      _fetchAccountHealth(); // Refresh balances
    }
  }

  @override
  void dispose() {
    _priceSub?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      // For tablet drawer
      endDrawer: Drawer(
        width: 300,
        child: AiTerminal(consensusResult: _consensus, isAnalyzing: _isAnalyzing),
      ),
      appBar: _buildGlobalTitleBar(),
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: _isDenOpen ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _isBackendOffline 
                ? _buildErrorState() 
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 1100) {
                        return _buildDesktopLayout();
                      } else if (constraints.maxWidth > 600) {
                        return _buildTabletLayout();
                      } else {
                        return _buildMobileLayout();
                      }
                    },
                  ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            top: 0,
            bottom: 0,
            right: _isDenOpen ? 0 : -MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: _isDenOpen ? [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, spreadRadius: 10)
                ] : [],
              ),
              child: TheDenScreen(
                consensusResult: _consensus,
                isAnalyzing: _isAnalyzing,
                activeSymbol: _activeSymbol,
                onClose: _toggleDen,
              ),
            ),
          ),
          if (_isSentinelFrozen) _buildSentinelFreezeLayer(),
        ],
      ),
      floatingActionButton: _isDenOpen ? null : FloatingActionButton(
        backgroundColor: const Color(0xFF0D1117),
        shape: CircleBorder(side: BorderSide(color: MehdAiTheme.blue.withOpacity(0.7), width: 2)),
        onPressed: _toggleDen,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: MehdAiTheme.blue.withOpacity(0.6), blurRadius: 15, spreadRadius: 3),
            ],
          ),
          child: ClipOval(
            child: Opacity(
              opacity: 0.9,
              child: Image.asset('assets/images/mehd_logo.png', width: 40, height: 40, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600 ? _buildBottomNav() : null,
    );
  }

  // ── TITLE BAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildGlobalTitleBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(36.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          border: Border(bottom: BorderSide(color: Color(0xFF30363D), width: 1.0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Side: Brand and Logo
            Row(
              children: [
                Opacity(
                  opacity: 0.6,
                  child: Image.asset('assets/images/mehd_logo.png', width: 20, height: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'MEHD AI',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: const Color(0xFF8B949E),
                  ),
                ),
              ],
            ),
            
            // Center: Active Symbol
            if (_activeSymbol != null)
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.shield, color: MehdAiTheme.red, size: 16),
                    tooltip: 'War Room',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WarRoomScreen(consensus: _consensus, isAnalyzing: _isAnalyzing))),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.store, color: MehdAiTheme.yellow, size: 16),
                    tooltip: 'Marketplace',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.public, color: MehdAiTheme.blue, size: 16),
                    tooltip: 'Community Fund',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityFundScreen())),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.hub, color: MehdAiTheme.purple, size: 16),
                    tooltip: 'Shadow Mode',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShadowModeScreen())),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _activeSymbol!,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: const Color(0xFFE6EDF3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Tooltip(
                    message: "SENTINEL ACTIVE",
                    child: Icon(Icons.remove_red_eye, color: MehdAiTheme.purple, size: 14),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
              
            // Right Side: Den Status
            _buildDenStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildDenStatus() {
    Color dotColor;
    String statusText;

    if (_isSentinelFrozen) {
      dotColor = const Color(0xFFF85149);
      statusText = 'SENTINEL FREEZE';
    } else if (_isBackendOffline) {
      dotColor = const Color(0xFFF85149);
      statusText = 'OFFLINE';
    } else if (_consensus != null && _consensus!.votes.length < 9) {
      dotColor = const Color(0xFFD29922);
      statusText = 'PARTIAL';
    } else {
      dotColor = const Color(0xFF3FB950);
      statusText = 'DEN READY';
    }

    return Row(
      children: [
        if (dotColor == const Color(0xFF3FB950))
          _PulsingDot(color: dotColor)
        else
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: const Color(0xFF8B949E),
          ),
        ),
      ],
    );
  }

  // ── ERROR STATE ──────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.06,
            child: Image.asset(
              'assets/images/mehd_logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '> Connection lost. Retrying...',
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFFF85149),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              const _BlinkCursor(),
            ],
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 180x180 Tiger Logo Watermark, opacity 0.06
          Opacity(
            opacity: 0.06,
            child: Image.asset(
              'assets/images/mehd_logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a symbol to begin',
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFF3B4048),
              fontSize: 13,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 32),
          _buildShortcutRow('Start Analysis', 'Ctrl+Enter'),
          const SizedBox(height: 12),
          _buildShortcutRow('Open Symbol Picker', 'Ctrl+K'),
          const SizedBox(height: 12),
          _buildShortcutRow('View Account', 'Ctrl+H'),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String action, String keys) {
    return SizedBox(
      width: 280,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action,
            style: GoogleFonts.inter(
              color: const Color(0xFF2D333B), // Almost invisible
              fontSize: 12,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              keys,
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFF58A6FF), // Blue text
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DESKTOP LAYOUT (>1100px) ────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SymbolSidebar(activeSymbol: _activeSymbol ?? '', onSymbolSelected: _selectSymbol),
        const VerticalDivider(width: 1, color: MehdAiTheme.borderColor),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(
                child: _activeSymbol == null 
                  ? _buildEmptyState()
                  : (_latestSnapshot == null 
                    ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                    : ZenChart(currentPrice: _latestSnapshot!, currentConsensus: _consensus)),
              ),
              if (_activeSymbol != null)
                ConsensusBar(
                  consensus: _consensus,
                  buttonState: _btnState,
                  onTradePressed: _handleTrade,
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: MehdAiTheme.borderColor),
        AiTerminal(consensusResult: _consensus, isAnalyzing: _isAnalyzing),
      ],
    );
  }

  // ── TABLET LAYOUT (600 - 1100px) ──────────────────────────────────────────────
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Mini Sidebar
        Container(
          width: 60,
          color: MehdAiTheme.bgSecondary,
          child: ListView(
            children: AppConstants.symbols.map((s) => InkWell(
              onTap: () => _selectSymbol(s),
              child: Container(
                height: 60,
                alignment: Alignment.center,
                color: s == _activeSymbol ? MehdAiTheme.blue.withOpacity(0.1) : Colors.transparent,
                child: Text(
                  s.replaceAll('/', '').substring(0, 3), // Show 'EUR' instead of '$'
                  style: MehdAiTheme.terminalStyle.copyWith(
                    color: s == _activeSymbol ? MehdAiTheme.blue : MehdAiTheme.textSecondary,
                    fontWeight: s == _activeSymbol ? FontWeight.bold : FontWeight.normal,
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
              // Custom app bar to open terminal drawer
              Container(
                height: 50,
                color: MehdAiTheme.bgSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_activeSymbol ?? 'Workspace', style: MehdAiTheme.headingStyle),
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.terminal, color: MehdAiTheme.blue),
                        onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _activeSymbol == null 
                  ? _buildEmptyState()
                  : (_latestSnapshot == null 
                    ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                    : ZenChart(currentPrice: _latestSnapshot!, currentConsensus: _consensus)),
              ),
              if (_activeSymbol != null)
                ConsensusBar(
                  consensus: _consensus,
                  buttonState: _btnState,
                  onTradePressed: _handleTrade,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── MOBILE LAYOUT (<600px) ──────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          // Horizontal Symbol Selector
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
                  selected: s == _activeSymbol,
                  onSelected: (val) {
                    if (val) _selectSymbol(s);
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
                // Tab 0: Chart
                _activeSymbol == null 
                  ? _buildEmptyState()
                  : (_latestSnapshot == null 
                    ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                    : ZenChart(currentPrice: _latestSnapshot!, currentConsensus: _consensus, denState: _currentDenState)),
                  
                // Tab 1: Terminal
                AiTerminal(consensusResult: _consensus, isAnalyzing: _isAnalyzing),
                
                // Tab 2: Account
                AccountHealthWidget(
                  health: _accountHealth,
                  recentTrades: _recentTrades,
                ),
              ],
            ),
          ),
          
          // Trade Bar always visible on chart tab
          if (_mobileTab == 0 && _activeSymbol != null)
            ConsensusBar(
              consensus: _consensus,
              buttonState: _btnState,
              onTradePressed: _handleTrade,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: MehdAiTheme.bgSecondary,
      selectedItemColor: MehdAiTheme.blue,
      unselectedItemColor: MehdAiTheme.textSecondary,
      currentIndex: _mobileTab,
      onTap: (i) => setState(() => _mobileTab = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Chart'),
        BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'Terminal'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Account'),
      ],
    );
  }

  Widget _buildSentinelFreezeLayer() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.remove_red_eye, color: MehdAiTheme.red, size: 100),
            const SizedBox(height: 32),
            Text(
              'SENTINEL HARD FREEZE',
              style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.red, fontSize: 32, letterSpacing: 4),
            ),
            const SizedBox(height: 16),
            Text(
              'Catastrophic risk or logical paradox detected on this instrument.\nTrading bounds locked indefinitely.',
              textAlign: TextAlign.center,
              style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MehdAiTheme.red.withOpacity(0.1),
                side: const BorderSide(color: MehdAiTheme.red),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: () {
                setState(() {
                  _activeSymbol = 'EUR/USD';
                  _consensus = null;
                  _isSentinelFrozen = false;
                  _selectSymbol('EUR/USD');
                });
              },
              child: Text('EVACUATE TO EUR/USD', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.red, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

class _BlinkCursor extends StatefulWidget {
  const _BlinkCursor();

  @override
  State<_BlinkCursor> createState() => _BlinkCursorState();
}

class _BlinkCursorState extends State<_BlinkCursor> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _ctrl.value > 0.5 ? 1.0 : 0.0,
        child: Container(width: 8, height: 16, color: const Color(0xFF58A6FF)),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.4 + (_ctrl.value * 0.6),
        child: Container(
          width: 8, 
          height: 8, 
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

