import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/domain/models/data_plan_entity.dart';

void main() {
  group('DataPlanEntity', () {
    const plan = DataPlanEntity(
      quotaBytes: 1000,
      cycleType: DataPlanCycleType.monthly,
      resetDay: 1,
      alertThresholdPercent: 90.0,
      warningThresholdPercent: 75.0,
    );

    test('remainingBytes clamps at zero when quota exceeded', () {
      expect(plan.remainingBytes(400), equals(600));
      expect(plan.remainingBytes(1000), equals(0));
      expect(plan.remainingBytes(1500), equals(0));
    });

    test('usagePercent calculates percentages correctly', () {
      expect(plan.usagePercent(0), equals(0.0));
      expect(plan.usagePercent(500), equals(50.0));
      expect(plan.usagePercent(1000), equals(100.0));
      expect(plan.usagePercent(1500), equals(150.0));

      const zeroPlan = DataPlanEntity(quotaBytes: 0);
      expect(zeroPlan.usagePercent(100), equals(0.0));
    });

    test('threshold warning and alert status flags work accurately', () {
      // 50% consumed: neither warning nor alert
      expect(plan.isWarning(500), isFalse);
      expect(plan.isAlert(500), isFalse);
      expect(plan.isExhausted(500), isFalse);

      // 80% consumed: in warning territory, not yet alert
      expect(plan.isWarning(800), isTrue);
      expect(plan.isAlert(800), isFalse);
      expect(plan.isExhausted(800), isFalse);

      // 95% consumed: in alert territory
      expect(plan.isWarning(950), isTrue);
      expect(plan.isAlert(950), isTrue);
      expect(plan.isExhausted(950), isFalse);

      // 100% consumed: exhausted
      expect(plan.isExhausted(1000), isTrue);
    });

    test('copyWith updates properties while retaining others', () {
      final updated = plan.copyWith(
        quotaBytes: 5000,
        cycleType: DataPlanCycleType.daily,
      );

      expect(updated.quotaBytes, equals(5000));
      expect(updated.cycleType, equals(DataPlanCycleType.daily));
      expect(updated.resetDay, equals(plan.resetDay));
      expect(updated.alertThresholdPercent, equals(plan.alertThresholdPercent));
    });

    test('supports equality, hashCode, and toString', () {
      const p1 = DataPlanEntity(quotaBytes: 100);
      const p2 = DataPlanEntity(quotaBytes: 100);
      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1.toString(), contains('DataPlanEntity'));
    });
  });
}
