import 'package:flutter/material.dart';

class AppColors {
  // YENİ HAKİ YEŞİL RENGİ
  static const Color primary = Color(0xFF4E7D55); 
  static const Color secondary = Color(0xFFFFC107);
  
  // Diğer renkler aynen kalıyor
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color textLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? backgroundDark 
        : backgroundLight;
  }
  
  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? surfaceDark 
        : surfaceLight;
  }
  
  static Color text(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? textDark 
        : textLight;
  }
  
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? textSecondaryDark 
        : textSecondaryLight;
  }
  
  static Color getPrayerColor(BuildContext context) {
    return primary;
  }
  
  static Color primaryLight(BuildContext context) {
    return primary.withOpacity(0.1);
  }
  
  static Color primaryDark(BuildContext context) {
    return primary.withOpacity(0.8);
  }
}