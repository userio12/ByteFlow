import 'dart:async';
import 'package:flutter/services.dart';
import '../../core/constants/channel_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/app_usage_dto.dart';
import '../models/network_summary_dto.dart';
import '../models/sim_info_dto.dart';
import '../models/speed_sample_dto.dart';
import '../models/usage_time_bucket_dto.dart';

/// Stateless platform channel client communicating with Android native subsystem.
class NativeNetworkService {
  final MethodChannel _methodChannel;
  final EventChannel _speedEventChannel;

  NativeNetworkService({
    MethodChannel? methodChannel,
    EventChannel? speedEventChannel,
  })  : _methodChannel = methodChannel ??
            const MethodChannel(ChannelConstants.methodChannelName),
        _speedEventChannel = speedEventChannel ??
            const EventChannel(ChannelConstants.speedStreamChannelName);

  /// Checks whether PACKAGE_USAGE_STATS is granted.
  Future<bool> hasUsagePermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodHasUsagePermission,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to check usage stats permission.',
        details: e.details,
      );
    }
  }

  /// Opens system Usage Access Settings.
  Future<bool> openUsageSettings() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodOpenUsageSettings,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to open usage access settings.',
        details: e.details,
      );
    }
  }

  /// Checks whether READ_PHONE_STATE is granted.
  Future<bool> hasPhoneStatePermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodHasPhoneStatePermission,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to check phone state permission.',
        details: e.details,
      );
    }
  }

  /// Queries active SIM cards metadata from SubscriptionManager.
  Future<List<SimInfoDto>> getSimCards() async {
    try {
      final rawList = await _methodChannel.invokeListMethod<dynamic>(
        ChannelConstants.methodGetSimCards,
      );
      if (rawList == null) return const [];
      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => SimInfoDto.fromMap(m))
          .toList();
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to query SIM cards.',
        details: e.details,
      );
    }
  }

  /// Dynamically queries hardware kernel device totals for arbitrary epoch window.
  Future<NetworkSummaryDto> getDeviceTotal({
    required int startTimeMs,
    required int endTimeMs,
  }) async {
    try {
      final rawMap = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
        ChannelConstants.methodGetDeviceTotal,
        {
          'startTimeMs': startTimeMs,
          'endTimeMs': endTimeMs,
        },
      );
      if (rawMap == null) {
        return NetworkSummaryDto(
          startTimeMs: startTimeMs,
          endTimeMs: endTimeMs,
        );
      }
      return NetworkSummaryDto.fromMap(rawMap);
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to query device total from kernel.',
        details: e.details,
      );
    }
  }

  /// Dynamically queries per-app UID usage across the requested timeframe.
  Future<List<AppUsageDto>> getAppsUsage({
    int networkType = ChannelConstants.networkTypeAll,
    required int startTimeMs,
    required int endTimeMs,
    bool includeIcons = true,
  }) async {
    try {
      final rawList = await _methodChannel.invokeListMethod<dynamic>(
        ChannelConstants.methodGetAppsUsage,
        {
          'networkType': networkType,
          'startTimeMs': startTimeMs,
          'endTimeMs': endTimeMs,
          'includeIcons': includeIcons,
        },
      );
      if (rawList == null) return const [];
      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => AppUsageDto.fromMap(m))
          .toList();
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to query app usage from kernel.',
        details: e.details,
      );
    }
  }

  /// Dynamically slices a timeframe into discrete buckets (e.g. 24 hourly buckets).
  Future<List<UsageTimeBucketDto>> getTimeBuckets({
    int networkType = ChannelConstants.networkTypeMobile,
    required int startTimeMs,
    required int endTimeMs,
    int stepIntervalMs = 3600000,
  }) async {
    try {
      final rawList = await _methodChannel.invokeListMethod<dynamic>(
        ChannelConstants.methodGetTimeBuckets,
        {
          'networkType': networkType,
          'startTimeMs': startTimeMs,
          'endTimeMs': endTimeMs,
          'stepIntervalMs': stepIntervalMs,
        },
      );
      if (rawList == null) return const [];
      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => UsageTimeBucketDto.fromMap(m))
          .toList();
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to query time buckets from kernel.',
        details: e.details,
      );
    }
  }

  /// Starts the ongoing low-priority LiveSpeedService.
  Future<bool> startLiveSpeedService({int intervalMs = 1000}) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodStartLiveSpeedService,
        {'intervalMs': intervalMs},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to start LiveSpeedService.',
        details: e.details,
      );
    }
  }

  /// Halts the LiveSpeedService foreground notification.
  Future<bool> stopLiveSpeedService() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodStopLiveSpeedService,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to stop LiveSpeedService.',
        details: e.details,
      );
    }
  }

  /// Checks if LiveSpeedService is actively running in foreground.
  Future<bool> isLiveSpeedServiceRunning() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodIsLiveSpeedServiceRunning,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to check LiveSpeedService status.',
        details: e.details,
      );
    }
  }

  /// Pushes updated metrics to native Android Home Screen AppWidget RemoteViews.
  Future<bool> updateWidgetData({
    required String carrier,
    required String simBadge,
    required int mobileBytes,
    required int wifiBytes,
    required int quotaBytes,
    required String quotaText,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodUpdateWidgetData,
        {
          'carrier': carrier,
          'simBadge': simBadge,
          'mobileBytes': mobileBytes,
          'wifiBytes': wifiBytes,
          'quotaBytes': quotaBytes,
          'quotaText': quotaText,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to update native AppWidget.',
        details: e.details,
      );
    }
  }

  /// Launches an application via Android's PackageManager by package name.
  Future<bool> launchApp(String packageName) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodLaunchApp,
        {'packageName': packageName},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to launch app $packageName.',
        details: e.details,
      );
    }
  }

  /// Opens Android System Application Details Settings for the specified package.
  Future<bool> openAppDetails(String packageName) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodOpenAppDetails,
        {'packageName': packageName},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to open app details for $packageName.',
        details: e.details,
      );
    }
  }

  /// Checks if ByteFlow is whitelisted / ignoring battery optimizations.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodIsIgnoringBatteryOptimizations,
      );
      return result ?? true;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to check battery optimization status.',
        details: e.details,
      );
    }
  }

  /// Prompts user to exempt ByteFlow from Android system battery optimizations.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodRequestIgnoreBatteryOptimizations,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to request battery optimization exemption.',
        details: e.details,
      );
    }
  }

  /// Dispatches a high-priority system notification for data plan warning or exhaustion alerts.
  Future<bool> sendQuotaNotification({
    required String title,
    required String body,
    required bool isWarning,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodSendQuotaNotification,
        {
          'title': title,
          'body': body,
          'isWarning': isWarning,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw PlatformServiceException(
        code: e.code,
        message: e.message ?? 'Failed to send quota notification.',
        details: e.details,
      );
    }
  }

  /// Emits real-time throughput rates from EventChannel.
  Stream<SpeedSampleDto> get speedStream {
    return _speedEventChannel.receiveBroadcastStream().map((event) {
      if (event is Map<dynamic, dynamic>) {
        return SpeedSampleDto.fromMap(event);
      }
      throw const FormatException('Expected Map event from speedEventChannel');
    });
  }
}
