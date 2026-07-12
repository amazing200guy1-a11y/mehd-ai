import 'package:http/http.dart' as http;

/// Web stub for createClient().
/// On web, browsers handle TLS and certificate pinning natively.
/// This stub simply returns a standard HTTP client.
http.Client createClient() => http.Client();
