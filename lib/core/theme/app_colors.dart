import 'package:flutter/material.dart';

/// Design-system color tokens.
///
/// Usage:
///   Theme.of(context).colorScheme.primary          — Material slots
///   AppColors.success / AppColors.warning           — semantic extras
///   AppColors.level['B1']                           — level badges
///
/// Never use raw hex values outside this file.
final class AppColors {
  AppColors._();

  // ─── Brand palette ──────────────────────────────────────────────────────────

  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color indigo900 = Color(0xFF1E1B4B);

  static const Color sky300 = Color(0xFF7DD3FC);
  static const Color sky400 = Color(0xFF38BDF8);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky600 = Color(0xFF0284C7);
  static const Color sky800 = Color(0xFF075985);
  static const Color sky900 = Color(0xFF0C4A6E);

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // ─── Semantic extras (not in Material ColorScheme) ──────────────────────────

  /// Success — green
  static const Color successLight = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color successContainerLight = Color(0xFFDCFCE7);
  static const Color successContainerDark = Color(0xFF166534);

  /// Warning — amber
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFCD34D);
  static const Color warningContainerLight = Color(0xFFFEF3C7);
  static const Color warningContainerDark = Color(0xFF92400E);

  // ─── Level badge colors ──────────────────────────────────────────────────────

  static const Map<String, Color> level = {
    'A1': Color(0xFF22C55E), // green-500
    'A2': Color(0xFF84CC16), // lime-500
    'B1': Color(0xFFF59E0B), // amber-500
    'B2': Color(0xFFEF4444), // red-500
    'C1': Color(0xFF8B5CF6), // violet-500
    'C2': Color(0xFF0EA5E9), // sky-500
  };

  // ─── ColorScheme light ───────────────────────────────────────────────────────

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary — Indigo
    primary: indigo600,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: indigo100,
    onPrimaryContainer: indigo900,

    // Secondary — Sky
    secondary: sky500,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0F2FE),
    onSecondaryContainer: sky900,

    // Tertiary — reuse for success green
    tertiary: Color(0xFF22C55E),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDCFCE7),
    onTertiaryContainer: Color(0xFF14532D),

    // Error — Red
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),

    // Surfaces
    surface: Color(0xFFFFFFFF),
    onSurface: slate900,
    surfaceContainerHighest: slate100,
    surfaceContainerHigh: slate100,
    surfaceContainer: slate50,
    surfaceContainerLow: Color(0xFFFCFDFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceDim: slate200,
    surfaceBright: Color(0xFFFFFFFF),

    onSurfaceVariant: slate500,
    outline: slate300,
    outlineVariant: slate200,

    // Inverse
    inverseSurface: slate800,
    onInverseSurface: slate50,
    inversePrimary: indigo400,

    // Scrim & shadow
    scrim: Color(0xFF000000),
    shadow: Color(0xFF000000),

    // Surface tint (used by elevated surfaces in M3)
    surfaceTint: indigo600,
  );

  // ─── ColorScheme dark ────────────────────────────────────────────────────────

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,

    // Primary — lighter Indigo
    primary: indigo400,
    onPrimary: indigo900,
    primaryContainer: indigo800,
    onPrimaryContainer: indigo100,

    // Secondary — lighter Sky
    secondary: sky400,
    onSecondary: sky900,
    secondaryContainer: sky800,
    onSecondaryContainer: Color(0xFFE0F2FE),

    // Tertiary — lighter Green
    tertiary: Color(0xFF4ADE80),
    onTertiary: Color(0xFF14532D),
    tertiaryContainer: Color(0xFF166534),
    onTertiaryContainer: Color(0xFFDCFCE7),

    // Error — lighter Red
    error: Color(0xFFF87171),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFEE2E2),

    // Surfaces
    surface: slate900,
    onSurface: slate50,
    surfaceContainerHighest: slate700,
    surfaceContainerHigh: slate700,
    surfaceContainer: slate800,
    surfaceContainerLow: slate800,
    surfaceContainerLowest: slate950,
    surfaceDim: slate950,
    surfaceBright: slate700,

    onSurfaceVariant: slate400,
    outline: slate600,
    outlineVariant: slate700,

    // Inverse
    inverseSurface: slate100,
    onInverseSurface: slate900,
    inversePrimary: indigo600,

    // Scrim & shadow
    scrim: Color(0xFF000000),
    shadow: Color(0xFF000000),

    // Surface tint
    surfaceTint: indigo400,
  );
}
