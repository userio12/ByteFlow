import 'package:flutter/material.dart';
import '../../../../domain/models/time_range.dart';
import '../../../core/widgets/time_range_segmented_button.dart';
import '../view_models/history_view_model.dart';
import '../widgets/hourly_spike_chart.dart';
import '../widgets/insights_grid.dart';
import '../widgets/monthly_trajectory_chart.dart';
import '../widgets/spike_culprit_card.dart';
import '../widgets/weekly_comparison_chart.dart';
import '../widgets/yearly_distribution_chart.dart';

/// The History & Trends analytics view rendering multi-timeframe charts and spike analysis.
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
          ),
          body: Column(
            children: [
              // Top TimeRange Switcher
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TimeRangeSegmentedButton(
                  selectedRange: vm.selectedRange,
                  onRangeChanged: vm.setTimeRange,
                ),
              ),
              const Divider(height: 1),

              // Content Area
              Expanded(
                child: vm.isLoading && summary == null
                    ? const Center(child: CircularProgressIndicator())
                    : summary == null
                        ? Center(
                            child: Text(
                              'No historical telemetry recorded.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: vm.loadData,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              children: [
                                // 1. Dynamic Chart Card
                                Card(
                                  elevation: 0,
                                  color: colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildDynamicChart(vm, summary),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 2. Spike Culprit Card (For Today range)
                                if (vm.selectedRange == TimeRange.today) ...[
                                  SpikeCulpritCard(spike: vm.selectedSpike),
                                  const SizedBox(height: 12),
                                ],

                                // 3. Insights Grid
                                InsightsGrid(summary: summary),
                                const SizedBox(height: 24),
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
          selectedHour: vm.selectedHourIndex,
          onHourSelected: vm.selectHour,
        ),
      TimeRange.week => WeeklyComparisonChart(buckets: summary.buckets),
      TimeRange.month => MonthlyTrajectoryChart(
          buckets: summary.buckets,
          quotaBytes: vm.quotaBytes,
        ),
      TimeRange.year => YearlyDistributionChart(buckets: summary.buckets),
    };
  }
}
