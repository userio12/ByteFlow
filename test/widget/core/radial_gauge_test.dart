import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/ui/core/animations/radial_gauge.dart';

void main() {
  group('RadialGauge Widget Test', () {
    testWidgets('renders CustomPaint and child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RadialGauge(
              percent: 0.65,
              size: 200,
              strokeWidth: 16,
              child: Text('65% Consumed'),
            ),
          ),
        ),
      );

      // Verify widget tree hierarchy
      expect(find.byType(RadialGauge), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('65% Consumed'), findsOneWidget);

      // Let animation settle
      await tester.pumpAndSettle();
      expect(find.text('65% Consumed'), findsOneWidget);
    });

    testWidgets('handles zero and 100% boundary values without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RadialGauge(percent: 0.0, child: Text('0%')),
                RadialGauge(percent: 1.0, child: Text('100%')),
                RadialGauge(percent: 1.5, child: Text('Overflow')), // clamped at 1.0
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Overflow'), findsOneWidget);
    });
  });
}
