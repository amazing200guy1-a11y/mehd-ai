import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/market_snapshot.dart';
import 'package:mehd_ai_flutter/models/candle.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/widgets/den_animation.dart';
import 'package:mehd_ai_flutter/models/automated_drawing.dart';
import 'package:mehd_ai_flutter/models/manual_drawing.dart';
import 'package:mehd_ai_flutter/core/drawing_engine.dart';
import 'package:mehd_ai_flutter/widgets/drawing_engine.dart';
import 'package:mehd_ai_flutter/widgets/drawing_toolbar.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/widgets/manual_drawing_painter.dart';

enum DrawingMode { auto, manual }
enum DrawingTool { none, line, hline, zone, fib }

class ManualDrawing {
  final DrawingTool type;
  final List<Offset> points;
  final Color color;
  ManualDrawing({
    required this.type,
    required this.points,
    required this.color,
  });
}

/// FILE 6 — zen_chart.dart
///
/// Build Debrief:
/// This makes Mehd AI completely different from MT4/TradingView.
/// Traditional charts are cluttered with MACD, RSI, Bollinger Bands, etc. 
/// It causes analysis paralysis. In Zen Mode, we remove all of that. 
/// The AI has already processed 11 layers of complex technicals and math natively.
/// Instead of showing the math, we paint the chart with pure, actionable zones.
/// A faint green rectangle = "The AIs think you should buy here." 
/// A faint red rectangle = "Resistance zone."
/// This distills thousands of lines of math into a single, calming visual.

class ZenChart extends StatefulWidget {
  final MarketSnapshot currentPrice;
  final ConsensusResult? currentConsensus;
  final DenState denState;
  final Function(List<AutomatedDrawing>)? onDrawingsUpdated;

  const ZenChart({
    super.key,
    required this.currentPrice,
    this.currentConsensus,
    this.denState = DenState.hidden,
    this.onDrawingsUpdated,
  });

  @override
  State<ZenChart> createState() => _ZenChartState();
}

class _ZenChartState extends State<ZenChart> with SingleTickerProviderStateMixin {
  String _selectedTimeframe = '1H';
  bool _isCandleChart = true;
  bool _isExpanded = false;

  // ── Zoom & Pan State ──
  double _zoomLevel = 1.0;
  double _scrollOffset = 0.0;
  Timer? _priceTimer;
  double _basePrice = 1.0;
  double _currentPrice = 1.0;
  int _tickCount = 0;
  GlobalKey _chartKey = GlobalKey();
  
  DrawingMode _drawingMode = DrawingMode.auto;
  double _baseZoom = 1.0;
  
  final ApiService _api = ApiService();

  // ── Drawing Engine State ──
  late AnimationController _drawingsAnim;
  final Map<String, bool> _activeDrawings = {
    'Lines': true,
    'Fibonacci': true,
    'Zones': true,
    'Patterns': true,
    'Institutional': true,
  };
  List<AutomatedDrawing> _currentDrawings = [];
  double _minLowCache = 0;
  double _maxHighCache = 0;
  List<Candle> _candleCache = [];

