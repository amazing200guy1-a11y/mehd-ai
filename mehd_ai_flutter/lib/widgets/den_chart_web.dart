// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class PlatformChartController {
  final VoidCallback onReady;
  final Function(Map) onEvent;

  html.IFrameElement? _iframe;
  final String _viewId = 'den-chart-${DateTime.now().millisecondsSinceEpoch}';
  bool _ready = false;

  PlatformChartController({
    required this.onReady,
    required this.onEvent,
  });

  void init() {
    _iframe = html.IFrameElement()
      ..src = 'assets/assets/chart/chart.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#000000';

    // Register the view
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframe!,
    );

    // Listen for messages from the iframe
    html.window.onMessage.listen((event) {
      try {
        final data = jsonDecode(event.data as String);
        if (data is Map) {
          if (data['type'] == 'ready') {
            _ready = true;
            onReady();
          }
          onEvent(data);
        }
      } catch (_) {
        // Ignore non-JSON messages from other sources
      }
    });

    // Mark ready after a short delay if iframe loads but doesn't send ready
    Future.delayed(const Duration(seconds: 2), () {
      if (!_ready) {
        _ready = true;
        onReady();
      }
    });
  }

  void sendCommand(String jsonStr) {
    if (_iframe?.contentWindow == null) return;
    // Call fromFlutter() inside the iframe
    _iframe!.contentWindow!.postMessage(jsonStr, '*');
  }

  void dispose() {
    _iframe = null;
  }

  Widget buildWidget() {
    return HtmlElementView(viewType: _viewId);
  }
}
