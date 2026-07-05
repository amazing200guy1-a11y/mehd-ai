import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/den_identity.dart';

/// Premium analysis loading widget — shows each AI agent "reporting in"
/// one by one, like ChatGPT's "Searching the web..." / "Thinking..."
///
/// Turns a painful 30-second wait into entertainment.
/// Each agent appears with a staggered animation and status indicator.
/// Users watch the intelligence machine work in real-time.

class AnalysisProgressWidget extends StatefulWidget {
  final bool isAnalyzing;

  const AnalysisProgressWidget({super.key, required this.isAnalyzing});

  @override
  State<AnalysisProgressWidget> createState() => _AnalysisProgressWidgetState();
}

class _AnalysisProgressWidgetState extends State<AnalysisProgressWidget>
    with TickerProviderStateMixin {
  final List<_AgentReport> _reports = [];
  Timer? _staggerTimer;
  int _currentIndex = 0;
  late AnimationController _pulseCtrl;

  // The exact order agents "report in" — matches the Den hierarchy
  static const List<_AgentDef> _agentSequence = [
    // THE RESEARCH — Sentiment Layer
    _AgentDef('PHANTOM', 'Scanning dark pool sentiment...', 'research'),
    _AgentDef('ORACLE', 'Reading pattern formations...', 'research'),
    _AgentDef('GROK', 'Gathering street intelligence...', 'research'),
    // THE STRATEGY — Strategy Layer
    _AgentDef('CAESAR', 'Formulating imperial strategy...', 'strategy'),
    _AgentDef('SAGE', 'Calculating risk parameters...', 'strategy'),
    _AgentDef('ATLAS', 'Running quantitative analysis...', 'strategy'),
    // OLYMPUS — Math Layer
    _AgentDef('TITAN', 'Backtesting historical data...', 'olympus'),
    _AgentDef('FORGE', 'Computing probability matrix...', 'olympus'),
    _AgentDef('VANGUARD', 'Verifying math alignment...', 'olympus'),
    // SUPREME — Override Layer
    _AgentDef('GUARDIAN', 'Enforcing risk boundaries...', 'supreme'),
    _AgentDef('SENTINEL', 'Checking for AI paradox...', 'supreme'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    if (widget.isAnalyzing) _startSequence();
  }

  @override
  void didUpdateWidget(AnalysisProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing && !oldWidget.isAnalyzing) {
      _startSequence();
    } else if (!widget.isAnalyzing && oldWidget.isAnalyzing) {
      _completeAll();
    }
  }

  void _startSequence() {
    _reports.clear();
    _currentIndex = 0;

    // Stagger agents appearing every 2-3 seconds
    _staggerTimer?.cancel();
    _staggerTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentIndex < _agentSequence.length) {
        // Mark previous agent as "complete"
        if (_reports.isNotEmpty) {
          setState(() {
            _reports.last.status = _ReportStatus.complete;
          });
        }

        // Add new agent as "analyzing"
        final agent = _agentSequence[_currentIndex];
        setState(() {
          _reports.add(_AgentReport(agent, _ReportStatus.analyzing));
          _currentIndex++;
        });
      } else {
        timer.cancel();
        // Mark last agent complete
        if (_reports.isNotEmpty) {
          setState(() => _reports.last.status = _ReportStatus.complete);
        }
      }
    });

    // Add the first agent immediately
    if (_agentSequence.isNotEmpty) {
      setState(() {
        _reports.add(_AgentReport(_agentSequence[0], _ReportStatus.analyzing));
        _currentIndex = 1;
      });
    }
  }

  void _completeAll() {
    _staggerTimer?.cancel();
    if (mounted) {
      setState(() {
        for (final r in _reports) {
          r.status = _ReportStatus.complete;
        }
      });
    }
  }

  @override
  void dispose() {
    _staggerTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnalyzing && _reports.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MehdAiTheme.blue.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: "THE DEN IS ANALYZING" + progress counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MehdAiTheme.blue
                              .withOpacity(0.5 + _pulseCtrl.value * 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: MehdAiTheme.blue
                                  .withOpacity(_pulseCtrl.value * 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'THE DEN IS ANALYZING',
                        style: GoogleFonts.jetBrainsMono(
                          color: MehdAiTheme.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${_reports.where((r) => r.status == _ReportStatus.complete).length}/11',
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF555555),
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _reports.length / 11,
              backgroundColor: const Color(0xFF1A1E28),
              valueColor: AlwaysStoppedAnimation<Color>(
                MehdAiTheme.blue.withOpacity(0.6),
              ),
              minHeight: 3,
            ),
          ),

          const SizedBox(height: 16),

          // Agent reports list
          ..._reports.map((report) => _buildAgentRow(report)),
        ],
      ),
    );
  }

  Widget _buildAgentRow(_AgentReport report) {
    final identity = DenIdentity.getIdentity(report.agent.name.toLowerCase());
    final isActive = report.status == _ReportStatus.analyzing;
    final isDone = report.status == _ReportStatus.complete;

    Color layerColor;
    switch (report.agent.layer) {
      case 'research':
        layerColor = const Color(0xFFBC8CFF);
        break;
      case 'strategy':
        layerColor = const Color(0xFFFFD700);
        break;
      case 'olympus':
        layerColor = const Color(0xFFFF9F43);
        break;
      case 'supreme':
        layerColor = const Color(0xFF00FF88);
        break;
      default:
        layerColor = MehdAiTheme.blue;
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            // Status indicator
            SizedBox(
              width: 18,
              height: 18,
              child: isDone
                  ? Icon(Icons.check_circle, color: layerColor, size: 16)
                  : isActive
                      ? AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: layerColor
                                  .withOpacity(0.3 + _pulseCtrl.value * 0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: layerColor
                                      .withOpacity(_pulseCtrl.value * 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                        ),
            ),
            const SizedBox(width: 12),
            // Agent name
            SizedBox(
              width: 80,
              child: Text(
                identity.displayName,
                style: GoogleFonts.jetBrainsMono(
                  color: isDone
                      ? layerColor
                      : (isActive ? Colors.white : const Color(0xFF555555)),
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Status text
            Expanded(
              child: Text(
                isDone ? '✓ Complete' : report.agent.action,
                style: GoogleFonts.jetBrainsMono(
                  color: isDone
                      ? const Color(0xFF444444)
                      : const Color(0xFF666666),
                  fontSize: 9,
                  fontStyle: isActive ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Internal data classes
class _AgentDef {
  final String name;
  final String action;
  final String layer;
  const _AgentDef(this.name, this.action, this.layer);
}

enum _ReportStatus { analyzing, complete }

class _AgentReport {
  final _AgentDef agent;
  _ReportStatus status;
  _AgentReport(this.agent, this.status);
}
