import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// FILE — den_animation.dart
/// 
/// Build Debrief:
/// The DenAnimation system is the visual heartbeat of Mehd AI. 
/// It encapsulates 5 distinct states that emotionally connect the trader 
/// to the AI models working for them.
/// 
/// State 1: Activation - A ghost tiger rises, surrounded by 11 predators lighting up.
/// State 2: Idle - A ghostly 5% opacity pulse waiting in the background.
/// State 3: Locked - A subtle aggressive shake. The Den growls "No."
/// State 4: Unlocked - A full blue flash with circuit waves. "Strike Now."
/// State 5: Kill Switch - An imposing red glow guarding the seed capital.
/// 
/// All animations rely on 60fps implicit Tweens and explicit AnimationControllers.

enum DenState {
  hidden,
  idle,
  activation,
  locked,
  unlocked,
  killSwitch,
}

class DenAnimation extends StatefulWidget {
  final DenState state;
  final bool animateModels; // Should the 11 agents circle the tiger?
  
  const DenAnimation({
    super.key,
    this.state = DenState.idle,
    this.animateModels = false,
  });

  @override
  State<DenAnimation> createState() => _DenAnimationState();
}

class _DenAnimationState extends State<DenAnimation> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _surgeController;

  final List<String> _predators = [
    'DON', 'PHANTOM', 'ORACLE', 'CAESAR', 'SAGE', 'GUARDIAN', 'TITAN', 'ATLAS', 'FORGE', 'THE DON', 'SENTINEL'
  ];

  @override
  void initState() {
    super.initState();
    // Idle 3-second breathing pulse
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    
    // Aggressive fast shake for Locked state
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 50));
    
    // Surge flash for Unlocked
    _surgeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void didUpdateWidget(DenAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == DenState.locked) {
        _shakeController.repeat(reverse: true);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _shakeController.stop();
        });
      } else if (widget.state == DenState.unlocked) {
        _surgeController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _surgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == DenState.hidden) return const SizedBox.shrink();

    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _shakeController, _surgeController]),
        builder: (context, child) {
          
          double opacity = 0.0;
          double scale = 1.0;
          Color glowColor = Colors.transparent;
          Offset shakeOffset = Offset.zero;
          double verticalOffset = 0.0;

          // Resolve visual traits per state
          switch (widget.state) {
            case DenState.idle:
              opacity = 0.05 + (_pulseController.value * 0.03); // pulses 5% to 8%
              verticalOffset = 0.0;
              break;
              
            case DenState.activation:
              opacity = 0.15;
              glowColor = MehdAiTheme.blue.withOpacity(0.3); // Blue eye flash base
              verticalOffset = -40.0; // Rises up slightly
              break;
              
            case DenState.locked:
              opacity = 0.12;
              // 400ms subtle shake
              if (_shakeController.isAnimating) {
                shakeOffset = Offset(_shakeController.value * 4 - 2, 0); 
              }
              break;
              
            case DenState.unlocked:
              // Flash bright blue
              opacity = 0.12 + (_surgeController.value * 0.4); 
              glowColor = MehdAiTheme.blue.withOpacity(_surgeController.value * 0.5);
              scale = 1.0 + (_surgeController.value * 0.05);
              break;
              
            case DenState.killSwitch:
              opacity = 0.20;
              glowColor = MehdAiTheme.red.withOpacity(0.4 + (_pulseController.value * 0.2));
              break;
              
            case DenState.hidden:
              break;
          }

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: opacity),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, currentOpacity, child) {
              
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: verticalOffset),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, currentY, child) {
                
                  return Transform.translate(
                    offset: Offset(shakeOffset.dx, currentY),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: glowColor != Colors.transparent 
                            ? [BoxShadow(color: glowColor, blurRadius: 60, spreadRadius: 10)]
                            : [],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Tiger Ghost removed to prevent duplicate tiger watermark
                            
                            // The 11 Predators Circling
                            if (widget.state == DenState.activation && widget.animateModels)
                              _buildCirclingPredators(),
                              
                            // Kill Switch Overlay
                            if (widget.state == DenState.killSwitch)
                              Positioned(
                                bottom: 10,
                                child: Text(
                                  'THE DEN HAS CLOSED',
                                  style: MehdAiTheme.headingStyle.copyWith(
                                    color: MehdAiTheme.red,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCirclingPredators() {
    return Stack(
      children: List.generate(_predators.length, (index) {
        final double angle = (index * (360 / _predators.length)) * math.pi / 180;
        final double radius = 130.0;
        
        final double x = radius * math.cos(angle);
        final double y = radius * math.sin(angle);
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          // 150ms cascade delay between predators lighting up
          duration: const Duration(milliseconds: 400),
          curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0, curve: Curves.easeOut),
          builder: (context, value, child) {
            return Positioned(
              left: 130 + (x * value) - 30, // center + offset - half width
              top: 130 + (y * value) - 10,
              child: SizedBox(), // Removed agent text overlay
            );
          },
        );
      }),
    );
  }
}
