import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class WeeklyScanCard extends StatelessWidget {
  final Map<String, dynamic> scanData;
  final VoidCallback onDismiss;

  const WeeklyScanCard({
    super.key,
    required this.scanData,
    required this.onDismiss,
  });

  /// Returns a human-readable freshness string, e.g. "3 days ago" or "2 hours ago".
  String _buildFreshnessLabel() {
    final generatedAt = scanData['generated_at'] as String?;
    if (generatedAt == null) return '';
    try {
      final dt = DateTime.parse(generatedAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays >= 1) return 'Generated ${diff.inDays}d ago';
      if (diff.inHours >= 1) return 'Generated ${diff.inHours}h ago';
      return 'Generated just now';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = scanData['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) return const SizedBox.shrink();
    final freshnessLabel = _buildFreshnessLabel();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1929),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MehdAiTheme.gold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: MehdAiTheme.gold.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.auto_graph, color: MehdAiTheme.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'YOUR WEEKLY AI SCAN',
                        style: MehdAiTheme.terminalStyle.copyWith(
                          color: MehdAiTheme.gold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      if (freshnessLabel.isNotEmpty) ...
                        [
                          const SizedBox(height: 2),
                          Text(
                            freshnessLabel,
                            style: MehdAiTheme.terminalStyle.copyWith(
                              color: const Color(0xFF666666),
                              fontSize: 10,
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, color: Color(0xFF666666), size: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Den has analyzed the top pairs for the upcoming week based on your free tier allocation.',
                  style: MehdAiTheme.terminalStyle.copyWith(
                    color: const Color(0xFFAAAAAA),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ...results.map((r) => _buildResultRow(r as Map<String, dynamic>)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(Map<String, dynamic> result) {
    final direction = result['direction'] ?? 'HOLD';
    final symbol = result['symbol'] ?? '';
    // FIX Cast-01: JSON decodes numbers without a decimal point as `int`, not `double`.
    // Using `as double` would throw TypeError at runtime (e.g. confidence = 85, not 85.0).
    final confidence = (result['confidence'] ?? 0).toDouble();
    
    Color dirColor = MehdAiTheme.textSecondary;
    if (direction == 'BUY') dirColor = MehdAiTheme.green;
    if (direction == 'SELL') dirColor = MehdAiTheme.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            symbol,
            style: MehdAiTheme.terminalStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dirColor.withOpacity(0.1),
                  border: Border.all(color: dirColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  direction,
                  style: MehdAiTheme.terminalStyle.copyWith(
                    color: dirColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${confidence.toStringAsFixed(1)}%',
                style: MehdAiTheme.terminalStyle.copyWith(
                  color: MehdAiTheme.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
