import 'package:flutter/material.dart';

class HusseinAdvmobprogThemeProvider extends ChangeNotifier {
  bool _isDark = true; // Default to dark mode for a dark gray theme

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // Dark Gray & Gray Light Theme Variant
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Colors.grey.shade800,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light gray background
      cardColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: Colors.grey.shade800,
        secondary: Colors.grey.shade600,
        surface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade900,
        elevation: 0,
      ),
    );
  }

  // Dark Gray & Gray Dark Theme Variant
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Colors.grey.shade400,
      scaffoldBackgroundColor: const Color(0xFF121212), // Deep dark gray
      cardColor: const Color(0xFF1E1E1E), // Elevated dark gray card
      colorScheme: ColorScheme.dark(
        primary: Colors.grey.shade300,
        secondary: Colors.grey.shade500,
        surface: const Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}