import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/den_identity.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/widgets/analysis_progress_widget.dart';
import 'package:mehd_ai_flutter/models/automated_drawing.dart';
import 'package:provider/provider.dart';
import 'package:mehd_ai_flutter/services/settings_service.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/models/account_health.dart';
import 'package:mehd_ai_flutter/services/news_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// FILE 7 — ai_terminal.dart
/// Grand Master Build Spec implementation.

class AiTerminal extends StatefulWidget {
  final ConsensusResult? consensusResult;
  final bool isAnalyzing;
  final List<AutomatedDrawing>? drawings;
  final VoidCallback? onStrikeComplete;

  const AiTerminal({
    super.key,
    this.consensusResult,
    required this.isAnalyzing,
    this.drawings,
    this.onStrikeComplete,
  });

  @override
  State<AiTerminal> createState() => _AiTerminalState();
}

class _AiTerminalState extends State<AiTerminal> {
  final ScrollController _terminalScroll = ScrollController();
  bool _hasTriggeredStrike = false;

  @override
  void didUpdateWidget(covariant AiTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.consensusResult != oldWidget.consensusResult) {
      // Reset strike flag when we get a brand new consensus
      _hasTriggeredStrike = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_terminalScroll.hasClients) {
          _terminalScroll.animateTo(
            _terminalScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _terminalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool unanimous = widget.consensusResult?.proceed == true;

    return Container(
      width: double.infinity,
      color: const Color(0xFF0D0D0D),
      child: SafeArea(
        bottom: true,
        child: DefaultTabController(
          length: 5,
          child: Column(
            children: [
              SizedBox(
                height: 38,
                child: TabBar(
                  isScrollable: false,
                  labelColor: const Color(0xFF58A6FF),
                  unselectedLabelColor: const Color(0xFF555555),
                  indicatorColor: const Color(0xFF58A6FF),
                  // Customize indicator weight and padding if needed
                  indicatorWeight: 2,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    Tab(child: Text('TERM', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold))),
                    Tab(child: Text('NEWS', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold))),
                    Tab(child: Text('VOTES', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold))),
                    Tab(child: Text('DEN', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold))),
                    Tab(child: Text('ACCT', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTerminalTab(),
                    _buildNewsTab(),
                    Container(
                      color: unanimous ? const Color(0xFF2EA043).withOpacity(0.05) : Colors.transparent,
                      child: _buildVotesTab(),
                    ),
                    _buildTheDenTab(),
                    _buildAccountTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsTab() {
    return FutureBuilder<List<NewsArticle>>(
      future: NewsService().fetchGeneralNews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF58A6FF)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading news', style: GoogleFonts.jetBrainsMono(color: Colors.red)));
        }
        final articles = snapshot.data ?? [];
        if (articles.isEmpty) {
          return Center(child: Text('No recent news.', style: GoogleFonts.jetBrainsMono(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            final timeStr = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(article.datetime * 1000));
            
            return InkWell(
              onTap: () async {
                if (article.url.isNotEmpty) {
                  final uri = Uri.parse(article.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('[$timeStr] ', style: GoogleFonts.jetBrainsMono(color: const Color(0xFF58A6FF), fontSize: 10)),
                        Text(article.source, style: GoogleFonts.jetBrainsMono(color: const Color(0xFFAAAAAA), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.headline,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (article.summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        article.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTerminalTab() {
    if (widget.isAnalyzing) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '> Entering The Den...',
              style: GoogleFonts.jetBrainsMono(color: const Color(0xFF58A6FF), fontSize: 11),
            ),
            const SizedBox(height: 32),
            AnalysisProgressWidget(isAnalyzing: widget.isAnalyzing),
          ],
        ),
      );
    }

    if (widget.consensusResult == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '> AWAITING SYSTEM INITIALIZATION...\n\nWelcome to The Den — Demo Mode. All analysis is simulated. Add API keys to enable real intelligence.',
          style: GoogleFonts.jetBrainsMono(color: const Color(0xFF555555), fontSize: 11),
        ),
      );
    }

    final votes = widget.consensusResult!.votes;
    final showNames = context.watch<SettingsService>().showAgentNames;

    return ListView.builder(
      controller: _terminalScroll,
      padding: const EdgeInsets.all(16),
      itemCount: votes.length + 2, // Initial + Final verdict
      itemBuilder: (context, index) {
        final timeStr = DateFormat('HH:mm:ss').format(widget.consensusResult!.timestamp.toLocal());
        
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '[$timeStr] <SYSTEM> Consensus execution started for ${widget.consensusResult!.tier} tier.',
              style: GoogleFonts.jetBrainsMono(color: const Color(0xFF58A6FF), fontSize: 11),
            ),
          );
        }

        if (index == votes.length + 1) {
          final isProceed = widget.consensusResult!.proceed;
          final color = isProceed ? const Color(0xFF2EA043) : const Color(0xFFF85149);
          
          final user = FirebaseAuth.instance.currentUser;
          final traderName = user?.displayName?.split(' ').first ?? 'Commander';
          
          final theDonMessage = isProceed 
              ? '> [THE DON] $traderName, it is unanimous. Strike with full force.'
              : '> [THE DON] $traderName, the market is misaligned. Stay out.';

          final text = isProceed 
              ? 'SIGNAL LOCKED. AWAITING YOUR COMMAND.'
              : 'PROTOCOL HALTED. ALIGNMENT INCOMPLETE.';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              onEnd: () {
                if (isProceed && !_hasTriggeredStrike) {
                  _hasTriggeredStrike = true;
                  widget.onStrikeComplete?.call();
                }
              },
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: value,
                      child: Text(
                        theDonMessage,
                        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: 0.2 + (0.8 * (0.5 + 0.5 * value % 1.0)), 
                      child: Text(
                        text,
                        style: GoogleFonts.jetBrainsMono(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }

        final vote = votes[index - 1];
        final id = DenIdentity.getIdentity(vote.modelName);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  '[$timeStr]',
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 7),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 64,
                child: Text(
                  showNames ? '<${id.displayName.toUpperCase()}>' : '<AGENT>',
                  style: TextStyle(
                    color: id.nodeColor,
                    fontSize: 7,
                    fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  vote.reasoning,
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 8),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVotesTab() {
    if (widget.consensusResult == null) {
      return const Center(child: Text('No active consensus.'));
    }

    final votes = widget.consensusResult!.votes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF333333))),
            ),
            children: [
              _headerCell('AGENT'),
              _headerCell('LAYER'),
              _headerCell('VERDICT'),
              _headerCell('CONFIDENCE'),
            ],
          ),
          ...votes.map((vote) {
            final id = DenIdentity.getIdentity(vote.modelName);
            final isBuy = vote.direction == 'BUY';
            final isSell = vote.direction == 'SELL';
            final color = isBuy ? const Color(0xFF2EA043) : (isSell ? const Color(0xFFF85149) : const Color(0xFF58A6FF));

            return TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
              ),
              children: [
                _cell(id.displayName, const Color(0xFFCCCCCC)),
                _cell(id.layer, const Color(0xFF8B949E)),
                _cell(vote.direction, color, bold: true),
                _cell('${(vote.confidence * 100).toInt()}%', const Color(0xFF8B949E)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(color: const Color(0xFF555555), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _cell(String text, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(color: color, fontSize: 11, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }

  Widget _buildTheDenTab() {
    // A static display of the 3-layer architecture map.
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLayerBox(
            'THE RESEARCH',
            'Sift, Sentiment, Order Flow',
            'Protects against retail crowding and sudden traps.',
            const Color(0xFFBC8CFF),
          ),
          const SizedBox(height: 12),
          _buildLayerBox(
            'THE STRATEGY',
            'Pattern, Structure, Trend',
            'Protects against trading against the primary institutional momentum.',
            const Color(0xFFFFD700),
          ),
          const SizedBox(height: 12),
          _buildLayerBox(
            'OLYMPUS',
            'Math, Fractal, Volatility',
            'Protects against low-probability mathematical environments.',
            const Color(0xFFFF9F43),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerBox(String title, String subtitle, String tooltip, Color accent) {
    return Tooltip(
      message: tooltip,
      textStyle: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: const Color(0xFF333333))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF080808),
          border: Border.all(color: const Color(0xFF1A1A1A)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, color: accent),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.jetBrainsMono(color: const Color(0xFF8B949E), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    return FutureBuilder<AccountHealth>(
      future: ApiService().getAccountHealth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF58A6FF)));
        }
        
        final health = snapshot.data;
        final balance = health?.balance ?? 0.0;
        final equity = health?.equity ?? 0.0;
        final drawdown = health?.dailyDrawdownPct ?? 0.0;
        
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetric('Balance', '\$${balance.toStringAsFixed(2)}', Colors.white),
              const SizedBox(height: 16),
              _buildMetric('Equity', '\$${equity.toStringAsFixed(2)}', Colors.white),
              const SizedBox(height: 32),
              _buildMetric('Daily Drawdown', '${drawdown.toStringAsFixed(2)}%', drawdown > 2.0 ? const Color(0xFFFF3B3B) : const Color(0xFF2EA043)),
              const SizedBox(height: 16),
              _buildMetric('Status', health?.isLocked == true ? 'LOCKED' : 'ACTIVE', health?.isLocked == true ? const Color(0xFFFF3B3B) : const Color(0xFF58A6FF)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(color: const Color(0xFF8B949E), fontSize: 11),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
