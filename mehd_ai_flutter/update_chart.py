import codecs

path = "c:\\Mehd ai\\mehd_ai_flutter\\lib\\widgets\\zen_chart.dart"
with open(path, 'r', encoding='utf-8') as f:
    t = f.read()

# 1. Update Enums
old_enums = "enum DrawingMode { auto, manual }"
new_enums = """enum DrawingMode { auto, manual }
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
}"""
t = t.replace(old_enums, new_enums)

# 2. Update state variables
t = t.replace("ManualDrawingTool _activeTool = ManualDrawingTool.none;", "DrawingTool _activeTool = DrawingTool.none;\n  List<Offset> _pendingPoints = [];")
t = t.replace("final List<ManualDrawing> _manualDrawings = [];", "List<ManualDrawing> _drawings = [];")

# 3. Add _handleTap inside _ZenChartState
handle_tap = """
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
"""
t = t.replace('Future<void> _loadManualDrawings', handle_tap + '\n  Future<void> _loadManualDrawings')

# 4. Update the Listener and GestureDetector logic
t = t.replace("""                    onPointerSignal: (PointerSignalEvent event) {
                      if (event is PointerScrollEvent) {
                        setState(() {
                          // Scroll up = zoom in, scroll down = zoom out
                          final delta = event.scrollDelta.dy;
                          _zoomLevel = (_zoomLevel * (1 - delta * 0.002))
                            .clamp(0.3, 8.0);
                        });
                      }
                    },""", """                    onPointerSignal: (PointerSignalEvent e) {
                      if (e is PointerScrollEvent) {
                        setState(() {
                          final delta = e.scrollDelta.dy;
                          _zoomLevel = (_zoomLevel - delta * 0.002).clamp(0.3, 8.0);
                        });
                      }
                    },""")

t = t.replace("""                      onScaleStart: (d) => _baseZoom = _zoomLevel,
                      onScaleUpdate: (d) {
                        if (d.pointerCount == 2) {
                          setState(() {
                            _zoomLevel = (_baseZoom * d.scale)
                              .clamp(0.3, 8.0);
                          });
                        }
                        // Pan/scroll with one finger
                        if (d.pointerCount == 1) {
                          setState(() {
                            _scrollOffset += d.focalPointDelta.dx;
                          });
                        }
                      },""", """                      onScaleStart: (ScaleStartDetails d) {
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
                      },""")

t = t.replace("""          // ── Manual Drawing Toolbar (left side) ──
          if (_drawingMode == DrawingMode.manual)
            Positioned(
              left: 8,
              top: 70,
              child: DrawingToolbar(
              activeTool: _activeTool,
              onToolChanged: (tool) => setState(() {
                _activeTool = tool;
                _firstTapPoint = null;
                // Deselect all
                for (final d in _manualDrawings) { d.isSelected = false; }
              }),
              onDeleteSelected: _deleteSelected,
              onClearAll: () => setState(() => _manualDrawings.clear()),
              drawingCount: _manualDrawings.length,
              hasSelection: _manualDrawings.any((d) => d.isSelected),
            ),
          ),""", """          if (_drawingMode == DrawingMode.manual)
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
            ),""")

t = t.replace("""          // ── Manual Drawing Overlay ──
          Padding(
            padding: const EdgeInsets.only(top: 60.0, bottom: 40, left: 16, right: 16),
            child: CustomPaint(
              size: Size.infinite,
              painter: ManualDrawingPainter(
                drawings: _manualDrawings,
                minX: 0,
                maxX: 30.0,
                minY: _minLowCache,
                maxY: _maxHighCache,
              ),
            ),
          ),""", "")

t = t.replace("""          // ── Gesture Layer for Drawing Interaction ──
          if (_activeTool != ManualDrawingTool.none)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              bottom: 40,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) => _handleChartTap(details, context),
                child: Container(color: Colors.transparent),
              ),
            ),""", "")

t = t.replace("opacity: _drawingMode == DrawingMode.manual ? 0.2 : 1.0,", "opacity: _drawingMode == DrawingMode.manual ? 0.15 : 1.0,")

# 6. Add _toolBtn widget builder
tool_btn = """
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
"""
t = t.replace("Widget _chartBtn(", tool_btn + "\n  Widget _chartBtn(")

# Add _drawManual method to ZenChartPainter
draw_manual = """
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
"""

t = t.replace("void _drawDashedLine(", draw_manual + "\n  void _drawDashedLine(")

# Hook up _drawManual inside paint()
t = t.replace("canvas.restore();\n  }", "  _drawManual(canvas, size, manualDrawings);\n    canvas.restore();\n  }")

# Add manualDrawings to ZenChartPainter
t = t.replace("final double maxHigh;", "final double maxHigh;\n  final List<ManualDrawing> manualDrawings;")
t = t.replace("required this.maxHigh,", "required this.maxHigh,\n    required this.manualDrawings,")

# When Painter is instanciated in ZenChartState:
t = t.replace("maxHigh: _maxHighCache,", "maxHigh: _maxHighCache,\n                                manualDrawings: _drawings,")

# Update auto button logic (setState for manual mode / auto mode)
auto_mode_btn_logic = """      onTap: () => setState(() {
        _drawingMode = mode;
        if (mode == DrawingMode.auto) {
          _activeTool = DrawingTool.none;
          _pendingPoints.clear();
        }
      }),"""
t = t.replace("""      onTap: () => setState(() {
        _drawingMode = mode;
        if (mode == DrawingMode.auto) {
          _activeTool = ManualDrawingTool.none;
        }
      }),""", auto_mode_btn_logic)

with open(path, 'w', encoding='utf-8') as f:
    f.write(t)

hs_path = "c:\\Mehd ai\\mehd_ai_flutter\\lib\\screens\\home_screen.dart"
with open(hs_path, 'r', encoding='utf-8') as f:
    hs = f.read()

hs = hs.replace("const LegalDisclaimer(),", "")
with open(hs_path, 'w', encoding='utf-8') as f:
    f.write(hs)

print("done")
