import 'package:flutter/material.dart';

/// Material 3 Typography scale optimized for tabular numbers and glance-reading.
abstract final class AppTypography {
  /// Hero live throughput rates (e.g. `2.45 MB/s`).
  static const TextStyle displayLarge = TextStyle(
    fontSize: 44.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Consumed plan amounts (e.g. `3.40 GB / 5.0 GB`).
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Card section headers, dialog titles.
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
  );

  /// Screen AppBar titles, App names in modals.
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
  );

  /// App list item titles, Carrier badges.
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  /// Explanatory captions, onboarding body text.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
  );

  /// App package IDs, metric subtitles, timestamps.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );

  /// Action buttons, segmented button labels.
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  /// Status chips, SIM badges, foreground/background tags.
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  /// Creates a unified [TextTheme] based on ByteFlow's typography scale.
  static TextTheme createTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.dark ? Colors.white : Colors.black87;
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: baseColor),
      headlineMedium: headlineMedium.copyWith(color: baseColor),
      headlineSmall: headlineSmall.copyWith(color: baseColor),
      titleLarge: titleLarge.copyWith(color: baseColor),
      titleMedium: titleMedium.copyWith(color: baseColor),
      bodyLarge: bodyLarge.copyWith(color: baseColor.withValues(alpha: 0.87)),
      bodyMedium: bodyMedium.copyWith(color: baseColor.withValues(alpha: 0.70)),
      labelLarge: labelLarge.copyWith(color: baseColor),
      labelSmall: labelSmall.copyWith(color: baseColor.withValues(alpha: 0.85)),
    );
  }
}
