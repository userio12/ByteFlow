import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/domain/models/data_plan_entity.dart';
import 'package:byteflow/domain/models/sim_info_entity.dart';
import 'package:byteflow/domain/use_cases/get_active_sim_info_use_case.dart';
import 'package:byteflow/domain/use_cases/get_data_plan_use_case.dart';
import 'package:byteflow/domain/use_cases/get_today_usage_use_case.dart';
import 'package:byteflow/domain/use_cases/save_data_plan_use_case.dart';
import 'package:byteflow/ui/features/plan/view_models/plan_view_model.dart';
import 'package:byteflow/ui/features/plan/views/plan_view.dart';
import 'package:byteflow/ui/features/plan/widgets/carrier_status_card.dart';
import 'package:byteflow/ui/features/plan/widgets/plan_summary_card.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('PlanView Widget Test', () {
    late FakeNetworkRepository fakeNetworkRepo;
    late FakePlanRepository fakePlanRepo;
    late PlanViewModel viewModel;

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
      fakePlanRepo = FakePlanRepository();

      fakeNetworkRepo.activeSims = const [
        SimInfoEntity(
          subId: 1,
          slotIndex: 0,
          carrierName: 'T-Mobile',
          displayName: 'Primary SIM',
          isDefaultData: true,
          isDataRoaming: false,
        ),
      ];

      fakePlanRepo.plan = const DataPlanEntity(
        quotaBytes: 5368709120, // 5 GB
        cycleType: DataPlanCycleType.monthly,
        resetDay: 1,
      );

      viewModel = PlanViewModel(
        getDataPlanUseCase: GetDataPlanUseCase(fakePlanRepo),
        saveDataPlanUseCase: SaveDataPlanUseCase(fakePlanRepo),
        getActiveSimInfoUseCase: GetActiveSimInfoUseCase(fakeNetworkRepo),
        getTodayUsageUseCase: GetTodayUsageUseCase(fakeNetworkRepo),
      );
    });

    testWidgets('renders carrier card, plan summary, and confirms edit buttons are removed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlanView(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify AppBar and primary cards
      expect(find.text('Data Plan & Quotas'), findsOneWidget);
      expect(find.byType(CarrierStatusCard), findsOneWidget);
      expect(find.byType(PlanSummaryCard), findsOneWidget);
      expect(find.text('T-Mobile'), findsOneWidget);

      // 2. Verify edit button is removed from AppBar and PlanSummaryCard
      expect(find.byTooltip('Edit Plan'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.edit_rounded), findsNothing);
    });

    testWidgets('renders empty SIM state when no SIM detected',
        (WidgetTester tester) async {
      fakeNetworkRepo.activeSims = const [];
      final noSimViewModel = PlanViewModel(
        getDataPlanUseCase: GetDataPlanUseCase(fakePlanRepo),
        saveDataPlanUseCase: SaveDataPlanUseCase(fakePlanRepo),
        getActiveSimInfoUseCase: GetActiveSimInfoUseCase(fakeNetworkRepo),
        getTodayUsageUseCase: GetTodayUsageUseCase(fakeNetworkRepo),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlanView(viewModel: noSimViewModel),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty SIM card elements
      expect(find.byType(CarrierStatusCard), findsOneWidget);
      expect(find.text('CELLULAR CARRIER'), findsOneWidget);
      expect(find.text('No SIM'), findsOneWidget);
      expect(find.text('No SIM Card Detected'), findsOneWidget);
      expect(
        find.text('Insert a SIM card or grant Phone State permission.'),
        findsOneWidget,
      );
    });

    testWidgets('CarrierStatusCard renders without overflow on narrow viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CarrierStatusCard(
                activeSim: null,
                allSims: [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CELLULAR CARRIER'), findsOneWidget);
      expect(find.text('No SIM Card Detected'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
