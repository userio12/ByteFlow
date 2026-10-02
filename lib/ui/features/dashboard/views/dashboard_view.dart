import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../domain/models/network_summary_entity.dart';
import '../../../core/widgets/carrier_badge.dart';
import '../../plan/view_models/plan_view_model.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../view_models/dashboard_view_model.dart';
import '../widgets/daily_comparison_tile.dart';
import '../widgets/plan_progress_ring.dart';
import '../widgets/speed_pulse_card.dart';

/// The primary Dashboard view presenting live network throughput, daily mobile/Wi-Fi splits,
/// and monthly quota progress.
class DashboardView extends StatefulWidget {
  final DashboardViewModel viewModel;
  final bool useBits;
  final VoidCallback? onNavigateToApps;
  final VoidCallback? onNavigateToPlan;
  final VoidCallback? onOpenSettings;

  const DashboardView({
    super.key,
    required this.viewModel,
    this.useBits = false,
    this.onNavigateToApps,
    this.onNavigateToPlan,
    this.onOpenSettings,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final sim = vm.activeSim;
        final summary = vm.todaySummary ??
            NetworkSummaryEntity(
              mobileRx: 0,
              mobileTx: 0,
              wifiRx: 0,
              wifiTx: 0,
              startTime: DateTime.now(),
              endTime: DateTime.now(),
            );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'ByteFlow',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              if (sim != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CarrierBadge(
                    carrierName: sim.carrierName,
                    slotIndex: sim.slotIndex,
                    isDefaultData: sim.isDefaultData,
                    isRoaming: sim.isDataRoaming,
                    onTap: widget.onNavigateToPlan,
                  ),
                ),
              IconButton(
                icon: const Icon(AppIcons.settings),
                tooltip: 'Settings',
                onPressed: widget.onOpenSettings,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: vm.isLoading && vm.todaySummary == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    children: [
                      // 1. Live Throughput Card
                      Builder(
                        builder: (ctx) {
                          final settingsVm = ctx.watch<SettingsViewModel?>();
                          final effectiveUseBits = settingsVm?.isSpeedUnitBits ?? widget.useBits;
                          return SpeedPulseCard(
                            speed: vm.currentSpeed,
                            useBits: effectiveUseBits,
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // 2. Network Category Segmented Selector
                      SegmentedButton<PlanCategory>(
                        segments: const [
                          ButtonSegment<PlanCategory>(
                            value: PlanCategory.cellular,
                            label: Text('Cellular'),
                            icon: Icon(AppIcons.cellular, size: 16),
                          ),
                          ButtonSegment<PlanCategory>(
                            value: PlanCategory.wifi,
                            label: Text('Wi-Fi'),
                            icon: Icon(AppIcons.wifi, size: 16),
                          ),
                        ],
                        selected: {vm.selectedCategory},
                        onSelectionChanged: (selected) {
                          if (selected.isNotEmpty) {
                            vm.selectCategory(selected.first);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // 3. Data Plan Progress Ring (Dynamic Cellular or Wi-Fi)
                      PlanProgressRing(
                        plan: vm.activePlan,
                        usedMobileBytes: vm.activeUsedBytes,
                        category: vm.selectedCategory,
                      ),
                      const SizedBox(height: 12),

                      // 4. Cellular vs Wi-Fi Today Split (Interactive Tap)
                      DailyComparisonTile(
                        summary: summary,
                        selectedCategory: vm.selectedCategory,
                        onSelectCategory: vm.selectCategory,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
