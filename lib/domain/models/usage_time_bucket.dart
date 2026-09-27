/// Represents an atomic time slice (e.g. 1 hour, 1 day, 1 month) in dynamic charts.
class UsageTimeBucket {
  final DateTime startTime;
  final DateTime endTime;
  final String label;
  final int mobileRxBytes;
  final int mobileTxBytes;
  final int wifiRxBytes;
  final int wifiTxBytes;

  const UsageTimeBucket({
    required this.startTime,
    required this.endTime,
    required this.label,
    this.mobileRxBytes = 0,
    this.mobileTxBytes = 0,
    this.wifiRxBytes = 0,
    this.wifiTxBytes = 0,
  });

  int get totalMobileBytes => mobileRxBytes + mobileTxBytes;
  int get totalWifiBytes => wifiRxBytes + wifiTxBytes;
  int get totalBytes => totalMobileBytes + totalWifiBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageTimeBucket &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          label == other.label &&
          mobileRxBytes == other.mobileRxBytes &&
          mobileTxBytes == other.mobileTxBytes &&
          wifiRxBytes == other.wifiRxBytes &&
          wifiTxBytes == other.wifiTxBytes;

  @override
  int get hashCode => Object.hash(
        startTime,
        endTime,
        label,
        mobileRxBytes,
        mobileTxBytes,
        wifiRxBytes,
        wifiTxBytes,
      );

  @override
  String toString() =>
      'UsageTimeBucket(label: $label, mobile: $totalMobileBytes, wifi: $totalWifiBytes)';
}
