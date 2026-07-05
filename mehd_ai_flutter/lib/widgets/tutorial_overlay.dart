import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class TutorialItem {
  final String title;
  final String description;
  final Widget? leading;

  const TutorialItem({
    required this.title,
    required this.description,
    this.leading,
  });
}

class TutorialOverlay extends StatelessWidget {
  final String screenKey;
  final String title;
  final String subtitle;
  final List<TutorialItem> items;

  const TutorialOverlay({
    super.key,
    required this.screenKey,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  /// Automatically shows the tutorial if it hasn't been seen yet.
  static Future<void> checkAndShow({
    required BuildContext context,
    required String screenKey,
    required String title,
    required String subtitle,
    required List<TutorialItem> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('tutorial_$screenKey') ?? false;

    if (!hasSeen) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => TutorialOverlay(
          screenKey: screenKey,
          title: title,
          subtitle: subtitle,
          items: items,
        ),
      );
      await prefs.setBool('tutorial_$screenKey', true);
    }
  }

  /// Forces the tutorial to show (e.g. for a Help button)
  static Future<void> forceShow({
    required BuildContext context,
    required String screenKey,
    required String title,
    required String subtitle,
    required List<TutorialItem> items,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TutorialOverlay(
        screenKey: screenKey,
        title: title,
        subtitle: subtitle,
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 650),
            decoration: BoxDecoration(
              color: const Color(0xFF080808).withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        MehdAiTheme.blue.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: MehdAiTheme.blue.withOpacity(0.15),
                          border: Border.all(color: MehdAiTheme.blue.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.school_rounded, color: MehdAiTheme.blue, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.leading != null) ...[
                              item.leading!,
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                
                // Action Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MehdAiTheme.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'I Understand',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
