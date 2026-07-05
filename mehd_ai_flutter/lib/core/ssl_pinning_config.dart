/// SECURITY: SSL Certificate Pinning Configuration
///
/// This file contains the configuration for SSL certificate pinning.
/// Certificate pinning ensures your app ONLY communicates with YOUR server,
/// even if an attacker has a fake SSL certificate.
///
/// HOW TO USE:
/// 1. Get your production server's SHA-256 certificate fingerprint:
///    Run: openssl s_client -connect YOUR_DOMAIN:443 | openssl x509 -fingerprint -sha256 -noout
///
/// 2. Paste the fingerprint(s) below in [pinnedCertificates]
///
/// 3. Import this config in api_service.dart and use it with the http client.
///
/// WHY THIS MATTERS:
/// Without pinning, a hacker on the same WiFi can use tools like mitmproxy
/// to intercept ALL your API calls (including auth tokens and trade data).
/// With pinning, even if they have a fake certificate, your app refuses to connect.
///
/// NOTE: For Flutter web, certificate pinning is handled by the browser.
/// This file is primarily for mobile (Android/iOS) and desktop builds.

import 'package:flutter/foundation.dart';

class SslPinningConfig {
  /// SHA-256 fingerprints of trusted certificates.
  /// Add your production server's certificate fingerprint here.
  /// You can pin both the leaf cert and the intermediate CA for redundancy.
  ///
  /// To generate: openssl s_client -connect YOUR_DOMAIN:443 | openssl x509 -fingerprint -sha256 -noout
  static const List<String> pinnedCertificates = [
    // TODO: Replace with your actual production certificate SHA-256 fingerprints
    // Example: 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    //
    // You should pin at LEAST 2 certificates:
    // 1. Your production server's leaf certificate
    // 2. A backup certificate (in case you need to rotate)
  ];

  /// Production backend host that pinning applies to.
  static const String pinnedHost =
      'mehd-ai-backend.railway.app'; // UPDATE with your actual domain

  /// Whether pinning is enabled. Disable during development (localhost doesn't have SSL).
  static bool get isEnabled => pinnedCertificates.isNotEmpty;

  /// Track whether we've already warned about missing pinning
  static bool _hasWarnedMissingPins = false;

  /// Validates a certificate's SHA-256 fingerprint against the pinned list.
  /// Returns true if the certificate matches a pinned entry.
  /// SECURITY: Logs a critical warning on first call if pinning is not configured.
  static bool validateCertificate(String sha256Fingerprint) {
    if (!isEnabled) {
      if (!_hasWarnedMissingPins) {
        _hasWarnedMissingPins = true;
        debugPrint(
          '⚠️ SECURITY WARNING: SSL Certificate Pinning is NOT configured. '
          'Add certificate fingerprints to SslPinningConfig.pinnedCertificates '
          'before deploying to production. Without pinning, API traffic can be '
          'intercepted on public WiFi via MITM attacks.',
        );
      }
      return true; // Pinning disabled = allow everything (dev mode)
    }
    return pinnedCertificates.any((pin) => pin == sha256Fingerprint);
  }
}

