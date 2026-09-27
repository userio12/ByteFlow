import '../../core/constants/app_constants.dart';

/// Billing cycle recurrence cadence.
enum DataPlanCycleType {
  monthly,
  daily,
  prepaid28Days;

  String get displayName => switch (this) {
        DataPlanCycleType.monthly => 'Monthly',
        DataPlanCycleType.daily => 'Daily',
        DataPlanCycleType.prepaid28Days => '28-Day Prepaid',
      };
}

/// Immutable data plan quota and billing cycle configuration.
class DataPlanEntity {
  final int quotaBytes;
  final DataPlanCycleType cycleType;
  final int resetDay;
  final double alertThresholdPercent;
  final double warningThresholdPercent;

  const DataPlanEntity({
    this.quotaBytes = AppConstants.defaultQuotaBytes,
    this.cycleType = DataPlanCycleType.monthly,
    this.resetDay = AppConstants.defaultResetDay,
    this.alertThresholdPercent = AppConstants.defaultAlertThresholdPercent,
    this.warningThresholdPercent = AppConstants.defaultWarningThresholdPercent,
  });

  /// Computes remaining quota in bytes (clamped at 0).
  int remainingBytes(int usedBytes) {
    final remaining = quotaBytes - usedBytes;
    return remaining > 0 ? remaining : 0;
  }

  /// Percentage of quota consumed (0.0 to 100.0+).
  double usagePercent(int usedBytes) {
    if (quotaBytes <= 0) return 0.0;
    return (usedBytes / quotaBytes) * 100.0;
  }

  /// Whether current consumption has reached or exceeded quota.
  bool isExhausted(int usedBytes) => usedBytes >= quotaBytes;

  /// Whether current consumption has entered warning territory.
  bool isWarning(int usedBytes) => usagePercent(usedBytes) >= warningThresholdPercent;

  /// Whether current consumption has entered critical alert territory.
  bool isAlert(int usedBytes) => usagePercent(usedBytes) >= alertThresholdPercent;

  DataPlanEntity copyWith({
    int? quotaBytes,
    DataPlanCycleType? cycleType,
    int? resetDay,
    double? alertThresholdPercent,
    double? warningThresholdPercent,
  }) {
    return DataPlanEntity(
      quotaBytes: quotaBytes ?? this.quotaBytes,
      cycleType: cycleType ?? this.cycleType,
      resetDay: resetDay ?? this.resetDay,
      alertThresholdPercent:
          alertThresholdPercent ?? this.alertThresholdPercent,
      warningThresholdPercent:
          warningThresholdPercent ?? this.warningThresholdPercent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPlanEntity &&
          runtimeType == other.runtimeType &&
          quotaBytes == other.quotaBytes &&
          cycleType == other.cycleType &&
          resetDay == other.resetDay &&
          alertThresholdPercent == other.alertThresholdPercent &&
          warningThresholdPercent == other.warningThresholdPercent;

  @override
  int get hashCode => Object.hash(
        quotaBytes,
        cycleType,
        resetDay,
        alertThresholdPercent,
        warningThresholdPercent,
      );

  @override
  String toString() =>
      'DataPlanEntity(quota: $quotaBytes, cycle: ${cycleType.displayName}, resetDay: $resetDay)';
}
