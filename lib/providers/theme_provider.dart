import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active [ThemeMode] and persists it across launches.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool isDark(BuildContext context) {
    if (_mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  /// Loads the saved preference; safe to call before runApp.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        _mode = ThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (_) {
      // Ignore storage errors (e.g. restricted web environments).
    }
  }

  /// Flips between light and dark based on what's currently shown.
  Future<void> toggle(BuildContext context) async {
    final next = isDark(context) ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // Non-fatal: the toggle still applies for this session.
    }
  }
}
