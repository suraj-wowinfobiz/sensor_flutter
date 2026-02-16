import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1f7bcf),
      secondary: Color(0xFFe68a2e),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFd64545),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF0a1a2a),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFf4f9ff),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3290df),
      secondary: Color(0xFFd97e2a),
      surface: Color(0xFF1d3852),
      error: Color(0xFFcc4a4a),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFe8f1fc),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0e1b2a),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF1d3852),
    ),
  );
}
