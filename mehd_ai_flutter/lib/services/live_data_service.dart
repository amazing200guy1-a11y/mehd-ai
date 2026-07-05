import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:mehd_ai_flutter/models/market_snapshot.dart';
import 'package:http/http.dart' as http;

class LiveDataService {
  WebSocketChannel? _channel;
  StreamController<MarketSnapshot>? _controller;
  Timer? _reconnectTimer;
  Timer? _pollTimer;  // For crypto REST polling
  String? _currentSymbol;
  String? _mappedSymbol;
  
  // Finnhub API Key — corrected (was accidentally doubled)
  static const _finnhubApiKey = 'd8rhtbpr01qnkitn2690'; 
  static const _wsUrl = 'wss://ws.finnhub.io?token=$_finnhubApiKey';

  /// Maps our internal symbols to Finnhub symbols
  String _mapToFinnhubSymbol(String symbol) {
    // Forex — all mapped to OANDA format
    if (symbol == 'EUR/USD') return 'OANDA:EUR_USD';
    if (symbol == 'GBP/USD') return 'OANDA:GBP_USD'; // FIX H1: was missing
    if (symbol == 'GBP/JPY') return 'OANDA:GBP_JPY';
    if (symbol == 'USD/JPY') return 'OANDA:USD_JPY';
    // Commodities & Indices
    if (symbol == 'XAU/USD') return 'OANDA:XAU_USD'; // Gold
    if (symbol == 'NAS100') return 'OANDA:NAS100_USD'; // FIX H1: was missing
    if (symbol == 'US30') return 'OANDA:US30_USD';   // FIX H1: was missing
    // Crypto
    if (symbol == 'BTC/USD') return 'BINANCE:BTCUSDT';
    if (symbol == 'ETH/USD') return 'BINANCE:ETHUSDT';
    if (symbol == 'SOL/USD') return 'BINANCE:SOLUSDT';
    if (symbol == 'XRP/USD') return 'BINANCE:XRPUSDT';
    if (symbol == 'DOGE/USD') return 'BINANCE:DOGEUSDT';
    return symbol; // Fallback
  }

  /// Connects to a live WebSocket feed for the given symbol.
  Stream<MarketSnapshot> streamPrices(String symbol) {
    _disconnect();
    
    _controller = StreamController<MarketSnapshot>.broadcast(
      onCancel: _disconnect,
    );
    
    _currentSymbol = symbol;
    _mappedSymbol = _mapToFinnhubSymbol(symbol);
    _connect();

    return _controller!.stream;
  }

  /// Fetches historical candles (last 100 minutes) to seed the chart
  Future<List<Map<String, dynamic>>> fetchHistoricalCandles(String symbol) async {
    final finnhubSym = _mapToFinnhubSymbol(symbol);
    final toTime = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final fromTime = toTime - (100 * 60); // 100 minutes ago

    // FINNHUB CRYPTO CANDLES (works because Finnhub IS reachable)
    if (finnhubSym.startsWith('BINANCE:')) {
      final toTime   = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final fromTime = toTime - (120 * 60); // 120 minutes ago
      final url = Uri.parse(
        'https://finnhub.io/api/v1/crypto/candle?symbol=$finnhubSym&resolution=1&from=$fromTime&to=$toTime&token=$_finnhubApiKey',
      );
      try {
        final response = await http.get(url);
        if (kDebugMode) print('Finnhub crypto status: ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['s'] == 'ok') {
            final List<Map<String, dynamic>> candles = [];
            final List t = data['t'];
            final List o = data['o'];
            final List h = data['h'];
            final List l = data['l'];
            final List c = data['c'];
            for (int i = 0; i < t.length; i++) {
              candles.add({
                'time':  t[i],
                'open':  (o[i] as num).toDouble(),
                'high':  (h[i] as num).toDouble(),
                'low':   (l[i] as num).toDouble(),
                'close': (c[i] as num).toDouble(),
              });
            }
            if (kDebugMode) print('Finnhub crypto candles: ${candles.length}');
            return candles;
          } else if (kDebugMode) {
            print('Finnhub crypto response: ${response.body}');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Finnhub crypto candle error: $e');
      }
      return [];
    }

    // Finnhub logic for Stocks/Forex
    String endpointPath = finnhubSym.startsWith('OANDA:') ? 'forex/candle' : 'stock/candle';
    final url = Uri.parse(
      'https://finnhub.io/api/v1/$endpointPath?symbol=$finnhubSym&resolution=1&from=$fromTime&to=$toTime&token=$_finnhubApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['s'] == 'ok') {
          final List<Map<String, dynamic>> candles = [];
          final List t = data['t'];
          final List o = data['o'];
          final List h = data['h'];
          final List l = data['l'];
          final List c = data['c'];

          for (int i = 0; i < t.length; i++) {
            candles.add({
              'time': t[i],
              'open': (o[i] as num).toDouble(),
              'high': (h[i] as num).toDouble(),
              'low': (l[i] as num).toDouble(),
              'close': (c[i] as num).toDouble(),
            });
          }
          return candles;
        }
      }
    } catch (e) {
      // Finnhub candle fetch failed — return empty list so caller falls back gracefully
    }
    return [];
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    _pollTimer = null;
    
    if (_channel != null && _mappedSymbol != null) {
      try {
        _channel!.sink.add(jsonEncode({'type': 'unsubscribe', 'symbol': _mappedSymbol}));
      } catch (_) {}
    }
    
    _channel?.sink.close(status.goingAway);
    _channel = null;
    if (_controller?.isClosed == false) {
      _controller?.close();
    }
  }

  void _connect() {
    if (_mappedSymbol == null || _controller == null) return;

    try {
      // ALL symbols now use Finnhub WebSocket (Binance is DNS-blocked on this network)
      // Finnhub supports BINANCE:BTCUSDT and OANDA:EUR_USD etc.
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.sink.add(jsonEncode({'type': 'subscribe', 'symbol': _mappedSymbol}));

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'trade') {
            final trades = data['data'] as List?;
            if (trades == null || trades.isEmpty) return;
            final lastTrade = trades.last;
            final price = (lastTrade['p'] as num).toDouble();
            final timeMs = (lastTrade['t'] as num).toInt();

            final snapshot = MarketSnapshot(
              id: _currentSymbol!,
              symbol: _currentSymbol!,
              bid: price - 0.0001,
              ask: price + 0.0001,
              spread: 0.0002,
              timestamp: DateTime.fromMillisecondsSinceEpoch(timeMs),
              open: price,
              high: price,
              low: price,
              close: price,
              volume: trades.fold(0.0, (sum, t) => sum + ((t['v'] as num?)?.toDouble() ?? 0.0)), // FIX C3: null-safe
              dataSource: 'finnhub_live',
              isLive: true,
            );

            if (_controller != null && !_controller!.isClosed) {
              _controller!.add(snapshot);
            }
          }
        },
        onError: (error) {
          if (kDebugMode) print('Finnhub WS Error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          if (kDebugMode) print('Finnhub WS Disconnected');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      if (kDebugMode) print('Failed to connect WebSocket: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_controller?.isClosed ?? true) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _connect();
    });
  }
}
