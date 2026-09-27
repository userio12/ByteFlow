import 'dart:io' show Platform;

/// Cross-platform and Android version inspection utilities.
abstract final class PlatformUtils {
  /// Returns `true` if executing on Android.
  static bool get isAndroid => Platform.isAndroid;

  /// Returns `true` if executing in automated testing environment.
  static bool get isTest => Platform.environment.containsKey('FLUTTER_TEST');
}
