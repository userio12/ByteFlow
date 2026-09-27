import '../../domain/models/sim_info_entity.dart';

/// Data Transfer Object for SIM card subscription and active carrier metadata.
class SimInfoDto {
  final int subId;
  final int slotIndex;
  final String displayName;
  final String carrierName;
  final String countryIso;
  final bool isDataRoaming;
  final bool isDefaultData;

  const SimInfoDto({
    required this.subId,
    required this.slotIndex,
    required this.displayName,
    required this.carrierName,
    this.countryIso = '',
    this.isDataRoaming = false,
    this.isDefaultData = false,
  });

  /// Pattern-matched deserialization from native SubscriptionManager map.
  factory SimInfoDto.fromMap(Map<dynamic, dynamic> map) {
    return switch (map) {
      {
        'subId': final num subId,
        'slotIndex': final num slotIndex,
        'carrierName': final String carrierName,
      } =>
        SimInfoDto(
          subId: subId.toInt(),
          slotIndex: slotIndex.toInt(),
          displayName: (map['displayName'] as String?) ?? carrierName,
          carrierName: carrierName,
          countryIso: (map['countryIso'] as String?) ?? '',
          isDataRoaming: (map['isDataRoaming'] as bool?) ?? false,
          isDefaultData: (map['isDefaultData'] as bool?) ?? false,
        ),
      _ => throw FormatException('Invalid SimInfoDto payload: $map'),
    };
  }

  /// Converts this DTO into a map.
  Map<String, dynamic> toMap() {
    return {
      'subId': subId,
      'slotIndex': slotIndex,
      'displayName': displayName,
      'carrierName': carrierName,
      'countryIso': countryIso,
      'isDataRoaming': isDataRoaming,
      'isDefaultData': isDefaultData,
    };
  }

  /// Converts this DTO to domain [SimInfoEntity].
  SimInfoEntity toEntity() {
    return SimInfoEntity(
      subId: subId,
      slotIndex: slotIndex,
      displayName: displayName,
      carrierName: carrierName,
      countryIso: countryIso,
      isDataRoaming: isDataRoaming,
      isDefaultData: isDefaultData,
    );
  }
}
