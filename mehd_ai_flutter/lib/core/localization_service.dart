import 'package:flutter/material.dart';

class LocalizationService extends ChangeNotifier {
  String _currentLocale = 'en';

  String get currentLocale => _currentLocale;

  bool get isRTL => _currentLocale == 'ar';

  void setLocale(String locale) {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      notifyListeners();
    }
  }

  // Very lightweight translation map for the core phrase
  final Map<String, Map<String, String>> _translations = {
    'en': {
      'capital_seed': 'Capital is a seed, not a sacrifice.',
      'language': 'English',
    },
    'es': {
      'capital_seed': 'El capital es una semilla, no un sacrificio.',
      'language': 'Español',
    },
    'fr': {
      'capital_seed': 'Le capital est une graine, pas un sacrifice.',
      'language': 'Français',
    },
    'de': {
      'capital_seed': 'Kapital ist ein Samen, kein Opfer.',
      'language': 'Deutsch',
    },
    'zh': {
      'capital_seed': '资本是一颗种子，而不是一种牺牲。',
      'language': '中文',
    },
    'ja': {
      'capital_seed': '資本は種であり、犠牲ではない。',
      'language': '日本語',
    },
    'ko': {
      'capital_seed': '자본은 씨앗이지 희생이 아니다.',
      'language': '한국어',
    },
    'ar': {
      'capital_seed': 'رأس المال بذرة، وليس تضحية.',
      'language': 'العربية',
    },
    'ru': {
      'capital_seed': 'Капитал – это семя, а не жертва.',
      'language': 'Русский',
    },
    'pt': {
      'capital_seed': 'O capital é uma semente, não um sacrifício.',
      'language': 'Português',
    },
  };

  String translate(String key) {
    return _translations[_currentLocale]?[key] ?? _translations['en']![key] ?? key;
  }

  List<String> get supportedLocales => _translations.keys.toList();
  
  String getLanguageName(String locale) {
    return _translations[locale]?['language'] ?? locale;
  }
}
