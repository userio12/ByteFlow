import 'package:byteflow/domain/models/data_plan_entity.dart';
import 'package:byteflow/domain/models/network_summary_entity.dart';
import 'package:byteflow/domain/use_cases/get_active_sim_info_use_case.dart';
import 'package:byteflow/domain/use_cases/get_data_plan_use_case.dart';
import 'package:byteflow/domain/use_cases/get_today_usage_use_case.dart';
import 'package:byteflow/domain/use_cases/save_data_plan_use_case.dart';
import 'package:byteflow/ui/features/plan/view_models/plan_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('DataPlanEntity Alert & Warning Threshold Unit Tests', () {
    const quota = 10 * 1024 * 1024 * 1024; // 10 GB
    const plan = DataPlanEntity(
      quotaBytes: quota,
      warningThresholdPercent: 80.0,
      alertThresholdPercent: 90.0,
    );

    test('usagePercent calculates correct percentage', () {
      expect(plan.usagePercent(0), equals(0.0));
      expect(plan.usagePercent(5 * 1024 * 1024 * 1024), equals(50.0));
      expect(plan.usagePercent(8 * 1024 * 1024 * 1024), equals(80.0));
      expect(plan.usagePercent(10 * 1024 * 1024 * 1024), equals(100.0));
    });

    test('isWarning flags true when usage reaches warning threshold', () {
      expect(plan.isWarning(7 * 1024 * 1024 * 1024), isFalse);
      expect(plan.isWarning(8 * 1024 * 1024 * 1024), isTrue);
      expect(plan.isWarning(9 * 1024 * 1024 * 1024), isTrue);
    });

    test('isAlert flags true when usage reaches critical alert threshold', () {
      expect(plan.isAlert(8 * 1024 * 1024 * 1024), isFalse);
      expect(plan.isAlert((9.5 * 1024 * 1024 * 1024).toInt()), isTrue);
    });

    test('isExhausted flags true when usage reaches or exceeds quotaBytes', () {
      expect(plan.isExhausted(9 * 1024 * 1024 * 1024), isFalse);
      expect(plan.isExhausted(10 * 1024 * 1024 * 1024), isTrue);
      expect(plan.isExhausted(11 * 1024 * 1024 * 1024), isTrue);
    });
  });

  group('PlanViewModel Quota Notification System Dispatch Tests', () {
    late FakePlanRepository fakePlanRepository;
    late FakeNetworkRepository fakeNetworkRepository;
    late FakeSettingsRepository fakeSettingsRepository;

    late GetDataPlanUseCase getDataPlanUseCase;
    late SaveDataPlanUseCase saveDataPlanUseCase;
    late GetActiveSimInfoUseCase getActiveSimInfoUseCase;
    late GetTodayUsageUseCase getTodayUsageUseCase;

    setUp(() {
      fakePlanRepository = FakePlanRepository();
      fakeNetworkRepository = FakeNetworkRepository();
      fakeSettingsRepository = FakeSettingsRepository();

      getDataPlanUseCase = GetDataPlanUseCase(fakePlanRepository);
      saveDataPlanUseCase = SaveDataPlanUseCase(fakePlanRepository);
      getActiveSimInfoUseCase = GetActiveSimInfoUseCase(fakeNetworkRepository);
      getTodayUsageUseCase = GetTodayUsageUseCase(fakeNetworkRepository);
    });

    test('does not send notification when below warning threshold', () async {
      const quota = 10 * 1024 * 1024 * 1024; // 10 GB
      fakePlanRepository.plan = const DataPlanEntity(
        quotaBytes: quota,
        warningThresholdPercent: 80.0,
      );
      fakeNetworkRepository.todaySummary = NetworkSummaryEntity(
        mobileRx: 2 * 1024 * 1024 * 1024, // 2 GB (20%)
        mobileTx: 0,
        wifiRx: 0,
        wifiTx: 0,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );

      final viewModel = PlanViewModel(
        getDataPlanUseCase: getDataPlanUseCase,
        saveDataPlanUseCase: saveDataPlanUseCase,
        getActiveSimInfoUseCase: getActiveSimInfoUseCase,
        getTodayUsageUseCase: getTodayUsageUseCase,
        planRepository: fakePlanRepository,
        settingsRepository: fakeSettingsRepository,
      );

      await viewModel.loadData();

      expect(fakeSettingsRepository.lastNotificationTitle, isNull);
      expect(fakeSettingsRepository.lastNotificationBody, isNull);
    });

    test('sends warning notification when usage >= warning threshold', () async {
      const quota = 10 * 1024 * 1024 * 1024; // 10 GB
      fakePlanRepository.plan = const DataPlanEntity(
        quotaBytes: quota,
        warningThresholdPercent: 80.0,
      );
      fakeNetworkRepository.todaySummary = NetworkSummaryEntity(
        mobileRx: (8.5 * 1024 * 1024 * 1024).toInt(), // 85%
        mobileTx: 0,
        wifiRx: 0,
        wifiTx: 0,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );

      final viewModel = PlanViewModel(
        getDataPlanUseCase: getDataPlanUseCase,
        saveDataPlanUseCase: saveDataPlanUseCase,
        getActiveSimInfoUseCase: getActiveSimInfoUseCase,
        getTodayUsageUseCase: getTodayUsageUseCase,
        planRepository: fakePlanRepository,
        settingsRepository: fakeSettingsRepository,
      );

      await viewModel.loadData();

      expect(fakeSettingsRepository.lastNotificationTitle, equals('⚠️ Data Warning Alert'));
      expect(fakeSettingsRepository.lastNotificationBody, contains('85%'));
      expect(fakeSettingsRepository.lastNotificationIsWarning, isTrue);
    });

    test('sends critical notification when usage reaches 100% quota', () async {
      const quota = 10 * 1024 * 1024 * 1024; // 10 GB
      fakePlanRepository.plan = const DataPlanEntity(
        quotaBytes: quota,
        warningThresholdPercent: 80.0,
      );
      fakeNetworkRepository.todaySummary = NetworkSummaryEntity(
        mobileRx: 10 * 1024 * 1024 * 1024, // 100%
        mobileTx: 0,
        wifiRx: 0,
        wifiTx: 0,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );

      final viewModel = PlanViewModel(
        getDataPlanUseCase: getDataPlanUseCase,
        saveDataPlanUseCase: saveDataPlanUseCase,
        getActiveSimInfoUseCase: getActiveSimInfoUseCase,
        getTodayUsageUseCase: getTodayUsageUseCase,
        planRepository: fakePlanRepository,
        settingsRepository: fakeSettingsRepository,
      );

      await viewModel.loadData();

      expect(fakeSettingsRepository.lastNotificationTitle, equals('🚨 Data Limit Reached'));
      expect(fakeSettingsRepository.lastNotificationBody, contains('100%'));
      expect(fakeSettingsRepository.lastNotificationIsWarning, isFalse);
    });
  });
}
