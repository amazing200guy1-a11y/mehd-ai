import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// FIX 7: Friendly error widget. Never show raw errors to users.
/// Displays a calm, actionable message with retry button.

class FriendlyError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const FriendlyError({
    super.key,
    this.message = 'The Den is temporarily unavailable.',
    this.onRetry,
    this.retryLabel,
  });

  /// Pre-built error states for common scenarios
  factory FriendlyError.denOffline({VoidCallback? onRetry}) => FriendlyError(
    message: 'The Den is temporarily offline. Your data is safe.',
    onRetry: onRetry,
    retryLabel: 'Retry in 30s',
  );

  factory FriendlyError.networkError({VoidCallback? onRetry}) => FriendlyError(
    message: 'Connection lost. Checking your network...',
    onRetry: onRetry,
    retryLabel: 'Reconnect',
  );

  factory FriendlyError.staleData({VoidCallback? onRetry}) => FriendlyError(
    message: 'Market data is stale. Trading locked for your protection.',
    onRetry: onRetry,
    retryLabel: 'Refresh Data',
  );

  factory FriendlyError.analysisTimeout({VoidCallback? onRetry}) => FriendlyError(
    message: 'The Den took too long to respond. Try again.',
    onRetry: onRetry,
    retryLabel: 'Re-analyze',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.yellow.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: MehdAiTheme.yellow, size: 32),
          const SizedBox(height: 16),
          Text(
            message,
            style: MehdAiTheme.terminalStyle.copyWith(
              color: MehdAiTheme.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 4,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                retryLabel ?? 'Retry', 
                style: MehdAiTheme.terminalStyle.copyWith(color: Colors.black), 
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MehdAiTheme.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
