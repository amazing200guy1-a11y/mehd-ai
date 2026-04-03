import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FILE 1 — theme.dart
/// Mehd AI Design System
///
/// Build Debrief:
/// This file defines the entire visual language of the application. By centralizing
/// colors, typography, and the ThemeData, we ensure the app looks consistently like a
/// premium IDE rather than a generic mobile app. The use of JetBrains Mono for data 
/// and Inter for labels provides that "dev tool" aesthetic.
/// A consistent design system is crucial because it builds trust. If traders see 
/// misaligned components or inconsistent colors, they will subconsciously distrust 
/// the platform with their money.

class MehdAiTheme {
  // Core Backgrounds - PURE BLACK
  static const Color bgPrimary = Color(0xFF000000);
  static const Color bgSecondary = Color(0xFF080808);
  static const Color bgTertiary = Color(0xFF111111);
  static const Color borderColor = Color(0xFF1A1A1A);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  
  // Semantic / Status Colors - GLOWING
  static const Color green = Color(0xFF00FF88);  // BUY / Profit
  static const Color red = Color(0xFFFF3B3B);    // SELL / Loss
  static const Color yellow = Color(0xFFFFD700); // HOLD / Warning
  static const Color blue = Color(0xFF58A6FF);   // Accent / Active
  static const Color purple = Color(0xFFBD93F9); // System / Kernel
  static const Color gold = Color(0xFFFFD700);   // Premium / Institutional
  static const Color white = Color(0xFFFFFFFF);   // Pure white alias
  static const Color shieldColor = Color(0xFF00D1FF); // Sovereign Blue

  // Border alias for convenience
  static const Color border = borderColor;

  // Body text style
  static TextStyle get bodyStyle => GoogleFonts.inter(
    color: textSecondary,
    fontWeight: FontWeight.w400,
    fontSize: 14,
  );

  // Glow Effects
  static List<BoxShadow> get greenGlow => [
    BoxShadow(color: green.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
  ];
  
  static List<BoxShadow> get blueGlow => [
    BoxShadow(color: blue.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
  ];

  static List<Shadow> get textGlowGreen => [
    Shadow(color: green.withOpacity(0.5), blurRadius: 4),
  ];

  static List<Shadow> get textGlowBlue => [
    Shadow(color: blue.withOpacity(0.5), blurRadius: 4),
  ];

  static List<Shadow> get textGlowRed => [
    Shadow(color: red.withOpacity(0.5), blurRadius: 4),
  ];

  static List<Shadow> get textGlowWhite => [
    Shadow(color: white.withOpacity(0.8), blurRadius: 8),
  ];

  static List<Shadow> get textGlowGold => [
    Shadow(color: gold.withOpacity(0.5), blurRadius: 4),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(color: gold.withOpacity(0.3), blurRadius: 12, spreadRadius: 2),
  ];

  static List<BoxShadow> get whiteGlow => [
    BoxShadow(color: white.withOpacity(0.5), blurRadius: 12, spreadRadius: 2),
  ];

  // Gradients
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF000000), Color(0xFF0A0A0A)],
  );

  // Text Styles
  static TextStyle get priceStyle => GoogleFonts.jetBrainsMono(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
        shadows: textGlowGreen,
      );

  static TextStyle get priceStyleRed => GoogleFonts.jetBrainsMono(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
        shadows: [Shadow(color: red.withOpacity(0.5), blurRadius: 4)],
      );

  static TextStyle get labelStyle => GoogleFonts.inter(
        color: textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );

  static TextStyle get terminalStyle => GoogleFonts.jetBrainsMono(
        color: textPrimary,
        fontWeight: FontWeight.normal,
        fontSize: 13,
      );

  static TextStyle get headingStyle => GoogleFonts.inter(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      );

  // Full Theme Data
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: blue,
      colorScheme: const ColorScheme.dark(
        primary: blue,
        secondary: green,
        surface: bgSecondary,
        error: red,
        onSurface: textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.jetBrainsMono(
          fontSize: 28, color: green, shadows: textGlowGreen),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.jetBrainsMono(
          fontSize: 11, color: textSecondary),
      ),
      dividerColor: borderColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      cardColor: bgSecondary,
      useMaterial3: true,
    );
  }
}
