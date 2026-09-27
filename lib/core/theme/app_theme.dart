import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Material 3 theme configurations supporting Monet dynamic colors and OLED Dark surfaces.
abstract final class AppTheme {
  static const Color defaultSeedColor = Color(0xFF3B82F6);

  /// Default fallback light color scheme.
  static final ColorScheme defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: defaultSeedColor,
    brightness: Brightness.light,
  );

  /// Default fallback OLED dark color scheme.
  static final ColorScheme defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: defaultSeedColor,
    brightness: Brightness.dark,
    surface: AppColors.oledSurface,
  ).copyWith(
    surface: AppColors.oledSurface,
  );

  /// Builds the light [ThemeData] using optional [dynamicColorScheme].
  static ThemeData lightTheme([ColorScheme? dynamicColorScheme]) {
    final colorScheme = dynamicColorScheme ?? defaultLightColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.createTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surfaceContainerLow,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.secondaryContainer,
      ),
    );
  }

  /// Builds the OLED dark [ThemeData] using optional [dynamicColorScheme].
  static ThemeData darkTheme([ColorScheme? dynamicColorScheme]) {
    final baseScheme = dynamicColorScheme ?? defaultDarkColorScheme;
    final colorScheme = baseScheme.copyWith(
      surface: AppColors.oledSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.oledBackground,
      colorScheme: colorScheme,
      textTheme: AppTypography.createTextTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.oledBackground,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.oledSurfaceContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.oledBackground,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.secondaryContainer,
      ),
    );
  }
}
