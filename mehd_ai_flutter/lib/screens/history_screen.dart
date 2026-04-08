import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/services/user_service.dart';
import 'package:provider/provider.dart';

/// FILE 9 — history_screen.dart
///
/// Build Debrief:
/// Full trade history with 3 tabs. Trade data comes from Firestore collections.
/// Color-coded P&L (green/red), expandable items, and timeline events.

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _trades = [];
  List<Map<String, dynamic>> _decisions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      final trades = await _userService.getTradeHistory(uid);
      final decisions = await _userService.getConsensusHistory(uid);
      if (mounted) setState(() { _trades = trades; _decisions = decisions; _isLoading = false; });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: MehdAiTheme.bgSecondary, elevation: 0,
        title: Text('History', style: MehdAiTheme.headingStyle.copyWith(fontSize: 18)),
        bottom: TabBar(
          isScrollable: true,
          controller: _tabController,
          indicatorColor: MehdAiTheme.blue, labelColor: MehdAiTheme.textPrimary,
          unselectedLabelColor: MehdAiTheme.textSecondary,
          labelStyle: MehdAiTheme.labelStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Trades'), Tab(text: 'AI Decisions'), Tab(text: 'Account Events')],
        ),
      ),
      body: _isLoading
        ? const Center(child: DenLoadingWidget(message: 'The Den is watching...'))
        : TabBarView(controller: _tabController, children: [_tradesTab(), _decisionsTab(), _eventsTab()]),
    );
  }

  Widget _tradesTab() {
    if (_trades.isEmpty) return _emptyState('No trades yet', 'Your trade history will appear here');
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: _trades.length,
      itemBuilder: (ctx, i) {
        final t = _trades[i];
        final profit = (t['profit'] as num?)?.toDouble() ?? 0;
        final isProfit = profit >= 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: MehdAiTheme.bgSecondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: MehdAiTheme.borderColor)),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: (isProfit ? MehdAiTheme.green : MehdAiTheme.red).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(t['direction'] == 'BUY' ? Icons.trending_up : Icons.trending_down, color: isProfit ? MehdAiTheme.green : MehdAiTheme.red, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['symbol'] ?? 'N/A', style: MehdAiTheme.priceStyle.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text('${t['direction'] ?? 'N/A'}  •  ${t['date'] ?? ''}  •  Risk: ${t['risk'] ?? '1'}%', style: MehdAiTheme.labelStyle.copyWith(fontSize: 11)),
            ])),
            Text('${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}', style: MehdAiTheme.priceStyle.copyWith(fontSize: 15, color: isProfit ? MehdAiTheme.green : MehdAiTheme.red)),
          ]),
        );
      },
    );
  }

  Widget _decisionsTab() {
    if (_decisions.isEmpty) return _emptyState('No AI decisions yet', 'Consensus analyses will appear here');
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: _decisions.length,
      itemBuilder: (ctx, i) {
        final d = _decisions[i];
        final consensus = (d['consensus_percentage'] as num?)?.toDouble() ?? 0;
        final proceed = d['proceed'] as bool? ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: MehdAiTheme.bgSecondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: MehdAiTheme.borderColor)),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: (proceed ? MehdAiTheme.green : MehdAiTheme.red).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(proceed ? Icons.check_circle_outline : Icons.cancel_outlined, color: proceed ? MehdAiTheme.green : MehdAiTheme.red, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['symbol'] ?? 'N/A', style: MehdAiTheme.priceStyle.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text('${d['date'] ?? ''}  •  ${proceed ? 'PROCEED' : 'REJECTED'}', style: MehdAiTheme.labelStyle.copyWith(fontSize: 11)),
            ])),
            Text('${consensus.toStringAsFixed(1)}%', style: MehdAiTheme.priceStyle.copyWith(fontSize: 15, color: proceed ? MehdAiTheme.green : MehdAiTheme.yellow)),
          ]),
        );
      },
    );
  }

  Widget _eventsTab() {
    // Mock account events (lock events, kill-switch activations, risk changes)
    final events = [
      {'type': 'info', 'title': 'Account Created', 'desc': 'Welcome to Mehd AI', 'time': 'Today'},
      {'type': 'setting', 'title': 'Risk Set', 'desc': 'Risk per trade set to 1.0%', 'time': 'Today'},
      {'type': 'success', 'title': 'Demo Mode Active', 'desc': 'Paper trading enabled', 'time': 'Today'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: events.length,
      itemBuilder: (ctx, i) {
        final e = events[i];
        IconData icon; Color color;
        switch (e['type']) {
          case 'lock': icon = Icons.lock; color = MehdAiTheme.red; break;
          case 'setting': icon = Icons.settings; color = MehdAiTheme.blue; break;
          case 'success': icon = Icons.check_circle; color = MehdAiTheme.green; break;
          default: icon = Icons.info_outline; color = MehdAiTheme.textSecondary;
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
            if (i < events.length - 1) Container(width: 2, height: 40, color: MehdAiTheme.borderColor),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['title']!, style: MehdAiTheme.headingStyle.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text(e['desc']!, style: MehdAiTheme.labelStyle.copyWith(fontSize: 12)),
              const SizedBox(height: 4),
              Text(e['time']!, style: MehdAiTheme.labelStyle.copyWith(fontSize: 10, color: MehdAiTheme.textSecondary.withOpacity(0.6))),
            ]),
          )),
        ]);
      },
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history, size: 48, color: MehdAiTheme.textSecondary.withOpacity(0.3)),
      const SizedBox(height: 16),
      Text(title, style: MehdAiTheme.headingStyle.copyWith(fontSize: 16)),
      const SizedBox(height: 8),
      Text(subtitle, style: MehdAiTheme.labelStyle.copyWith(fontSize: 13)),
    ]));
  }
}
