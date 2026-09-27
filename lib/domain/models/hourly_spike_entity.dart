/// Immutable entity identifying peak hourly usage spikes and culprit apps.
class HourlySpikeEntity {
  final int hourOfDay;
  final int totalBytes;
  final String? culpritAppName;
  final String? culpritPackageName;
  final int? culpritBytes;

  const HourlySpikeEntity({
    required this.hourOfDay,
    required this.totalBytes,
    this.culpritAppName,
    this.culpritPackageName,
    this.culpritBytes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HourlySpikeEntity &&
          runtimeType == other.runtimeType &&
          hourOfDay == other.hourOfDay &&
          totalBytes == other.totalBytes &&
          culpritAppName == other.culpritAppName &&
          culpritPackageName == other.culpritPackageName &&
          culpritBytes == other.culpritBytes;

  @override
  int get hashCode => Object.hash(
        hourOfDay,
        totalBytes,
        culpritAppName,
        culpritPackageName,
        culpritBytes,
      );

  @override
  String toString() =>
      'HourlySpikeEntity(hour: $hourOfDay:00, total: $totalBytes, culprit: $culpritAppName)';
}
