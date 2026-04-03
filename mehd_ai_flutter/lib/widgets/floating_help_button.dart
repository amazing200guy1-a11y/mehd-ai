import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/screens/help/support_screen.dart';

class FloatingHelpButton extends StatelessWidget {
  const FloatingHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      child: FloatingActionButton(
        heroTag: 'help_btn',
        mini: true,
        backgroundColor: MehdAiTheme.bgTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: MehdAiTheme.borderColor),
        ),
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SupportScreen()),
          );
        },
        child: const Icon(Icons.question_mark, color: MehdAiTheme.textSecondary, size: 20),
      ),
    );
  }
}
