import 'package:flutter/material.dart';

/// Design-system typography tokens.
///
/// Built on the Noto Sans font family following the Material 3 type scale.
/// Noto Sans is chosen for its excellent Cyrillic and Latin coverage (RU/KY/EN).
/// All styles use `height` (line-height multiplier) and `letterSpacing`
/// values tuned for Noto Sans metrics.
///
/// Usage:
///   Theme.of(context).textTheme.titleLarge
///   AppTypography.textTheme.bodyMedium
final class AppTypography {
  AppTypography._();

  static const String _font = 'NotoSans';

  // ─── Type scale ──────────────────────────────────────────────────────────────
  //
  // Role            │ Size │ Weight │ Line-h │ Spacing
  // ────────────────┼──────┼────────┼────────┼────────
  // displayLarge    │  57  │ 400    │ 1.12   │ -0.25
  // displayMedium   │  45  │ 400    │ 1.16   │  0
  // displaySmall    │  36  │ 400    │ 1.22   │  0
  // headlineLarge   │  32  │ 600    │ 1.25   │  0
  // headlineMedium  │  28  │ 600    │ 1.29   │  0
  // headlineSmall   │  24  │ 600    │ 1.33   │  0
  // titleLarge      │  22  │ 600    │ 1.27   │  0
  // titleMedium     │  16  │ 600    │ 1.50   │  0.15
  // titleSmall      │  14  │ 500    │ 1.43   │  0.10
  // bodyLarge       │  16  │ 400    │ 1.50   │  0.15
  // bodyMedium      │  14  │ 400    │ 1.43   │  0.25
  // bodySmall       │  12  │ 400    │ 1.33   │  0.40
  // labelLarge      │  14  │ 600    │ 1.43   │  0.10
  // labelMedium     │  12  │ 500    │ 1.33   │  0.50
  // labelSmall      │  11  │ 500    │ 1.45   │  0.50

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _font,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 1.12,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontFamily: _font,
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
      letterSpacing: 0,
    ),
    displaySmall: TextStyle(
      fontFamily: _font,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
      letterSpacing: 0,
    ),
    headlineLarge: TextStyle(
      fontFamily: _font,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontFamily: _font,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontFamily: _font,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontFamily: _font,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontFamily: _font,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.50,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.10,
    ),
    bodyLarge: TextStyle(
      fontFamily: _font,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.50,
      letterSpacing: 0.15,
    ),
    bodyMedium: TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: _font,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.40,
    ),
    labelLarge: TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.10,
    ),
    labelMedium: TextStyle(
      fontFamily: _font,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.50,
    ),
    labelSmall: TextStyle(
      fontFamily: _font,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: 0.50,
    ),
  );
}
