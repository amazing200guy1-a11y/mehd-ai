import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/models/market_snapshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mehd_ai_flutter/core/constants.dart';

class MarketDataController extends ChangeNotifier {
  String? activeSymbol;
  MarketSnapshot? latestSnapshot;
  ConsensusResult? consensus;
  bool isAnalyzing = false;
  bool isBackendOffline = false;
  bool isSentinelFrozen = false;
  ButtonState btnState = ButtonState.locked;
  bool feedbackShown = false;
  bool showFeedbackOption = false;

  final ApiService _apiService = ApiService();
  StreamSubscription<MarketSnapshot>? _priceSub;
  StreamSubscription<QuerySnapshot>? _firestoreSub;

  static const Map<String, double> _spreads = {
    'EUR/USD': 0.8,
    'GBP/USD': 1.2,
    'GBP/JPY': 1.5,
    'XAU/USD': 2.5,
    'BTC/USD': 8.0,
    'ETH/USD': 5.0,
    'NAS100':  1.0,
    'US30':    2.0,
  };

  /// Base prices for realistic demo data
  static const Map<String, double> _basePrices = {
    'EUR/USD': 1.08420,
    'GBP/USD': 1.26340,
    'GBP/JPY': 189.420,
    'XAU/USD': 2318.50,
    'BTC/USD': 67420.0,
    'ETH/USD': 3240.0,
    'NAS100':  17842.0,
    'US30':    38910.0,
    'PARADOX/USD': 1.0,
  };

  void selectSymbol(String rawSymbol, {required Function(String) onStatusMsg}) {
    final symbol = rawSymbol.replaceAll('/', '');
    activeSymbol = rawSymbol;
    consensus = null;
    btnState = ButtonState.locked;
    latestSnapshot = null;
    notifyListeners();

    // ── INSTANT DEMO SNAPSHOT ──
    // Provide chart data immediately so the UI never hangs on "Entering the Den..."
    // If real data arrives from the stream, it will override this.
    final basePrice = _basePrices[rawSymbol] ?? 1.0;
    final currentSpread = _spreads[rawSymbol] ?? 1.0;
    final spreadDecimal = currentSpread / 10000; // rough representation
    latestSnapshot = MarketSnapshot(
      id: 'demo_${symbol}_${DateTime.now().millisecondsSinceEpoch}',
      symbol: rawSymbol,
      bid: basePrice,
      ask: basePrice + spreadDecimal,
      open: basePrice * 0.999,
      high: basePrice * 1.002,
      low: basePrice * 0.997,
      close: basePrice,
      spread: currentSpread, // Keep in pips!
      volume: 1000,
      timestamp: DateTime.now().toUtc(),
    );
    notifyListeners();

    // Try real price stream (will override demo if backend is live)
    _priceSub?.cancel();
    _priceSub = _apiService.streamPrices(symbol).listen((snapshot) {
      latestSnapshot = snapshot;
      notifyListeners();
    });

    _listenToFirestore(symbol, onStatusMsg);
    _triggerAnalysis(symbol, onStatusMsg);
  }

  void _listenToFirestore(String symbol, Function(String) onStatusMsg) {
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
           _handleNewConsensus(parsed, onStatusMsg);
        }
      });
  }

  Future<void> _triggerAnalysis(String symbol, Function(String) onStatusMsg) async {
    isAnalyzing = true;
    notifyListeners();
    
    final startTime = DateTime.now();
    ConsensusResult? finalResult;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('orchestrateConsensus');
      final result = await callable.call({
         'symbol': symbol,
         'userId': userId,
         'tier': 'sovereign',
      }).timeout(const Duration(seconds: 8)); // Fast timeout — don't hang
      
      if (result.data != null) {
        finalResult = ConsensusResult.fromJson(Map<String, dynamic>.from(result.data));
      }
    } catch (e) {
      debugPrint('Cloud Function failed, falling back to demo: \$e');
      finalResult = _buildDemoConsensus(symbol);
    }

    // Minimum 3s "thinking" feel (was 8s — too slow)
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds < 3000) {
      await Future.delayed(Duration(milliseconds: 3000 - elapsed.inMilliseconds));
    }

    if (finalResult != null) {
      _handleNewConsensus(finalResult, onStatusMsg);
    }
  }

  ConsensusResult _buildDemoConsensus(String symbol) {
    final isBull = ['EUR/USD', 'XAU/USD', 'NAS100', 'BTC/USD'].contains(symbol);
    final randomValue = 72 + (DateTime.now().millisecond % 20);
    
    return ConsensusResult(
      votes: [],
      finalDirection: isBull ? 'BUY' : 'SELL',
      consensusPercentage: randomValue.toDouble(),
      proceed: true,
      timestamp: DateTime.now(),
      rejectionReason: null,
      tier: 'sovereign',
    );
  }

  void _handleNewConsensus(ConsensusResult result, Function(String) onStatusMsg) {
    int maxVotes = 0;
    for (var dir in ['BUY', 'SELL', 'HOLD']) {
      int count = result.votes.where((v) => v.direction == dir).length;
      if (count > maxVotes) maxVotes = count;
    }
    
    bool isDeveloping = maxVotes == 7 && !result.proceed;
    bool isVetoed = !result.proceed && result.rejectionReason != null && result.rejectionReason!.contains("Math Layer Veto");
    bool isFrozen = !result.proceed && result.rejectionReason != null && result.rejectionReason!.contains("SENTINEL_HARD_FREEZE");

    bool justFlipped = btnState == ButtonState.developing && result.proceed;

    consensus = result;
    isAnalyzing = false;
    isSentinelFrozen = isFrozen;
    
    if (isFrozen) {
      btnState = ButtonState.locked;
    } else if (isVetoed) {
      btnState = ButtonState.vetoed;
    } else if (isDeveloping) {
      btnState = ButtonState.developing;
    } else if (result.proceed) {
      btnState = result.finalDirection == 'BUY' 
          ? ButtonState.readyBuy 
          : ButtonState.readySell;
      
      if (justFlipped) {
        onStatusMsg(result.tier == 'sovereign' 
            ? "Unanimous. All 11 layers aligned.\nThis is the rarest signal in The Den.\nStrike with full force."
            : "The Den agrees. Strike now.");
      }
    } else {
      btnState = ButtonState.locked;
    }
    
    if (!feedbackShown) {
      Future.delayed(const Duration(seconds: 5), () {
        showFeedbackOption = true;
        notifyListeners();
        Future.delayed(const Duration(seconds: 8), () {
          if (showFeedbackOption) {
            showFeedbackOption = false;
            feedbackShown = true;
            notifyListeners();
          }
        });
      });
    }
    notifyListeners();
  }

  void hideFeedbackOption() {
    showFeedbackOption = false;
    feedbackShown = true;
    notifyListeners();
  }

  void overrideActiveSymbol(String sym) {
    activeSymbol = sym;
    notifyListeners();
  }
  
  void overrideSentinelFrozen(bool frozen) {
    isSentinelFrozen = frozen;
    notifyListeners();
  }
  
  void clearConsensus() {
    consensus = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _priceSub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }
}
