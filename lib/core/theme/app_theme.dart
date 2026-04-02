import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/core/theme/app_typography.dart';

/// Assembles the full Material 3 [ThemeData] for light and dark modes.
///
/// Color tokens  → [AppColors]
/// Text tokens   → [AppTypography]
/// Size tokens   → [AppConstants]
final class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(AppColors.lightScheme);
  static ThemeData get darkTheme => _build(AppColors.darkScheme);

  // ─── Builder ─────────────────────────────────────────────────────────────────

  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: AppTypography.textTheme,

      // ── Scaffold ────────────────────────────────────────────────────────────
      scaffoldBackgroundColor: scheme.surface,

      // ── AppBar ───────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: AppTypography.textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
        ),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: scheme.surface,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: scheme.surface,
              ),
      ),

      // ── BottomNavigationBar ──────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.textTheme.labelSmall,
        unselectedLabelStyle: AppTypography.textTheme.labelSmall,
      ),

      // ── NavigationBar (M3 bottom nav) ────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onPrimaryContainer);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = AppTypography.textTheme.labelSmall;
          if (states.contains(WidgetState.selected)) {
            return base?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600);
          }
          return base?.copyWith(color: scheme.onSurfaceVariant);
        }),
        elevation: 0,
        height: AppConstants.bottomNavHeight,
      ),

      // ── Cards ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: AppConstants.cardElevation,
        color: isLight ? AppColors.slate50 : AppColors.slate800,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusXL)),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusM)),
          ),
          textStyle: AppTypography.textTheme.labelLarge,
          elevation: 0,
        ),
      ),

      // ── Filled Button ────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusM)),
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusM)),
          ),
          side: BorderSide(color: scheme.outline),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppTypography.textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusM)),
          ),
        ),
      ),

      // ── Input / TextField ────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.slate50 : AppColors.slate800,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusM)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppConstants.radiusM)),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppConstants.radiusM)),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppConstants.radiusM)),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppConstants.radiusM)),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        hintStyle: AppTypography.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: AppTypography.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: scheme.primary,
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.slate100 : AppColors.slate700,
        selectedColor: scheme.primaryContainer,
        labelStyle: AppTypography.textTheme.labelMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusS)),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : AppColors.slate800,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusXXL)),
        ),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        elevation: 0,
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? Colors.white : AppColors.slate800,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXXL),
          ),
        ),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),

      // ── Divider ──────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: AppConstants.dividerThickness,
        space: 0,
      ),

      // ── List Tile ────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingS,
        ),
        titleTextStyle: AppTypography.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurface,
        ),
        subtitleTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        iconColor: scheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusM)),
        ),
      ),

      // ── Switch ───────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
      ),

      // ── Progress Indicator ───────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
        linearMinHeight: 6,
      ),

      // ── Snackbar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? AppColors.slate800 : AppColors.slate700,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.slate50,
        ),
        actionTextColor: AppColors.indigo400,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusM)),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Icon ─────────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: scheme.onSurface,
        size: 24,
      ),

      // ── Page transitions ─────────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
