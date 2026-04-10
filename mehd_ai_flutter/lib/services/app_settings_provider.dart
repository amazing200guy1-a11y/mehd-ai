import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  bool _showAgentNames = true;

  AppSettingsProvider({required this.prefs}) {
    _showAgentNames = prefs.getBool('showAgentNames') ?? true;
  }

  bool get showAgentNames => _showAgentNames;

  void setShowAgentNames(bool show) async {
    if (_showAgentNames != show) {
      _showAgentNames = show;
      notifyListeners();
      await prefs.setBool('showAgentNames', show);
    }
  }
}
