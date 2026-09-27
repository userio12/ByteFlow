import '../../domain/models/usage_time_bucket.dart';

/// Data Transfer Object for discrete time bucket measurements.
class UsageTimeBucketDto {
  final int startTimeMs;
  final int endTimeMs;
  final int rxBytes;
  final int txBytes;
  final String networkType;
  final String? label;

  const UsageTimeBucketDto({
    required this.startTimeMs,
    required this.endTimeMs,
    this.rxBytes = 0,
    this.txBytes = 0,
    this.networkType = 'mobile',
    this.label,
  });

  /// Pattern-matched deserialization from native Platform Channel or SQLite map.
  factory UsageTimeBucketDto.fromMap(Map<dynamic, dynamic> map) {
    return switch (map) {
      {
        'startTimeMs': final num start,
        'endTimeMs': final num end,
      } =>
        UsageTimeBucketDto(
          startTimeMs: start.toInt(),
          endTimeMs: end.toInt(),
          rxBytes: (map['rxBytes'] as num?)?.toInt() ?? 0,
          txBytes: (map['txBytes'] as num?)?.toInt() ?? 0,
          networkType: (map['networkType'] as String?) ?? 'mobile',
          label: map['label'] as String?,
        ),
      _ => throw FormatException('Invalid UsageTimeBucketDto payload: $map'),
    };
  }

  /// Converts this DTO into a map for SQLite persistence.
  Map<String, dynamic> toMap() {
    return {
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
      'rxBytes': rxBytes,
      'txBytes': txBytes,
      'totalBytes': rxBytes + txBytes,
      'networkType': networkType,
      'label': label,
    };
  }

  /// Converts this DTO to an immutable domain [UsageTimeBucket].
  UsageTimeBucket toEntity({String? fallbackLabel}) {
    final start = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
    final end = DateTime.fromMillisecondsSinceEpoch(endTimeMs);
    final isWifi = networkType.toLowerCase() == 'wifi';

    return UsageTimeBucket(
      startTime: start,
      endTime: end,
      label: label ?? fallbackLabel ?? '${start.hour.toString().padLeft(2, '0')}:00',
      mobileRxBytes: isWifi ? 0 : rxBytes,
      mobileTxBytes: isWifi ? 0 : txBytes,
      wifiRxBytes: isWifi ? rxBytes : 0,
      wifiTxBytes: isWifi ? txBytes : 0,
    );
  }
}
