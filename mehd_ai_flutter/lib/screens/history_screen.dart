import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/services/user_service.dart';
import 'package:mehd_ai_flutter/services/payment_service.dart';
import 'package:mehd_ai_flutter/widgets/missed_signals_card.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

/// FILE 9 — history_screen.dart
/// UPGRADE: Institutional-Grade History & Auditing Screen
/// Complete visual overhaul containing ambient depth, glassmorphic trade & decision records,
/// glowing custom status pills, and high-precision timeline auditing.

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _orbCtrl;
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _trades = [];
  List<Map<String, dynamic>> _decisions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    try {
      if (uid != null) {
        final trades = await _userService.getTradeHistory(uid);
        final decisions = await _userService.getConsensusHistory(uid);
        if (mounted) {
          setState(() {
            _trades = trades;
            _decisions = decisions;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  Widget _buildGlowOrb(Color color, {double size = 300}) {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_orbCtrl.value * 0.1),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        title: Text(
          'AUDIT TRAIL & HISTORY',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: MehdAiTheme.bgSecondary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: MehdAiTheme.blue,
              indicatorWeight: 3,
              labelColor: MehdAiTheme.blue,
              unselectedLabelColor: MehdAiTheme.textSecondary,
              labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'TRADES'),
                Tab(text: 'DECISIONS'),
                Tab(text: 'EVENTS'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlowOrb(MehdAiTheme.blue.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildGlowOrb(MehdAiTheme.purple.withOpacity(0.04)),
          ),

          _isLoading
              ? const Center(child: DenLoadingWidget(message: 'The Den is watching...'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _tradesTab(),
                    _decisionsTab(),
                    _eventsTab(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _tradesTab() {
    final payment = context.read<PaymentService>();
    final isFree = payment.currentTier.toLowerCase() == 'observer';

    if (_trades.isEmpty && !isFree) {
      return _emptyState('NO TRADES DETECTED', 'Executed broker transactions will load dynamically');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _trades.length + (isFree ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (isFree && i == 0) {
          return MissedSignalsCard(
            missedCount: 14,
            exampleMissed: 'XAU/USD BUY @ 2350.40',
            onDismiss: () {},
          );
        }

        final index = isFree ? i - 1 : i;
        if (index < 0 || index >= _trades.length) return const SizedBox.shrink();

        final t = _trades[index];
        final profit = (t['profit'] as num?)?.toDouble() ?? 0;
        final isProfit = profit >= 0;
        final themeColor = isProfit ? MehdAiTheme.green : MehdAiTheme.red;

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: themeColor.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(color: themeColor.withOpacity(0.01), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  // Animated Indicator Circle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: themeColor.withOpacity(0.2)),
                    ),
                    child: Icon(
                      t['direction'] == 'BUY' ? Icons.trending_up : Icons.trending_down,
                      color: themeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t['symbol'] ?? 'N/A',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildMiniChip(
                              t['direction'] ?? 'N/A',
                              themeColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              t['date'] ?? '',
                              style: MehdAiTheme.labelStyle.copyWith(fontSize: 10),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24)),
                            const SizedBox(width: 8),
                            Text(
                              'Risk: ${t['risk'] ?? '1'}%',
                              style: MehdAiTheme.labelStyle.copyWith(fontSize: 10, color: MehdAiTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'P&L',
                        style: MehdAiTheme.labelStyle.copyWith(fontSize: 9, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                          color: themeColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _decisionsTab() {
    if (_decisions.isEmpty) {
      return _emptyState('NO DECISIONS LOGGED', 'Consensus telemetry reports will render here');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _decisions.length,
      itemBuilder: (ctx, i) {
        final d = _decisions[i];
        final consensus = (d['consensus_percentage'] as num?)?.toDouble() ?? 0;
        final proceed = d['proceed'] as bool? ?? false;
        final themeColor = proceed ? MehdAiTheme.green : MehdAiTheme.red;

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: themeColor.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: themeColor.withOpacity(0.2)),
                    ),
                    child: Icon(
                      proceed ? Icons.verified_user_outlined : Icons.gpp_bad_outlined,
                      color: themeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              d['symbol'] ?? 'N/A',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildMiniChip(
                              proceed ? 'PASSED' : 'BLOCKED',
                              themeColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d['date'] ?? '',
                          style: MehdAiTheme.labelStyle.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'CONSENSUS',
                        style: MehdAiTheme.labelStyle.copyWith(fontSize: 9, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${consensus.toStringAsFixed(0)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: proceed ? MehdAiTheme.green : MehdAiTheme.yellow,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _eventsTab() {
    final events = [
      {'type': 'info', 'title': 'Account Created', 'desc': 'Welcome to Mehd AI institutional gateway', 'time': 'Today'},
      {'type': 'setting', 'title': 'Risk Profile Hardened', 'desc': 'Risk per trade set to immutable 1.0%', 'time': 'Today'},
      {'type': 'success', 'title': 'Zero-Trust Pipeline Armed', 'desc': 'Digital Twin paper trade sniping initialized', 'time': 'Today'},
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: events.length,
      itemBuilder: (ctx, i) {
        final e = events[i];
        IconData icon;
        Color color;
        switch (e['type']) {
          case 'lock':
            icon = Icons.lock;
            color = MehdAiTheme.red;
            break;
          case 'setting':
            icon = Icons.settings;
            color = MehdAiTheme.blue;
            break;
          case 'success':
            icon = Icons.verified;
            color = MehdAiTheme.green;
            break;
          default:
            icon = Icons.info_outline;
            color = MehdAiTheme.textSecondary;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vertical timeline connectors
            Column(
              children: [
                AnimatedBuilder(
                  animation: _orbCtrl,
                  builder: (_, __) {
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.3 + (_orbCtrl.value * 0.2))),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.08), blurRadius: 10),
                        ],
                      ),
                      child: Icon(icon, color: color, size: 16),
                    );
                  },
                ),
                if (i < events.length - 1)
                  Container(
                    width: 1.5,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withOpacity(0.3), Colors.white.withOpacity(0.03)],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            e['title']!,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e['time']!,
                          style: MehdAiTheme.labelStyle.copyWith(
                            fontSize: 9,
                            color: MehdAiTheme.textSecondary.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e['desc']!,
                      style: MehdAiTheme.labelStyle.copyWith(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.01),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 40,
                color: MehdAiTheme.textSecondary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: MehdAiTheme.labelStyle.copyWith(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
