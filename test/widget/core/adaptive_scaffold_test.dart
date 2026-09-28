import 'package:byteflow/ui/core/widgets/adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveScaffold Widget Tests', () {
    testWidgets('renders bottom navigation bar with rounded top corners on mobile screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            currentIndex: selectedIndex,
            onDestinationSelected: (index) => selectedIndex = index,
            children: const [
              Text('Tab 0'),
              Text('Tab 1'),
              Text('Tab 2'),
              Text('Tab 3'),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify ClipRRect exists and has top-left and top-right rounded corners
      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsOneWidget);

      final clipRRect = tester.widget<ClipRRect>(clipRRectFinder);
      final borderRadius = clipRRect.borderRadius as BorderRadius;

      expect(borderRadius.topLeft, equals(const Radius.circular(24.0)));
      expect(borderRadius.topRight, equals(const Radius.circular(24.0)));
      expect(borderRadius.bottomLeft, equals(Radius.zero));
      expect(borderRadius.bottomRight, equals(Radius.zero));

      // Verify Container wrapping ClipRRect has matching border radius and shadow
      final containerFinder = find.ancestor(
        of: clipRRectFinder,
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      final containerRadius = decoration!.borderRadius as BorderRadius;
      expect(containerRadius.topLeft, equals(const Radius.circular(24.0)));
      expect(containerRadius.topRight, equals(const Radius.circular(24.0)));
      expect(decoration.boxShadow, isNotEmpty);

      // Verify NavigationBar is descendant of ClipRRect
      final navBarInClip = find.descendant(
        of: clipRRectFinder,
        matching: find.byType(NavigationBar),
      );
      expect(navBarInClip, findsOneWidget);
    });

    testWidgets('supports custom bottomBarCornerRadius',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            currentIndex: 0,
            bottomBarCornerRadius: 32.0,
            onDestinationSelected: (_) {},
            children: const [
              Text('Tab 0'),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      final borderRadius = clipRRect.borderRadius as BorderRadius;

      expect(borderRadius.topLeft, equals(const Radius.circular(32.0)));
      expect(borderRadius.topRight, equals(const Radius.circular(32.0)));
      expect(borderRadius.bottomLeft, equals(Radius.zero));
      expect(borderRadius.bottomRight, equals(Radius.zero));
    });

    testWidgets('handles destination selection clicks',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return AdaptiveScaffold(
                currentIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                children: const [
                  Text('Content 0'),
                  Text('Content 1'),
                  Text('Content 2'),
                  Text('Content 3'),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Content 0'), findsOneWidget);

      // Tap on Apps destination (second destination)
      await tester.tap(find.text('Apps'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));
      expect(find.text('Content 1'), findsOneWidget);
    });

    testWidgets('renders badges for active traffic and plan warning',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            currentIndex: 0,
            hasActiveTraffic: true,
            hasPlanWarning: true,
            onDestinationSelected: (_) {},
            children: const [Text('Content')],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check badges are present
      final badges = tester.widgetList<Badge>(find.byType(Badge));
      final visibleBadges = badges.where((b) => b.isLabelVisible).toList();
      expect(visibleBadges.length, greaterThanOrEqualTo(2));
    });

    testWidgets('switches to NavigationRail on wide screen (>= 600dp)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            currentIndex: 0,
            onDestinationSelected: (_) {},
            children: const [Text('Content')],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(ClipRRect), findsNothing);
    });
  });
}
