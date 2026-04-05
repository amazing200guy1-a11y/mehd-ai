import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/market_snapshot.dart';
import 'package:mehd_ai_flutter/models/candle.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/models/chart_enums.dart';
import 'package:mehd_ai_flutter/models/manual_drawing_model.dart';
import 'package:mehd_ai_flutter/models/automated_drawing.dart';
import 'package:mehd_ai_flutter/core/drawing_engine.dart';
import 'package:mehd_ai_flutter/widgets/den_animation.dart';
import 'package:mehd_ai_flutter/screens/settings_screen.dart';
import 'package:mehd_ai_flutter/screens/war_room_screen.dart';
import 'package:mehd_ai_flutter/screens/journey_screen.dart';
import 'package:mehd_ai_flutter/screens/war_room_community_screen.dart';
import 'package:mehd_ai_flutter/screens/rejection_feed_screen.dart';

// Modular Components
import 'package:mehd_ai_flutter/widgets/chart/zen_chart_header.dart';
import 'package:mehd_ai_flutter/widgets/chart/zen_chart_telemetry.dart';
import 'package:mehd_ai_flutter/widgets/chart/zen_chart_toolbar.dart';
import 'package:mehd_ai_flutter/widgets/chart/zen_chart_canvas.dart';

class ZenChart extends StatefulWidget {
  final MarketSnapshot currentPrice;
  final ConsensusResult? currentConsensus;
  final DenState denState;
  final Function(List<AutomatedDrawing>)? onDrawingsUpdated;

  const ZenChart({
    super.key,
    required this.currentPrice,
    this.currentConsensus,
    required this.denState,
    this.onDrawingsUpdated,
  });

  @override
  State<ZenChart> createState() => _ZenChartState();
}

class _ZenChartState extends State<ZenChart> with TickerProviderStateMixin {
  late AnimationController _scanlineAnim;
  late AnimationController _drawingsAnim;
  late AnimationController _shimmerAnim;

  double _zoomLevel = 1.0;
  double _baseZoom = 1.0;
  double _scrollOffset = 0.0;
  String _selectedTimeframe = '1H';
  bool _isCandleChart = true;

  DrawingMode _drawingMode = DrawingMode.auto;
  DrawingTool _activeTool = DrawingTool.none;
  final List<ManualDrawing> _drawings = [];
  final List<Offset> _pendingPoints = [];

  final List<Candle> _candleCache = [];
  List<AutomatedDrawing> _currentDrawings = [];
  
  double _minLowCache = 0;
  double _maxHighCache = 100;

  @override
  void initState() {
    super.initState();
    _scanlineAnim = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _drawingsAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _shimmerAnim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _generateMockData();
  }

  void _generateMockData() {
    final rand = math.Random();
    double lastClose = 1.0850;
    DateTime now = DateTime.now();
    for (int i = 0; i < 100; i++) {
      final open = lastClose;
      final close = open + (rand.nextDouble() - 0.5) * 0.0020;
      final high = math.max(open, close) + rand.nextDouble() * 0.0010;
      final low = math.min(open, close) - rand.nextDouble() * 0.0010;
      _candleCache.add(Candle(
        open: open,
        high: high,
        low: low,
        close: close,
        timestamp: now.subtract(Duration(hours: 100 - i)),
      ));
      lastClose = close;
    }
    _updateMinMax();
  }

  void _updateMinMax() {
    if (_candleCache.isEmpty) return;
    _minLowCache = _candleCache.map((c) => c.low).reduce(math.min);
    _maxHighCache = _candleCache.map((c) => c.high).reduce(math.max);
  }

  @override
  void didUpdateWidget(ZenChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPrice.bid != oldWidget.currentPrice.bid) {
      // Simulate real-time candle update
      final last = _candleCache.last;
      _candleCache[_candleCache.length - 1] = Candle(
        open: last.open,
        high: math.max(last.high, widget.currentPrice.bid),
        low: math.min(last.low, widget.currentPrice.bid),
        close: widget.currentPrice.bid,
        timestamp: last.timestamp,
      );
      _updateMinMax();
    }

