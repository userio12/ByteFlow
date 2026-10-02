import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../view_models/plan_view_model.dart';
import '../widgets/carrier_status_card.dart';
import '../widgets/plan_summary_card.dart';

/// The Plan & Quota management view presenting carrier status, quota progress, and allowance budgets.
class PlanView extends StatefulWidget {
  final PlanViewModel viewModel;

  const PlanView({
    super.key,
    required this.viewModel,
  });

  @override
  State<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<PlanView> {
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

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Data Plan & Quotas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: vm.isLoading && vm.activeSim == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: vm.loadData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    children: [
                      // 0. Plan Category Switcher (Cellular vs Wi-Fi)
                      SegmentedButton<PlanCategory>(
                        segments: const [
                          ButtonSegment(
                            value: PlanCategory.cellular,
                            label: Text('Cellular Plan'),
                            icon: Icon(AppIcons.cellular, size: 16),
                          ),
                          ButtonSegment(
                            value: PlanCategory.wifi,
                            label: Text('Wi-Fi Plan'),
                            icon: Icon(AppIcons.wifi, size: 16),
                          ),
                        ],
                        selected: {vm.selectedCategory},
                        onSelectionChanged: (val) {
                          vm.selectCategory(val.first);
                        },
                      ),
                      const SizedBox(height: 14),

                      // 1. Context Card: Carrier status for cellular, Wi-Fi info for wifi
                      if (vm.selectedCategory == PlanCategory.cellular)
                        CarrierStatusCard(
                          activeSim: vm.activeSim,
                          allSims: vm.allSims,
                        )
                      else
                        Card(
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    AppIcons.wifi,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Wi-Fi / Hotspot FUP Policy',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Track home broadband, MiFi, or pocket hotspot monthly Fair Usage Policy allowances.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // 2. Plan Configuration & Allowance Summary
                      PlanSummaryCard(
                        plan: vm.plan,
                        usedBytes: vm.cycleUsedBytes,
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
