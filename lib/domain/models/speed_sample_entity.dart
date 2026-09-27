/// Immutable real-time network throughput snapshot emitted by LiveSpeedService.
class SpeedSampleEntity {
  final int downloadBps;
  final int uploadBps;
  final DateTime timestamp;

  const SpeedSampleEntity({
    required this.downloadBps,
    required this.uploadBps,
    required this.timestamp,
  });

  int get totalBps => downloadBps + uploadBps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeedSampleEntity &&
          runtimeType == other.runtimeType &&
          downloadBps == other.downloadBps &&
          uploadBps == other.uploadBps &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(downloadBps, uploadBps, timestamp);

  @override
  String toString() =>
      'SpeedSampleEntity(down: $downloadBps B/s, up: $uploadBps B/s)';
}
