import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:mehd_ai_flutter/models/account_health.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/models/market_snapshot.dart';
import 'package:mehd_ai_flutter/models/executive_brief.dart';

/// FILE 3 — api_service.dart
///
/// Build Debrief:
/// The ApiService is the single source of truth for all network calls.
/// If the backend changes its URL structure, we only update this one file.
/// It wraps every HTTP call in robust error handling so the UI never crashes
/// if the server drops. For the live SSE stream, we use HTTP chunked responses
/// to manually parse incoming Server-Sent Events from the FastAPI backend.

class ApiService {
  final http.Client _client = http.Client();

  /// Pings the backend to see if it's alive.
  Future<bool> healthCheck() async {
    try {
      final response = await _client.get(Uri.parse('${AppConstants.baseUrl}/health')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false; // Backend unreachable
    }
  }

  /// Asks the 9 AI models to analyze a symbol in real-time.
  Future<ConsensusResult> analyzeSymbol(String symbol) async {
    try {
      final cleanSymbol = symbol.replaceAll('/', '');
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/analyze/$cleanSymbol'),
      ).timeout(const Duration(seconds: 35)); // Give room for 30s ML timeout

      if (response.statusCode == 200) {
        return ConsensusResult.fromJson(jsonDecode(response.body));
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
        headers: {'Content-Type': 'application/json'},
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
    try {
      final response = await _client.get(Uri.parse('${AppConstants.baseUrl}/account_health')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return AccountHealth.fromJson(jsonDecode(response.body));
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

  /// Connects to the Server-Sent Events endpoint and yields live prices.
  Stream<MarketSnapshot> streamPrices(String symbol) async* {
    // Sanitize symbol: 'EUR/USD' -> 'EURUSD' so FastAPI path parameter works
    final cleanSymbol = symbol.replaceAll('/', '');
    final request = http.Request('GET', Uri.parse('${AppConstants.wsUrl}/$cleanSymbol'));
    // We send Accept: text/event-stream so the server handles it properly
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
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/den/research'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"query": query}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {"response": "NETWORK ERROR: Could not reach The Den Research Room."};
    }
  }

  Future<Map<String, dynamic>> denStrategy(String query) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/den/strategy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"query": query}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {"response": "NETWORK ERROR: Could not reach The Den Strategy Room."};
    }
  }

  Future<Map<String, dynamic>> denMath(String query) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/den/math'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"query": query}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {"response": "NETWORK ERROR: Could not reach The Den Math Room."};
    }
  }

  Future<Map<String, dynamic>> denVibe(String query) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/den/vibe'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await _client.get(Uri.parse('${AppConstants.baseUrl}/den/brief/$tradeId')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return ExecutiveBrief.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}
