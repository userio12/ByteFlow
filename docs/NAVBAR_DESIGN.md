# ByteFlow — Navigation Bar (Navbar) & Adaptive Navigation Specification

> **Governed by Official Flutter Agent Skills**:
> - [`flutter-build-responsive-layout`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-build-responsive-layout/SKILL.md)
> - [`flutter-apply-architecture-best-practices`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md)

This document details the Material 3 Navigation Bar architecture, responsive breakpoints, state preservation strategy, typography, haptics, and visual tokens for **ByteFlow**.

---

## 1. Material 3 Navigation Architecture

ByteFlow strictly implements the official Flutter responsive layout guidelines (`flutter-build-responsive-layout`):
- **Mobile Screens (`width < 600dp`)**: Bottom-aligned Material 3 `NavigationBar`.
- **Foldables & Tablets (`width >= 600dp`)**: Adaptive leading `NavigationRail` or expanded drawer to maximize vertical reading area and avoid horizontal stretching.

```
Mobile Layout (< 600dp)                  Tablet / Foldable Layout (>= 600dp)
+-------------------------------+        +-----------------------------------------------+
|          Screen Body          |        | [NavRail] |                                   |
|                               |        |   [⚡]    |                 Screen Body       |
|                               |        |   [📱]    |                                   |
|                               |        |   [📈]    |                                   |
|                               |        |   [📋]    |                                   |
+-------------------------------+        |           |                                   |
| [⚡Dash] [📱Apps] [📈Hist] [📋Plan]|        +-----------+-----------------------------------+
+-------------------------------+
```

---

## 2. Destinations & Iconography

| Destination | Active Icon | Inactive Icon | Label | Dynamic Badge | Tooltip |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Dashboard** | `Icons.speed_rounded` | `Icons.speed_outlined` | `Dashboard` | Live green pulse dot (when traffic > 100 KB/s) | Live speed & daily overview |
| **2. App Usage** | `Icons.apps_rounded` | `Icons.apps_outlined` | `Apps` | None | Per-app data detective |
| **3. History** | `Icons.insights_rounded` | `Icons.insights_outlined` | `History` | None | Hourly, Weekly, Monthly & Yearly analytics |
| **4. Plan** | `Icons.pie_chart_rounded` | `Icons.pie_chart_outline_rounded` | `Plan` | Amber `!` dot if usage > 80% quota | Active carrier & data quota |

---

## 3. Visual Tokens & Material 3 Styling

```dart
NavigationBarThemeData(
  height: 68.0,
  elevation: 0.0,
  backgroundColor: colorScheme.surfaceContainer,
  surfaceTintColor: Colors.transparent,
  indicatorColor: colorScheme.secondaryContainer,
  indicatorShape: const StadiumBorder(),
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  labelTextStyle: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.2,
      );
    }
    return TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant,
      letterSpacing: 0.2,
    );
  }),
  iconTheme: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return IconThemeData(
        color: colorScheme.onSecondaryContainer,
        size: 24.0,
      );
    }
    return IconThemeData(
      color: colorScheme.onSurfaceVariant,
      size: 24.0,
    );
  }),
)
```

---

## 4. State Preservation Strategy (`IndexedStack`)

A common mistake in mobile apps is rebuilding tabs from scratch on every switch, destroying scroll positions, filter states, and search queries.

ByteFlow wraps all 4 primary destinations in an **`IndexedStack`**:
```dart
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _destinations = const [
    DashboardView(),
    AppUsageView(),
    HistoryView(),
    PlanView(),
  ];

  void _onDestinationSelected(int index) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 600.0;
        
        if (isLargeScreen) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: _buildRailDestinations(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _destinations,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _destinations,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: _buildBarDestinations(),
          ),
        );
      },
    );
  }
}
```

### Benefits:
1. **Instant Tab Switching**: Switching between Dashboard, Apps, and History takes 0 milliseconds with no reloading spinners.
2. **Scroll Offset Retention**: If the user scrolls down to app #45 in the App Usage list, switches to History, and returns to Apps, the scroll position is exactly where they left it.
3. **Zero Unnecessary NetworkStats Queries**: Does not re-query hardware accounting tables on every tab switch.

---

## 5. Micro-Interactions & Haptic Touch

1. **Light Haptic Click**: Triggered via `HapticFeedback.selectionClick()` on every tab change for physical tactile feedback.
2. **Pill Indicator Sweep**: Material 3 stadium pill expands smoothly (`200ms` `Curves.easeInOutCubic`) behind the selected icon.
3. **Live Indicator Badge**: The Dashboard tab features a subtle green glowing dot that animates when active traffic exceeds 100 KB/s.
4. **Quota Warning Badge**: When remaining data drops below 20%, a soft amber badge appears on the Plan tab icon to alert the user without intrusive dialogs.
