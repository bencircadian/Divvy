import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum ThemeModeOption { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  ThemeModeOption _themeMode = ThemeModeOption.system;

  ThemeModeOption get themeMode => _themeMode;

  ThemeMode get effectiveThemeMode {
    switch (_themeMode) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode {
    if (_themeMode == ThemeModeOption.dark) return true;
    if (_themeMode == ThemeModeOption.light) return false;
    // System mode - check platform brightness
    return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  void setThemeMode(ThemeModeOption mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeModeOption.light) {
      _themeMode = ThemeModeOption.dark;
    } else {
      _themeMode = ThemeModeOption.light;
    }
    notifyListeners();
  }
}
