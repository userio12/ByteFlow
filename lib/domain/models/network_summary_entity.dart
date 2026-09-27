/// Immutable summary of device-wide mobile and Wi-Fi data traffic.
class NetworkSummaryEntity {
  final int mobileRx;
  final int mobileTx;
  final int wifiRx;
  final int wifiTx;
  final DateTime startTime;
  final DateTime endTime;

  const NetworkSummaryEntity({
    this.mobileRx = 0,
    this.mobileTx = 0,
    this.wifiRx = 0,
    this.wifiTx = 0,
    required this.startTime,
    required this.endTime,
  });

  int get mobileTotal => mobileRx + mobileTx;
  int get wifiTotal => wifiRx + wifiTx;
  int get grandTotal => mobileTotal + wifiTotal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkSummaryEntity &&
          runtimeType == other.runtimeType &&
          mobileRx == other.mobileRx &&
          mobileTx == other.mobileTx &&
          wifiRx == other.wifiRx &&
          wifiTx == other.wifiTx &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => Object.hash(
        mobileRx,
        mobileTx,
        wifiRx,
        wifiTx,
        startTime,
        endTime,
      );

  @override
  String toString() =>
      'NetworkSummaryEntity(mobile: $mobileTotal, wifi: $wifiTotal, total: $grandTotal)';
}
