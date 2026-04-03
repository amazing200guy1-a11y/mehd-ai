import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/widgets/den_verdict_card.dart';

/// FILE — vibe_trading_screen.dart
///
/// Build Debrief:
/// Vibe Trading Mode transforms the app from a terminal into a true companion.
/// Instead of manually picking pairs and charting, the user speaks to The Den 
/// in natural language.
/// 
/// Core Features Built:
/// 1. Emotion Firewall: Explicit checks for tilt words (scared, revenge, angry).
///    Returns an empathetic, protective response without triggering a live trade.
/// 2. Generative Stream UI: Simulates The Don token-by-token streaming
///    for the companion feel.
/// 3. Contextual UI Rendering: When the Den successfully finds a pair, it
///    injects the DenVerdictCard directly into the chat stream for 1-tap execution.

class VibeTradingScreen extends StatefulWidget {
  const VibeTradingScreen({super.key});

  @override
  State<VibeTradingScreen> createState() => _VibeTradingScreenState();
}

class _VibeTradingScreenState extends State<VibeTradingScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _tiltWords = [
    'scared', 'angry', 'revenge', 'frustrated', 'loss', 'recover', 'desperate', 'liquidated'
  ];

  @override
  void initState() {
    super.initState();
    // Initial greeting
    _messages.add(
      _ChatMessage(
        text: 'The Den is hunting. Tell me what you are looking for today.',
        isUser: false,
      )
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  /// Check if user input contains emotional/tilt language before sending
  bool _detectTilt(String text) {
    final lower = text.toLowerCase();
    return _tiltWords.any((word) => lower.contains(word));
  }

  Future<void> _handleUserSubmit() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    // Client-side tilt detection (server also checks, this is defense in depth)
    final clientDetectedTilt = _detectTilt(text);

    // Call real Python API
    final response = await _apiService.denVibe(text);
    
    if (!mounted) return;

    final responseText = response['text'] as String? ?? "The Den is unavailable.";
    final isEmotional = (response['is_emotional'] as bool? ?? false) || clientDetectedTilt;
    final consensusData = response['consensus'] as Map?;

    ConsensusResult? consensus;
    if (consensusData != null && !isEmotional) {
      consensus = ConsensusResult(
        finalDirection: consensusData['final_direction'] ?? "HOLD",
        consensusPercentage: (consensusData['consensus_percentage'] ?? 0).toDouble(),
        proceed: consensusData['proceed'] ?? false,
        timestamp: DateTime.now(),
        rejectionReason: consensusData['rejection_reason'],
        votes: [
          AIVote(modelName: 'The Don (Risk Executive)', snapshotId: 'mock', direction: 'HOLD', confidence: 0.85, reasoning: 'Analyzing risk parameters.'),
          AIVote(modelName: 'The Quant (Math & Stats)', snapshotId: 'mock', direction: 'BUY', confidence: 0.90, reasoning: 'Statistical edge identified.'),
          AIVote(modelName: 'The Prophecy (Time Cycles)', snapshotId: 'mock', direction: 'BUY', confidence: 0.75, reasoning: 'Cycle alignment favorable.'),
          AIVote(modelName: 'The General (Macro)', snapshotId: 'mock', direction: 'HOLD', confidence: 0.80, reasoning: 'Awaiting macro prints.'),
          AIVote(modelName: 'The Sniper (Execution)', snapshotId: 'mock', direction: 'BUY', confidence: 0.95, reasoning: 'Entry trigger met.'),
          AIVote(modelName: 'The Shadow (Dark Pools)', snapshotId: 'mock', direction: 'SELL', confidence: 0.60, reasoning: 'Minor outflow detected.'),
          AIVote(modelName: 'The Psychologist (Sentiment)', snapshotId: 'mock', direction: 'BUY', confidence: 0.88, reasoning: 'Retail shorting heavily.'),
          AIVote(modelName: 'The Architect (Structure)', snapshotId: 'mock', direction: 'BUY', confidence: 0.92, reasoning: 'Market structure bullish.'),
          AIVote(modelName: 'The Auditor (Compliance)', snapshotId: 'mock', direction: 'HOLD', confidence: 0.99, reasoning: 'Within risk limits.'),
          AIVote(modelName: 'The Detective (On-Chain)', snapshotId: 'mock', direction: 'BUY', confidence: 0.70, reasoning: 'Accumulation visible.'),
          AIVote(modelName: 'The Historian (Backtester)', snapshotId: 'mock', direction: 'HOLD', confidence: 0.82, reasoning: 'Similar patterns mixed.'),
        ], 
      );
    }

    _streamResponse(responseText, consensus);
  }

  void _streamResponse(String fullText, ConsensusResult? consensus) async {
    final msg = _ChatMessage(text: '', isUser: false, isStreaming: true);
    setState(() {
      _messages.add(msg);
      _isTyping = false;
    });

    final words = fullText.split(' ');
    for (var word in words) {
      await Future.delayed(const Duration(milliseconds: 40)); // Token stream speed
      if (!mounted) return;
      
      setState(() {
        msg.text += '$word ';
      });
      _scrollToBottom();
    }
    
    setState(() {
      msg.isStreaming = false;
      msg.consensusWidget = consensus;
    });
    _scrollToBottom();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: MehdAiTheme.blue),
            const SizedBox(width: 8),
            Text('VIBE TRADING', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
          ],
        ),
        backgroundColor: MehdAiTheme.bgPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(false),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MehdAiTheme.bgSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MehdAiTheme.borderColor),
            ),
            child: Text(
              'The Den is thinking...',
              style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            _buildAvatar(false),
            const SizedBox(width: 16),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: msg.isUser ? MehdAiTheme.blue.withOpacity(0.1) : MehdAiTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: msg.isUser ? MehdAiTheme.blue.withOpacity(0.3) : MehdAiTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    msg.text + (msg.isStreaming ? ' ▋' : ''),
                    style: MehdAiTheme.labelStyle.copyWith(
                      color: msg.isUser ? MehdAiTheme.textPrimary : MehdAiTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                if (msg.consensusWidget != null) ...[
                  const SizedBox(height: 16),
                  DenVerdictCard(consensus: msg.consensusWidget!),
                ]
              ],
            ),
          ),
          
          if (msg.isUser) ...[
            const SizedBox(width: 16),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    if (isUser) {
      return Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(
          color: MehdAiTheme.bgTertiary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 16, color: MehdAiTheme.textSecondary),
      );
    }
    
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117), // Pure dark
        shape: BoxShape.circle,
        border: Border.all(color: MehdAiTheme.blue.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: MehdAiTheme.blue.withOpacity(0.2), blurRadius: 8),
        ]
      ),
      child: ClipOval(
        child: Opacity(
          opacity: 0.8,
          child: Image.asset('assets/images/mehd_logo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: MehdAiTheme.bgPrimary,
        border: Border(top: BorderSide(color: MehdAiTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              onSubmitted: (_) => _handleUserSubmit(),
              style: MehdAiTheme.terminalStyle,
              decoration: InputDecoration(
                hintText: 'Tell The Den what you want to trade...',
                hintStyle: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: MehdAiTheme.bgSecondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: MehdAiTheme.blue, width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: MehdAiTheme.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: MehdAiTheme.blue),
              onPressed: _handleUserSubmit,
            ),
          )
        ],
      ),
    );
  }
}

class _ChatMessage {
  String text;
  final bool isUser;
  bool isStreaming;
  ConsensusResult? consensusWidget;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });
}
