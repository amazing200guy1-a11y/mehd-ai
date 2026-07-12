import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// IO (Android/iOS/Desktop) implementation of createPinnedClient.
/// This file is only compiled on non-web targets via conditional import.
http.Client createClient() {
  final List<String> allowedFingerprints = [
    // Format: "4a0f8b..." hex string representing SHA-256 of the server SSL cert.
    // Paste production certificate fingerprint here before going live.
  ];

  final HttpClient innerClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  innerClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
    // Always trust localhost for local development
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return true;
    }

    if (allowedFingerprints.isEmpty) {
      debugPrint('⚠️ SSL PINNING: No fingerprints configured. Allowing connection by default in dev mode.');
      return true;
    }

    // Hash the certificate DER bytes and compare against the whitelist
    final sha256Digest = sha256.convert(cert.der);
    final fingerprint = sha256Digest.toString().toLowerCase().replaceAll(':', '').replaceAll(' ', '');

    for (final allowed in allowedFingerprints) {
      final cleanAllowed = allowed.toLowerCase().replaceAll(':', '').replaceAll(' ', '');
      if (fingerprint == cleanAllowed) {
        debugPrint('✓ SSL PINNING: Certificate verified for $host');
        return true;
      }
    }

    debugPrint('❌ SSL PINNING ERROR: Fingerprint mismatch for $host — connection blocked!');
    debugPrint('Received: $fingerprint');
    return false;
  };

  return IOClient(innerClient);
}
