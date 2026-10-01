import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/time_range.dart';
import '../../../core/widgets/empty_state_card.dart';
import '../view_models/history_view_model.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/history_filter_modal_sheet.dart';
import '../widgets/hourly_spike_chart.dart';
import '../widgets/monthly_trajectory_chart.dart';
import '../widgets/weekly_comparison_chart.dart';
import '../widgets/yearly_distribution_chart.dart';

/// The History & Trends analytics view rendering multi-timeframe charts and network slice filtering.
class HistoryView extends StatefulWidget {
  final HistoryViewModel viewModel;

  const HistoryView({
    super.key,
    required this.viewModel,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.init();
  }

  void _openFilterSheet(BuildContext context, HistoryViewModel vm) {
    HistoryFilterModalSheet.show(
      context,
      selectedRange: vm.selectedRange,
      onRangeChanged: vm.setTimeRange,
      selectedNetworkType: vm.selectedNetworkType,
      onNetworkTypeChanged: vm.setNetworkType,
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
        final summary = vm.summary;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Usage History & Trends',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(AppIcons.refresh),
                tooltip: 'Refresh',
                onPressed: vm.loadData,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              // Compact Quick-Pills Filter Bar
              HistoryFilterBar(
                selectedRange: vm.selectedRange,
                onRangeChanged: vm.setTimeRange,
                selectedNetworkType: vm.selectedNetworkType,
                onNetworkTypeChanged: vm.setNetworkType,
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
                      '${vm.selectedRange.displayName} • Total: ${ByteFormatter.format(vm.totalFilteredBytes)}',
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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

              // Content Area
              Expanded(
                child: vm.isLoading && summary == null
                    ? const Center(child: CircularProgressIndicator())
                    : summary == null
                        ? EmptyStateCard(
                            icon: AppIcons.search,
                            title: 'No Telemetry Recorded',
                            message: vm.isFiltered
                                ? 'No usage recorded matching current filter settings.'
                                : 'No historical telemetry recorded for this timeframe.',
                            actionLabel:
                                vm.isFiltered ? 'Reset Filters' : 'Refresh',
                            onActionPressed: vm.isFiltered
                                ? vm.resetFilters
                                : vm.loadData,
                          )
                        : RefreshIndicator(
                            onRefresh: vm.loadData,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              children: [
                                // Dynamic Chart Card
                                Card(
                                  elevation: 0,
                                  color: colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getChartTitle(vm.selectedRange),
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                            color:
                                                colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildDynamicChart(vm, summary),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getChartTitle(TimeRange range) => switch (range) {
        TimeRange.today => '24-HOUR HOURLY TRAFFIC',
        TimeRange.week => '7-DAY COMPARATIVE CONSUMPTION',
        TimeRange.month => '30-DAY CUMULATIVE QUOTA PACE',
        TimeRange.year => '12-MONTH HISTORICAL DISTRIBUTION',
      };

  Widget _buildDynamicChart(
    HistoryViewModel vm,
    dynamic summary,
  ) {
    return switch (vm.selectedRange) {
      TimeRange.today => HourlySpikeChart(
          buckets: summary.buckets,
          networkType: vm.selectedNetworkType,
        ),
      TimeRange.week => WeeklyComparisonChart(
          buckets: summary.buckets,
          networkType: vm.selectedNetworkType,
        ),
      TimeRange.month => MonthlyTrajectoryChart(
          buckets: summary.buckets,
          quotaBytes: vm.quotaBytes,
          networkType: vm.selectedNetworkType,
        ),
      TimeRange.year => YearlyDistributionChart(
          buckets: summary.buckets,
          networkType: vm.selectedNetworkType,
        ),
    };
  }
}
