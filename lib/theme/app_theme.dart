import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand palette
// ─────────────────────────────────────────────────────────────────────────────

/// Primary brand blue — used as the keystone for both light and dark themes.
const _kBrandBlue = Color(0xFF1A6FDB);
const _kBrandBlueDark =
    Color(0xFF4A9EFF); // lighter tint for dark mode legibility

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  // ── Shared typography ───────────────────────────────────────────────────────

  static const _fontFamily = 'Inter';

  static TextTheme _textTheme(ColorScheme cs) => TextTheme(
        displayLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: cs.onSurface,
        ),
        displayMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          color: cs.onSurface,
        ),
        headlineLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: cs.onSurface,
        ),
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: cs.onSurface,
        ),
        headlineSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        titleLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: cs.onSurface,
        ),
        titleMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: cs.onSurface,
        ),
        titleSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: cs.onSurface,
        ),
        bodyLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.15,
          color: cs.onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.25,
          color: cs.onSurface,
        ),
        bodySmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          letterSpacing: 0.4,
          color: cs.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: cs.onSurface,
        ),
        labelMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: cs.onSurface,
        ),
        labelSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: cs.onSurfaceVariant,
        ),
      );

  // ── Shared component overrides ───────────────────────────────────────────────

  static InputDecorationTheme _inputTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withAlpha(80)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          color: cs.onSurfaceVariant,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          color: cs.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return cs.primary;
          if (states.contains(WidgetState.error)) return cs.error;
          return cs.onSurfaceVariant;
        }),
        errorStyle: TextStyle(
          fontFamily: _fontFamily,
          color: cs.error,
          fontSize: 12,
        ),
      );

  static FilledButtonThemeData _filledButtonTheme(ColorScheme cs) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: cs.outline.withAlpha(120)),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme(ColorScheme cs) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  static CardThemeData _cardTheme(ColorScheme cs) => CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
        ),
        color: cs.surfaceContainerLow,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      );

  static AppBarTheme _appBarTheme(ColorScheme cs, Brightness brightness) =>
      AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: cs.onSurface,
        ),
        iconTheme: IconThemeData(color: cs.onSurface, size: 22),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: cs.surface,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: cs.surface,
              ),
      );

  static NavigationBarThemeData _navBarTheme(ColorScheme cs) =>
      NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: _fontFamily,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          );
        }),
      );

  static SnackBarThemeData _snackBarTheme(ColorScheme cs) => SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: cs.onInverseSurface,
          fontSize: 14,
        ),
        actionTextColor: cs.inversePrimary,
        elevation: 4,
      );

  static DividerThemeData _dividerTheme(ColorScheme cs) => DividerThemeData(
        color: cs.outlineVariant.withAlpha(60),
        thickness: 1,
        space: 1,
      );

  static ChipThemeData _chipTheme(ColorScheme cs) => ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
        ),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      );

  static IconButtonThemeData _iconButtonTheme(ColorScheme cs) =>
      IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: cs.onSurfaceVariant,
          highlightColor: cs.primary.withAlpha(20),
        ),
      );

  // ── Light Theme ──────────────────────────────────────────────────────────────

  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: _kBrandBlue,
      brightness: Brightness.light,
      // Hand-tuned surface hierarchy for a clean, airy feel
      surface: const Color(0xFFF8F9FC),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF1F4FA),
      surfaceContainer: const Color(0xFFE8EDF5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      fontFamily: _fontFamily,
      textTheme: _textTheme(cs),
      inputDecorationTheme: _inputTheme(cs),
      filledButtonTheme: _filledButtonTheme(cs),
      outlinedButtonTheme: _outlinedButtonTheme(cs),
      textButtonTheme: _textButtonTheme(cs),
      cardTheme: _cardTheme(cs),
      appBarTheme: _appBarTheme(cs, Brightness.light),
      navigationBarTheme: _navBarTheme(cs),
      snackBarTheme: _snackBarTheme(cs),
      dividerTheme: _dividerTheme(cs),
      chipTheme: _chipTheme(cs),
      iconButtonTheme: _iconButtonTheme(cs),
      scaffoldBackgroundColor: cs.surface,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────────

  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
      seedColor: _kBrandBlueDark,
      brightness: Brightness.dark,
      // Deep navy surface stack — avoids pure black for more premium feel
      surface: const Color(0xFF0F1923),
      surfaceContainerLowest: const Color(0xFF141D28),
      surfaceContainerLow: const Color(0xFF19232F),
      surfaceContainer: const Color(0xFF1F2D3D),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      fontFamily: _fontFamily,
      textTheme: _textTheme(cs),
      inputDecorationTheme: _inputTheme(cs),
      filledButtonTheme: _filledButtonTheme(cs),
      outlinedButtonTheme: _outlinedButtonTheme(cs),
      textButtonTheme: _textButtonTheme(cs),
      cardTheme: _cardTheme(cs),
      appBarTheme: _appBarTheme(cs, Brightness.dark),
      navigationBarTheme: _navBarTheme(cs),
      snackBarTheme: _snackBarTheme(cs),
      dividerTheme: _dividerTheme(cs),
      chipTheme: _chipTheme(cs),
      iconButtonTheme: _iconButtonTheme(cs),
      scaffoldBackgroundColor: cs.surface,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
