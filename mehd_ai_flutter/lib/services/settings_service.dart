import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService extends ChangeNotifier {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool _darkMode = true;
  bool _tradeSignals = true;
  bool _autoStopLoss = true;
  bool _guardianAlerts = true;
  bool _showAgentNames = true;
  bool _shadowMode = false;
  bool _paperMode = true;
  String _language = 'English';

  bool get darkMode => _darkMode;
  bool get tradeSignals => _tradeSignals;
  bool get autoStopLoss => _autoStopLoss;
  bool get guardianAlerts => _guardianAlerts;
  bool get showAgentNames => _showAgentNames;
  bool get shadowMode => _shadowMode;
  bool get paperMode => _paperMode;
  String get language => _language;

  Future<void> load() async {
    final p = await _prefs;
    _darkMode = p.getBool('darkMode') ?? true;
    _tradeSignals = p.getBool('signals') ?? true;
    _autoStopLoss = p.getBool('autoSL') ?? true;
    _guardianAlerts = p.getBool('guardian') ?? true;
    _showAgentNames = p.getBool('agentNames') ?? true;
    _shadowMode = p.getBool('shadow') ?? false;
    _paperMode = p.getBool('paper') ?? true;
    _language = p.getString('language') ?? 'English';
    notifyListeners();
  }

  Future<void> _save(String key, dynamic val) async {
    final p = await _prefs;
    if (val is bool) await p.setBool(key, val);
    if (val is String) await p.setString(key, val);
    
    // Sync to Firebase if user is logged in
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('settings').doc('prefs')
          .set({key: val}, SetOptions(merge: true));
      } catch (e) {
        // Ignored
      }
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    await _save('darkMode', v);
  }

  Future<void> setTradeSignals(bool v) async {
    _tradeSignals = v;
    await _save('signals', v);
  }

  Future<void> setAutoStopLoss(bool v) async {
    _autoStopLoss = v;
    await _save('autoSL', v);
  }

  Future<void> setGuardianAlerts(bool v) async {
    _guardianAlerts = v;
    await _save('guardian', v);
  }

  Future<void> setShowAgentNames(bool v) async {
    _showAgentNames = v;
    await _save('agentNames', v);
  }

  Future<void> setShadowMode(bool v) async {
    _shadowMode = v;
    await _save('shadow', v);
    // Update Firebase visibility on parent user document:
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .update({'shadowMode': v});
      } catch (e) {
        // Ignored
      }
    }
  }

  Future<void> setPaperMode(bool v) async {
    _paperMode = v;
    await _save('paper', v);
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _save('language', lang);
  }

  Future<void> clearLocal() async {
    final p = await _prefs;
    await p.clear();
    await load();
  }
}
