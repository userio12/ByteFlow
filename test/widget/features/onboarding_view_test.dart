import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:byteflow/ui/features/onboarding/views/onboarding_view.dart';

import '../../mocks/mock_native_network_service.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('OnboardingView Widget Test', () {
    late FakeSettingsRepository fakeSettingsRepo;
    late MockNativeNetworkService mockNativeService;
    late OnboardingViewModel viewModel;

    setUp(() {
      fakeSettingsRepo = FakeSettingsRepository();
      mockNativeService = MockNativeNetworkService(
        usagePermissionGranted: false,
        phoneStatePermissionGranted: false,
      );
      viewModel = OnboardingViewModel(
        settingsRepository: fakeSettingsRepo,
        nativeService: mockNativeService,
      );
    });

    testWidgets('renders initial welcome slide and navigates through carousel',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool onFinishedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingView(
            viewModel: viewModel,
            onFinished: () {
              onFinishedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Step 1 of 5
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Welcome to ByteFlow'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next to go to Slide 2 (100% On-Device & Private)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.text('100% On-Device & Private'), findsOneWidget);

      // Tap Next to go to Slide 3 (Usage Access)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.text('Usage Access Permission'), findsOneWidget);

      // Tap Next to go to Slide 4 (SIM & Notification Access)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 4 of 5'), findsOneWidget);
      expect(find.text('SIM & Notification Access'), findsOneWidget);

      // Tap Next to go to Slide 5 (You're Ready to Flow!)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 5 of 5'), findsOneWidget);
      expect(find.text("You're Ready to Flow!"), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap Get Started on the final slide
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(onFinishedCalled, isTrue);
      expect(fakeSettingsRepo.onboardingCompleted, isTrue);
    });

    testWidgets('Skip button immediately completes onboarding',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool onFinishedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingView(
            viewModel: viewModel,
            onFinished: () {
              onFinishedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Skip
      final skipBtn = find.text('Skip');
      expect(skipBtn, findsOneWidget);
      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      expect(onFinishedCalled, isTrue);
      expect(fakeSettingsRepo.onboardingCompleted, isTrue);
    });
  });
}
