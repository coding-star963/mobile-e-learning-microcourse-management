import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light / dark mode. The student's choice is kept on this device; dark
/// (the app's original look) is the default.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ThemeMode initial = ThemeMode.dark}) : _mode = initial;

  static const String _key = 'theme_mode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  /// Loads the saved choice (called once on app start).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = ThemeMode.values.where((m) => m.name == prefs.getString(_key));
      if (saved.isNotEmpty && saved.first != _mode) {
        _mode = saved.first;
        notifyListeners();
      }
    } catch (_) {
      // Keep the default when storage is unavailable.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }

  /// Switches between light and dark from the app bar; [current] is the
  /// brightness on screen now (it may come from the system setting).
  Future<void> toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
