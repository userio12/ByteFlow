import 'dart:async';
import 'package:byteflow/core/constants/channel_constants.dart';
import 'package:byteflow/data/models/app_usage_dto.dart';
import 'package:byteflow/data/models/network_summary_dto.dart';
import 'package:byteflow/data/models/sim_info_dto.dart';
import 'package:byteflow/data/models/speed_sample_dto.dart';
import 'package:byteflow/data/models/usage_time_bucket_dto.dart';
import 'package:byteflow/data/services/native_network_service.dart';

/// In-memory fake test double for [NativeNetworkService] avoiding real Platform Channel invocations.
class MockNativeNetworkService extends NativeNetworkService {
  bool usagePermissionGranted;
  bool phoneStatePermissionGranted;
  bool isServiceRunning;
  List<SimInfoDto> simCards;
  NetworkSummaryDto? deviceTotal;
  List<AppUsageDto> appsUsage;
  List<UsageTimeBucketDto> timeBuckets;
  
  final StreamController<SpeedSampleDto> _speedController =
      StreamController<SpeedSampleDto>.broadcast();

  MockNativeNetworkService({
    this.usagePermissionGranted = true,
    this.phoneStatePermissionGranted = true,
    this.isServiceRunning = false,
    this.simCards = const [],
    this.deviceTotal,
    this.appsUsage = const [],
    this.timeBuckets = const [],
  });

  @override
  Future<bool> hasUsagePermission() async => usagePermissionGranted;

  @override
  Future<bool> openUsageSettings() async => true;

  @override
  Future<bool> hasPhoneStatePermission() async => phoneStatePermissionGranted;

  @override
  Future<List<SimInfoDto>> getSimCards() async => simCards;

  @override
  Future<NetworkSummaryDto> getDeviceTotal({
    required int startTimeMs,
    required int endTimeMs,
  }) async {
    return deviceTotal ??
        NetworkSummaryDto(
          mobileRx: 104857600, // 100 MB
          mobileTx: 20971520,  // 20 MB
          wifiRx: 524288000,   // 500 MB
          wifiTx: 104857600,   // 100 MB
          startTimeMs: startTimeMs,
          endTimeMs: endTimeMs,
        );
  }

  @override
  Future<List<AppUsageDto>> getAppsUsage({
    int networkType = ChannelConstants.networkTypeAll,
    required int startTimeMs,
    required int endTimeMs,
    bool includeIcons = true,
  }) async {
    return appsUsage;
  }

  @override
  Future<List<UsageTimeBucketDto>> getTimeBuckets({
    int networkType = ChannelConstants.networkTypeMobile,
    required int startTimeMs,
    required int endTimeMs,
    int stepIntervalMs = 3600000,
  }) async {
    return timeBuckets;
  }

  @override
  Future<bool> startLiveSpeedService({int intervalMs = 1000}) async {
    isServiceRunning = true;
    return true;
  }

  @override
  Future<bool> stopLiveSpeedService() async {
    isServiceRunning = false;
    return true;
  }

  @override
  Future<bool> isLiveSpeedServiceRunning() async => isServiceRunning;

  bool refreshNotificationCalled = false;

  @override
  Future<bool> refreshLiveSpeedNotification() async {
    refreshNotificationCalled = true;
    return true;
  }

  @override
  Future<bool> updateWidgetData({
    required String carrier,
    required String simBadge,
    required int mobileBytes,
    required int wifiBytes,
    required int quotaBytes,
    required String quotaText,
  }) async {
    return true;
  }

  bool batteryOptimizationsIgnored = false;
  String? lastLaunchedPackage;
  String? lastOpenedDetailsPackage;
  String? lastNotificationTitle;
  String? lastNotificationBody;
  bool? lastNotificationIsWarning;

  @override
  Future<bool> launchApp(String packageName) async {
    lastLaunchedPackage = packageName;
    return true;
  }

  @override
  Future<bool> openAppDetails(String packageName) async {
    lastOpenedDetailsPackage = packageName;
    return true;
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => batteryOptimizationsIgnored;

  @override
  Future<bool> requestIgnoreBatteryOptimizations() async {
    batteryOptimizationsIgnored = true;
    return true;
  }

  @override
  Future<bool> sendQuotaNotification({
    required String title,
    required String body,
    required bool isWarning,
  }) async {
    lastNotificationTitle = title;
    lastNotificationBody = body;
    lastNotificationIsWarning = isWarning;
    return true;
  }

  @override
  Stream<SpeedSampleDto> get speedStream => _speedController.stream;

  void emitSpeed(SpeedSampleDto sample) {
    if (!_speedController.isClosed) {
      _speedController.add(sample);
    }
  }

  void dispose() {
    _speedController.close();
  }
}
