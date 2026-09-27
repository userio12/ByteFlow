/// Immutable entity representing data consumption of an installed Android app or system UID.
class AppUsageEntity {
  final int uid;
  final String packageName;
  final String appName;
  final int rxBytes;
  final int txBytes;
  final int foregroundRx;
  final int foregroundTx;
  final int backgroundRx;
  final int backgroundTx;
  final String? appIconBase64;

  const AppUsageEntity({
    required this.uid,
    required this.packageName,
    required this.appName,
    this.rxBytes = 0,
    this.txBytes = 0,
    this.foregroundRx = 0,
    this.foregroundTx = 0,
    this.backgroundRx = 0,
    this.backgroundTx = 0,
    this.appIconBase64,
  });

  int get totalBytes => rxBytes + txBytes;
  int get foregroundBytes => foregroundRx + foregroundTx;
  int get backgroundBytes => backgroundRx + backgroundTx;

  /// Returns percentage of this app's traffic consumed while in background (0.0 - 100.0).
  double get backgroundPercentage {
    if (totalBytes == 0) return 0.0;
    return (backgroundBytes / totalBytes) * 100.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUsageEntity &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          packageName == other.packageName &&
          rxBytes == other.rxBytes &&
          txBytes == other.txBytes &&
          foregroundRx == other.foregroundRx &&
          foregroundTx == other.foregroundTx &&
          backgroundRx == other.backgroundRx &&
          backgroundTx == other.backgroundTx;

  @override
  int get hashCode => Object.hash(
        uid,
        packageName,
        rxBytes,
        txBytes,
        foregroundRx,
        foregroundTx,
        backgroundRx,
        backgroundTx,
      );

  @override
  String toString() =>
      'AppUsageEntity(pkg: $packageName, total: $totalBytes, fg: $foregroundBytes, bg: $backgroundBytes)';
}
