import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'theme_mode'; // ⭐️ persistencia
  //ThemeMode es un enum {system, light, dark}
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;
  Future<void> _cargarTema() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_prefKey);

    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (mode == 'light') {
      _themeMode = ThemeMode.light;
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_prefKey, 'dark');
    } else if (mode == ThemeMode.light) {
      await prefs.setString(_prefKey, 'light');
      await prefs.remove(_prefKey);
    }
  }

  Future<void> toggleDark(bool enable) async {
    await setThemeMode(enable ? ThemeMode.dark : ThemeMode.light);
  }

  //método para cambiar el tema
  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
