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
  // Core Backgrounds
  static const Color bgPrimary = Color(0xFF0D1117);
  static const Color bgSecondary = Color(0xFF161B22);
  static const Color bgTertiary = Color(0xFF21262D);
  static const Color borderColor = Color(0xFF30363D);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  
  // Semantic / Status Colors
  static const Color green = Color(0xFF3FB950);  // BUY / Profit
  static const Color red = Color(0xFFF85149);    // SELL / Loss
  static const Color yellow = Color(0xFFD29922); // HOLD / Warning
  static const Color blue = Color(0xFF58A6FF);   // Accent / Active
  static const Color purple = Color(0xFFBC8CFF); // System / Kernel

  // Text Styles
  static TextStyle get priceStyle => GoogleFonts.jetBrainsMono(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
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
      ),
      textTheme: TextTheme(
        // All prices and numbers
        displayLarge: GoogleFonts.jetBrainsMono(
          fontSize: 28, color: const Color(0xFF3FB950)),
        // All labels  
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF8B949E)),
        // Terminal text
        bodySmall: GoogleFonts.jetBrainsMono(
          fontSize: 11, color: const Color(0xFF3B4048)),
      ),
      dividerColor: borderColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSecondary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardColor: bgSecondary,
      useMaterial3: true,
    );
  }
}
