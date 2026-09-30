import 'package:flutter/material.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../domain/models/time_range.dart';
import '../../../core/widgets/time_range_segmented_button.dart';
import '../view_models/history_view_model.dart';
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

              // Network Filter Chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Network: ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildNetworkChip(
                        label: 'All',
                        icon: null,
                        type: ChannelConstants.networkTypeAll,
                        colorScheme: colorScheme,
                        selectedType: vm.selectedNetworkType,
                        onChanged: vm.setNetworkType,
                      ),
                      const SizedBox(width: 6),
                      _buildNetworkChip(
                        label: 'Mobile',
                        icon: AppIcons.cellular,
                        type: ChannelConstants.networkTypeMobile,
                        colorScheme: colorScheme,
                        selectedType: vm.selectedNetworkType,
                        onChanged: vm.setNetworkType,
                      ),
                      const SizedBox(width: 6),
                      _buildNetworkChip(
                        label: 'Wi-Fi',
                        icon: AppIcons.wifi,
                        type: ChannelConstants.networkTypeWifi,
                        colorScheme: colorScheme,
                        selectedType: vm.selectedNetworkType,
                        onChanged: vm.setNetworkType,
                      ),
                    ],
                  ),
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

  Widget _buildNetworkChip({
    required String label,
    required IconData? icon,
    required int type,
    required ColorScheme colorScheme,
    required int selectedType,
    required ValueChanged<int> onChanged,
  }) {
    final isSelected = selectedType == type;

    return ChoiceChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 15,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            )
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(type),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
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
