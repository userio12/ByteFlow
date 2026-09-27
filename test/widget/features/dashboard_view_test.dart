import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/theme/app_icons.dart';
import 'package:byteflow/domain/models/data_plan_entity.dart';
import 'package:byteflow/domain/models/sim_info_entity.dart';
import 'package:byteflow/domain/use_cases/get_active_sim_info_use_case.dart';
import 'package:byteflow/domain/use_cases/get_data_plan_use_case.dart';
import 'package:byteflow/domain/use_cases/get_today_usage_use_case.dart';
import 'package:byteflow/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:byteflow/ui/features/dashboard/views/dashboard_view.dart';
import 'package:byteflow/ui/features/dashboard/widgets/daily_comparison_tile.dart';
import 'package:byteflow/ui/features/dashboard/widgets/plan_progress_ring.dart';
import 'package:byteflow/ui/features/dashboard/widgets/speed_pulse_card.dart';
import 'package:byteflow/ui/features/dashboard/widgets/top_apps_preview_card.dart';

import '../../mocks/mock_native_network_service.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('DashboardView Widget Test', () {
    late FakeNetworkRepository fakeNetworkRepo;
    late FakePlanRepository fakePlanRepo;
    late MockNativeNetworkService mockNativeService;
    late DashboardViewModel viewModel;

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
      fakePlanRepo = FakePlanRepository();
      mockNativeService = MockNativeNetworkService();

      fakeNetworkRepo.activeSims = const [
        SimInfoEntity(
          subId: 1,
          slotIndex: 0,
          carrierName: 'Verizon',
          displayName: 'SIM 1',
          isDefaultData: true,
          isDataRoaming: false,
        ),
      ];

      fakePlanRepo.plan = const DataPlanEntity(
        quotaBytes: 10737418240, // 10 GB
        cycleType: DataPlanCycleType.monthly,
        resetDay: 1,
      );

      viewModel = DashboardViewModel(
        getTodayUsageUseCase: GetTodayUsageUseCase(fakeNetworkRepo),
        getActiveSimInfoUseCase: GetActiveSimInfoUseCase(fakeNetworkRepo),
        getDataPlanUseCase: GetDataPlanUseCase(fakePlanRepo),
        networkRepository: fakeNetworkRepo,
        nativeService: mockNativeService,
      );
    });

    testWidgets('renders all major dashboard sections and handles user actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool openedSettings = false;
      bool navigatedToApps = false;
      bool navigatedToPlan = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardView(
            viewModel: viewModel,
            onOpenSettings: () => openedSettings = true,
            onNavigateToApps: () => navigatedToApps = true,
            onNavigateToPlan: () => navigatedToPlan = true,
          ),
        ),
      );

      // Settle animations and initial async load
      await tester.pumpAndSettle();

      // 1. Verify App Bar elements
      expect(find.text('ByteFlow'), findsOneWidget);
      expect(find.text('Verizon'), findsOneWidget); // Carrier badge

      // 2. Verify Dashboard feature cards
      expect(find.byType(SpeedPulseCard), findsOneWidget);
      expect(find.text('LIVE NETWORK SPEED'), findsOneWidget);

      expect(find.byType(PlanProgressRing), findsOneWidget);
      expect(find.byType(DailyComparisonTile), findsOneWidget);
      expect(find.byType(TopAppsPreviewCard), findsOneWidget);

      // 3. Test settings button tap
      final settingsBtn = find.byIcon(AppIcons.settings);
      expect(settingsBtn, findsOneWidget);
      await tester.tap(settingsBtn);
      expect(openedSettings, isTrue);

      // 4. Test carrier badge tap triggers plan navigation
      final carrierBadge = find.text('Verizon');
      await tester.tap(carrierBadge);
      expect(navigatedToPlan, isTrue);

      // 5. Test top apps 'View All' tap triggers apps navigation
      final viewAllBtn = find.text('View All');
      expect(viewAllBtn, findsOneWidget);
      await tester.tap(viewAllBtn);
      expect(navigatedToApps, isTrue);
    });
  });
}
