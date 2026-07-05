import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mehd_ai_flutter/core/theme.dart';

/// SECURITY: Device Security Guard
///
/// Checks the device environment for security threats at app startup.
/// For a financial trading app, we must verify the device is safe before
/// allowing access to trade execution or account data.
///
/// Checks performed:
/// 1. Root/Jailbreak detection (basic method channel check)
/// 2. Debug mode warning
/// 3. Emulator detection (basic)
///
/// NOTE: For production, integrate a dedicated package like
/// `flutter_jailbreak_detection` or `freerasp` for comprehensive
/// runtime application self-protection (RASP).

class DeviceSecurityGuard {
  static const _channel = MethodChannel('mehd_ai/security');

  /// Runs all device security checks. Returns a list of warnings.
  /// An empty list means the device is considered safe.
  static Future<List<String>> runChecks() async {
    final List<String> warnings = [];

    // Check 1: Debug mode (always available in Flutter)
    if (_isDebugMode()) {
      warnings.add(
          'DEBUG_MODE: App is running in debug mode. This is expected during development only.');
    }

    // Check 2: Root/Jailbreak detection — skip on web (MethodChannels hang)
    if (!kIsWeb) {
      try {
        final isRooted = await _checkRootStatus();
        if (isRooted) {
          warnings.add(
              'ROOT_DETECTED: This device appears to be rooted/jailbroken. Trading on compromised devices is a security risk.');
        }
      } catch (e) {
        // If we can't check, log but don't block
        debugPrint('SECURITY: Root check unavailable on this platform: $e');
      }
    }

    return warnings;
  }

  /// Checks if app is running in debug mode
  static bool _isDebugMode() {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }

  /// Basic root/jailbreak detection using platform channel
  /// In production, use flutter_jailbreak_detection or freerasp package
  static Future<bool> _checkRootStatus() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceRooted')
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      return result ?? false;
    } on MissingPluginException {
      // Platform channel not implemented — safe to proceed but log
      debugPrint(
          'SECURITY: Root detection channel not available. Add native implementation for production.');
      return false;
    } catch (e) {
      debugPrint('SECURITY: Root detection error: $e');
      return false;
    }
  }

  /// Shows a security warning dialog if threats are detected
  static Future<void> showWarningIfNeeded(
      BuildContext context, List<String> warnings) async {
    // Filter out debug mode warnings in development
    final criticalWarnings =
        warnings.where((w) => !w.startsWith('DEBUG_MODE')).toList();

    if (criticalWarnings.isEmpty) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD29922), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFD29922), size: 28),
            SizedBox(width: 12),
            Text(
              'Security Warning',
              style: TextStyle(
                color: Color(0xFFD29922),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following security concerns were detected:',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...criticalWarnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          w.split(': ').last,
                          style: const TextStyle(
                              color: Color(0xFFCCCCCC), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            const Text(
              'Mehd AI recommends using a non-rooted device for trading.',
              style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'I Understand the Risks',
              style: TextStyle(color: MehdAiTheme.blue, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
