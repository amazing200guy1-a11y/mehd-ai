import 'package:http/http.dart' as http;

// Conditional import: dart:io implementation on native platforms, web stub on browsers.
// This prevents dart:io symbols (HttpClient, X509Certificate, IOClient) from being
// referenced during a web build, which would cause a compile error.
import 'pinned_http_client_io.dart'
    if (dart.library.js_interop) 'pinned_http_client_web.dart';

/// Returns an HTTP client that enforces SSL certificate pinning on native
/// platforms (Android / iOS / Desktop). On web, browsers manage TLS natively
/// so a plain [http.Client] is returned.
http.Client createPinnedClient() => createClient();
