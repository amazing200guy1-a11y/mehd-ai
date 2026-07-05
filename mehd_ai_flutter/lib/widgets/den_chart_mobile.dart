import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class PlatformChartController {
  final VoidCallback onReady;
  final Function(Map) onEvent;
  final String interval;

  WebViewController? _ctrl;

  PlatformChartController({
    required this.onReady,
    required this.onEvent,
    this.interval = '1m',
  });

  void init() {
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) {
          try {
            final data = jsonDecode(msg.message);
            if (data['type'] == 'ready') {
              onReady();
            }
            onEvent(data);
          } catch (e) {
            debugPrint("DenChart JSON Error: $e");
          }
        },
      )
      ..loadFlutterAsset('assets/chart/chart.html');
  }

  void sendCommand(String jsonStr) {
    final escaped = jsonStr
        .replaceAll("'", "\\'")
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
    _ctrl?.runJavaScript("fromFlutter('$escaped')");
  }

  void dispose() {
    _ctrl = null;
  }

  Widget buildWidget() {
    if (_ctrl == null) {
      return Container(
          color: const Color(0xFF000000),
          child: const Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 1.0))));
    }
    return WebViewWidget(controller: _ctrl!);
  }
}
