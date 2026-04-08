import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class DenChart extends StatefulWidget {
  final String symbol;
  final double basePrice;
  final bool isAutoMode;
  final String activeTool;
  final List<Map<String, dynamic>> commands;
  final Function(Map) onEvent;
  
  const DenChart({
    required this.symbol,
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
  WebViewController? _ctrl;
  bool _ready = false;
  int _lastCmdLen = 0;
  
  @override
  void initState() {
    super.initState();
    _initChart();
  }
  
  void _initChart() {
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) {
          try {
            final data = jsonDecode(msg.message);
            widget.onEvent(data);
            if (data['type'] == 'ready') {
              setState(() => _ready = true);
              _sendSymbol();
              _sendMode();
              _sendTool();
              _sendInitialCommands();
            }
          } catch (e) {
            debugPrint("DenChart JSON Error: $e");
          }
        },
      )
      ..loadFlutterAsset('assets/chart/chart.html');
  }
  
  @override
  void didUpdateWidget(DenChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;
    
    if (oldWidget.symbol != widget.symbol) {
      _sendSymbol();
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
    } else if (widget.commands.length < _lastCmdLen || (widget.commands.isEmpty && _lastCmdLen > 0)) {
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
      'price': widget.basePrice,
    });
  }

  void _sendMode() {
    _send({
      'action': 'set_mode',
      'mode': widget.isAutoMode ? 'auto' : 'manual'
    });
  }

  void _sendTool() {
    _send({
      'action': 'set_tool',
      'tool': widget.activeTool
    });
  }

  void _sendInitialCommands() {
    for (var cmd in widget.commands) {
      _send(cmd);
    }
    _lastCmdLen = widget.commands.length;
  }
  
  void _send(Map<String, dynamic> cmd) {
    final jsonStr = jsonEncode(cmd).replaceAll("'", "\\'");
    _ctrl?.runJavaScript("fromFlutter('$jsonStr')");
  }
  
  void clearDrawings() {
    _send({'action': 'clear'});
  }
  
  @override
  Widget build(BuildContext context) {
    if (_ctrl == null) {
      return Container(color: const Color(0xFF000000));
    }
    return WebViewWidget(controller: _ctrl!);
  }
}
