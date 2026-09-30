import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/domain/models/data_plan_entity.dart';
import 'package:byteflow/domain/models/network_summary_entity.dart';
import 'package:byteflow/domain/use_cases/get_active_sim_info_use_case.dart';
import 'package:byteflow/domain/use_cases/get_data_plan_use_case.dart';
import 'package:byteflow/domain/use_cases/get_today_usage_use_case.dart';
import 'package:byteflow/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:byteflow/ui/features/plan/view_models/plan_view_model.dart';

import '../../mocks/mock_native_network_service.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('DashboardViewModel Tests', () {
    late FakeNetworkRepository fakeNetworkRepo;
    late FakePlanRepository fakePlanRepo;
    late MockNativeNetworkService mockNativeService;
    late DashboardViewModel viewModel;

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
      fakePlanRepo = FakePlanRepository();
      mockNativeService = MockNativeNetworkService();

      fakeNetworkRepo.todaySummary = NetworkSummaryEntity(
        mobileRx: 200 * 1024 * 1024,
        mobileTx: 50 * 1024 * 1024,
        wifiRx: 800 * 1024 * 1024,
        wifiTx: 200 * 1024 * 1024,
        startTime: DateTime.now().subtract(const Duration(hours: 12)),
        endTime: DateTime.now(),
      );

      fakePlanRepo.plan = const DataPlanEntity(
        quotaBytes: 2 * 1024 * 1024 * 1024, // 2 GB
        cycleType: DataPlanCycleType.monthly,
        resetDay: 1,
      );

      fakePlanRepo.wifiPlan = const DataPlanEntity(
        quotaBytes: 50 * 1024 * 1024 * 1024, // 50 GB
        cycleType: DataPlanCycleType.monthly,
        resetDay: 1,
      );

      viewModel = DashboardViewModel(
        getTodayUsageUseCase: GetTodayUsageUseCase(fakeNetworkRepo),
        getActiveSimInfoUseCase: GetActiveSimInfoUseCase(fakeNetworkRepo),
        getDataPlanUseCase: GetDataPlanUseCase(fakePlanRepo),
        nativeService: mockNativeService,
        planRepository: fakePlanRepo,
      );
    });

    test('loadData loads both cellular and wifi plans and summaries', () async {
      await viewModel.loadData();

      expect(viewModel.cellularPlan.quotaBytes, equals(2 * 1024 * 1024 * 1024));
      expect(viewModel.wifiPlan.quotaBytes, equals(50 * 1024 * 1024 * 1024));
      expect(viewModel.selectedCategory, equals(PlanCategory.cellular));
      expect(viewModel.activePlan.quotaBytes, equals(2 * 1024 * 1024 * 1024));
      expect(viewModel.activeUsedBytes, equals(250 * 1024 * 1024)); // 200 + 50 MB
    });

    test('selectCategory switches to Wi-Fi mode and reflects Wi-Fi metrics', () async {
      await viewModel.loadData();

      bool notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.selectCategory(PlanCategory.wifi);

      expect(notified, isTrue);
      expect(viewModel.selectedCategory, equals(PlanCategory.wifi));
      expect(viewModel.activePlan.quotaBytes, equals(50 * 1024 * 1024 * 1024));
      expect(viewModel.activeUsedBytes, equals(1000 * 1024 * 1024)); // 800 + 200 MB
    });

    test('selectCategory switches back to Cellular mode', () async {
      await viewModel.loadData();
      viewModel.selectCategory(PlanCategory.wifi);
      expect(viewModel.selectedCategory, equals(PlanCategory.wifi));

      viewModel.selectCategory(PlanCategory.cellular);
      expect(viewModel.selectedCategory, equals(PlanCategory.cellular));
      expect(viewModel.activePlan.quotaBytes, equals(2 * 1024 * 1024 * 1024));
      expect(viewModel.activeUsedBytes, equals(250 * 1024 * 1024));
    });
  });
}
