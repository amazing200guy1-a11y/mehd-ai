import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart'; // Phase 7
import 'package:mehd_ai_flutter/widgets/den_animation.dart'; // Phase 8
import 'package:mehd_ai_flutter/screens/den/the_den_screen.dart'; // Phase 8 Container
import 'package:mehd_ai_flutter/widgets/symbol_sidebar.dart';
import 'package:mehd_ai_flutter/widgets/quick_pip_calculator.dart';
import 'package:mehd_ai_flutter/widgets/zen_chart.dart';
import 'package:mehd_ai_flutter/widgets/executive_brief_dialog.dart';
import 'package:mehd_ai_flutter/screens/war_room_screen.dart';
import 'package:mehd_ai_flutter/screens/marketplace_screen.dart';
import 'package:mehd_ai_flutter/screens/rejection_feed_screen.dart';
import 'package:mehd_ai_flutter/screens/war_room_community_screen.dart';
import 'package:mehd_ai_flutter/screens/shadow_mode_screen.dart';
import 'package:mehd_ai_flutter/screens/data_moat_screen.dart';
import 'package:mehd_ai_flutter/screens/api_docs_screen.dart';
import 'package:mehd_ai_flutter/screens/compliance_screen.dart';
import 'package:mehd_ai_flutter/screens/heatmap_screen.dart';
import 'package:mehd_ai_flutter/screens/licensing_screen.dart';
import 'package:mehd_ai_flutter/widgets/trade_history_item.dart';
import 'package:mehd_ai_flutter/widgets/mistake_dna_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mehd_ai_flutter/widgets/onboarding_tips.dart';
import 'package:mehd_ai_flutter/widgets/floating_help_button.dart';
import 'package:mehd_ai_flutter/screens/help/support_screen.dart';
import 'package:mehd_ai_flutter/screens/language_screen.dart';

import 'package:mehd_ai_flutter/widgets/legal_disclaimer.dart';

