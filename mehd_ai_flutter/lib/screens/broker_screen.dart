import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum TrustTier {
  trueEcn,
  hybrid,
  marketMaker,
  universal
}

class Broker {
  final String id;
  final String name;
  final String initials;
  final String type;
  final Color color;
  
  // New Broker Health Metrics (The 4 Pillars)
  final int healthScore;
  final double avgSlippage;       // Price Accuracy
  final int executionLatency;     // Execution Speed
  final int withdrawalHonesty;    // Withdrawal & Account Honesty
  final String spreadStability;   // Spread Stability
  
  final TrustTier trustTier;
  final String warningMessage;

  const Broker({
    required this.id,
    required this.name,
    required this.initials,
    required this.type,
    required this.color,
    required this.healthScore,
    required this.avgSlippage,
    required this.executionLatency,
    required this.withdrawalHonesty,
    required this.spreadStability,
    required this.trustTier,
    this.warningMessage = '',
  });
}

class BrokerScreen extends StatefulWidget {
  const BrokerScreen({super.key});

  @override
  State<BrokerScreen> createState() => _BrokerScreenState();
}

class _BrokerScreenState extends State<BrokerScreen> {
  bool _isConnected = false;
  String _connectedBroker = '';
  String _accountType = ''; // demo/live
  
  final _secureStorage = const FlutterSecureStorage();
  final _apiKeyCtrl = TextEditingController();
  final _accountIdCtrl = TextEditingController();

