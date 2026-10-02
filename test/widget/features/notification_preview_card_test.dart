import 'package:byteflow/ui/features/settings/widgets/notification_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPreviewCard Widget Test', () {
    Widget buildSubject({
      bool useBits = false,
      bool isStatusBarSpeedIcon = true,
      bool isLiveSpeedEnabled = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: NotificationPreviewCard(
            useBits: useBits,
            isStatusBarSpeedIcon: isStatusBarSpeedIcon,
            isLiveSpeedEnabled: isLiveSpeedEnabled,
          ),
        ),
      );
    }

    testWidgets('renders initial collapsed preview with speed pills and status bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('NOTIFICATION PREVIEW'), findsOneWidget);
      expect(find.text('Collapsed'), findsOneWidget);
      expect(find.text('Expanded'), findsOneWidget);

      // Status bar simulation
      expect(find.text('10:09'), findsOneWidget);
      expect(find.text('14M'), findsOneWidget); // Dynamic status bar speed icon

      // Collapsed view pills
      expect(find.text('↓ '), findsOneWidget);
      expect(find.text('↑ '), findsOneWidget);
      expect(find.text('14.8 MB/s'), findsOneWidget);
      expect(find.text('2.1 MB/s'), findsOneWidget);
      expect(find.text('Today: 1.65 GB'), findsOneWidget);
    });

    testWidgets('switches to expanded view when tapping Expanded segmented button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap 'Expanded'
      await tester.tap(find.text('Expanded'));
      await tester.pumpAndSettle();

      expect(find.text('ByteFlow • Speed Monitor'), findsOneWidget);
      expect(find.text('● Live'), findsOneWidget);
      expect(find.text('Wi-Fi 5G'), findsOneWidget);
      expect(find.text('DOWNLOAD'), findsOneWidget);
      expect(find.text('UPLOAD'), findsOneWidget);
      expect(find.text("Today's Usage"), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);

      // Action buttons
      expect(find.text('⚡ Dashboard'), findsOneWidget);
      expect(find.text('📊 Plan'), findsOneWidget);
      expect(find.text('⏸ Pause'), findsOneWidget);
    });

    testWidgets('renders bits formatting when useBits is true', (tester) async {
      await tester.pumpWidget(buildSubject(useBits: true));
      await tester.pumpAndSettle();

      expect(find.text('118m'), findsOneWidget); // Status bar bits
      expect(find.text('124.2 Mb/s'), findsOneWidget); // Download bits
    });

    testWidgets('renders static icon when isStatusBarSpeedIcon is false', (tester) async {
      await tester.pumpWidget(buildSubject(isStatusBarSpeedIcon: false));
      await tester.pumpAndSettle();

      expect(find.text('14M'), findsNothing);
      expect(find.byIcon(Icons.speed), findsOneWidget);
    });
  });
}
