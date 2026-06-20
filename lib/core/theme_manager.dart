import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tema yönetimi için singleton class
class ThemeManager extends ChangeNotifier implements ValueListenable<ThemeMode> {
  
  // İŞTE BURASI DÜZELTİLDİ: LateInitializationError hatasını önler
  static ThemeManager? _instance;
  
  factory ThemeManager() {
    _instance ??= ThemeManager._internal();
    return _instance!;
  }
  
  ThemeManager._internal();

  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  
  @override
  ThemeMode get value => _themeMode;

  Future<void> loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _themeMode = ThemeMode.system;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> changeTheme(ThemeMode newTheme) async {
    if (_themeMode == newTheme) return;
    
    _themeMode = newTheme;
    notifyListeners(); 
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', newTheme.index);
    } catch (e) {
      print('Tema kaydedilemedi: $e');
    }
  }

  String getThemeName(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return 'Sistem Ayarı';
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
    }
  }

  String getThemeDescription(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return 'Cihazın sistem ayarını takip eder';
      case ThemeMode.light:
        return 'Her zaman açık tema kullanır';
      case ThemeMode.dark:
        return 'Her zaman koyu tema kullanır';
    }
  }

  IconData getThemeIcon(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return Icons.settings_system_daydream;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }
}