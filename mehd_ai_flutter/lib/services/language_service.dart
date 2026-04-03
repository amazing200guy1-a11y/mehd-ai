import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// FILE — language_service.dart
/// UPGRADE 7: Global Language System
/// Manages the app's current locale and persists it.

class LanguageService extends ChangeNotifier {
  final SharedPreferences prefs;
  static const String _langKey = 'selected_language';
  Locale _currentLocale = const Locale('en');

  LanguageService({required this.prefs}) {
    final langCode = prefs.getString(_langKey);
    if (langCode != null) {
      _currentLocale = Locale(langCode);
    }
  }

  Locale get currentLocale => _currentLocale;

  Future<void> setLocale(Locale newLocale) async {
    if (_currentLocale == newLocale) return;
    _currentLocale = newLocale;
    notifyListeners();
    
    await prefs.setString(_langKey, newLocale.languageCode);
    
    // Save to Firebase (Fix 4)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('language')
          .set({'code': newLocale.languageCode});
    }
  }

  // Helper for UI — all 8 languages for the global grid
  static final List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'status': 'ACTIVE'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'status': 'COMING SOON'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'status': 'COMING SOON'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'status': 'COMING SOON'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷', 'status': 'COMING SOON'},
    {'code': 'id', 'name': 'Bahasa', 'flag': '🇮🇩', 'status': 'COMING SOON'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳', 'status': 'COMING SOON'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺', 'status': 'COMING SOON'},
  ];
}
