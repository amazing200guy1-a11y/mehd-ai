import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/widgets/den_verdict_card.dart';
import 'package:mehd_ai_flutter/services/nlg_engine.dart';
import 'package:mehd_ai_flutter/services/command_parser_service.dart';

/// FILE — pulse_trading_screen.dart
///
/// Build Debrief:
/// Pulse Trading Mode transforms the app from a terminal into a true companion.
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

class PulseTradingScreen extends StatefulWidget {
  const PulseTradingScreen({super.key});

  @override
  State<PulseTradingScreen> createState() => _PulseTradingScreenState();
}

class _PulseTradingScreenState extends State<PulseTradingScreen> {
  late final _SyntaxHighlightController _inputController;
  final ScrollController _scrollController = ScrollController();
  
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  
  bool _showCommandSuggestions = false;
  Timer? _hintTimer;
  int _currentHintIndex = 0;
  final List<String> _hints = [
    "Tell The Den what you want to trade...",
    "Try typing: /long BTC 10x",
    "Ask me how you feel about the market...",
    "Try typing: /short ETH 5x",
    "Type /help to see all commands",
  ];
  
  // Imposing a strict limit to prevent chatbot-style rambling.
  int _pulseEnergy = 5;
  final int _maxEnergy = 5;

  final List<String> _tiltWords = [
    'scared', 'angry', 'revenge', 'frustrated', 'loss', 'recover', 'desperate', 'liquidated'
  ];

