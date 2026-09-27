/// Channel and method names connecting Flutter to the native Android subsystem.
abstract final class ChannelConstants {
  /// MethodChannel name for network queries, permissions, and service controls.
  static const String methodChannelName = 'com.byteflow/network_v1';

  /// EventChannel name for real-time throughput stream updates.
  static const String speedStreamChannelName = 'com.byteflow/speed_stream_v1';

  // Method names
  static const String methodHasUsagePermission = 'hasUsagePermission';
  static const String methodRequestUsagePermission = 'requestUsagePermission';
  static const String methodOpenUsageSettings = 'openUsageSettings';
  static const String methodHasPhoneStatePermission = 'hasPhoneStatePermission';
  static const String methodGetSimCards = 'getSimCards';
  static const String methodGetDeviceTotal = 'getDeviceTotal';
  static const String methodGetAppsUsage = 'getAppsUsage';
  static const String methodGetTimeBuckets = 'getTimeBuckets';
  static const String methodStartLiveSpeedService = 'startLiveSpeedService';
  static const String methodStopLiveSpeedService = 'stopLiveSpeedService';
  static const String methodIsLiveSpeedServiceRunning = 'isLiveSpeedServiceRunning';
  static const String methodUpdateWidgetData = 'updateWidgetData';
  static const String methodLaunchApp = 'launchApp';
  static const String methodOpenAppDetails = 'openAppDetails';
  static const String methodIsIgnoringBatteryOptimizations = 'isIgnoringBatteryOptimizations';
  static const String methodRequestIgnoreBatteryOptimizations = 'requestIgnoreBatteryOptimizations';
  static const String methodSendQuotaNotification = 'sendQuotaNotification';

  // Network type constants aligned with ConnectivityManager
  static const int networkTypeMobile = 0;
  static const int networkTypeWifi = 1;
  static const int networkTypeAll = -1;
}
