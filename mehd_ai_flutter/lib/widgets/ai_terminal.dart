import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';

/// FILE 7 — ai_terminal.dart
///
/// Build Debrief:
/// This is the psychological core of the app. Why do traders lose money? Emotion.
/// By showing raw, monospace text output of EXACTLY what the 9 AI models 
/// are thinking, we build immense trust. The user isn't just seeing a green button;
/// they are seeing 'DeepSeek-V3 says the standard deviation is tight.'
/// The staggered streaming effect (handled by DelayedWidget below) makes it feel 
/// alive, like you're watching a supercomputer think.

class AiTerminal extends StatefulWidget {
  final ConsensusResult? consensusResult;
  final bool isAnalyzing;

  const AiTerminal({
    super.key,
    this.consensusResult,
    required this.isAnalyzing,
  });

  @override
  State<AiTerminal> createState() => _AiTerminalState();
}

class _AiTerminalState extends State<AiTerminal> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant AiTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new data arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Fixed width on desktop
      color: MehdAiTheme.bgPrimary,
      child: Column(
        children: [
          // Tabs
          Container(
            color: MehdAiTheme.bgSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI TERMINAL', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textPrimary, fontWeight: FontWeight.bold)),
                Text('THE DEN', style: MehdAiTheme.labelStyle),
                Text('ACCOUNT', style: MehdAiTheme.labelStyle),
              ],
            ),
          ),
          
          const Divider(height: 1, color: MehdAiTheme.borderColor),
          
          Expanded(
            child: _buildFeed(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    if (widget.isAnalyzing) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultTextStyle(
              style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.purple),
              child: AnimatedTextKit(
                animatedTexts: [TypewriterAnimatedText('> Entering The Den...')],
                isRepeatingAnimation: false,
                displayFullTextOnTap: true,
              ),
            ),
            const SizedBox(height: 32),
            const Center(child: DenLoadingWidget(message: 'The Den is hunting...')),
          ],
        ),
      );
    }

    if (widget.consensusResult == null) {
      return Center(
        child: Text(
          '> Awaiting Market Selection',
          style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary),
        ),
      );
    }

    final votes = widget.consensusResult!.votes;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: votes.length + 1, // +1 for the final system verdict
      itemBuilder: (context, index) {
        if (index == votes.length) {
          // Final System Verdict Message
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    '> [SYSTEM] Den Verdict: ${widget.consensusResult!.consensusPercentage.toStringAsFixed(1)}% ${widget.consensusResult!.finalDirection}\n> PROCEED: ${widget.consensusResult!.proceed.toString().toUpperCase()}',
                    style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.purple, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        }

        final vote = votes[index];
        final color = _getColorForDirection(vote.direction);
        
        // Simulating the 300ms stream delay per model log
        return TweenAnimationBuilder<double>(
          key: ValueKey('${widget.consensusResult!.timestamp.toIso8601String()}_$index'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeIn), // cascade delay
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: RichText(
                    text: TextSpan(
                      style: MehdAiTheme.terminalStyle,
                      children: [
                        TextSpan(text: '[', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
                        TextSpan(text: vote.modelName.toUpperCase(), style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold)),
                        TextSpan(text: '] ', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
                        TextSpan(text: '${vote.direction} ', style: MehdAiTheme.terminalStyle.copyWith(color: color, fontWeight: FontWeight.bold)),
                        TextSpan(text: '(${vote.confidence.toStringAsFixed(1)}%)\n', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
                        TextSpan(text: '> ${vote.reasoning}', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getColorForDirection(String direction) {
    switch (direction.toUpperCase()) {
      case 'BUY':
        return MehdAiTheme.green;
      case 'SELL':
        return MehdAiTheme.red;
      default:
        return MehdAiTheme.yellow;
    }
  }
}
