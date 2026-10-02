import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/domain/models/data_plan_entity.dart';
import 'package:byteflow/domain/models/sim_info_entity.dart';
import 'package:byteflow/domain/use_cases/get_active_sim_info_use_case.dart';
import 'package:byteflow/domain/use_cases/get_data_plan_use_case.dart';
import 'package:byteflow/domain/use_cases/get_today_usage_use_case.dart';
import 'package:byteflow/domain/use_cases/save_data_plan_use_case.dart';
import 'package:byteflow/ui/features/plan/view_models/plan_view_model.dart';
import 'package:byteflow/ui/features/settings/views/data_plan_settings_view.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('DataPlanSettingsView Widget Test', () {
    late FakeNetworkRepository fakeNetworkRepo;
    late FakePlanRepository fakePlanRepo;
    late FakeSettingsRepository fakeSettingsRepo;
    late PlanViewModel viewModel;

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
      fakePlanRepo = FakePlanRepository();
      fakeSettingsRepo = FakeSettingsRepository();

      fakeNetworkRepo.activeSims = const [
        SimInfoEntity(
          subId: 1,
          slotIndex: 0,
          carrierName: 'AT&T',
          displayName: 'SIM 1',
          isDefaultData: true,
          isDataRoaming: false,
        ),
      ];

      fakePlanRepo.plan = const DataPlanEntity(
        quotaBytes: 10737418240, // 10 GB
        cycleType: DataPlanCycleType.monthly,
        resetDay: 5,
        alertThresholdPercent: 80,
      );

      viewModel = PlanViewModel(
        getDataPlanUseCase: GetDataPlanUseCase(fakePlanRepo),
        saveDataPlanUseCase: SaveDataPlanUseCase(fakePlanRepo),
        getActiveSimInfoUseCase: GetActiveSimInfoUseCase(fakeNetworkRepo),
        getTodayUsageUseCase: GetTodayUsageUseCase(fakeNetworkRepo),
        planRepository: fakePlanRepo,
        settingsRepository: fakeSettingsRepo,
      );
    });

    testWidgets('renders all configuration fields, toggles category, and saves plan successfully',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: DataPlanSettingsView(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify App Bar title
      expect(find.text('Data Plan & Quotas'), findsOneWidget);

      // 2. Verify Category Switcher
      expect(find.text('Cellular Plan'), findsOneWidget);
      expect(find.text('Wi-Fi Plan'), findsOneWidget);

      // 3. Verify Cellular Configuration Form
      expect(find.text('CONFIGURE CELLULAR PLAN'), findsOneWidget);
      expect(find.text('AT&T'), findsOneWidget);
      expect(find.text('Quota Size'), findsOneWidget);
      expect(find.text('GB'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Day 5'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('Save Data Plan'), findsOneWidget);

      // 4. Switch category to Wi-Fi Plan
      await tester.tap(find.text('Wi-Fi Plan'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIGURE WI-FI PLAN'), findsOneWidget);
      expect(find.text('Wi-Fi / Hotspot Allowance'), findsOneWidget);

      // 5. Switch back to Cellular Plan
      await tester.tap(find.text('Cellular Plan'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIGURE CELLULAR PLAN'), findsOneWidget);

      // 6. Tap Save Data Plan
      final saveBtn = find.text('Save Data Plan');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // 7. Verify confirmation SnackBar
      expect(find.text('Data plan updated successfully.'), findsOneWidget);
    });
  });
}
