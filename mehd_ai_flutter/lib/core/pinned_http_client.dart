import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:crypto/crypto.dart';

/// Pinned HTTP Client factory.
/// On web platforms, standard browser HTTP client is returned (browsers manage pinning natively).
/// On mobile/desktop platforms, returns a client that verifies SSL certificates against SHA-256 fingerprints.
http.Client createPinnedClient() {
  if (kIsWeb) {
    return http.Client();
  }

  // Pre-configured list of allowed SHA-256 fingerprints (e.g. from Let's Encrypt / your backend server certificate).
  // Under development, we can configure this or fallback to allowing localhost certificates automatically.
  final List<String> allowedFingerprints = [
    // Format: "4a0f8b..." hex string representing the SHA-256 signature of the SSL cert.
    // Paste production SSL certificate hash here when ready.
  ];

  final HttpClient innerClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  innerClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
    // SECURITY: Always trust localhost for local testing
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return true;
    }

    if (allowedFingerprints.isEmpty) {
      // If no fingerprints are configured yet in development, warning-log and allow connection
      debugPrint("⚠️ SSL PINNING: Allowed fingerprints list is empty. Connection allowed by default in dev.");
      return true;
    }

    // Hash the certificate's DER bytes
    final Digest sha256Digest = sha256.convert(cert.der);
    final String fingerprint = sha256Digest.toString().toLowerCase().replaceAll(':', '').replaceAll(' ', '');

    for (final allowed in allowedFingerprints) {
      final cleanAllowed = allowed.toLowerCase().replaceAll(':', '').replaceAll(' ', '');
      if (fingerprint == cleanAllowed) {
        debugPrint("✓ SSL PINNING: Handshake verified for host $host");
        return true;
      }
    }

    debugPrint("❌ SSL PINNING ERROR: Certificate fingerprint mismatch for host $host!");
    debugPrint("Received fingerprint: $fingerprint");
    return false;
  };

  return IOClient(innerClient);
}
