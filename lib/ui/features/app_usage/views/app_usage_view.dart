import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../core/widgets/empty_state_card.dart';
import '../view_models/app_usage_view_model.dart';
import '../widgets/app_details_bottom_sheet.dart';
import '../widgets/app_filter_modal_sheet.dart';
import '../widgets/app_search_filter_bar.dart';
import '../widgets/app_usage_tile.dart';

/// The App Usage Detective view rendering a virtualized list of per-app network consumption.
class AppUsageView extends StatefulWidget {
  final AppUsageViewModel viewModel;

  const AppUsageView({
    super.key,
    required this.viewModel,
  });

  @override
  State<AppUsageView> createState() => _AppUsageViewState();
}

class _AppUsageViewState extends State<AppUsageView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.init();
  }

  void _openFilterSheet(BuildContext context, AppUsageViewModel vm) {
    AppFilterModalSheet.show(
      context,
      selectedRange: vm.selectedRange,
      onRangeChanged: vm.setTimeRange,
      selectedNetworkType: vm.selectedNetworkType,
      onNetworkTypeChanged: vm.setNetworkType,
      selectedAppType: vm.selectedAppType,
      onAppTypeChanged: vm.setAppType,
      selectedSortOrder: vm.sortOrder,
      onSortOrderChanged: vm.setSortOrder,
      onReset: vm.resetFilters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final apps = vm.filteredApps;
        final maxBytes = apps.isNotEmpty ? apps.first.totalBytes : 1;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'App Data Usage',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(AppIcons.refresh),
                tooltip: 'Refresh',
                onPressed: vm.loadApps,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              // Compact Search & Filter controls
              AppSearchFilterBar(
                searchQuery: vm.searchQuery,
                onSearchChanged: vm.setSearchQuery,
                selectedNetworkType: vm.selectedNetworkType,
                onNetworkTypeChanged: vm.setNetworkType,
                selectedRange: vm.selectedRange,
                onRangeChanged: vm.setTimeRange,
                selectedAppType: vm.selectedAppType,
                onAppTypeChanged: vm.setAppType,
                selectedSortOrder: vm.sortOrder,
                onSortOrderChanged: vm.setSortOrder,
                onOpenFilterSheet: () => _openFilterSheet(context, vm),
                isFiltered: vm.isFiltered,
              ),

              // Summary & Reset Banner
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${apps.length} apps • Total: ${ByteFormatter.format(vm.totalFilteredBytes)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (vm.isFiltered)
                      InkWell(
                        onTap: vm.resetFilters,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Reset Filters',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Virtualized App List
              Expanded(
                child: vm.isLoading && apps.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : apps.isEmpty
                        ? EmptyStateCard(
                            icon: AppIcons.search,
                            title: 'No Applications Found',
                            message: vm.searchQuery.isNotEmpty
                                ? 'No applications match "${vm.searchQuery}".'
                                : vm.isFiltered
                                    ? 'No usage recorded matching current filter settings.'
                                    : 'No network usage recorded for this time range.',
                            actionLabel: vm.isFiltered
                                ? 'Reset Filters'
                                : 'Refresh',
                            onActionPressed: vm.isFiltered
                                ? vm.resetFilters
                                : vm.loadApps,
                          )
                        : RefreshIndicator(
                            onRefresh: vm.loadApps,
                            child: ListView.builder(
                              itemExtent: AppUsageTile.tileHeight,
                              itemCount: apps.length,
                              itemBuilder: (context, index) {
                                final app = apps[index];
                                return AppUsageTile(
                                  app: app,
                                  maxBytes: maxBytes,
                                  onTap: () =>
                                      AppDetailsBottomSheet.show(context, app),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
