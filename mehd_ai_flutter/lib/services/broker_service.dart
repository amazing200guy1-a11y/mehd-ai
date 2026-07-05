import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mehd_ai_flutter/core/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BrokerCredentials {
  final String exchangeId;
  final String apiKey;
  final String apiSecret;

  BrokerCredentials({
    required this.exchangeId,
    required this.apiKey,
    required this.apiSecret,
  });
}

class BrokerService extends ChangeNotifier {
  // Singleton pattern
  static final BrokerService _instance = BrokerService._internal();
  factory BrokerService() => _instance;
  BrokerService._internal();

  String? _activeExchange;
  String? get activeExchange => _activeExchange;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> init() async {
    // In a real app, we would query the backend to see if a vault exists for this user
    _isConnected = false;
    notifyListeners();
  }

  /// Securely transmits the broker credentials to the Backend KMS Vault.
  /// Keys are never stored locally; they are immediately encrypted by the server.
  Future<bool> connectBroker({
    required String exchangeId,
    required String apiKey,
    required String apiSecret,
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return false;

      final url = Uri.parse('${AppConstants.baseUrl}/account/broker');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'exchange_id': exchangeId,
          'api_key': apiKey,
          'api_secret': apiSecret,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _activeExchange = exchangeId;
        _isConnected = true;
        notifyListeners();
        return true;
      }
      
      debugPrint("BrokerService: Backend rejected keys: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("BrokerService: Failed to transmit keys securely: $e");
      return false;
    }
  }

  Future<void> disconnect() async {
    _activeExchange = null;
    _isConnected = false;
    notifyListeners();
  }

  /// No longer retrieves credentials locally. The backend already has them encrypted.
  Future<BrokerCredentials?> getActiveCredentials() async {
    return null;
  }
}
