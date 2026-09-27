import '../../domain/models/network_summary_entity.dart';

/// Data Transfer Object for serialized device cumulative network statistics.
class NetworkSummaryDto {
  final int mobileRx;
  final int mobileTx;
  final int wifiRx;
  final int wifiTx;
  final int startTimeMs;
  final int endTimeMs;

  const NetworkSummaryDto({
    this.mobileRx = 0,
    this.mobileTx = 0,
    this.wifiRx = 0,
    this.wifiTx = 0,
    required this.startTimeMs,
    required this.endTimeMs,
  });

  /// Pattern-matched deserialization from native Platform Channel map.
  factory NetworkSummaryDto.fromMap(Map<dynamic, dynamic> map) {
    return switch (map) {
      {
        'startTimeMs': final num start,
        'endTimeMs': final num end,
      } =>
        NetworkSummaryDto(
          mobileRx: (map['mobileRx'] as num?)?.toInt() ?? 0,
          mobileTx: (map['mobileTx'] as num?)?.toInt() ?? 0,
          wifiRx: (map['wifiRx'] as num?)?.toInt() ?? 0,
          wifiTx: (map['wifiTx'] as num?)?.toInt() ?? 0,
          startTimeMs: start.toInt(),
          endTimeMs: end.toInt(),
        ),
      _ => throw FormatException('Invalid NetworkSummaryDto payload: $map'),
    };
  }

  /// Converts this DTO into a map for IPC or SQLite persistence.
  Map<String, dynamic> toMap() {
    return {
      'mobileRx': mobileRx,
      'mobileTx': mobileTx,
      'mobileTotal': mobileRx + mobileTx,
      'wifiRx': wifiRx,
      'wifiTx': wifiTx,
      'wifiTotal': wifiRx + wifiTx,
      'grandTotal': mobileRx + mobileTx + wifiRx + wifiTx,
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
    };
  }

  /// Converts this DTO to an immutable domain [NetworkSummaryEntity].
  NetworkSummaryEntity toEntity() {
    return NetworkSummaryEntity(
      mobileRx: mobileRx,
      mobileTx: mobileTx,
      wifiRx: wifiRx,
      wifiTx: wifiTx,
      startTime: DateTime.fromMillisecondsSinceEpoch(startTimeMs),
      endTime: DateTime.fromMillisecondsSinceEpoch(endTimeMs),
    );
  }
}
