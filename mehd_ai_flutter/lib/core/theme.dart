import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  bool _isDark = true;
  
  ThemeProvider({required this.prefs}) {
    _isDark = prefs.getBool('darkMode') ?? true;
  }

  bool get isDark => _isDark;
  
  ThemeData get theme => MehdAiTheme.getTheme(_isDark);
  
  void setDark(bool dark) async {
    if (_isDark == dark) return;
    _isDark = dark;
    notifyListeners();
    await prefs.setBool('darkMode', dark);
  }
}

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
  // --- Dynamic Color System ---
  // These methods return the correct color based on context brightness.
  
  static Color background(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? bgPrimary : white;
      
  static Color surface(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? bgSecondary : const Color(0xFFF2F2F2);

  static Color border(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? borderColor : const Color(0xFFE5E5E5);

  static Color text(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? textPrimary : const Color(0xFF1A1A1A);

  static Color textDim(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? textSecondary : const Color(0xFF666666);

  // --- Core Backgrounds (Dark Mode Defaults) ---
  static const Color bgPrimary = Color(0xFF030303); // Slightly softer than pure black
  static const Color bgSecondary = Color(0xFF0A0A0A);
  static const Color bgTertiary = Color(0xFF141414);
  static const Color borderColor = Color(0xFF1F1F1F);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF5F5F5); // Slightly softer white
  static const Color textSecondary = Color(0xFF888888);
  
  // Semantic / Status Colors - GLOWING
  static const Color green = Color(0xFF00E676);  // BUY / Profit (softer green)
  static const Color red = Color(0xFFFF3B3B);    // SELL / Loss
  static const Color yellow = Color(0xFFFFD700); // HOLD / Warning
  static const Color amber = Color(0xFFFFC107);  // HOLD / Warning
  static const Color blue = Color(0xFF3B82F6);   // Institutional, richer blue
  static const Color purple = Color(0xFF8B5CF6); // Softer purple
  static const Color gold = Color(0xFFFFD700);   // Premium / Institutional
  static const Color white = Color(0xFFFFFFFF);   // Pure white alias
  static const Color grey = Color(0xFF666666);    // Inactive / Offline
  static const Color shieldColor = Color(0xFF00D1FF); // Sovereign Blue

  // UI Constants
  static const double borderRadius = 12.0;

  // Body text style
  static TextStyle get bodyStyle => GoogleFonts.outfit(
    color: textSecondary,
    fontWeight: FontWeight.w400,
    fontSize: 14,
  );

  // Main UI font — clean and premium
  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 13,
    letterSpacing: 0.5,
    color: const Color(0xFF888888));

  // Data/numbers font — technical
  static TextStyle get dataMono => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    letterSpacing: 0.3,
    color: const Color(0xFFCCCCCC));

  // Headlines — institutional
  static TextStyle get headline => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 3,
    color: blue); // uses blue constant — always in sync

  // Glow Effects (Upgraded to be Soft & Organic)
  static List<BoxShadow> get greenGlow => [
    BoxShadow(color: green.withOpacity(0.15), blurRadius: 20, spreadRadius: 4),
    BoxShadow(color: green.withOpacity(0.05), blurRadius: 40, spreadRadius: 10),
  ];
  
  static List<BoxShadow> get blueGlow => [
    BoxShadow(color: blue.withOpacity(0.15), blurRadius: 20, spreadRadius: 4),
    BoxShadow(color: blue.withOpacity(0.05), blurRadius: 40, spreadRadius: 10),
  ];

  static List<Shadow> get textGlowGreen => [
    const Shadow(color: Colors.greenAccent, blurRadius: 8),
  ];

  static List<Shadow> get textGlowBlue => [
    const Shadow(color: Colors.blueAccent, blurRadius: 8),
  ];

  static List<Shadow> get textGlowRed => [
    const Shadow(color: Colors.redAccent, blurRadius: 8),
  ];

  static List<Shadow> get textGlowWhite => [
    const Shadow(color: Colors.white, blurRadius: 8),
  ];

  static List<Shadow> get textGlowGold => [
    const Shadow(color: Colors.orangeAccent, blurRadius: 8),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(color: gold.withOpacity(0.15), blurRadius: 24, spreadRadius: 4),
    BoxShadow(color: gold.withOpacity(0.05), blurRadius: 48, spreadRadius: 12),
  ];

  static List<BoxShadow> get whiteGlow => [
    BoxShadow(color: white.withOpacity(0.15), blurRadius: 24, spreadRadius: 4),
  ];

  // Gradients (Upgraded to Organic Depth)
  static LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFF151922).withOpacity(0.8), 
      const Color(0xFF080B10).withOpacity(0.9)
    ],
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

  static TextStyle get labelStyle => GoogleFonts.outfit(
        color: textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );

  static TextStyle get terminalStyle => GoogleFonts.jetBrainsMono(
        color: textPrimary,
        fontWeight: FontWeight.normal,
        fontSize: 13,
      );

  static TextStyle get headingStyle => GoogleFonts.plusJakartaSans(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      );

  // Full Theme Data Factory
  static ThemeData getTheme(bool isDark) {
    if (isDark) {
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
          displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 28, color: green, shadows: textGlowGreen),
          bodyMedium: GoogleFonts.outfit(
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
    } else {
      // PREMIUM LIGHT MODE (Paper/Ivory style)
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFBFBFB), // Soft Ivory
        primaryColor: const Color(0xFF0066CC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0066CC),
          secondary: Color(0xFF008855),
          surface: Color(0xFFF2F2F2),
          error: Color(0xFFCC3333),
          onSurface: Color(0xFF1A1A1A),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 28, color: const Color(0xFF008855)),
          bodyMedium: GoogleFonts.outfit(
            fontSize: 14, color: const Color(0xFF666666)),
          bodySmall: GoogleFonts.jetBrainsMono(
            fontSize: 11, color: const Color(0xFF666666)),
        ),
        dividerColor: const Color(0xFFE5E5E5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFBFBFB),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
          titleTextStyle: TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        cardColor: Colors.white,
        useMaterial3: true,
      );
    }
  }
}
