// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class AdvancedTvChart extends StatefulWidget {
  final String symbol;

  const AdvancedTvChart({super.key, required this.symbol});

  @override
  State<AdvancedTvChart> createState() => _AdvancedTvChartState();
}

class _AdvancedTvChartState extends State<AdvancedTvChart> {
  late String _viewId;
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _viewId = 'tv-advanced-chart-${DateTime.now().millisecondsSinceEpoch}';
    _registerIframe();
  }

  void _registerIframe() {
    final tvSymbol = _formatSymbol(widget.symbol);

    // Build srcDoc with string concatenation so Dart correctly interpolates tvSymbol.
    // Using a triple-quoted string with \$tvSymbol would send the LITERAL text "$tvSymbol"
    // and TradingView would never receive the actual formatted symbol.
    final srcDoc = '<!DOCTYPE html>'
        '<html><head>'
        '<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0">'
        '<style>'
        'body,html{margin:0;padding:0;height:100%;overflow:hidden;background:#000;}'
        '.tradingview-widget-container{height:100%;width:100%;}'
        '</style>'
        '</head><body>'
        '<div class="tradingview-widget-container">'
        '<div id="tv_chart_container" style="height:100%;width:100%"></div>'
        '<script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>'
        '<script type="text/javascript">'
        'new TradingView.widget({'
        '"autosize":true,'
        '"symbol":"$tvSymbol",'
        '"interval":"15",'
        '"timezone":"Etc/UTC",'
        '"theme":"dark",'
        '"style":"1",'
        '"locale":"en",'
        '"enable_publishing":false,'
        '"backgroundColor":"rgba(0,0,0,1)",'
        '"gridColor":"rgba(255,255,255,0.05)",'
        '"hide_top_toolbar":false,'
        '"hide_legend":false,'
        '"save_image":false,'
        '"container_id":"tv_chart_container",'
        '"toolbar_bg":"#0D1117",'
        '"studies":["Volume@tv-basicstudies"]'
        '});'
        '</script></div></body></html>';

    _iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..srcdoc = srcDoc;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframe!,
    );
  }

  String _formatSymbol(String raw) {
    final stripped = raw.replaceAll('/', '');
    if (stripped.contains('BTC') || stripped.contains('ETH')) {
      return 'BINANCE:$stripped';
    }
    return 'FX:$stripped';
  }

  @override
  void didUpdateWidget(AdvancedTvChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _viewId = 'tv-advanced-chart-${DateTime.now().millisecondsSinceEpoch}';
      _registerIframe();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
