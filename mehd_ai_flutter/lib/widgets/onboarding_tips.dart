import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingTips extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingTips({super.key, required this.onComplete});

  @override
  State<OnboardingTips> createState() => _OnboardingTipsState();
}

class _OnboardingTipsState extends State<OnboardingTips> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'text': "Welcome to Mehd AI — the world's first 11-agent consensus trading platform",
      'align': Alignment.center,
      'hasArrow': false,
    },
    {
      'text': "Select any symbol here to begin analysis",
      'align': Alignment.centerLeft,
      'offset': const Offset(80, 0),
      'hasArrow': true,
      'arrowDir': 'left',
    },
    {
      'text': "This is the Zen Chart — AI zones are painted directly here",
      'align': Alignment.center,
      'offset': const Offset(0, -100),
      'hasArrow': true,
      'arrowDir': 'down',
    },
    {
      'text': "Watch The Den think in real time here",
      'align': Alignment.centerRight,
      'offset': const Offset(-320, 0),
      'hasArrow': true,
      'arrowDir': 'right',
    },
    {
      'text': "Trade button unlocks only when 7+ agents agree",
      'align': Alignment.bottomCenter,
      'offset': const Offset(0, -150),
      'hasArrow': true,
      'arrowDir': 'down',
    },
    {
      'text': "1% maximum risk enforced here — cannot be changed",
      'align': Alignment.bottomCenter,
      'offset': const Offset(0, -100), // Depending on where Risk Kernel is
      'hasArrow': true,
      'arrowDir': 'down',
    },
    {
      'text': "Enter the Institutional War Room here",
      'align': Alignment.topCenter,
      'offset': const Offset(0, 50),
      'hasArrow': true,
      'arrowDir': 'up',
    },
    {
      'text': "You are protected. The Den is watching. Capital is a seed, not a sacrifice.",
      'align': Alignment.center,
      'hasArrow': false,
    },
  ];

  void _nextStep() async {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _finish();
    }
  }

  void _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final text = step['text'] as String;
    final align = step['align'] as Alignment;
    final offset = step['offset'] as Offset? ?? Offset.zero;
    final hasArrow = step['hasArrow'] as bool;
    final arrowDir = step['arrowDir'] as String?;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dimmer
          GestureDetector(
            onTap: _nextStep,
            child: Container(
              color: Colors.black.withOpacity(0.85),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Tooltip Position
          Align(
            alignment: align,
            child: Transform.translate(
              offset: offset,
              child: _buildTooltip(text, hasArrow, arrowDir),
            ),
          ),

          // Controls (Bottom Right)
          Positioned(
            bottom: 32,
            right: 32,
            left: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: TextButton(
                    onPressed: _finish,
                    child: Text('SKIP', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary), overflow: TextOverflow.ellipsis),
                  ),
                ),
                Row(
                  children: List.generate(_steps.length, (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentStep == index ? MehdAiTheme.blue : MehdAiTheme.textSecondary.withOpacity(0.3),
                    ),
                  )),
                ),
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MehdAiTheme.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    onPressed: _nextStep,
                    child: Text(
                      _currentStep == _steps.length - 1 ? 'START TRADING' : 'NEXT',
                      style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(String text, bool hasArrow, String? arrowDir) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MehdAiTheme.blue),
        boxShadow: [
          BoxShadow(
            color: MehdAiTheme.blue.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasArrow && arrowDir == 'up') const Icon(Icons.arrow_upward, color: MehdAiTheme.blue, size: 32),
          if (hasArrow && arrowDir == 'up') const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasArrow && arrowDir == 'left') const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.arrow_back, color: MehdAiTheme.blue, size: 32)),
              Expanded(
                  child: Text(
                    text,
                    style: MehdAiTheme.terminalStyle.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 4,
                  ),
              ),
              if (hasArrow && arrowDir == 'right') const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.arrow_forward, color: MehdAiTheme.blue, size: 32)),
            ],
          ),
          
          if (hasArrow && arrowDir == 'down') const SizedBox(height: 16),
          if (hasArrow && arrowDir == 'down') const Icon(Icons.arrow_downward, color: MehdAiTheme.blue, size: 32),
        ],
      ),
    );
  }
}
