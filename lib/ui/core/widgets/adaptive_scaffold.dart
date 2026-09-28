import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../l10n/app_localizations.dart';

/// A Material 3 responsive layout container adapting between a bottom [NavigationBar]
/// (< 600dp) and a leading [NavigationRail] (>= 600dp).
/// Uses [IndexedStack] to preserve screen state across destination switches.
class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> children;
  final bool hasActiveTraffic;
  final bool hasPlanWarning;
  final double bottomBarCornerRadius;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.children,
    this.hasActiveTraffic = false,
    this.hasPlanWarning = false,
    this.bottomBarCornerRadius = 24.0,
  });

  static const double largeScreenMinWidth = 600.0;

  void _handleDestinationSelected(int index) {
    if (index != currentIndex) {
      HapticFeedback.selectionClick();
      onDestinationSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= largeScreenMinWidth;

        if (isLargeScreen) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: _handleDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: colorScheme.surfaceContainer,
                  indicatorColor: colorScheme.secondaryContainer,
                  destinations: _buildRailDestinations(context),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900.0),
                      child: IndexedStack(
                        index: currentIndex,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final topRadius = Radius.circular(bottomBarCornerRadius);
        final topRoundedBorderRadius = BorderRadius.only(
          topLeft: topRadius,
          topRight: topRadius,
        );

        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: children,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: topRoundedBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.25 : 0.08,
                  ),
                  blurRadius: 10.0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: topRoundedBorderRadius,
              clipBehavior: Clip.antiAlias,
              child: NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: _handleDestinationSelected,
                backgroundColor: colorScheme.surfaceContainer,
                indicatorColor: colorScheme.secondaryContainer,
                destinations: _buildBarDestinations(context),
              ),
            ),
          ),
        );
      },
    );
  }

  List<NavigationDestination> _buildBarDestinations(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dashboardLabel = l10n?.tabDashboard ?? 'Dashboard';
    final appsLabel = l10n?.tabApps ?? 'Apps';
    final historyLabel = l10n?.tabHistory ?? 'History';
    final planLabel = l10n?.tabPlan ?? 'Plan';

    return [
      NavigationDestination(
        icon: Badge(
          isLabelVisible: hasActiveTraffic,
          backgroundColor: AppColors.wifi,
          smallSize: 8,
          child: const Icon(AppIcons.dashboardInactive),
        ),
        selectedIcon: Badge(
          isLabelVisible: hasActiveTraffic,
          backgroundColor: AppColors.wifi,
          smallSize: 8,
          child: const Icon(AppIcons.dashboardActive),
        ),
        label: dashboardLabel,
        tooltip: 'Live speed & daily overview',
      ),
      NavigationDestination(
        icon: const Icon(AppIcons.appsInactive),
        selectedIcon: const Icon(AppIcons.appsActive),
        label: appsLabel,
        tooltip: 'Per-app data detective',
      ),
      NavigationDestination(
        icon: const Icon(AppIcons.historyInactive),
        selectedIcon: const Icon(AppIcons.historyActive),
        label: historyLabel,
        tooltip: 'Multi-timeframe analytics',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: hasPlanWarning,
          backgroundColor: AppColors.statusWarning,
          smallSize: 8,
          child: const Icon(AppIcons.planInactive),
        ),
        selectedIcon: Badge(
          isLabelVisible: hasPlanWarning,
          backgroundColor: AppColors.statusWarning,
          smallSize: 8,
          child: const Icon(AppIcons.planActive),
        ),
        label: planLabel,
        tooltip: 'Active carrier & data quota',
      ),
    ];
  }

  List<NavigationRailDestination> _buildRailDestinations(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dashboardLabel = l10n?.tabDashboard ?? 'Dashboard';
    final appsLabel = l10n?.tabApps ?? 'Apps';
    final historyLabel = l10n?.tabHistory ?? 'History';
    final planLabel = l10n?.tabPlan ?? 'Plan';

    return [
      NavigationRailDestination(
        icon: Badge(
          isLabelVisible: hasActiveTraffic,
          backgroundColor: AppColors.wifi,
          smallSize: 8,
          child: const Icon(AppIcons.dashboardInactive),
        ),
        selectedIcon: Badge(
          isLabelVisible: hasActiveTraffic,
          backgroundColor: AppColors.wifi,
          smallSize: 8,
          child: const Icon(AppIcons.dashboardActive),
        ),
        label: Text(dashboardLabel),
      ),
      NavigationRailDestination(
        icon: const Icon(AppIcons.appsInactive),
        selectedIcon: const Icon(AppIcons.appsActive),
        label: Text(appsLabel),
      ),
      NavigationRailDestination(
        icon: const Icon(AppIcons.historyInactive),
        selectedIcon: const Icon(AppIcons.historyActive),
        label: Text(historyLabel),
      ),
      NavigationRailDestination(
        icon: Badge(
          isLabelVisible: hasPlanWarning,
          backgroundColor: AppColors.statusWarning,
          smallSize: 8,
          child: const Icon(AppIcons.planInactive),
        ),
        selectedIcon: Badge(
          isLabelVisible: hasPlanWarning,
          backgroundColor: AppColors.statusWarning,
          smallSize: 8,
          child: const Icon(AppIcons.planActive),
        ),
        label: Text(planLabel),
      ),
    ];
  }
}
