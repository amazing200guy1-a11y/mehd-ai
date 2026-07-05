import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class LegalWarningDialog extends StatelessWidget {
  const LegalWarningDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LegalWarningDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MehdAiTheme.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: MehdAiTheme.red, width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: MehdAiTheme.red, size: 28),
          const SizedBox(width: 12),
          Text(
            'HIGH RISK WARNING',
            style: MehdAiTheme.headingStyle.copyWith(
              color: MehdAiTheme.red,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are about to enable AI-assisted trading.',
            style: MehdAiTheme.labelStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Trading on margin involves significant risk of capital loss. Mehd AI is a decision-support tool, not financial advice. Past performance does not guarantee future results.',
            style: MehdAiTheme.labelStyle.copyWith(
              color: MehdAiTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'By proceeding, you acknowledge that you assume full responsibility for all trades executed and any resulting losses.',
            style: MehdAiTheme.labelStyle.copyWith(
              color: MehdAiTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'CANCEL',
            style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: MehdAiTheme.red.withOpacity(0.2),
            side: const BorderSide(color: MehdAiTheme.red),
          ),
          child: Text(
            'I AGREE',
            style: MehdAiTheme.labelStyle.copyWith(
              color: MehdAiTheme.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
