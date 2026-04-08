import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/market_snapshot.dart';

class ZenChartHeader extends StatelessWidget {
  final MarketSnapshot currentPrice;

  const ZenChartHeader({
    super.key,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    final spread = currentPrice.spread;

    return Positioned(
      top: 16,
      right: 16,
      left: 140, // Ensure it doesn't overlap with left toolbar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  currentPrice.symbol,
                  style: MehdAiTheme.headingStyle.copyWith(fontSize: 24),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _LivePriceFlashText(price: currentPrice.bid),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (spread > 5.0)
                const Padding(
                  padding: EdgeInsets.only(right: 6.0),
                  child: Icon(Icons.warning_amber_rounded, size: 14, color: MehdAiTheme.red),
                ),
              Flexible(
                child: Text(
                  'Spread: ${spread.toStringAsFixed(1)} pips',
                  style: TextStyle(
                    color: spread < 2.0
                        ? const Color(0xFF00FF88)
                        : spread < 5.0
                        ? const Color(0xFFD29922)
                        : const Color(0xFFFF3B3B),
                    fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _LivePriceFlashText extends StatefulWidget {
  final double price;
  const _LivePriceFlashText({required this.price});

  @override
  State<_LivePriceFlashText> createState() => _LivePriceFlashTextState();
}

class _LivePriceFlashTextState extends State<_LivePriceFlashText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnim;
  double _lastPrice = 0;

  @override
  void initState() {
    super.initState();
    _lastPrice = widget.price;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _colorAnim = ColorTween(begin: MehdAiTheme.textPrimary, end: MehdAiTheme.textPrimary).animate(_controller);
  }

  @override
  void didUpdateWidget(_LivePriceFlashText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != _lastPrice) {
      final isUp = widget.price > _lastPrice;
      _colorAnim = ColorTween(
        begin: isUp ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B),
        end: MehdAiTheme.textPrimary,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
      _lastPrice = widget.price;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnim,
      builder: (context, _) => Text(
        widget.price.toStringAsFixed(5),
        style: MehdAiTheme.terminalStyle.copyWith(
          fontSize: 18,
          color: _colorAnim.value,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
