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

    testWidgets('renders initial collapsed Samsung One UI preview without app title', (tester) async {
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

      // Unit text should be styled with light-blue color inside the notification card
      final cardUnitFinder = find.descendant(
        of: find.byKey(const ValueKey('collapsed_card')),
        matching: find.text('KB/s'),
      );
      final unitText = tester.widget<Text>(cardUnitFinder);
      expect(unitText.style?.color, const Color(0xFF7CA8F8));

      // Collapsed view text lines
      expect(find.text('Down: 0 B/s   Up: 0 B/s'), findsOneWidget);
      expect(find.text('Mobile: 910.4 MB   WiFi: 0 MB'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      // Crucial: App title must NOT be in collapsed view
      expect(find.text('Internet Speed Meter Lite'), findsNothing);
    });

    testWidgets('switches to expanded view with app identity header and upward chevron', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap 'Expanded'
      await tester.tap(find.text('Expanded'));
      await tester.pumpAndSettle();

      // App identity header is now visible
      expect(find.text('Internet Speed Meter Lite'), findsOneWidget);
      expect(find.text('Down: 0 B/s   Up: 0 B/s'), findsOneWidget);
      expect(find.text('Mobile: 910.4 MB   WiFi: 0 MB'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);

      // Obsolete buttons should not exist
      expect(find.text('⚡ Dashboard'), findsNothing);
      expect(find.text('⏸ Pause'), findsNothing);
    });

    testWidgets('renders bits formatting when useBits is true', (tester) async {
      await tester.pumpWidget(buildSubject(useBits: true));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
      expect(find.text('Kbps'), findsWidgets);
      expect(find.text('Down: 0 b/s   Up: 0 b/s'), findsOneWidget);
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
      expect(find.text('Internet Speed Meter Lite'), findsNothing);

      // Tap collapsed card -> should expand
      await tester.tap(find.byKey(const ValueKey('collapsed_card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('expanded_card')), findsOneWidget);
      expect(find.text('Internet Speed Meter Lite'), findsOneWidget);

      // Tap expanded card -> should collapse
      await tester.tap(find.byKey(const ValueKey('expanded_card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('collapsed_card')), findsOneWidget);
      expect(find.text('Internet Speed Meter Lite'), findsNothing);
    });
  });
}
