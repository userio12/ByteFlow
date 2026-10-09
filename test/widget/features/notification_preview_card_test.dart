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
          body: SingleChildScrollView(
            child: NotificationPreviewCard(
              useBits: useBits,
              isStatusBarSpeedIcon: isStatusBarSpeedIcon,
              isLiveSpeedEnabled: isLiveSpeedEnabled,
            ),
          ),
        ),
      );
    }

    testWidgets('renders initial collapsed preview without app title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('NOTIFICATION PREVIEW'), findsOneWidget);
      expect(find.text('Collapsed'), findsOneWidget);
      expect(find.text('Expanded'), findsOneWidget);

      // Status bar simulation
      expect(find.text('10:14'), findsOneWidget);
      expect(find.text('91%'), findsOneWidget);

      // Speed indicator: 0 KB/s (numeric on top, unit underneath)
      expect(find.text('0'), findsWidgets);
      expect(find.text('KB/s'), findsWidgets);

      // Unit text should be styled with light-blue color inside the status bar strip
      final statusUnitFinder = find.text('KB/s');
      final unitText = tester.widget<Text>(statusUnitFinder);
      expect(unitText.style?.color, const Color(0xFF8AB4F8));

      // Collapsed view throughput speeds
      expect(find.text('Down: '), findsOneWidget);
      expect(find.text('Up: '), findsOneWidget);
      expect(find.text('0 B/s'), findsNWidgets(2));
      expect(find.text('Mobile: 910.4 MB  •  Wi-Fi: 0 MB'), findsOneWidget);

      // Bottom notification shade controls
      expect(find.text('Notification settings'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Crucial: App title must NOT be in collapsed view
      expect(find.text('ByteFlow'), findsNothing);
      expect(find.text('Internet Speed Meter Lite'), findsNothing);
    });

    testWidgets('switches to expanded view with network info, speeds, and quota status', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap 'Expanded'
      await tester.tap(find.text('Expanded'));
      await tester.pumpAndSettle();

      // Network connection line is visible
      expect(find.text('Wi-Fi • Connected'), findsOneWidget);
      expect(find.text('Down: '), findsOneWidget);
      expect(find.text('Up: '), findsOneWidget);
      expect(find.text('0 B/s'), findsNWidgets(2));
      expect(find.text('Today: 910.4 MB Mobile  •  0 MB Wi-Fi'), findsOneWidget);
      expect(find.text('Data Plan: Active (Quota: 1.8 GB remaining)'), findsOneWidget);

      // App identity must NOT be duplicated in card body
      expect(find.text('ByteFlow'), findsNothing);
      expect(find.text('DOWN'), findsNothing);
      expect(find.text('UP'), findsNothing);

      // Obsolete buttons and legacy text should not exist
      expect(find.text('Internet Speed Meter Lite'), findsNothing);
      expect(find.text('⚡ Dashboard'), findsNothing);
      expect(find.text('⏸ Pause'), findsNothing);
      expect(find.text('Today\'s Usage'), findsNothing);
    });

    testWidgets('renders bits formatting when useBits is true', (tester) async {
      await tester.pumpWidget(buildSubject(useBits: true));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
      expect(find.text('Kbps'), findsOneWidget);
      expect(find.text('Down: '), findsOneWidget);
      expect(find.text('Up: '), findsOneWidget);
      expect(find.text('0 b/s'), findsNWidgets(2));
    });

    testWidgets('renders static icon when isStatusBarSpeedIcon is false', (tester) async {
      await tester.pumpWidget(buildSubject(isStatusBarSpeedIcon: false));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('toggles One UI notification shade context with quick settings', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Sun, 4 Oct'), findsNothing);

      // Tap shade context toggle
      await tester.tap(find.byKey(const ValueKey('shade_context_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Sun, 4 Oct'), findsOneWidget);
      expect(find.text('Notification settings'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('tapping card directly toggles between collapsed and expanded states', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.byKey(const ValueKey('collapsed_card')), findsOneWidget);
      expect(find.text('ByteFlow'), findsNothing);

      // Tap collapsed card -> should expand
      await tester.tap(find.byKey(const ValueKey('collapsed_card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('expanded_card')), findsOneWidget);
      expect(find.text('Wi-Fi • Connected'), findsOneWidget);
      expect(find.text('ByteFlow'), findsNothing);
      expect(find.text('DOWN'), findsNothing);
      expect(find.text('UP'), findsNothing);

      // Tap expanded card -> should collapse
      await tester.tap(find.byKey(const ValueKey('expanded_card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('collapsed_card')), findsOneWidget);
      expect(find.text('ByteFlow'), findsNothing);
    });
  });
}
