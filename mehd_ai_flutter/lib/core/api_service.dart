import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:mehd_ai_flutter/models/account_health.dart';
import 'package:mehd_ai_flutter/widgets/mistake_dna_dialog.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/models/market_snapshot.dart';
import 'package:mehd_ai_flutter/models/executive_brief.dart';
import 'package:mehd_ai_flutter/models/manual_drawing.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// FILE 3 — api_service.dart
///
/// Build Debrief:
/// The ApiService is the single source of truth for all network calls.
/// If the backend changes its URL structure, we only update this one file.
/// It wraps every HTTP call in robust error handling so the UI never crashes
/// if the server drops. For the live SSE stream, we use HTTP chunked responses
/// to manually parse incoming Server-Sent Events from the FastAPI backend.

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  _CacheEntry(this.data, this.timestamp);
  bool isValid(Duration maxAge) => DateTime.now().difference(timestamp) < maxAge;
}

class ApiService {
  final http.Client _client = http.Client();
  static final Map<String, _CacheEntry> _cache = {};

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<Map<String, String>> _getHeaders([Map<String, String>? extra]) async {
    final token = await _getAuthToken();
    final h = <String, String>{};
    if (token != null) h['Authorization'] = 'Bearer $token';
    if (extra != null) h.addAll(extra);
    return h;
  }

  /// Expose the cache so UI can clear it if needed
  void clearCache() => _cache.clear();

  /// Close the HTTP client to release connection pool resources
  void dispose() => _client.close();

  /// Pings the backend to see if it's alive.
  Future<bool> healthCheck() async {
    try {
      final response = await _client.get(Uri.parse('${AppConstants.baseUrl}/health'), headers: await _getHeaders()).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false; // Backend unreachable
    }
  }

