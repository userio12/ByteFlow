import 'package:byteflow/domain/models/speed_sample_entity.dart';
import 'package:byteflow/ui/core/animations/pulse_indicator.dart';
import 'package:byteflow/ui/features/dashboard/widgets/speed_pulse_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpeedPulseCard Widget Test', () {
    testWidgets('renders idle state when throughput is zero',
        (WidgetTester tester) async {
      final idleSpeed = SpeedSampleEntity(
        downloadBps: 0,
        uploadBps: 0,
        timestamp: DateTime(2026, 9, 26),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedPulseCard(speed: idleSpeed),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('LIVE NETWORK SPEED'), findsOneWidget);
      expect(find.text('Idle'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);

      final pulse = tester.widget<PulseIndicator>(find.byType(PulseIndicator));
      expect(pulse.isActive, isFalse);
    });

    testWidgets('renders live pulse active state when throughput > 1 KB/s',
        (WidgetTester tester) async {
      // 5 MB/s download, 1 MB/s upload
      final activeSpeed = SpeedSampleEntity(
        downloadBps: 5 * 1024 * 1024,
        uploadBps: 1024 * 1024,
        timestamp: DateTime(2026, 9, 26),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedPulseCard(speed: activeSpeed),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Live Pulse'), findsOneWidget);
      final pulse = tester.widget<PulseIndicator>(find.byType(PulseIndicator));
      expect(pulse.isActive, isTrue);
    });

    testWidgets('renders speed in bits when useBits is true',
        (WidgetTester tester) async {
      // 1 MB/s = 8 Mbps
      final speed = SpeedSampleEntity(
        downloadBps: 1024 * 1024,
        uploadBps: 512 * 1024,
        timestamp: DateTime(2026, 9, 26),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedPulseCard(
              speed: speed,
              useBits: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SpeedPulseCard), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
    });
  });
}
