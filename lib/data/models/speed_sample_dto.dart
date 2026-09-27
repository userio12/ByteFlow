import '../../domain/models/speed_sample_entity.dart';

/// Data Transfer Object for real-time throughput samples from EventChannel.
class SpeedSampleDto {
  final int downloadBps;
  final int uploadBps;
  final int timestampMs;

  const SpeedSampleDto({
    required this.downloadBps,
    required this.uploadBps,
    required this.timestampMs,
  });

  /// Pattern-matched deserialization from EventChannel map.
  factory SpeedSampleDto.fromMap(Map<dynamic, dynamic> map) {
    return switch (map) {
      {
        'downloadBps': final num down,
        'uploadBps': final num up,
      } =>
        SpeedSampleDto(
          downloadBps: down.toInt(),
          uploadBps: up.toInt(),
          timestampMs: (map['timestampMs'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
      _ => throw FormatException('Invalid SpeedSampleDto payload: $map'),
    };
  }

  /// Converts this DTO to domain [SpeedSampleEntity].
  SpeedSampleEntity toEntity() {
    return SpeedSampleEntity(
      downloadBps: downloadBps,
      uploadBps: uploadBps,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
  }
}
