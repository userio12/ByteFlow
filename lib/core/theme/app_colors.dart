import 'package:flutter/material.dart';

/// Semantic color palette, dynamic color harmonization, and OLED dark tokens.
abstract final class AppColors {
  // OLED Dark Backgrounds & Surface Containers
  static const Color oledBackground = Color(0xFF121316);
  static const Color oledSurface = Color(0xFF1A1C20);
  static const Color oledSurfaceContainer = Color(0xFF22242A);
  static const Color oledSurfaceContainerHigh = Color(0xFF2B2E36);
  static const Color oledSurfaceContainerHighest = Color(0xFF353942);

  // Network Interface Tonal Accents
  static const Color cellular = Color(0xFF3B82F6);
  static const Color wifi = Color(0xFF10B981);
  static const Color hotspot = Color(0xFFF59E0B);

  // Traffic Direction Rates
  static const Color downloadRate = Color(0xFF06B6D4);
  static const Color uploadRate = Color(0xFFEC4899);

  // Foreground vs Background App Data Split
  static const Color foregroundUsage = Color(0xFF10B981);
  static const Color backgroundUsage = Color(0xFFF97316);

  // Plan Quota Status Indicators
  static const Color statusNormal = Color(0xFF22C55E);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusCritical = Color(0xFFEF4444);

  /// Returns appropriate status color based on percentage of quota consumed (0-100).
  static Color statusForUsagePercent(
    double percent, {
    double warningThreshold = 80.0,
    double alertThreshold = 90.0,
  }) {
    if (percent >= alertThreshold) {
      return statusCritical;
    } else if (percent >= warningThreshold) {
      return statusWarning;
    }
    return statusNormal;
  }
}