  Future<Map<String, dynamic>> checkCompliance() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/compliance'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": "api_offline"};
    }
  }

  // ── THE AUDITOR ENDPOINT ──
  Future<PostMortemResult?> performAudit(Map<String, dynamic> auditData) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/den/audit'),
        headers: await _getHeaders({'Content-Type': 'application/json'}),
        body: jsonEncode(auditData),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return PostMortemResult.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("API Service - performAudit failed: $e");
    }
    return null;
  }

  /// Asks the 11 AI agents to analyze a symbol in real-time.
  Future<ConsensusResult> analyzeSymbol(String symbol) async {
    final cacheKey = 'analyze_$symbol';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid(const Duration(minutes: 5))) {
      return _cache[cacheKey]!.data as ConsensusResult;
    }

    try {
      final cleanSymbol = symbol.replaceAll('/', '');
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/analyze/$cleanSymbol'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 35)); // Give room for 30s ML timeout

      if (response.statusCode == 200) {
        final result = ConsensusResult.fromJson(jsonDecode(response.body));
        _cache[cacheKey] = _CacheEntry(result, DateTime.now());
        return result;
      } else {
        throw Exception('Failed to analyze: ${response.statusCode}');
      }
    } catch (e) {
      // Graceful fallback if backend is down
      return ConsensusResult(
        votes: [],
        finalDirection: "HOLD",
        consensusPercentage: 0.0,
        proceed: false,
        rejectionReason: "BACKEND_UNREACHABLE: $e",
        timestamp: DateTime.now().toUtc(),
      );
    }
  }

  /// Submits a trade order to the Risk Kernel.
  Future<RiskDecision> executeTrade(TradeOrder order) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/execute'),
        headers: await _getHeaders({'Content-Type': 'application/json'}),
        body: jsonEncode(order.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 400) {
        // FastAPI returns 400 for bad risk logic but still returns RiskDecision json
        return RiskDecision.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Execution failed: ${response.statusCode}');
      }
    } catch (e) {
      return RiskDecision(
        id: "",
        approved: false,
        calculatedLotSize: 0,
        stopLoss: 0,
        rejectionReason: "NETWORK_ERROR: $e",
        timestamp: DateTime.now().toUtc(),
      );
    }
  }

  /// Fetches real-time account status and kill-switch locks.
  Future<AccountHealth> getAccountHealth() async {
    final cacheKey = 'account_health';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid(const Duration(seconds: 30))) {
      return _cache[cacheKey]!.data as AccountHealth;
    }

    try {
      final response = await _client.get(Uri.parse('${AppConstants.baseUrl}/account_health'), headers: await _getHeaders()).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final health = AccountHealth.fromJson(jsonDecode(response.body));
        _cache[cacheKey] = _CacheEntry(health, DateTime.now());
        return health;
      } else {
        throw Exception('Failed fetching account: ${response.statusCode}');
      }
    } catch (e) {
      // Safe mock state if offline
      return AccountHealth(
        balance: 0.0,
        equity: 0.0,
        dailyDrawdownPct: 0.0,
        isLocked: true,
        lockReason: "BACKEND_OFFLINE",
      );
    }
  }

  /// Fetches system health and advanced technical telemetry
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await _client.get(Uri.parse('${AppConstants.baseUrl}/health'), headers: await _getHeaders()).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Health check failed: $e");
    }
    return {};
  }

  /// Connects to the Server-Sent Events endpoint and yields live prices.
  Stream<MarketSnapshot> streamPrices(String symbol) async* {
    // Sanitize symbol: 'EUR/USD' -> 'EURUSD' so FastAPI path parameter works
    final cleanSymbol = symbol.replaceAll('/', '');
    final request = http.Request('GET', Uri.parse('${AppConstants.wsUrl}/$cleanSymbol'));
    final authHeaders = await _getHeaders();
    request.headers.addAll(authHeaders);
    request.headers['Accept'] = 'text/event-stream';

    try {
      final response = await _client.send(request);
      if (response.statusCode != 200) {
        throw Exception('Stream connection failed: ${response.statusCode}');
      }

      await for (var chunk in response.stream.transform(utf8.decoder)) {
        // SSE chunks look like: `data: {"symbol":"EURUSD"...}\n\n`
        final lines = chunk.split('\n');
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isNotEmpty) {
              try {
                yield MarketSnapshot.fromJson(jsonDecode(jsonStr));
              } catch (e) {
                // Ignore parse errors on half-chunks
              }
            }
          }
        }
      }
    } catch (e) {
      // Stream failed or backend offline. 
      // In a real app we'd throw or wait and reconnect.
      yield* const Stream.empty();
    }
  }

  // ── THE DEN ENDPOINTS (Phase 7 API Integration) ──

  Future<Map<String, dynamic>> denResearch(String query) async {
    final cacheKey = 'research_$query';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid(const Duration(minutes: 5))) {
      return _cache[cacheKey]!.data as Map<String, dynamic>;
    }
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/den/research'),
        headers: await _getHeaders({'Content-Type': 'application/json'}),
        body: jsonEncode({"query": query}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      _cache[cacheKey] = _CacheEntry(data, DateTime.now());
      return data;
    } catch (e) {
      return {"response": "NETWORK ERROR: Could not reach The Den Research Room."};
    }
  }

  Future<Map<String, dynamic>> denStrategy(String query) async {
    final cacheKey = 'strategy_$query';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid(const Duration(minutes: 5))) {
      return _cache[cacheKey]!.data as Map<String, dynamic>;
    }
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/den/strategy'),
        headers: await _getHeaders({'Content-Type': 'application/json'}),
        body: jsonEncode({"query": query}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      _cache[cacheKey] = _CacheEntry(data, DateTime.now());
      return data;
    } catch (e) {
      return {"response": "NETWORK ERROR: Could not reach The Den Strategy Room."};
    }
  }

  Future<Map<String, dynamic>> denMath(String query) async {
    final cacheKey = 'math_$query';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid(const Duration(minutes: 5))) {
      return _cache[cacheKey]!.data as Map<String, dynamic>;
    }
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/den/math'),
        headers: await _getHeaders({'Content-Type': 'application/json'}),
        body: jsonEncode({"query": query}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      _cache[cacheKey] = _CacheEntry(data, DateTime.now());
      return data;
    } catch (e) {
      return {"response": "NETWORK ERROR: Could not reach The Den Math Room."};
    }
  }

  Future<Map<String, dynamic>> denVibe(String query) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/den/vibe'),
        headers: await _getHeaders({'Content-Type': 'application/json'}),
        body: jsonEncode({"query": query}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {
        "text": "Connection to The Den failed. Please retry.",
        "is_emotional": false,
        "consensus": null
      };
    }
  }

  Future<ExecutiveBrief?> getExecutiveBrief(String tradeId) async {
    try {
      final response = await _client.get(Uri.parse('${AppConstants.baseUrl}/den/brief/$tradeId'), headers: await _getHeaders()).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return ExecutiveBrief.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // ── DRAWING PERSISTENCE ──

  Future<void> saveDrawings(String symbol, List<ManualDrawing> drawings) async {
    try {
      final cleanSymbol = symbol.replaceAll('/', '');
      final data = drawings.map((d) => d.toJson()).toList();
      await _client.post(
        Uri.parse('${AppConstants.baseUrl}/drawings/$cleanSymbol'),
        headers: await _getHeaders({'Content-Type': 'application/json'}),
        body: jsonEncode({"drawings": data}),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Failed to save drawings: $e");
    }
  }

  Future<List<ManualDrawing>> loadDrawings(String symbol) async {
    try {
      final cleanSymbol = symbol.replaceAll('/', '');
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/drawings/$cleanSymbol'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['drawings'] as List;
        return data.map((d) => ManualDrawing.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint("Failed to load drawings: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> validateManualLevel(String symbol, double price) async {
    try {
      final cleanSymbol = symbol.replaceAll('/', '');
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/drawings/validate'),
        headers: await _getHeaders({'Content-Type': 'application/json'}),
        body: jsonEncode({"symbol": cleanSymbol, "price": price}),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("API - Validation failed: $e");
    }
    return {"is_valid": false, "label": "validation_failed", "strength": 0.0};
  }
}