  @override
  void initState() {
    super.initState();
    _inputController = _SyntaxHighlightController();
    _inputController.addListener(_onInputChanged);

    // Initial greeting
    _messages.add(
      _ChatMessage(
        text: 'The Den is hunting. Tell me what you are looking for today, or use / to execute commands.',
        isUser: false,
      )
    );

    _hintTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _inputController.text.isEmpty && !_showCommandSuggestions) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _hints.length;
        });
      }
    });
  }

  void _onInputChanged() {
    final text = _inputController.text;
    if (text.startsWith('/') && !_showCommandSuggestions) {
      setState(() => _showCommandSuggestions = true);
    } else if (!text.startsWith('/') && _showCommandSuggestions) {
      setState(() => _showCommandSuggestions = false);
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _inputController.removeListener(_onInputChanged);
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
    if (_pulseEnergy <= 0) return;
    
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() {
      _pulseEnergy -= 1;
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    // --- COMMAND PARSER INTERCEPTION ---
    if (text.startsWith('/')) {
      final cmd = CommandParserService.parse(text);
      
      if (!cmd.isValid) {
        _streamResponse("COMMAND REJECTED: ${cmd.errorMessage}", null);
        return;
      }

      if (cmd.action == 'help') {
        _streamResponse("AVAILABLE COMMANDS:\n/long [SYMBOL] [LEV]\n/short [SYMBOL] [LEV]\n/close [SYMBOL]\n/help", null);
        return;
      }

      if (cmd.action == 'close') {
        _streamResponse("Closing all active positions for ${cmd.symbol}. Executing via TWAP.", null);
        return;
      }

      // It's a valid /long or /short command. Bypass NLG and immediately render the Execution Card.
      final direction = cmd.action == 'long' ? 'BUY' : 'SELL';
      final symbol = cmd.symbol ?? 'UNKNOWN';
      final lev = cmd.leverage ?? 1;

      final consensus = ConsensusResult(
        finalDirection: direction,
        consensusPercentage: 99.9, // Terminal override is absolute
        proceed: true,
        timestamp: DateTime.now(),
        votes: [
          AIVote(modelName: 'Terminal Override', snapshotId: 'cmd', direction: direction, confidence: 1.0, reasoning: 'Direct execution command: $symbol at ${lev}x.'),
        ],
      );

      _streamResponse("Terminal command accepted. Initiating absolute execution sequence for $symbol at ${lev}x.", consensus);
      return;
    }
    // -----------------------------------

    // Client-side tilt detection (server also checks, this is defense in depth)
    final clientDetectedTilt = _detectTilt(text);

    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 600));

    final isEmotional = clientDetectedTilt;
    
    // Generate Random Direction/Confidence for the demo
    final random = Random();
    final dirs = ['BUY', 'SELL', 'HOLD'];
    final confs = ['HIGH', 'MEDIUM'];
    final direction = isEmotional ? 'HOLD' : dirs[random.nextInt(dirs.length)];
    final confidence = confs[random.nextInt(confs.length)];

    final responseText = isEmotional 
        ? "The Den detects emotional volatility in your phrasing. Trading while compromised is a statistical failure. We are enforcing a temporary freeze on your terminal. Step away from the screens."
        : NLGEngine().generateResponse(direction: direction, confidenceTier: confidence);
    
    if (!mounted) return;

    ConsensusResult? consensus;
    if (!isEmotional) {
      consensus = ConsensusResult(
        finalDirection: direction,
        consensusPercentage: direction == 'HOLD' ? 50.0 : (random.nextDouble() * 20 + 75), // 75-95%
        proceed: direction != 'HOLD',
        timestamp: DateTime.now(),
        rejectionReason: direction == 'HOLD' ? "The agents are conflicted or detecting a trap." : null,
        votes: [
          AIVote(modelName: 'The Don (Risk Executive)', snapshotId: 'mock', direction: direction, confidence: 0.85, reasoning: 'Analyzing risk parameters.'),
          AIVote(modelName: 'The Quant (Math & Stats)', snapshotId: 'mock', direction: direction, confidence: 0.90, reasoning: 'Statistical edge identified.'),
          AIVote(modelName: 'The Sniper (Execution)', snapshotId: 'mock', direction: direction, confidence: 0.95, reasoning: 'Entry trigger met.'),
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
            Text('PULSE TRADING', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
          ],
        ),
        backgroundColor: MehdAiTheme.bgPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
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
    final isExhausted = _pulseEnergy <= 0;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: MehdAiTheme.bgPrimary,
        border: Border(top: BorderSide(color: MehdAiTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pulse Energy Tracker
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  isExhausted ? Icons.battery_alert : Icons.bolt, 
                  color: isExhausted ? Colors.redAccent : MehdAiTheme.blue, 
                  size: 14
                ),
                const SizedBox(width: 6),
                Text(
                  isExhausted 
                      ? 'PULSE COMMAND LIMIT EXHAUSTED'
                      : 'PULSE COMMANDS: $_pulseEnergy/$_maxEnergy',
                  style: MehdAiTheme.labelStyle.copyWith(
                    color: isExhausted ? Colors.redAccent : MehdAiTheme.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          if (_showCommandSuggestions) _buildCommandSuggestions(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  enabled: !isExhausted,
                  onSubmitted: isExhausted ? null : (_) => _handleUserSubmit(),
                  style: MehdAiTheme.terminalStyle,
                  decoration: InputDecoration(
                    hintText: isExhausted 
                        ? 'The Den is locked. Focus on execution.' 
                        : _hints[_currentHintIndex],
                    hintStyle: MehdAiTheme.terminalStyle.copyWith(
                      color: isExhausted ? Colors.redAccent.withOpacity(0.5) : MehdAiTheme.textSecondary.withOpacity(0.5)
                    ),
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
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: isExhausted ? MehdAiTheme.bgSecondary : MehdAiTheme.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send, 
                    color: isExhausted ? MehdAiTheme.textSecondary : MehdAiTheme.blue
                  ),
                  onPressed: isExhausted ? null : _handleUserSubmit,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommandSuggestions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.blue.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: MehdAiTheme.blue.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildSuggestionItem('/long', '[SYMBOL] [LEVERAGE]', 'Open a long position', Icons.trending_up, MehdAiTheme.green),
          _buildSuggestionItem('/short', '[SYMBOL] [LEVERAGE]', 'Open a short position', Icons.trending_down, MehdAiTheme.red),
          _buildSuggestionItem('/close', '[SYMBOL]', 'Close an active position', Icons.close_fullscreen, MehdAiTheme.amber),
          _buildSuggestionItem('/help', '', 'View all terminal commands', Icons.help_outline, MehdAiTheme.blue),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String cmd, String params, String desc, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        _inputController.text = '$cmd ';
        _inputController.selection = TextSelection.fromPosition(TextPosition(offset: _inputController.text.length));
        setState(() => _showCommandSuggestions = false);
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 12),
            Text(cmd, style: MehdAiTheme.terminalStyle.copyWith(color: color, fontWeight: FontWeight.bold)),
            if (params.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(params, style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white30, fontSize: 10)),
            ],
            const Spacer(),
            Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
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

class _SyntaxHighlightController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final String text = this.text;
    
    if (!text.startsWith('/')) {
      return TextSpan(style: style, text: text);
    }

    final parts = text.split(' ');
    final List<TextSpan> children = [];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (i == 0) {
        // Command is colored blue
        children.add(TextSpan(text: part, style: style?.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold)));
      } else if (i == 1 && part.isNotEmpty) {
        // Symbol is colored yellow
        children.add(TextSpan(text: ' $part', style: style?.copyWith(color: MehdAiTheme.yellow)));
      } else if (i == 2 && part.isNotEmpty) {
        // Leverage is colored purple
        children.add(TextSpan(text: ' $part', style: style?.copyWith(color: MehdAiTheme.purple)));
      } else {
        children.add(TextSpan(text: ' $part', style: style));
      }
    }

    // Add trailing spaces back if any
    if (text.endsWith(' ') && parts.isNotEmpty) {
      children.add(TextSpan(text: ' ' * (text.length - text.trimRight().length), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}