    if (widget.currentConsensus != oldWidget.currentConsensus && widget.currentConsensus != null) {
      _triggerAIDrawings();
    }
  }

  void _triggerAIDrawings() {
    if (widget.currentConsensus?.proceed == true) {
      setState(() {
        _currentDrawings = DrawingEngine.generateDrawings(
          _candleCache, 0, 100.0, _minLowCache, _maxHighCache, {}
        );
      });
      _drawingsAnim.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _scanlineAnim.dispose();
    _drawingsAnim.dispose();
    _shimmerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MehdAiTheme.bgPrimary,
      child: Row(
        children: [
          if (_drawingMode == DrawingMode.manual) _buildDrawSidebar(),
          Expanded(
            child: Stack(
              children: [
                ZenChartCanvas(
                  candles: _candleCache,
                  zoomLevel: _zoomLevel,
                  scrollOffset: _scrollOffset,
                  symbol: widget.currentPrice.symbol,
                  currentPrice: widget.currentPrice.bid,
                  consensus: widget.currentConsensus,
                  isCandles: _isCandleChart,
                  timeframe: _selectedTimeframe,
                  manualDrawings: _drawings,
                  currentDrawings: _currentDrawings,
                  drawingsAnim: _drawingsAnim,
                  shimmerAnim: _shimmerAnim,
                  denState: widget.denState,
                  drawingMode: _drawingMode,
                  activeTool: _activeTool,
                  onTapDown: _handleTap,
                  onScaleStart: (d) => _baseZoom = _zoomLevel,
                  onScaleUpdate: _handleScaleUpdate,
                  onPointerScroll: _handlePointerScroll,
                ),
                ZenChartTelemetry(
                  scanlineAnim: _scanlineAnim,
                  agentColors: const [Color(0xFF58A6FF), Color(0xFF00FF88), Color(0xFFFF3B3B)],
                ),
                ZenChartHeader(currentPrice: widget.currentPrice),
                ZenChartToolbar(
                  onZoomIn: () => setState(() => _zoomLevel = (_zoomLevel + 0.3).clamp(0.3, 8.0)),
                  onZoomOut: () => setState(() => _zoomLevel = (_zoomLevel - 0.3).clamp(0.3, 8.0)),
                  onReset: () => setState(() { _zoomLevel = 1.0; _scrollOffset = 0.0; }),
                  onTimeframeChanged: (tf) => setState(() => _selectedTimeframe = tf),
                  selectedTimeframe: _selectedTimeframe,
                  onDrawingModeChanged: (mode) => setState(() {
                    _drawingMode = mode;
                    if (mode == DrawingMode.auto) {
                      _activeTool = DrawingTool.none;
                      _pendingPoints.clear();
                    }
                  }),
                  drawingMode: _drawingMode,
                  onChartTypeChanged: (isCandle) => setState(() => _isCandleChart = isCandle),
                  isCandleChart: _isCandleChart,
                  navIcons: [
                    _topBarIcon(Icons.radar, 'War Room', const Color(0xFFFF3B3B), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarRoomScreen(isAnalyzing: false)))),
                    _topBarIcon(Icons.trending_up, 'Journey', const Color(0xFF58A6FF), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JourneyScreen()))),
                    _topBarIcon(Icons.groups_outlined, 'Platoon', const Color(0xFF00FF88), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarRoomCommunityScreen()))),
                    _topBarIcon(Icons.block_outlined, 'Rejected', const Color(0xFFD29922), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RejectionFeedScreen()))),
                    _topBarIcon(Icons.settings_outlined, 'Settings', const Color(0xFF666666), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                  ],
                ),
                if (_drawingMode == DrawingMode.manual)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: _chartBtn('X', 'Clear Drawings', () => setState(() => _drawings.clear())),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      if (d.pointerCount >= 2) {
        _zoomLevel = (_baseZoom * d.scale).clamp(0.3, 8.0);
      } else if (d.pointerCount == 1) {
        _scrollOffset += d.focalPointDelta.dx;
        final maxScroll = _candleCache.length * 10.0 * _zoomLevel;
        _scrollOffset = _scrollOffset.clamp(-maxScroll, 0.0);
      }
    });
  }

  void _handlePointerScroll(PointerScrollEvent e) {
    setState(() {
      final delta = e.scrollDelta.dy;
      _zoomLevel = (_zoomLevel - delta * 0.002).clamp(0.3, 8.0);
    });
  }

  void _handleTap(Offset localPos) {
    setState(() {
      _pendingPoints.add(localPos);
      if (_pendingPoints.length >= 2 || _activeTool == DrawingTool.hline) {
        _drawings.add(ManualDrawing(
          type: _activeTool,
          points: List.from(_pendingPoints),
          color: _activeTool == DrawingTool.zone ? Colors.blue.withOpacity(0.4) : const Color(0xFF58A6FF),
        ));
        _pendingPoints.clear();
      }
    });
  }

  Widget _buildDrawSidebar() {
    return Container(
      width: 60,
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          const SizedBox(height: 80),
          _toolBtn('LINE', DrawingTool.line),
          _toolBtn('HORZ', DrawingTool.hline),
          _toolBtn('ZONE', DrawingTool.zone),
          _toolBtn('FIB', DrawingTool.fib),
        ],
      ),
    );
  }

  Widget _toolBtn(String label, DrawingTool tool) {
    final isActive = _activeTool == tool;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = isActive ? DrawingTool.none : tool),
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
          child: Text(label, style: TextStyle(color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF444444), fontSize: 9, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _chartBtn(String icon, String tooltip, VoidCallback fn) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: fn,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: const Color(0xFF0A0A0A), border: Border.all(color: const Color(0xFF1A1A1A)), borderRadius: BorderRadius.circular(3)),
        child: Center(child: Text(icon, style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 13))),
      ),
    ),
  );

  Widget _topBarIcon(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(icon, color: color.withOpacity(0.6), size: 16),
        ),
      ),
    );
  }
}