  DrawingTool _activeTool = DrawingTool.none;
  List<Offset> _pendingPoints = [];
  List<ManualDrawing> _drawings = [];
  Offset? _firstTapPoint;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _drawingsAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _loadManualDrawings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateCandles(widget.currentPrice.symbol);
    });

    _priceTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      setState(() {
        // Realistic random walk
        final change = (math.Random().nextDouble() - 0.495) * _basePrice * 0.0003;
        _currentPrice += change;

        // Update last candle close
        if (_candleCache.isNotEmpty) {
          final last = _candleCache.last;
          _candleCache[_candleCache.length - 1] = Candle(
            open: last.open,
            close: _currentPrice,
            high: math.max(last.high, _currentPrice),
            low: math.min(last.low, _currentPrice),
            timestamp: last.timestamp,
          );
        }

        // New candle every 30 ticks
        _tickCount++;
        if (_tickCount % 30 == 0) {
          _candleCache.add(Candle(
            open: _currentPrice,
            close: _currentPrice,
            high: _currentPrice,
            low: _currentPrice,
            timestamp: DateTime.now(),
          ));
          if (_candleCache.length > 250) {
            _candleCache.removeAt(0);
          }
        }
      });
    });
  }

  
  void _handleTap(Offset pos) {
    setState(() {
      _pendingPoints.add(pos);
      
      if (_activeTool == DrawingTool.hline) {
        _drawings.add(ManualDrawing(
          type: DrawingTool.hline,
          points: [pos],
          color: const Color(0xFFD29922),
        ));
        _pendingPoints.clear();
        return;
      }
      
      if (_pendingPoints.length == 2) {
        _drawings.add(ManualDrawing(
          type: _activeTool,
          points: List.from(_pendingPoints),
          color: _activeTool == DrawingTool.line
            ? const Color(0xFF58A6FF)
            : _activeTool == DrawingTool.zone
            ? const Color(0xFF00FF88)
            : const Color(0xFFD4AF37),
        ));
        _pendingPoints.clear();
      }
    });
  }

  Future<void> _loadManualDrawings() async {
    final drawings = await _api.loadDrawings(widget.currentPrice.symbol);
    if (mounted) {
      setState(() {
        _manualDrawings.addAll(drawings);
      });
    }
  }

  void _saveManualDrawings() {
    _api.saveDrawings(widget.currentPrice.symbol, _manualDrawings);
  }

  @override
  void didUpdateWidget(ZenChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPrice.symbol != widget.currentPrice.symbol) {
      _generateCandles(widget.currentPrice.symbol);
    } else if (oldWidget.currentConsensus?.finalDirection != widget.currentConsensus?.finalDirection) {
      _chartKey = GlobalKey(); // refresh key for repaint
    }
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _drawingsAnim.dispose();
    super.dispose();
  }

  double _getBasePrice(String symbol) {
    const prices = {
      'EUR/USD': 1.08420,
      'GBP/USD': 1.26340,
      'GBP/JPY': 189.420,
      'XAU/USD': 2318.50,
      'BTC/USD': 67420.0,
      'ETH/USD': 3240.0,
      'NAS100':  17842.0,
      'US30':    38910.0,
      'PARADOX/USD': 1.0,
    };
    return prices[symbol] ?? 1.0;
  }

  void _generateCandles(String symbol) {
    final basePrice = _getBasePrice(symbol);
    final candles = <Candle>[];
    double price = basePrice;
    
    _basePrice = basePrice;

    for (int i = 0; i < 100; i++) {
        final open = price;
        final change = (math.Random().nextDouble() - 0.48) * basePrice * 0.003;
        final close = open + change;
        final high = math.max(open, close) + math.Random().nextDouble() * basePrice * 0.001;
        final low = math.min(open, close) - math.Random().nextDouble() * basePrice * 0.001;
        
        candles.add(Candle(
          open: open,
          close: close,
          high: high,
          low: low,
          timestamp: DateTime.now().subtract(Duration(hours: 100 - i)),
        ));
        price = close;
    }

    _chartKey = GlobalKey();

    setState(() {
      _candleCache = candles;
      _currentPrice = price;
      
      double maxHigh = _candleCache.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      double minLow = _candleCache.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      final range = maxHigh - minLow;
      _maxHighCache = maxHigh + (range * 0.1);
      _minLowCache = minLow - (range * 0.1);

      _currentDrawings = DrawingEngine.generateDrawings(
        _candleCache, 0, 100.0, _minLowCache, _maxHighCache, _activeDrawings
      );
      
      if (widget.onDrawingsUpdated != null) {
        widget.onDrawingsUpdated!(_currentDrawings);
      }
      _drawingsAnim.forward(from: 0.0);
    });
  }

  void _toggleDrawing(String key) {
    setState(() => _activeDrawings[key] = !(_activeDrawings[key]!));
    if (_candleCache.isNotEmpty) {
      setState(() {
        _currentDrawings = DrawingEngine.generateDrawings(
          _candleCache, 0, 100.0, _minLowCache, _maxHighCache, _activeDrawings
        );
      });
      _drawingsAnim.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MehdAiTheme.bgPrimary,
      child: Stack(
        children: [
          // 1. Tiger Logo Watermark (Deepest Background)
          Center(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/images/mehd_logo.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // 2. Eye Glow Overlay (15% targeted opacity)
          Center(
            child: ShaderMask(
              shaderCallback: (rect) {
                return RadialGradient(
                  center: const Alignment(0, -0.2), // Positioned over eyes
                  radius: 0.2,
                  colors: [
                    Colors.white.withOpacity(0.15), // 15% glow
                    Colors.transparent,
                  ],
                  stops: const [0.4, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.srcATop,
              child: Opacity(
                opacity: 0.05, // Additional 5% for eyes to reach 15% total
                child: Image.asset(
                  'assets/images/mehd_logo.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 3. The Den Animation Layer
          Positioned.fill(
            child: DenAnimation(
              state: widget.denState,
              animateModels: widget.denState == DenState.activation,
            ),
          ),

          // 2. The FL Chart (simplified line/candlestick representation) with Gestures
          Padding(
            padding: const EdgeInsets.only(top: 60.0, bottom: 40, left: 16, right: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Listener(
                    onPointerSignal: (PointerSignalEvent e) {
                      if (e is PointerScrollEvent) {
                        setState(() {
                          final delta = e.scrollDelta.dy;
                          _zoomLevel = (_zoomLevel - delta * 0.002).clamp(0.3, 8.0);
                        });
                      }
                    },
                    child: GestureDetector(
                      onScaleStart: (ScaleStartDetails d) {
                        _baseZoom = _zoomLevel;
                      },
                      onScaleUpdate: (ScaleUpdateDetails d) {
                        setState(() {
                          if (d.pointerCount >= 2) {
                            _zoomLevel = (_baseZoom * d.scale).clamp(0.3, 8.0);
                          }
                          if (d.pointerCount == 1) {
                            _scrollOffset += d.focalPointDelta.dx;
                            final maxScroll = _candleCache.length * 10.0 * _zoomLevel;
                            _scrollOffset = _scrollOffset.clamp(-maxScroll, 0.0);
                          }
                        });
                      },
                      onTapDown: (TapDownDetails d) {
                        if (_drawingMode != DrawingMode.manual) return;
                        if (_activeTool == DrawingTool.none) return;
                        _handleTap(d.localPosition);
                      },
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            child: CustomPaint(
                              key: _chartKey,
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: ZenChartPainter(
                                candles: _candleCache,
                                zoomLevel: _zoomLevel,
                                scrollOffset: _scrollOffset,
                                symbol: widget.currentPrice.symbol,
                                currentPrice: _currentPrice,
                                consensus: widget.currentConsensus,
                                isCandles: _isCandleChart,
                                timeframe: _selectedTimeframe,
                                minLow: _minLowCache,
                                maxHigh: _maxHighCache,
                                manualDrawings: _drawings,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: Opacity(
                              opacity: _drawingMode == DrawingMode.manual ? 0.15 : 1.0,
                              child: AnimatedBuilder(
                                animation: _drawingsAnim,
                                builder: (context, child) => DrawingEngineOverlay(
                                  drawings: _currentDrawings,
                                  minX: 0,
                                  maxX: 30.0, // Scale logic omitted. Real zooming scales the canvas instead.
                                  minY: _minLowCache,
                                  maxY: _maxHighCache,
                                  animationValue: _drawingsAnim.value,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top Navigation (Timeframe, Demo Badge, Chart Type)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTimeframeSelector(),
                  const SizedBox(width: 8),
                  _buildDrawingToggle(),
                  const SizedBox(width: 8),
                  _buildDemoBadge(),
                  const SizedBox(width: 8),
                  _buildChartToggle(),
                ],
              ),
            ),
          ),

          // Live Header Price ticker
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.currentPrice.symbol,
                  style: MehdAiTheme.headingStyle.copyWith(fontSize: 24),
                ),
                _LivePriceFlashText(price: widget.currentPrice.bid),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.currentPrice.spread > 2.0)
                      const Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: Icon(Icons.warning_amber_rounded, size: 14, color: MehdAiTheme.red),
                      ),
                    Flexible(
                      child: Text(
                        'Spread: ${widget.currentPrice.spread.toStringAsFixed(1)} pips',
                        style: MehdAiTheme.labelStyle.copyWith(
                          color: _getSpreadColor(widget.currentPrice.spread),
                          fontWeight: widget.currentPrice.spread > 2.0 ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // AI Drawings Settings Toggle
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildDrawingsToggleOverlay(),
          ),

          // ── Zoom Buttons ──
          Positioned(
            right: 8,
            bottom: 30,
            child: Column(
              children: [
                _chartBtn('+', () {
                  setState(() =>
                    _zoomLevel = (_zoomLevel + 0.3)
                      .clamp(0.3, 8.0));
                }),
                const SizedBox(height: 3),
                _chartBtn('-', () {
                  setState(() =>
                    _zoomLevel = (_zoomLevel - 0.3)
                      .clamp(0.3, 8.0));
                }),
                const SizedBox(height: 3),
                _chartBtn('↺', () {
                  setState(() {
                    _zoomLevel = 1.0;
                    _scrollOffset = 0.0;
                  });
                }),
              ],
            ),
          ),

          if (_drawingMode == DrawingMode.manual)
            Positioned(
              left: 8,
              top: 70,
              child: Column(
                children: [
                  _toolBtn('Line', DrawingTool.line),
                  _toolBtn('H-Line', DrawingTool.hline),
                  _toolBtn('Zone', DrawingTool.zone),
                  _toolBtn('Fib', DrawingTool.fib),
                  GestureDetector(
                    onTap: () => setState(() {
                      _drawings.clear();
                      _pendingPoints.clear();
                      _activeTool = DrawingTool.none;
                    }),
                    child: Container(
                      width: 44, height: 44,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080808),
                        border: Border.all(color: const Color(0xFF111111), width: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Center(
                        child: Text('CLR', style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 9)),
                      ),
                    ),
                  ),
                ],
              ),
            ),





          // ── Expand/Collapse ⛶ Button ──
          Positioned(
            top: 16,
            right: 60,
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: MehdAiTheme.bgSecondary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: MehdAiTheme.borderColor),
                ),
                child: Icon(
                  _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                  size: 18,
                  color: MehdAiTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Manual Drawing Gesture Handling ──
  void _handleChartTap(TapUpDetails details, BuildContext context) {
    final chartBox = context.findRenderObject() as RenderBox?;
    if (chartBox == null) return;
    final localPoint = details.localPosition;
    final chartSize = chartBox.size;
    
    // Convert screen point to price-domain coordinates
    final rangeX = 30.0;
    final rangeY = _maxHighCache - _minLowCache;
    final domainX = (localPoint.dx / chartSize.width) * rangeX;
    final domainY = _minLowCache + (1.0 - localPoint.dy / chartSize.height) * rangeY;

    setState(() {
      switch (_activeTool) {
        case ManualDrawingTool.trendline:
          if (_firstTapPoint == null) {
            _firstTapPoint = Offset(domainX, domainY);
          } else {
            _manualDrawings.add(ManualTrendline(
              id: 'manual_${_nextId++}',
              startX: _firstTapPoint!.dx,
              startY: _firstTapPoint!.dy,
              endX: domainX,
              endY: domainY,
            ));
            _firstTapPoint = null;
          }
          break;

        case ManualDrawingTool.horizontalLine:
          _manualDrawings.add(ManualHorizontalLine(
            id: 'manual_${_nextId++}',
            priceLevel: domainY,
          ));
          break;

        case ManualDrawingTool.zone:
          if (_firstTapPoint == null) {
            _firstTapPoint = Offset(domainX, domainY);
          } else {
            final top = domainY > _firstTapPoint!.dy ? domainY : _firstTapPoint!.dy;
            final bot = domainY < _firstTapPoint!.dy ? domainY : _firstTapPoint!.dy;
            _manualDrawings.add(ManualZone(
              id: 'manual_${_nextId++}',
              topPrice: top,
              bottomPrice: bot,
            ));
            _firstTapPoint = null;
          }
          break;

        case ManualDrawingTool.fibonacci:
          if (_firstTapPoint == null) {
            _firstTapPoint = Offset(domainX, domainY);
          } else {
            final high = domainY > _firstTapPoint!.dy ? domainY : _firstTapPoint!.dy;
            final low = domainY < _firstTapPoint!.dy ? domainY : _firstTapPoint!.dy;
            _manualDrawings.add(ManualFibonacci(
              id: 'manual_${_nextId++}',
              highPrice: high,
              lowPrice: low,
            ));
            _firstTapPoint = null;
          }
          break;

        case ManualDrawingTool.none:
          break;
      }
      _saveManualDrawings();
    });
  }

  void _deleteSelected() {
    setState(() {
      _manualDrawings.removeWhere((d) => d.isSelected);
      _saveManualDrawings();
    });
  }

  Widget _buildDrawingsToggleOverlay() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MehdAiTheme.bgSecondary.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: MehdAiTheme.blue.withOpacity(0.5)),
        ),
        child: const Icon(Icons.auto_awesome, color: MehdAiTheme.blue, size: 20),
      ),
      color: MehdAiTheme.bgSecondary,
      offset: const Offset(0, -250),
      itemBuilder: (context) {
        return _activeDrawings.keys.map((String key) {
          return PopupMenuItem<String>(
            value: key,
            child: StatefulBuilder(
              builder: (context, setPopupState) {
                final bool isActive = _activeDrawings[key] == true;
                return CheckboxListTile(
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: MehdAiTheme.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: MehdAiTheme.green.withOpacity(0.4)),
                        ),
                        child: Text('AI', style: MehdAiTheme.labelStyle.copyWith(fontSize: 8, color: MehdAiTheme.green)),
                      ),
                      Flexible(
                        child: Text(
                          key, 
                          style: MehdAiTheme.labelStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  value: isActive,
                  activeColor: MehdAiTheme.blue,
                  checkColor: MehdAiTheme.bgPrimary,
                  onChanged: (bool? value) {
                    _toggleDrawing(key);
                    setPopupState(() {}); // update checkbox visually
                  },
                );
              }
            ),
          );
        }).toList();
      },
    );
  }

  Color _getSpreadColor(double spread) {
    if (spread < 1.0) return MehdAiTheme.green;
    if (spread <= 2.0) return MehdAiTheme.yellow;
    return MehdAiTheme.red; // Extreme spread
  }

  Widget _buildTimeframeSelector() {
    final timeframes = ['1M', '5M', '15M', '1H', '4H', '1D'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: timeframes.map((tf) {
          final isSelected = _selectedTimeframe == tf;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedTimeframe = tf;
                // In a real app, this would fetch new data.
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? MehdAiTheme.blue.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tf,
                style: MehdAiTheme.labelStyle.copyWith(
                  color: isSelected ? MehdAiTheme.blue : MehdAiTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDemoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MehdAiTheme.yellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: MehdAiTheme.yellow.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: MehdAiTheme.yellow),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'DEMO',
              style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.yellow, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(Icons.candlestick_chart, 'Candles', true),
          _buildToggleOption(Icons.show_chart, 'Line', false),
        ],
      ),
    );
  }

  Widget _buildToggleOption(IconData icon, String label, bool isCandle) {
    final isSelected = _isCandleChart == isCandle;
    return InkWell(
      onTap: () {
        setState(() => _isCandleChart = isCandle);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? MehdAiTheme.bgPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? MehdAiTheme.white : MehdAiTheme.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: MehdAiTheme.labelStyle.copyWith(
                  color: isSelected ? MehdAiTheme.white : MehdAiTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        border: Border.all(color: const Color(0xFF111111)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _drawingModeBtn('AUTO', DrawingMode.auto),
          _drawingModeBtn('MANUAL', DrawingMode.manual),
        ],
      ),
    );
  }

  Widget _drawingModeBtn(String label, DrawingMode mode) {
    final isActive = _drawingMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _drawingMode = mode;
        if (mode == DrawingMode.auto) {
          _activeTool = DrawingTool.none;
          _pendingPoints.clear();
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF020810) : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: isActive ? Border.all(color: const Color(0xFF58A6FF)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF333333),
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  
  Widget _toolBtn(String label, DrawingTool tool) {
    final isActive = _activeTool == tool;
    return GestureDetector(
      onTap: () => setState(() =>
        _activeTool = isActive ? DrawingTool.none : tool),
      child: Container(
        width: 44, height: 44,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF020810) : const Color(0xFF080808),
          border: Border.all(
            color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF111111),
            width: isActive ? 1.5 : 0.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(
              color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF444444),
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chartBtn(String icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          icon,
          style: const TextStyle(
            color: Color(0xFF58A6FF),
            fontSize: 13,
          ),
        ),
      ),
    ),
  );
}

class ZenChartPainter extends CustomPainter {
  final List<Candle> candles;
  final double zoomLevel;
  final double scrollOffset;
  final String symbol;
  final double currentPrice;
  final ConsensusResult? consensus;
  final bool isCandles;
  final String timeframe;
  final double minLow;
  final double maxHigh;
  final List<ManualDrawing> manualDrawings;

  ZenChartPainter({
    required this.candles,
    required this.zoomLevel,
    required this.scrollOffset,
    required this.symbol,
    required this.currentPrice,
    this.consensus,
    this.isCandles = true,
    this.timeframe = '1H',
    required this.minLow,
    required this.maxHigh,
    required this.manualDrawings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty || size.width == 0 || size.height == 0) return;

    final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    canvas.save();
    canvas.scale(1/dpr, 1/dpr);

    final W = size.width * dpr;
    final H = size.height * dpr;
    // Right side: price axis only. Bottom: time axis.
    final pad = EdgeInsets.fromLTRB(8 * dpr, 12 * dpr, 46 * dpr, 24 * dpr);

    // Candle width changes with zoom
    final baseWidth = (size.width / 60) * dpr;
    final candleWidth = baseWidth * zoomLevel;

    // Scroll offset logically needs to be converted
    final scrollPhysical = scrollOffset * dpr;
    final candlesFromRight = (scrollPhysical / candleWidth).floor().abs();
    final visibleCount = (W / candleWidth).ceil();

    final startIdx = math.max(0, candles.length - visibleCount - candlesFromRight);
    final endIdx = math.min(candles.length, candles.length - candlesFromRight);
    final visibleCandles = candles.sublist(
      startIdx.clamp(0, candles.length),
      endIdx.clamp(0, candles.length),
    );

    if (visibleCandles.isEmpty) {
      canvas.restore();
      return;
    }

    // Price range from visible candles only
    final hi = visibleCandles.map((c) => c.high).reduce(math.max);
    final lo = visibleCandles.map((c) => c.low).reduce(math.min);
    final range = (hi - lo) == 0 ? 0.001 : hi - lo;
    final hiPad = hi + range * 0.08;
    final loPad = lo - range * 0.08;
    final rangePad = hiPad - loPad;

    double px(int i) => pad.left + i * candleWidth + candleWidth / 2;
    double py(double price) => pad.top + (1 - (price - loPad) / rangePad) * (H - pad.top - pad.bottom);

    // AI Zones Background
    if (consensus != null && consensus!.proceed) {
      final isBuy = consensus!.finalDirection == 'BUY';
      final zoneColor = isBuy ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B);
      final paint = Paint()
        ..color = zoneColor.withOpacity(0.05)
        ..style = PaintingStyle.fill;
      final rect = isBuy 
        ? Rect.fromLTRB(0, py(lo + range * 0.5), W, H - pad.bottom)
        : Rect.fromLTRB(0, pad.top, W, py(hi - range * 0.5));
      canvas.drawRect(rect, paint);
    }

    // Grid lines (subtle)
    final gridPaint = Paint()
      ..color = const Color(0xFF0D0D0D)
      ..strokeWidth = 1.0; // exactly 1px physically
    for (int i = 0; i <= 4; i++) {
      final y = pad.top + (i / 4) * (H - pad.top - pad.bottom);
      canvas.drawLine(Offset(pad.left, y), Offset(W - pad.right, y), gridPaint);
    }

    // Time Axis (Vertical grid and labels)
    final maxTicks = 4;
    final int step = math.max(1, visibleCandles.length ~/ maxTicks);
    for (int i = 0; i < visibleCandles.length; i += step) {
      final x = px(i);
      canvas.drawLine(Offset(x, pad.top), Offset(x, H - pad.bottom), gridPaint);
      
      // Bottom: time axis (HH:mm intraday, DD MMM daily)
      final DateTime? time = visibleCandles[i].timestamp;
      if (time == null) continue;
      
      final isIntraday = timeframe == '1M' || timeframe == '5M' || timeframe == '15M' || timeframe == '1H';
      String timeLabel = '';
      if (isIntraday) {
        timeLabel = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        timeLabel = '${time.day.toString().padLeft(2, '0')} ${months[time.month - 1]}';
      }
      
      _drawText(
        canvas,
        timeLabel,
        Offset(x - 14 * dpr, H - pad.bottom + 6 * dpr),
        color: const Color(0xFF333333),
        fontSize: 8 * dpr,
      );
    }

    // Draw candles
    if (isCandles) {
      for (int i = 0; i < visibleCandles.length; i++) {
        final candle = visibleCandles[i];
        final x = px(i);
        // Spec: Thin crisp candles (green up, red down)
        final isBull = candle.close >= candle.open;
        final color = isBull ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B);
        final candlePaint = Paint()
          ..color = color
          ..strokeWidth = 1.0 // 1 pixel exact
          ..strokeCap = StrokeCap.round;

        // Wick
        canvas.drawLine(
          Offset(x, py(candle.high)),
          Offset(x, py(candle.low)),
          candlePaint,
        );

        // Body proportion
        final bodyTop = py(math.max(candle.open, candle.close));
        final bodyBot = py(math.min(candle.open, candle.close));
        final bodyHeight = math.max(bodyBot - bodyTop, 1.0); // minimum 1 px body
        
        // Very thin candles
        final cWidth = math.max(candleWidth * 0.5, 2.0); 
        
        canvas.drawRect(
          Rect.fromLTWH(
            x - cWidth / 2,
            bodyTop,
            cWidth,
            bodyHeight,
          ),
          Paint()..color = color,
        );
      }
    } else {
      // Line Chart
      final linePaint = Paint()
        ..color = const Color(0xFF58A6FF)
        ..strokeWidth = 2.0 * dpr
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
        
      final path = Path();
      for (int i = 0; i < visibleCandles.length; i++) {
        final xPos = px(i);
        final yPos = py(visibleCandles[i].close);
        if (i == 0) {
          path.moveTo(xPos, yPos);
        } else {
          path.lineTo(xPos, yPos);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    // Current price line
    final priceY = py(currentPrice);
    final isUp = visibleCandles.last.close >= visibleCandles.last.open;
    final pricePaint = Paint()
      ..color = isUp ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B)
      ..strokeWidth = 1.0;

    _drawDashedLine(canvas, Offset(pad.left, priceY), Offset(W - pad.right, priceY), pricePaint);

    // Price box (Right side)
    canvas.drawRect(Rect.fromLTWH(W - pad.right + 2 * dpr, priceY - 7 * dpr, 46 * dpr, 14 * dpr), pricePaint);

    // Price text
    final dp = currentPrice > 100 ? 2 : 5;
    _drawText(
      canvas,
      currentPrice.toStringAsFixed(dp),
      Offset(W - pad.right + 6 * dpr, priceY - 4.5 * dpr),
      color: const Color(0xFF000000),
      fontSize: 8 * dpr,
      bold: true,
    );

    // Price axis labels: right-aligned, 7px, #1a1a1a
    for (int i = 0; i <= 4; i++) {
      final priceLevel = loPad + rangePad * ((4 - i) / 4);
      _drawText(
        canvas,
        priceLevel.toStringAsFixed(dp),
        Offset(W - pad.right + 4 * dpr, py(priceLevel) - 4 * dpr),
        color: const Color(0xFF1a1a1a),
        fontSize: 7 * dpr,
      );
    }

      _drawManual(canvas, size, manualDrawings);
    canvas.restore();
  }

  
  void _drawManual(Canvas canvas, Size size, List<ManualDrawing> drawings) {
    for (var d in drawings) {
      if (d.points.isEmpty) continue;
      final p = Paint()
        ..color = d.color
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      switch (d.type) {
        case DrawingTool.line:
          if (d.points.length < 2) continue;
          canvas.drawLine(d.points[0], d.points[1], p);
          canvas.drawCircle(d.points[0], 4, Paint()..color = d.color);
          canvas.drawCircle(d.points[1], 4, Paint()..color = d.color);
          break;
          
        case DrawingTool.hline:
          canvas.drawLine(
            Offset(0, d.points[0].dy),
            Offset(size.width - 60, d.points[0].dy),
            p..color = d.color..strokeWidth = 0.8..style = PaintingStyle.stroke,
          );
          break;
          
        case DrawingTool.zone:
          if (d.points.length < 2) continue;
          final rect = Rect.fromPoints(d.points[0], d.points[1]);
          canvas.drawRect(rect, Paint()..color = d.color.withOpacity(0.06)..style = PaintingStyle.fill);
          canvas.drawRect(rect, p);
          break;
          
        case DrawingTool.fib:
          if (d.points.length < 2) continue;
          final top = math.min(d.points[0].dy, d.points[1].dy);
          final bot = math.max(d.points[0].dy, d.points[1].dy);
          final range = bot - top;
          for (var level in [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0]) {
            final y = top + range * level;
            final isStar = level == 0.618;
            canvas.drawLine(
              Offset(0, y),
              Offset(size.width - 60, y),
              Paint()
                ..color = const Color(0xFFD4AF37).withOpacity(isStar ? 0.7 : 0.25)
                ..strokeWidth = isStar ? 1.2 : 0.5
            );
          }
          break;
          
        default: break;
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double distance = 0;
    final total = (end.dx - start.dx);
    while (distance < total) {
      canvas.drawLine(
        Offset(start.dx + distance, start.dy),
        Offset(math.min(start.dx + distance + dashWidth, end.dx), end.dy),
        paint,
      );
      distance += dashWidth + dashSpace;
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, {required Color color, double fontSize = 9, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Courier New',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant ZenChartPainter oldDelegate) {
    return oldDelegate.currentPrice != currentPrice || 
           oldDelegate.zoomLevel != zoomLevel ||
           oldDelegate.scrollOffset != scrollOffset ||
           oldDelegate.symbol != symbol ||
           oldDelegate.consensus?.finalDirection != consensus?.finalDirection ||
           oldDelegate.isCandles != isCandles ||
           oldDelegate.timeframe != timeframe;
  }
}

// Candle model now in separate file

class _LivePriceFlashText extends StatefulWidget {
  final double price;
  const _LivePriceFlashText({required this.price});
  @override
  State<_LivePriceFlashText> createState() => _LivePriceFlashTextState();
}

class _LivePriceFlashTextState extends State<_LivePriceFlashText> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Color _flashColor;

  @override
  void initState() {
    super.initState();
    _flashColor = MehdAiTheme.blue;
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void didUpdateWidget(covariant _LivePriceFlashText old) {
    super.didUpdateWidget(old);
    if (widget.price != old.price) {
      if (widget.price > old.price) {
        _flashColor = MehdAiTheme.green;
      } else {
        _flashColor = MehdAiTheme.red;
      }
      _anim.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final color = Color.lerp(_flashColor, MehdAiTheme.blue, _anim.value) ?? MehdAiTheme.blue;
        final isFlashing = _anim.isAnimating && _anim.value < 0.5;
        return Text(
          widget.price.toStringAsFixed(5),
          style: MehdAiTheme.priceStyle.copyWith(
            fontSize: 28, 
            color: color,
            shadows: isFlashing ? [BoxShadow(color: _flashColor.withOpacity(0.5), blurRadius: 10)] : [],
          ),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
