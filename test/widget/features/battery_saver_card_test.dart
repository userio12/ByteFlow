import 'package:byteflow/ui/features/settings/widgets/battery_saver_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatterySaverCard Widget Tests', () {
    testWidgets('renders Optimized state with request exemption button and handles tap',
        (WidgetTester tester) async {
      var exemptionRequested = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatterySaverCard(
              isBatteryOptimizationsIgnored: false,
              onRequestExemption: () {
                exemptionRequested = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check titles & chips
      expect(find.text('ZERO-DRAIN BATTERY SAVER'), findsOneWidget);
      expect(find.text('OEM TASK KILLER DEFENSE'), findsOneWidget);
      expect(find.text('Optimized'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Verify request exemption button is present and triggers callback
      final button = find.byKey(const Key('request_battery_exemption_button'));
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(exemptionRequested, isTrue);
    });

    testWidgets('renders Whitelisted state without request exemption button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatterySaverCard(
              isBatteryOptimizationsIgnored: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Whitelisted'), findsOneWidget);
      expect(find.byKey(const Key('request_battery_exemption_button')), findsNothing);
    });
  });
}
