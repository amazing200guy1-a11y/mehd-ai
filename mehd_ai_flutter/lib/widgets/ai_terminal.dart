import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/den_identity.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';
import 'package:mehd_ai_flutter/models/automated_drawing.dart';

/// FILE 7 — ai_terminal.dart
/// Grand Master Build Spec implementation.

class AiTerminal extends StatefulWidget {
  final ConsensusResult? consensusResult;
  final bool isAnalyzing;
  final List<AutomatedDrawing>? drawings;

  const AiTerminal({
    super.key,
    this.consensusResult,
    required this.isAnalyzing,
    this.drawings,
  });

  @override
  State<AiTerminal> createState() => _AiTerminalState();
}

class _AiTerminalState extends State<AiTerminal> {
  int _currentTab = 0;
  final List<String> _tabs = ['>_ TERMINAL', 'VOTES', 'THE DEN', 'ACCOUNT'];
  final ScrollController _terminalScroll = ScrollController();

  @override
  void didUpdateWidget(covariant AiTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.consensusResult != oldWidget.consensusResult && _currentTab == 0) {
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
  Widget build(BuildContext context) {
    final bool unanimous = widget.consensusResult?.proceed == true;

    return Container(
      width: double.infinity,
      color: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          // Header / Tab Bar
          Container(
            height: 36,
            color: const Color(0xFF080808),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isActive = _currentTab == index;
                return InkWell(
                  onTap: () => setState(() => _currentTab = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? const Color(0xFF58A6FF) : Colors.transparent,
                          width: 2,
                        ),
                        right: const BorderSide(color: Color(0xFF111111)),
                      ),
                      color: isActive ? const Color(0xFF0D0D0D) : Colors.transparent,
                    ),
                    child: Text(
                      _tabs[index],
                      style: GoogleFonts.jetBrainsMono(
                        color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF555555),
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Content Area
          Expanded(
            child: Container(
              color: unanimous && _currentTab == 1 ? const Color(0xFF2EA043).withOpacity(0.05) : Colors.transparent,
              child: _buildCurrentTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return _buildTerminalTab();
      case 1:
        return _buildVotesTab();
      case 2:
        return _buildTheDenTab();
      case 3:
        return _buildAccountTab();
      default:
        return const SizedBox();
    }
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
            const Center(child: DenLoadingWidget(message: 'Initializing agents...')),
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
              Text(
                '[$timeStr] ',
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFF8B949E), fontSize: 11), // 8b949e for timestamps
              ),
              Expanded(
                child: Text(
                  '<${id.displayName.toUpperCase()}> ${vote.reasoning}',
                  style: GoogleFonts.jetBrainsMono(color: const Color(0xFFCCCCCC), fontSize: 11), // standard log
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
            'THE UNDERWORLD',
            'Sift, Sentiment, Order Flow',
            'Protects against retail crowding and sudden traps.',
            const Color(0xFFBC8CFF),
          ),
          const SizedBox(height: 12),
          _buildLayerBox(
            'THE EMPIRE',
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetric('Balance', '\$10,000.00', Colors.white),
          const SizedBox(height: 16),
          _buildMetric('Daily P/L', '+\$142.50', const Color(0xFF2EA043)),
          const SizedBox(height: 32),
          _buildMetric('Risk Cap', '1.0% (Enforced)', const Color(0xFF58A6FF)),
          const SizedBox(height: 16),
          _buildMetric('Drawdown Limit', '3.0% (Active)', const Color(0xFF58A6FF)),
        ],
      ),
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
