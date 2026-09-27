/// Immutable entity representing an active SIM card subscription and carrier metadata.
class SimInfoEntity {
  final int subId;
  final int slotIndex;
  final String displayName;
  final String carrierName;
  final String countryIso;
  final bool isDataRoaming;
  final bool isDefaultData;

  const SimInfoEntity({
    required this.subId,
    required this.slotIndex,
    required this.displayName,
    required this.carrierName,
    this.countryIso = '',
    this.isDataRoaming = false,
    this.isDefaultData = false,
  });

  /// Short slot badge (e.g. `"SIM 1"`, `"SIM 2"`).
  String get slotBadge => 'SIM ${slotIndex + 1}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimInfoEntity &&
          runtimeType == other.runtimeType &&
          subId == other.subId &&
          slotIndex == other.slotIndex &&
          displayName == other.displayName &&
          carrierName == other.carrierName &&
          isDefaultData == other.isDefaultData;

  @override
  int get hashCode => Object.hash(
        subId,
        slotIndex,
        displayName,
        carrierName,
        isDefaultData,
      );

  @override
  String toString() =>
      'SimInfoEntity(subId: $subId, slot: $slotBadge, carrier: $carrierName, default: $isDefaultData)';
}
