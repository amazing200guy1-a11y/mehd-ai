// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

class DenChart extends StatefulWidget {
  final String symbol;
  final String interval;
  final double basePrice;
  final bool isAutoMode;
  final String activeTool;
  final List<Map<String, dynamic>> commands;
  final Function(Map) onEvent;

  const DenChart({
    required this.symbol,
    this.interval = '1m',
    required this.basePrice,
    required this.isAutoMode,
    this.activeTool = 'none',
    this.commands = const [],
    required this.onEvent,
    super.key,
  });

  @override
  State<DenChart> createState() => DenChartState();
}

class DenChartState extends State<DenChart> {
  html.IFrameElement? _iframe;
  late String _viewId;
  bool _ready = false;
  int _lastCmdLen = 0;
  StreamSubscription? _msgSub; // store subscription so we can cancel it

  @override
  void initState() {
    super.initState();
    _viewId = 'den-chart-web-${DateTime.now().millisecondsSinceEpoch}';
    _initChart();
  }

  @override
  void dispose() {
    // Cancel the message listener so it doesn't fire after widget is gone
    _msgSub?.cancel();
    _msgSub = null;
    _iframe = null;
    super.dispose();
  }

  void _initChart() {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    _iframe = html.IFrameElement()
      ..src = 'assets/assets/chart/chart.html?v=$cacheBuster'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#000000';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframe!,
    );

    // Store the subscription so we can cancel it in dispose()
    _msgSub = html.window.onMessage.listen((event) {
      if (!mounted) return;
      try {
        final data = jsonDecode(event.data as String);
        if (data is Map) {
          widget.onEvent(data);
          if (data['type'] == 'ready') {
            _ready = true;
            _sendSymbol();
            _sendMode();
            _sendTool();
            _sendInitialCommands();
          }
        }
      } catch (e) {
        // Ignore JSON parse errors from non-chart messages
      }
    });

    // Fallback if ready event is missed
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (!_ready) {
        _ready = true;
        _sendSymbol();
        _sendMode();
        _sendTool();
        _sendInitialCommands();
      }
    });

    // Send symbol early so chart starts loading immediately
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _sendSymbol();
    });
  }

  @override
  void didUpdateWidget(DenChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.symbol != widget.symbol || oldWidget.interval != widget.interval) {
      _sendSymbol();
      return;
    }

    if (!_ready) return;

    if (oldWidget.basePrice != widget.basePrice) {
      _sendTick();
    }

    if (oldWidget.isAutoMode != widget.isAutoMode) {
      _sendMode();
    }
    if (oldWidget.activeTool != widget.activeTool) {
      _sendTool();
    }

    if (widget.commands.length > _lastCmdLen) {
      final newCommands = widget.commands.sublist(_lastCmdLen);
      for (final cmd in newCommands) {
        _send(cmd);
      }
      _lastCmdLen = widget.commands.length;
    } else if (widget.commands.length < _lastCmdLen ||
        (widget.commands.isEmpty && _lastCmdLen > 0)) {
      clearDrawings();
      for (final cmd in widget.commands) {
        _send(cmd);
      }
      _lastCmdLen = widget.commands.length;
    }
  }

  void _sendSymbol() {
    _send({
      'action': 'set_symbol',
      'symbol': widget.symbol,
      'interval': widget.interval,
      'price': widget.basePrice,
    });
  }

  void _sendTick() {
    _send({
      'action': 'tick',
      'price': widget.basePrice,
      'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  void _sendMode() {
    _send({'action': 'set_mode', 'mode': widget.isAutoMode ? 'auto' : 'manual'});
  }

  void _sendTool() {
    _send({'action': 'set_tool', 'tool': widget.activeTool});
  }

  void _sendInitialCommands() {
    for (var cmd in widget.commands) {
      _send(cmd);
    }
    _lastCmdLen = widget.commands.length;
  }

  void _send(Map<String, dynamic> cmd) {
    if (!mounted) return;
    final jsonStr = jsonEncode(cmd);

    // Capture local reference to avoid TOCTOU race condition
    // (contentWindow could become null between check and use)
    try {
      final win = _iframe?.contentWindow;
      if (win != null) {
        win.postMessage(jsonStr, '*');
      } else {
        // Retry once after 300ms if contentWindow isn't ready yet
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          try {
            final retryWin = _iframe?.contentWindow;
            if (retryWin != null) {
              retryWin.postMessage(jsonStr, '*');
            }
          } catch (_) {
            // Iframe detached, silently ignore
          }
        });
      }
    } catch (e) {
      // Iframe detached or cross-origin error, silently ignore
    }
  }

  void clearDrawings() {
    _send({'action': 'clear'});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
