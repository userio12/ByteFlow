import '../../core/constants/app_constants.dart';
import '../../domain/models/data_plan_entity.dart';

/// Data Transfer Object for serialized data plan configuration.
class DataPlanDto {
  final int quotaBytes;
  final String cycleType;
  final int resetDay;
  final double alertThresholdPercent;
  final double warningThresholdPercent;

  const DataPlanDto({
    this.quotaBytes = AppConstants.defaultQuotaBytes,
    this.cycleType = 'monthly',
    this.resetDay = AppConstants.defaultResetDay,
    this.alertThresholdPercent = AppConstants.defaultAlertThresholdPercent,
    this.warningThresholdPercent = AppConstants.defaultWarningThresholdPercent,
  });

  /// Pattern-matched deserialization from JSON or SharedPreferences map.
  factory DataPlanDto.fromMap(Map<String, dynamic> map) {
    return switch (map) {
      {
        'quotaBytes': final num quota,
      } =>
        DataPlanDto(
          quotaBytes: quota.toInt(),
          cycleType: (map['cycleType'] as String?) ?? 'monthly',
          resetDay: (map['resetDay'] as num?)?.toInt() ?? AppConstants.defaultResetDay,
          alertThresholdPercent:
              (map['alertThresholdPercent'] as num?)?.toDouble() ??
                  AppConstants.defaultAlertThresholdPercent,
          warningThresholdPercent:
              (map['warningThresholdPercent'] as num?)?.toDouble() ??
                  AppConstants.defaultWarningThresholdPercent,
        ),
      _ => const DataPlanDto(),
    };
  }

  /// Converts this DTO into a map for JSON serialization or SharedPreferences.
  Map<String, dynamic> toMap() {
    return {
      'quotaBytes': quotaBytes,
      'cycleType': cycleType,
      'resetDay': resetDay,
      'alertThresholdPercent': alertThresholdPercent,
      'warningThresholdPercent': warningThresholdPercent,
    };
  }

  /// Converts this DTO to domain [DataPlanEntity].
  DataPlanEntity toEntity() {
    final cycle = switch (cycleType.toLowerCase()) {
      'daily' => DataPlanCycleType.daily,
      'prepaid28days' || '28days' => DataPlanCycleType.prepaid28Days,
      _ => DataPlanCycleType.monthly,
    };

    return DataPlanEntity(
      quotaBytes: quotaBytes,
      cycleType: cycle,
      resetDay: resetDay,
      alertThresholdPercent: alertThresholdPercent,
      warningThresholdPercent: warningThresholdPercent,
    );
  }

  /// Creates a DTO directly from domain [DataPlanEntity].
  factory DataPlanDto.fromEntity(DataPlanEntity entity) {
    return DataPlanDto(
      quotaBytes: entity.quotaBytes,
      cycleType: entity.cycleType.name,
      resetDay: entity.resetDay,
      alertThresholdPercent: entity.alertThresholdPercent,
      warningThresholdPercent: entity.warningThresholdPercent,
    );
  }
}