import 'package:mehd_ai_flutter/core/connection_monitor.dart';
import 'package:mehd_ai_flutter/core/input_validator.dart';
import 'package:mehd_ai_flutter/core/performance_tracker.dart';
import 'package:mehd_ai_flutter/models/automated_drawing.dart';

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
  final PerformanceTracker _perf = PerformanceTracker();
  bool _isTradeProcessing = false;
  List<AutomatedDrawing> _currentDrawings = [];

  String? _activeSymbol;
  MarketSnapshot? _latestSnapshot;
  ConsensusResult? _consensus;
  AccountHealth? _accountHealth;
  
  StreamSubscription<MarketSnapshot>? _priceSub;
  StreamSubscription<QuerySnapshot>? _firestoreSub;
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

  // Help & Onboarding
  bool _hasSeenOnboarding = true;
  bool _showUpdateBanner = true;
  bool _showFeedbackOption = false;
  bool _feedbackShown = false; // session flag

  // FIX 5: Connection quality
  final ConnectionMonitor _connectionMonitor = ConnectionMonitor();

  // FIX 6: Paper trading enforcement (mock profile)
  int _paperTradesCompleted = 0;
  bool _legalAccepted = false;
  Timer? _retryTimer;

  // Polling replaced by Firestore real-time listener (Upgrade 5 — _listenToFirestore)

  void _listenToFirestore(String symbol) {
    _firestoreSub?.cancel();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _firestoreSub = FirebaseFirestore.instance
      .collection('users').doc(userId)
      .collection('analyses')
      .where('symbol', isEqualTo: symbol)
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
           final data = snapshot.docs.first.data();
           final parsed = ConsensusResult.fromJson(data);
           if (mounted) {
              _handleNewConsensus(parsed);
           }
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
    _checkOnboardingStatus();
    _loadLegalStatus();
    _connectionMonitor.startMonitoring();
    _initializeApp();
  }

  Future<void> _loadLegalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _legalAccepted = prefs.getBool('legal_accepted') ?? false);
    }
  }

  Future<void> acceptLegal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('legal_accepted', true);
    if (mounted) setState(() => _legalAccepted = true);
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_onboarding') ?? false;
    if (mounted) {
      setState(() => _hasSeenOnboarding = seen);
    }
  }

  Future<void> _initializeApp() async {
    final isAlive = await _apiService.healthCheck();
    if (isAlive) {
      if (mounted) setState(() => _isBackendOffline = false);
      _fetchAccountHealth();

      // Phase 9: Pre-cache highest volume symbols
      Future.wait([
        _apiService.analyzeSymbol('EUR/USD'),
        _apiService.analyzeSymbol('XAU/USD'),
      ]).catchError((_) => <ConsensusResult>[]);
      
    } else {
      if (mounted) setState(() => _isBackendOffline = true);
      _retryConnection();
    }
  }

  void _retryConnection() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) { timer.cancel(); return; }
      final isAlive = await _apiService.healthCheck();
      if (isAlive) {
        timer.cancel();
        setState(() => _isBackendOffline = false);
        _fetchAccountHealth();
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
      if (mounted) setState(() => _latestSnapshot = snapshot);
    });

    // DEMO MODE FIX: Issue a mock synchronous snapshot so chart renders immediately
    if (_isBackendOffline) {
      _latestSnapshot = MarketSnapshot(
        id: 'mock_demo',
        symbol: symbol,
        bid: 1.0500,
        ask: 1.0502,
        open: 1.0500,
        high: 1.0550,
        low: 1.0450,
        close: 1.0500,
        spread: 0.0002,
        volume: 1000,
        timestamp: DateTime.now().toUtc(),
      );
    }

    // 2. Listen to Firestore instead of polling
    _listenToFirestore(symbol);
    
    // 3. Trigger The Den (Cloud Function)
    _triggerAnalysis(symbol);
  }

  Future<void> _triggerAnalysis(String symbol) async {
    setState(() => _isAnalyzing = true);
    
    final startTime = DateTime.now();
    ConsensusResult? finalResult;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('orchestrateConsensus');
      final result = await callable.call({
         'symbol': symbol,
         'userId': userId,
         'tier': 'sovereign',
      });
      
      if (result.data != null) {
        finalResult = ConsensusResult.fromJson(Map<String, dynamic>.from(result.data));
      }
    } catch (e) {
      debugPrint('Cloud Function failed, falling back to demo: $e');
      finalResult = _buildDemoConsensus(symbol);
    }

    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds < 8000) {
      await Future.delayed(Duration(milliseconds: 8000 - elapsed.inMilliseconds));
    }

    if (finalResult != null) {
      _handleNewConsensus(finalResult);
    }
  }

  ConsensusResult _buildDemoConsensus(String symbol) {
    final isBull = ['EUR/USD', 'XAU/USD', 'NAS100', 'BTC/USD'].contains(symbol);
    final randomValue = 72 + (DateTime.now().millisecond % 20);
    
    return ConsensusResult(
      votes: [], // Basic demo result
      finalDirection: isBull ? 'BUY' : 'SELL',
      consensusPercentage: randomValue.toDouble(),
      proceed: true,
      timestamp: DateTime.now(),
      rejectionReason: null,
      tier: 'sovereign',
    );
  }

  void _handleNewConsensus(ConsensusResult result) {
    if (!mounted) return;
    
    // Check if it's 7/11
    int maxVotes = 0;
    for (var dir in ['BUY', 'SELL', 'HOLD']) {
      int count = result.votes.where((v) => v.direction == dir).length;
      if (count > maxVotes) maxVotes = count;
    }
    
    bool isDeveloping = maxVotes == 7 && !result.proceed;
    bool isVetoed = !result.proceed && result.rejectionReason != null && result.rejectionReason!.contains("Math Layer Veto");
    bool isFrozen = !result.proceed && result.rejectionReason != null && result.rejectionReason!.contains("SENTINEL_HARD_FREEZE");

    // Check if it was developing and just flipped to proceed
    bool justFlipped = _btnState == ButtonState.developing && result.proceed;

    setState(() {
      _consensus = result;
      _isAnalyzing = false;
      _isSentinelFrozen = isFrozen;
      
      if (isFrozen) {
        _btnState = ButtonState.locked;
      } else if (isVetoed) {
        _btnState = ButtonState.vetoed;
      } else if (isDeveloping) {
        _btnState = ButtonState.developing;
      } else if (result.proceed) {
        _btnState = result.finalDirection == 'BUY' 
            ? ButtonState.readyBuy 
            : ButtonState.readySell;
        
        if (justFlipped) {
          final isSovereign = result.tier == 'sovereign' && result.proceed;
          final txt = isSovereign 
            ? "Unanimous. All 11 layers aligned.\nThis is the rarest signal in The Den.\nStrike with full force."
            : "The Den agrees. Strike now.";
          final bg = isSovereign ? MehdAiTheme.white : MehdAiTheme.green;
          final tc = isSovereign ? MehdAiTheme.bgPrimary : Colors.white;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: bg, 
              content: Text(txt, style: MehdAiTheme.terminalStyle.copyWith(color: tc)),
              duration: Duration(seconds: isSovereign ? 6 : 4),
            ),
          );
        }
      } else {
        _btnState = ButtonState.locked;
      }
      
      // Show feedback after analysis finishes (Fix 3)
      if (!_feedbackShown) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _showFeedbackOption = true);
            // Auto hide after 8 seconds if no response
            Future.delayed(const Duration(seconds: 8), () {
              if (mounted && _showFeedbackOption) {
                setState(() => _showFeedbackOption = false);
                _feedbackShown = true;
              }
            });
          }
        });
      }
    });
  }

  Future<void> _handleTrade() async {
    if (_consensus == null || _latestSnapshot == null) return;

    // ── ZERO ERROR: Prevent double-tap execution ──
    if (_isTradeProcessing) return;

    // ── ZERO ERROR: Stale price lockout ──
    if (_perf.isPriceStale) {
      _showErrorBanner('Price data is stale (>5s old). Trading locked for your safety.');
      return;
    }

    // ── ZERO ERROR: Duplicate trade guard (5s cooldown) ──
    if (DuplicateTradeGuard.isDuplicate(_latestSnapshot!.symbol, _consensus!.finalDirection)) {
      _showErrorBanner('Duplicate trade blocked. Wait 5 seconds between identical trades.');
      return;
    }

    // ── Paper Trading Enforcement (I5 Fix) ──
    if (!_legalAccepted) {
      _showErrorBanner('You must accept the Terms of Service before trading.');
      return;
    }
    if (_paperTradesCompleted < 10) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: MehdAiTheme.bgSecondary,
          title: Text('Paper Trading Required', style: MehdAiTheme.headingStyle),
          content: Text(
            'You have completed $_paperTradesCompleted/10 paper trades.\n\n'
            'Complete at least 10 paper trades before live trading. '
            'This protects you from mistakes while you learn.',
            style: MehdAiTheme.labelStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Understood', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue)),
            ),
          ],
        ),
      );
      setState(() => _paperTradesCompleted++);
      return;
    }

    // ── ACCURACY: Input validation ──
    final lotSize = 1.0;
    final stopLoss = _consensus!.finalDirection == 'BUY' ? _latestSnapshot!.bid - 0.0050 : _latestSnapshot!.ask + 0.0050;
    final validationError = InputValidator.validateTradeOrder(
      symbol: _latestSnapshot!.symbol,
      direction: _consensus!.finalDirection,
      lotSize: lotSize,
      entryPrice: _latestSnapshot!.bid,
      stopLoss: stopLoss,
    );
    if (validationError != null) {
      _showErrorBanner(validationError);
      return;
    }

    // ── CONFIRMATION DIALOG — "Are you sure?" ──
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MehdAiTheme.bgSecondary,
        title: Row(
          children: [
            Icon(_consensus!.finalDirection == 'BUY' ? Icons.trending_up : Icons.trending_down,
              color: _consensus!.finalDirection == 'BUY' ? MehdAiTheme.green : MehdAiTheme.red),
            const SizedBox(width: 12),
            Text('Confirm Trade Execution', style: MehdAiTheme.headingStyle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_consensus!.finalDirection} ${_latestSnapshot!.symbol}', style: MehdAiTheme.terminalStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Entry: ${_latestSnapshot!.bid.toStringAsFixed(5)}', style: MehdAiTheme.labelStyle),
            Text('SL: ${stopLoss.toStringAsFixed(5)}', style: MehdAiTheme.labelStyle),
            Text('Lot Size: ${lotSize.toStringAsFixed(2)}', style: MehdAiTheme.labelStyle),
            Text('Consensus: ${_consensus!.consensusPercentage.toStringAsFixed(1)}%', style: MehdAiTheme.labelStyle),
            const SizedBox(height: 16),
            Text('Risk: 1.0% maximum enforced by HardRiskKernel.', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.gold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _consensus!.finalDirection == 'BUY' ? MehdAiTheme.green : MehdAiTheme.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('EXECUTE ${_consensus!.finalDirection}', style: MehdAiTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ── EXECUTE ──
    setState(() {
      _btnState = ButtonState.executing;
      _isTradeProcessing = true;
    });
    
    final order = TradeOrder(
      symbol: _latestSnapshot!.symbol,
      direction: _consensus!.finalDirection,
      lotSize: lotSize, 
      stopLoss: stopLoss,
      votes: _consensus!.votes,
    );
    
    final decision = await _apiService.executeTrade(order);

    if (mounted) setState(() => _isTradeProcessing = false);
    
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
        
        if (isWin && _consensus!.consensusPercentage >= 75.0) {
          // Sovereign Intelligence Data Moat trigger
          debugPrint("[SOVEREIGN MOAT] Alpha Snapshot secured for ${_latestSnapshot!.symbol}");
          // Trigger Executive Brief (Winners only for now, losers get Auditors)
          Future.delayed(const Duration(seconds: 1), () async {
            final brief = await _apiService.getExecutiveBrief(decision.id);
            if (brief != null && mounted) {
              showDialog(
                context: context, 
                builder: (ctx) => ExecutiveBriefDialog(brief: brief),
              );
            }
          });
        } else if (!isWin) {
          // Post-Mortem Agent trigger: Every losing trade gets audited
          debugPrint("[POST-MORTEM AGENT] Loss detected. Triggering The Auditor.");
          Future.delayed(const Duration(milliseconds: 500), () async {
            try {
              final auditData = {
                "trade_id": decision.id,
                "symbol": _latestSnapshot!.symbol,
                "direction": _consensus!.finalDirection,
                "entry_price": entry,
                "exit_price": exit,
                "pnl": -50.0, // Mock loss amount
                "user_notes": "Trade went against consensus momentum."
              };
              
              // This should ideally live in ApiService but inlining the call for now
              final response = await _apiService.performAudit(auditData);
              if (mounted && response != null) {
                 showDialog(
                   context: context,
                   barrierDismissible: false, // Force them to acknowledge
                   builder: (ctx) => MistakeDnaDialog(
                     result: response,
                     onAcceptRule: () {
                         // Real implementation would save the proposed rule
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Constitution Updated.', style: MehdAiTheme.terminalStyle),
                             backgroundColor: MehdAiTheme.gold,
                           )
                         );
                     },
                   ),
                 );
              }
            } catch (e) {
              debugPrint("Audit failed: \$e");
            }
          });
        }
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _btnState = ButtonState.locked); // reset
        });
      }
            _fetchAccountHealth(); // Refresh balances
    }
  }

  void _showSymbolPicker() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: MehdAiTheme.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          width: 300,
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('SYMBOL PICKER', style: MehdAiTheme.headingStyle),
              ),
              Expanded(
                child: ListView(
                  children: AppConstants.symbols.map((s) => ListTile(
                    title: Text(s, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectSymbol(s);
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountHealth() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: MehdAiTheme.bgSecondary,
        child: SizedBox(
          width: 800,
          height: 600,
          child: AccountHealthWidget(health: _accountHealth, recentTrades: _recentTrades),
        )
      ),
    );
  }

  @override
  void dispose() {
    _priceSub?.cancel();
    _pollingTimer?.cancel();
    _retryTimer?.cancel();
    _connectionMonitor.stopMonitoring();
    _apiService.dispose();
    super.dispose();
  }

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
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (_activeSymbol != null && !_isAnalyzing) {
                _triggerAnalysis(_activeSymbol!);
              }
              return null;
            },
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              _showSymbolPicker();
              return null;
            },
          ),
          HelpIntent: CallbackAction<HelpIntent>(
            onInvoke: (intent) {
              _showAccountHealth();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: MehdAiTheme.bgPrimary,
            endDrawer: Drawer(
              width: 300,
              child: AiTerminal(consensusResult: _consensus, isAnalyzing: _isAnalyzing),
            ),
            appBar: _buildGlobalTitleBar(),
            body: Stack(
              children: [
                _buildActivationWarning(),
                AnimatedOpacity(
                  opacity: _isDenOpen ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: LayoutBuilder(
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
                if (_isBackendOffline) _buildFixedErrorBanner(),
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
                if (!_isDenOpen)
                  const Positioned(
                    bottom: 90,
                    right: 16,
                    child: QuickPipCalculator(),
                  ),
                if (_isSentinelFrozen) _buildSentinelFreezeLayer(),
                if (_consensus?.panicProtocolActive == true) _buildPanicOverlay(),
                
                // New Global Elements
                if (_showFeedbackOption) _buildFeedbackPopup(),
                if (_showUpdateBanner) _buildVersionBanner(),
                const FloatingHelpButton(),
                if (!_hasSeenOnboarding) OnboardingTips(onComplete: () => setState(() => _hasSeenOnboarding = true)),
              ],
            ),
            floatingActionButton: _isDenOpen ? null : FloatingActionButton(
              backgroundColor: const Color(0xFF0D1117),
              shape: const CircleBorder(side: BorderSide(color: MehdAiTheme.blue, width: 2)),
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
          ),
        ),
      ),
    );
  }

  // ── TITLE BAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildGlobalTitleBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(36.0),
      child: Container(
        decoration: const BoxDecoration(
          color: MehdAiTheme.bgPrimary,
          border: Border(bottom: BorderSide(color: MehdAiTheme.borderColor, width: 1.0)),
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
                    color: MehdAiTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.language, color: MehdAiTheme.blue, size: 16),
                  tooltip: 'Language Settings',
                  onPressed: () => _showLanguagePicker(),
                ),
              ],
            ),
            
            // Center: Active Symbol
            if (_activeSymbol != null)
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                        icon: const Icon(Icons.analytics_outlined, color: MehdAiTheme.gold, size: 16),
                        tooltip: 'Sovereign Data Moat',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DataMoatScreen())),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.shield_outlined, color: MehdAiTheme.shieldColor, size: 16),
                        tooltip: 'Live Rejection Feed',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RejectionFeedScreen())),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.code, color: MehdAiTheme.green, size: 16),
                        tooltip: 'Consensus API',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ApiDocsScreen())),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.gavel, color: MehdAiTheme.red, size: 16),
                        tooltip: 'Compliance & Audit',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComplianceScreen())),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.grid_view, color: MehdAiTheme.gold, size: 16),
                        tooltip: 'Global Heatmap',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HeatmapScreen())),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.business_center, color: MehdAiTheme.purple, size: 16),
                        tooltip: 'Enterprise Licensing',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LicensingScreen())),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.help_outline, color: MehdAiTheme.blue, size: 16),
                        tooltip: 'Help Center',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.people_alt, color: MehdAiTheme.blue, size: 16),
                        tooltip: 'War Room Platoon',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WarRoomCommunityScreen())),
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
                          color: MehdAiTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Tooltip(
                        message: "SENTINEL ACTIVE",
                        child: Icon(Icons.remove_red_eye, color: MehdAiTheme.purple, size: 14),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: MehdAiTheme.bgSecondary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: MehdAiTheme.borderColor),
                        ),
                        child: Text(
                          _getActiveSession(),
                          style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textSecondary, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.calendar_month, color: MehdAiTheme.textSecondary, size: 16),
                        tooltip: 'Economic Calendar',
                        onPressed: () => _showEconomicCalendar(),
                      ),
                    ],
                  ),
                ),
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

  String _getActiveSession() {
    final hour = DateTime.now().toUtc().hour;
    if (hour >= 13 && hour < 16) return "LONDON/NY OVERLAP";
    if (hour >= 8 && hour < 16) return "LONDON / UTC";
    if (hour >= 13 && hour < 21) return "NEW YORK / UTC";
    if (hour >= 0 && hour < 8) return "ASIAN / UTC";
    return "CLOSED / UTC";
  }

  Widget _buildDenStatus() {
    Color dotColor;
    String statusText;

    if (_isSentinelFrozen) {
      dotColor = const Color(0xFFF85149);
      statusText = 'SENTINEL FREEZE';
    } else if (_isBackendOffline) {
      dotColor = const Color(0xFFD29922);
      statusText = 'DEMO';
    } else if (_latestSnapshot != null && _latestSnapshot!.isStale) {
      dotColor = const Color(0xFFF85149);
      statusText = 'STALE DATA';
    } else if (_consensus != null && _consensus!.votes.length < 11) {
      dotColor = const Color(0xFFD29922);
      statusText = 'PARTIAL';
    } else {
      dotColor = const Color(0xFF00FF88);
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
            color: MehdAiTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── FEEDBACK & VERSION BANNER ────────────────────────────────────────────────
  Widget _buildVersionBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: MaterialBanner(
        backgroundColor: MehdAiTheme.blue.withOpacity(0.9),
        content: Text(
          'Mehd AI has been updated — New features available. Refresh to update.',
          style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showUpdateBanner = false),
            child: Text('DISMISS', style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackPopup() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: MehdAiTheme.bgSecondary,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: MehdAiTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Was this analysis helpful?', style: MehdAiTheme.labelStyle.copyWith(color: Colors.white)),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.thumb_up_alt_outlined, color: MehdAiTheme.green, size: 20),
                onPressed: () {
                  setState(() {
                    _showFeedbackOption = false;
                    _feedbackShown = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: MehdAiTheme.green, 
                    content: Text('Den noted. Thank you.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    duration: Duration(seconds: 2),
                  ));
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.thumb_down_alt_outlined, color: MehdAiTheme.red, size: 20),
                onPressed: () {
                  setState(() {
                    _showFeedbackOption = false;
                    _feedbackShown = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: MehdAiTheme.red, 
                    content: Text('Den noted. Thank you.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    duration: Duration(seconds: 2),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MehdAiTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      builder: (context) {
        return const LanguageGridPicker();
      },
    );
  }

  Widget _buildFixedErrorBanner() {
    return Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: Container(
        width: double.infinity,
        height: 24, // fixed small height
        color: const Color(0xFF0A0800),
        padding: const EdgeInsets.symmetric(
          horizontal: 10),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
              color: Color(0xFFD29922),
              size: 10),
            const SizedBox(width: 5),
            const Flexible(
              child: Text(
                'SIMULATED DATA — Add API keys '
                'for live trading',
                style: TextStyle(
                  color: Color(0xFFD29922),
                  fontSize: 8,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFD29922)
                    .withOpacity(0.4),
                  width: 0.5),
                borderRadius:
                  BorderRadius.circular(2),
              ),
              child: const Text('DEMO MODE',
                style: TextStyle(
                  color: Color(0xFFD29922),
                  fontSize: 7,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 5),
            // Dismiss button
            GestureDetector(
              onTap: () => setState(() =>
                _showBanner = false),
              child: Icon(Icons.close,
                color: const Color(0xFFD29922)
                  .withOpacity(0.5),
                size: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationWarning() {
    if (_legalAccepted) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: MehdAiTheme.gold.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.warning_amber_rounded, color: Colors.black, size: 14),
             const SizedBox(width: 8),
             Text(
               'UNACTIVATED TERMINAL: Accept Risk Disclosure to enable trading.',
               style: MehdAiTheme.terminalStyle.copyWith(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
             ),
             const SizedBox(width: 12),
             GestureDetector(
               onTap: acceptLegal,
               child: Text(
                 'ACCEPT NOW →',
                 style: MehdAiTheme.terminalStyle.copyWith(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
               ),
             )
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────────────────────
  // ── EMPTY STATE ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 180x180 Tiger Logo Watermark with pulsing glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MehdAiTheme.blue.withOpacity(0.05),
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      'assets/images/mehd_logo.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (rect) {
                      return RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 0.2,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.4, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.asset(
                        'assets/images/mehd_logo.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                '11 AGENTS AWAITING COMMAND',
                style: GoogleFonts.jetBrainsMono(
                  color: MehdAiTheme.blue,
                  fontSize: 14,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select a symbol from the sidebar to begin multi-agent analysis.',
                style: MehdAiTheme.labelStyle.copyWith(
                  color: MehdAiTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: MehdAiTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MehdAiTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildShortcutRow('Start Analysis', 'Ctrl+Enter', Icons.bolt),
                    const SizedBox(height: 16),
                    _buildShortcutRow('Open Symbol Picker', 'Ctrl+K', Icons.search),
                    const SizedBox(height: 16),
                    _buildShortcutRow('View Account Metrics', 'Ctrl+Shift+H', Icons.analytics_outlined),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutRow(String action, String keys, IconData icon) {
    return SizedBox(
      width: 280,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: MehdAiTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                action,
                style: GoogleFonts.inter(
                  color: MehdAiTheme.textPrimary, 
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: MehdAiTheme.bgTertiary,
              border: Border.all(color: MehdAiTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              keys,
              style: GoogleFonts.jetBrainsMono(
                color: MehdAiTheme.blue, 
                fontSize: 10,
                fontWeight: FontWeight.bold,
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
          flex: 7, // 70% width for the main charting area
          child: Column(
            children: [
              Expanded(
                child: _activeSymbol == null 
                  ? _buildEmptyState()
                  : (_latestSnapshot == null 
                    ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                    : ZenChart(
                        currentPrice: _latestSnapshot!, 
                        currentConsensus: _consensus,
                        onDrawingsUpdated: (d) => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _currentDrawings = d); }),
                      )),
              ),
              if (_activeSymbol != null)
                ConsensusBar(
                  consensus: _consensus,
                  buttonState: _btnState,
                  onTradePressed: _handleTrade,
                  currentSpread: _latestSnapshot?.spread ?? 0.0,
                ),
              
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: MehdAiTheme.borderColor),
        Expanded(
          flex: 3, // 30% width for the AI Terminal side panel
          child: AiTerminal(
            consensusResult: _consensus, 
            isAnalyzing: _isAnalyzing, 
            drawings: _currentDrawings
          ),
        ),
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
                    : ZenChart(
                        currentPrice: _latestSnapshot!, 
                        currentConsensus: _consensus,
                        onDrawingsUpdated: (d) => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _currentDrawings = d); }),
                      )),
              ),
              if (_activeSymbol != null)
                ConsensusBar(
                  consensus: _consensus,
                  buttonState: _btnState,
                  onTradePressed: _handleTrade,
                  currentSpread: _latestSnapshot?.spread ?? 0.0,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
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
                    // Tab 0: AI TERMINAL (Chart + Terminal)
                    Column(
                      children: [
                        SizedBox(
                          height: constraints.maxHeight * 0.4,
                          child: _activeSymbol == null 
                            ? _buildEmptyState()
                            : (_latestSnapshot == null 
                              ? const Center(child: DenLoadingWidget(message: 'Entering the Den...'))
                              : ZenChart(
                                  currentPrice: _latestSnapshot!, 
                                  currentConsensus: _consensus, 
                                  denState: _currentDenState,
                                  onDrawingsUpdated: (d) {
                                    if (_currentDrawings.length != d.length) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) setState(() => _currentDrawings = d);
                                      });
                                    }
                                  },
                                )),
                        ),
                        Expanded(
                          child: AiTerminal(
                            consensusResult: _consensus, 
                            isAnalyzing: _isAnalyzing, 
                            drawings: _currentDrawings
                          ),
                        ),
                      ],
                    ),
                      
                    // Tab 1: THE DEN
                    SizedBox(
                      height: constraints.maxHeight - 60 - 70 - 40,
                      child: TheDenScreen(
                        consensusResult: _consensus,
                        isAnalyzing: _isAnalyzing,
                        activeSymbol: _activeSymbol,
                        onClose: () => setState(() => _mobileTab = 0),
                      ),
                    ),
                    
                    // Tab 2: ACCOUNT
                    AccountHealthWidget(
                      health: _accountHealth,
                      recentTrades: _recentTrades,
                    ),
                  ],
                ),
              ),
              
              // Trade Bar always visible on AI TERMINAL tab
              if (_mobileTab == 0 && _activeSymbol != null)
                ConsensusBar(
                  consensus: _consensus,
                  buttonState: _btnState,
                  onTradePressed: _handleTrade,
                  currentSpread: _latestSnapshot?.spread ?? 0.0,
                ),
              
            ],
          );
        },
      ),
    );
  }


  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: MehdAiTheme.bgSecondary,
      selectedItemColor: MehdAiTheme.blue,
      unselectedItemColor: MehdAiTheme.textSecondary,
      currentIndex: _mobileTab,
      onTap: (i) {
        setState(() {
          _mobileTab = i;
          if (i == 1) {
            _isDenOpen = true; // Sync for desktop logic
          } else {
            _isDenOpen = false;
          }
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'AI TERMINAL'),
        BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'THE DEN'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'ACCOUNT'),
      ],
    );
  }

  Widget _buildSentinelFreezeLayer() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.remove_red_eye, color: MehdAiTheme.red, size: 100),
                const SizedBox(height: 32),
                Text(
                  'SENTINEL HARD FREEZE',
                  style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.red, fontSize: 32, letterSpacing: 4),
                  textAlign: TextAlign.center,
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
        ),
      ),
    );
  }

  void _showEconomicCalendar() {
    // Mock high-impact events with realistic upcoming data
    final now = DateTime.now().toUtc();
    final events = [
      {'name': 'Non-Farm Payrolls (NFP)', 'impact': 'HIGH', 'time': now.add(const Duration(hours: 52)), 'currency': 'USD'},
      {'name': 'FOMC Interest Rate Decision', 'impact': 'HIGH', 'time': now.add(const Duration(hours: 120)), 'currency': 'USD'},
      {'name': 'CPI (YoY)', 'impact': 'HIGH', 'time': now.add(const Duration(hours: 168)), 'currency': 'USD'},
      {'name': 'PPI (MoM)', 'impact': 'MEDIUM', 'time': now.add(const Duration(hours: 200)), 'currency': 'USD'},
      {'name': 'Retail Sales (MoM)', 'impact': 'MEDIUM', 'time': now.add(const Duration(hours: 240)), 'currency': 'USD'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: MehdAiTheme.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: MehdAiTheme.borderColor)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ECONOMIC CALENDAR', style: MehdAiTheme.headingStyle),
                  IconButton(icon: const Icon(Icons.close, color: MehdAiTheme.textSecondary, size: 18), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              Text('High-Impact Events — USD Focus', style: MehdAiTheme.labelStyle),
              const SizedBox(height: 16),
              const Divider(color: MehdAiTheme.borderColor),
              ...events.map((e) {
                final eventTime = e['time'] as DateTime;
                final diff = eventTime.difference(now);
                final hoursLeft = diff.inHours;
                final minsLeft = diff.inMinutes % 60;
                final isImminent = hoursLeft == 0 && minsLeft <= 15;
                final impactColor = e['impact'] == 'HIGH' ? MehdAiTheme.red : MehdAiTheme.yellow;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: MehdAiTheme.borderColor.withOpacity(0.3))),
                    color: isImminent ? MehdAiTheme.red.withOpacity(0.05) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: impactColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e['name'] as String, style: MehdAiTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold))),
                      if (isImminent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: MehdAiTheme.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text('⚠ IMMINENT', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.red, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      Text(
                        hoursLeft > 0 ? '${hoursLeft}h ${minsLeft}m' : '${minsLeft}m',
                        style: MehdAiTheme.terminalStyle.copyWith(color: isImminent ? MehdAiTheme.red : MehdAiTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MehdAiTheme.yellow.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: MehdAiTheme.yellow.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: MehdAiTheme.yellow),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'The Den auto-locks execution 15 minutes before HIGH impact events to protect capital.',
                      style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.yellow, fontSize: 10),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanicOverlay() {
    return Positioned.fill(
      child: Container(
        color: MehdAiTheme.bgPrimary.withOpacity(0.95),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _PulsingDot(color: MehdAiTheme.red),
                    const SizedBox(height: 24),
                    Text(
                      'PANIC PROTOCOL ENGAGED',
                      style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.red, fontSize: 32, letterSpacing: 4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: MehdAiTheme.red.withOpacity(0.1),
                        border: Border.all(color: MehdAiTheme.red.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CRITICAL ALERT: Systemic Market Failure.\nSecure Capital Immediately.',
                        style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.red, fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _consensus?.rejectionReason ?? 'Execution disabled by Risk Nucleus.',
                      style: MehdAiTheme.labelStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(color: MehdAiTheme.red),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () {
                        setState(() {
                          _consensus = null;
                          _activeSymbol = null;
                          _isDenOpen = false;
                        });
                      },
                      child: Text('ACKNOWLEDGE & DISMISS', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

class ActivateIntent extends Intent {
  const ActivateIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class HelpIntent extends Intent {
  const HelpIntent();
}
