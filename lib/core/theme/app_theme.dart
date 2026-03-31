import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color successColor = Color(0xFF22C55E);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Level colors
  static const Map<String, Color> levelColors = {
    'A1': Color(0xFF22C55E),
    'A2': Color(0xFF84CC16),
    'B1': Color(0xFFF59E0B),
    'B2': Color(0xFFEF4444),
    'C1': Color(0xFF8B5CF6),
    'C2': Color(0xFF0EA5E9),
  };

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: cardColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      );
}