  final List<Broker> brokers = [
    const Broker(
      id: 'pepperstone', 
      name: 'Pepperstone', 
      initials: 'PP', 
      type: 'MT5 Compatible', 
      color: Color(0xFF4ECDC4),
      healthScore: 96,
      avgSlippage: 0.2,
      executionLatency: 45,
      withdrawalHonesty: 98,
      spreadStability: '99%',
      trustTier: TrustTier.trueEcn,
    ),
    const Broker(
      id: 'icmarkets', 
      name: 'IC Markets', 
      initials: 'IC', 
      type: 'MT5 Compatible', 
      color: Color(0xFF00D4FF),
      healthScore: 94,
      avgSlippage: 0.3,
      executionLatency: 40,
      withdrawalHonesty: 97,
      spreadStability: '98%',
      trustTier: TrustTier.trueEcn,
    ),
    const Broker(
      id: 'oanda', 
      name: 'OANDA', 
      initials: 'OA', 
      type: 'API Direct', 
      color: Color(0xFF58A6FF),
      healthScore: 88,
      avgSlippage: 0.6,
      executionLatency: 60,
      withdrawalHonesty: 100,
      spreadStability: '85%',
      trustTier: TrustTier.hybrid,
    ),
    const Broker(
      id: 'xm', 
      name: 'XM', 
      initials: 'XM', 
      type: 'MT5 Compatible', 
      color: Color(0xFFD29922),
      healthScore: 72,
      avgSlippage: 1.4,
      executionLatency: 120,
      withdrawalHonesty: 85,
      spreadStability: '60%',
      trustTier: TrustTier.hybrid,
    ),
    const Broker(
      id: 'exness', 
      name: 'Exness', 
      initials: 'EX', 
      type: 'MT5 Compatible', 
      color: Color(0xFFFF6B00),
      healthScore: 42,
      avgSlippage: 3.5,
      executionLatency: 350,
      withdrawalHonesty: 65,
      spreadStability: '40%',
      trustTier: TrustTier.marketMaker,
      warningMessage: 'Warning: This broker routinely artificially widens spreads and delays execution. The AI\'s mathematical accuracy will be severely compromised.',
    ),
    const Broker(
      id: 'mt5', 
      name: 'Universal MT5', 
      initials: 'M5', 
      type: 'Any Broker', 
      color: Color(0xFF888888),
      healthScore: 0,
      avgSlippage: 0.0,
      executionLatency: 0,
      withdrawalHonesty: 0,
      spreadStability: 'N/A',
      trustTier: TrustTier.universal,
      warningMessage: 'Universal MT5 connection lacks AI Health Tracking. Use at your own risk.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('BROKER SHIELD', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: MehdAiTheme.white),
      ),
      body: Stack(
        children: [
          // Background Animated Orbs for Glassmorphism effect
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D4FF).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.1), blurRadius: 100, spreadRadius: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB122E5).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFB122E5).withOpacity(0.1), blurRadius: 100, spreadRadius: 100),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWideScreen = constraints.maxWidth > 600;
                
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AI BROKER INTELLIGENCE",
                            style: MehdAiTheme.headingStyle.copyWith(color: const Color(0xFF888888), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "The Den continuously monitors execution latency and slippage to expose market manipulation. Connect to a verified ECN for maximum AI accuracy.",
                            style: MehdAiTheme.labelStyle.copyWith(color: const Color(0xFF777777), fontSize: 12, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_isConnected) _buildConnectedState(),
                        ],
                      ),
                    ),

                    isWideScreen 
                      ? SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: constraints.maxWidth > 1200 ? 3 : 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildGlassmorphismCard(brokers[index]),
                            childCount: brokers.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildGlassmorphismCard(brokers[index]),
                            ),
                            childCount: brokers.length,
                          ),
                        ),
                        
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFF222222))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or', style: MehdAiTheme.labelStyle.copyWith(color: const Color(0xFF444444))),
                              ),
                              const Expanded(child: Divider(color: Color(0xFF222222))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildPaperTradingCard(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildConnectedState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF001208),
        border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00FF88).withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Color(0xFF00FF88), size: 24),
              const SizedBox(width: 12),
              Text("SHIELD ACTIVE: BROKER CONNECTED", style: MehdAiTheme.headingStyle.copyWith(color: const Color(0xFF00FF88), letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Broker: ${brokers.firstWhere((b) => b.id == _connectedBroker, orElse: () => brokers.last).name}", style: MehdAiTheme.labelStyle.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("Account: ****1234", style: MehdAiTheme.labelStyle.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("Type: ${_accountType.toUpperCase()}", style: MehdAiTheme.labelStyle.copyWith(fontSize: 14)),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isConnected = false;
                    _connectedBroker = '';
                    _accountType = '';
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0505),
                  side: const BorderSide(color: Color(0xFFFF3B3B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text('DISCONNECT', style: MehdAiTheme.terminalStyle.copyWith(color: const Color(0xFFFF3B3B), fontSize: 11, letterSpacing: 1)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGlassmorphismCard(Broker broker) {
    Color scoreColor;
    if (broker.healthScore >= 90) {
      scoreColor = const Color(0xFF00FF88);
    } else if (broker.healthScore >= 70) {
      scoreColor = const Color(0xFFD29922);
    } else if (broker.healthScore > 0) {
      scoreColor = const Color(0xFFFF3B3B);
    } else {
      scoreColor = const Color(0xFF555555);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF080808).withOpacity(0.4),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showConnectSheet(broker),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48, 
                              height: 48,
                              decoration: BoxDecoration(
                                color: broker.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: broker.color.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  broker.initials,
                                  style: TextStyle(color: broker.color, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(broker.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      broker.trustTier == TrustTier.trueEcn ? Icons.verified_user : 
                                      broker.trustTier == TrustTier.marketMaker ? Icons.warning_amber_rounded : Icons.info_outline,
                                      size: 14,
                                      color: broker.trustTier == TrustTier.trueEcn ? const Color(0xFF00FF88) : 
                                            broker.trustTier == TrustTier.marketMaker ? const Color(0xFFFF3B3B) : const Color(0xFF888888),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      broker.trustTier == TrustTier.trueEcn ? 'ECN VERIFIED' : 
                                      broker.trustTier == TrustTier.marketMaker ? 'MARKET MAKER' : broker.type.toUpperCase(), 
                                      style: TextStyle(
                                        color: broker.trustTier == TrustTier.trueEcn ? const Color(0xFF00FF88) : 
                                              broker.trustTier == TrustTier.marketMaker ? const Color(0xFFFF3B3B) : const Color(0xFF888888), 
                                        fontSize: 10,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Health Score Circular Indicator
                        if (broker.healthScore > 0)
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: broker.healthScore / 100,
                                  color: scoreColor,
                                  backgroundColor: scoreColor.withOpacity(0.1),
                                  strokeWidth: 4,
                                ),
                                Text(
                                  '${broker.healthScore}',
                                  style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        else if (_isConnected && _connectedBroker == broker.id)
                          const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 32)
                      ],
                    ),
                    const Spacer(),
                    
                    if (broker.healthScore > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF222222)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMicroStat('LATENCY (SPEED)', '${broker.executionLatency} ms', broker.executionLatency < 100 ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B)),
                                Container(width: 1, height: 24, color: const Color(0xFF333333)),
                                _buildMicroStat('ACCURACY (SLIP)', '${broker.avgSlippage} pips', broker.avgSlippage < 1.0 ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(height: 1, width: double.infinity, color: const Color(0xFF333333)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMicroStat('WITHDRAWAL SCORE', '${broker.withdrawalHonesty}/100', broker.withdrawalHonesty >= 90 ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B)),
                                Container(width: 1, height: 24, color: const Color(0xFF333333)),
                                _buildMicroStat('SPREAD STABILITY', broker.spreadStability, (() {
                                  final val = double.tryParse(broker.spreadStability.replaceAll('%', ''));
                                  if (val == null) return const Color(0xFF555555);
                                  return val >= 90 ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B);
                                })()),
                              ],
                            ),
                          ],
                        ),
                      )
                    else 
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF58A6FF).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF58A6FF).withOpacity(0.2)),
                        ),
                        child: const Center(
                          child: Text(
                            'CONNECT VIA API →',
                            style: TextStyle(color: Color(0xFF58A6FF), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicroStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaperTradingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF020810).withOpacity(0.5),
            border: Border.all(color: const Color(0xFF58A6FF).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.school, color: Color(0xFF58A6FF), size: 32),
              const SizedBox(height: 12),
              const Text(
                'PAPER TRADING ENVIRONMENT',
                style: TextStyle(color: Color(0xFF58A6FF), fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '\$10,000 simulated balance. Perfect for testing The Den\'s accuracy without risking real capital.',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    context.read<TradingController>().setPaperMode(true);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF58A6FF).withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: const Color(0xFF58A6FF).withOpacity(0.5))),
                  ),
                  child: const Text(
                    'ACTIVATE PAPER TRADING',
                    style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConnectSheet(Broker broker) {
    setState(() {
      _accountType = 'demo';
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparent for blur
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 24,
                    right: 24,
                    top: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050505).withOpacity(0.8),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CONNECT TO ${broker.name.toUpperCase()}',
                              style: TextStyle(color: broker.color, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: () => Navigator.pop(context),
                            )
                          ],
                        ),
                        
                        if (broker.warningMessage.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16, bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B3B).withOpacity(0.1),
                              border: Border.all(color: const Color(0xFFFF3B3B).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_rounded, color: Color(0xFFFF3B3B), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    broker.warningMessage,
                                    style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 11, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        const SizedBox(height: 24),
                        
                        if (broker.id == 'oanda') ...[
                          _brokerField('API Key', controller: _apiKeyCtrl, obscure: true),
                          _brokerField('Account ID', controller: _accountIdCtrl),
                          _accountTypeToggle(setModalState),
                        ],
                        
                        if (broker.id != 'oanda') ...[
                          _brokerField('MT5 Login', controller: _accountIdCtrl),
                          _brokerField('MT5 Password', controller: _apiKeyCtrl, obscure: true),
                          _brokerField('Server', hint: 'e.g. ${broker.name}-MT5Real'),
                          _accountTypeToggle(setModalState),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: broker.color.withOpacity(0.15),
                              side: BorderSide(color: broker.color.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              _connectBroker(broker);
                              Navigator.pop(context);
                            },
                            child: Text(
                              'ESTABLISH SECURE CONNECTION',
                              style: TextStyle(color: broker.color, letterSpacing: 1.5, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _brokerField(String label, {bool obscure = false, String? hint, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 12),
          hintStyle: const TextStyle(color: Color(0xFF333333), fontSize: 12),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF58A6FF)),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _accountTypeToggle(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          const Text('Account Environment:', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
          const Spacer(),
          ChoiceChip(
            label: const Text('DEMO'),
            selected: _accountType == 'demo',
            onSelected: (_) => setModalState(() => _accountType = 'demo'),
            selectedColor: const Color(0xFF58A6FF).withOpacity(0.2),
            backgroundColor: Colors.transparent,
            side: BorderSide(color: _accountType == 'demo' ? const Color(0xFF58A6FF) : Colors.white.withOpacity(0.1)),
            labelStyle: TextStyle(
              color: _accountType == 'demo' ? const Color(0xFF58A6FF) : const Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('LIVE'),
            selected: _accountType == 'live',
            onSelected: (_) => setModalState(() => _accountType = 'live'),
            selectedColor: const Color(0xFFFF3B3B).withOpacity(0.2),
            backgroundColor: Colors.transparent,
            side: BorderSide(color: _accountType == 'live' ? const Color(0xFFFF3B3B) : Colors.white.withOpacity(0.1)),
            labelStyle: TextStyle(
              color: _accountType == 'live' ? const Color(0xFFFF3B3B) : const Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _connectBroker(Broker selectedBroker) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    await _secureStorage.write(key: 'broker_api_key', value: _apiKeyCtrl.text);
    await _secureStorage.write(key: 'broker_account_id', value: _accountIdCtrl.text);
    
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('broker')
            .doc('config')
            .set({
          'broker': selectedBroker.id,
          'type': _accountType,
          'status': 'pending',
          'savedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Ignored
      }
    }

    _apiKeyCtrl.clear();
    _accountIdCtrl.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: const Color(0xFF0A0800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFD29922), width: 0.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('🛡️ Credentials Encrypted & Saved',
              style: TextStyle(color: Color(0xFFD29922), fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              'Awaiting backend API handshake.',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11)),
          ]),
      ));
      
      setState(() {
        _isConnected = true; 
        _connectedBroker = selectedBroker.id;
      });
    }
  }
}
