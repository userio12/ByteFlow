import '../../domain/models/app_usage_entity.dart';

/// Data Transfer Object for serialized per-app usage records.
class AppUsageDto {
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
  final bool isSystemApp;

  const AppUsageDto({
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
    this.isSystemApp = false,
  });

  /// Pattern-matched deserialization from native Platform Channel or SQLite map.
  factory AppUsageDto.fromMap(Map<dynamic, dynamic> map) {
    return switch (map) {
      {
        'uid': final num uid,
        'packageName': final String packageName,
        'appName': final String appName,
      } =>
        AppUsageDto(
          uid: uid.toInt(),
          packageName: packageName,
          appName: appName,
          rxBytes: (map['rxBytes'] as num?)?.toInt() ?? 0,
          txBytes: (map['txBytes'] as num?)?.toInt() ?? 0,
          foregroundRx: (map['foregroundRx'] as num?)?.toInt() ?? 0,
          foregroundTx: (map['foregroundTx'] as num?)?.toInt() ?? 0,
          backgroundRx: (map['backgroundRx'] as num?)?.toInt() ?? 0,
          backgroundTx: (map['backgroundTx'] as num?)?.toInt() ?? 0,
          appIconBase64: map['appIconBase64'] as String?,
          isSystemApp: (map['isSystemApp'] as bool?) ?? (uid.toInt() < 10000),
        ),
      _ => throw FormatException('Invalid AppUsageDto payload: $map'),
    };
  }

  /// Converts this DTO into a map for IPC or SQLite persistence.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'packageName': packageName,
      'appName': appName,
      'rxBytes': rxBytes,
      'txBytes': txBytes,
      'totalBytes': rxBytes + txBytes,
      'foregroundRx': foregroundRx,
      'foregroundTx': foregroundTx,
      'backgroundRx': backgroundRx,
      'backgroundTx': backgroundTx,
      'appIconBase64': appIconBase64,
      'isSystemApp': isSystemApp,
    };
  }

  /// Converts this DTO to an immutable domain [AppUsageEntity].
  AppUsageEntity toEntity() {
    return AppUsageEntity(
      uid: uid,
      packageName: packageName,
      appName: appName,
      rxBytes: rxBytes,
      txBytes: txBytes,
      foregroundRx: foregroundRx,
      foregroundTx: foregroundTx,
      backgroundRx: backgroundRx,
      backgroundTx: backgroundTx,
      appIconBase64: appIconBase64,
      isSystemApp: isSystemApp,
    );
  }

  /// Creates a DTO directly from an [AppUsageEntity].
  factory AppUsageDto.fromEntity(AppUsageEntity entity) {
    return AppUsageDto(
      uid: entity.uid,
      packageName: entity.packageName,
      appName: entity.appName,
      rxBytes: entity.rxBytes,
      txBytes: entity.txBytes,
      foregroundRx: entity.foregroundRx,
      foregroundTx: entity.foregroundTx,
      backgroundRx: entity.backgroundRx,
      backgroundTx: entity.backgroundTx,
      appIconBase64: entity.appIconBase64,
      isSystemApp: entity.isSystemApp,
    );
  }
}
