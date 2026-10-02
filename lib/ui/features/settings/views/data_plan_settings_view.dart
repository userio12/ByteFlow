import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../domain/models/data_plan_entity.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../plan/view_models/plan_view_model.dart';
import '../../plan/widgets/carrier_status_card.dart';

/// Settings sub-screen allowing users to view and edit cellular and Wi-Fi data plans and quotas.
class DataPlanSettingsView extends StatefulWidget {
  final PlanViewModel viewModel;

  const DataPlanSettingsView({
    super.key,
    required this.viewModel,
  });

  @override
  State<DataPlanSettingsView> createState() => _DataPlanSettingsViewState();
}

class _DataPlanSettingsViewState extends State<DataPlanSettingsView> {
  late final TextEditingController _quotaController;
  String _quotaUnit = 'GB';
  late DataPlanCycleType _cycleType;
  late int _resetDay;
  late double _alertThreshold;
  late PlanCategory _activeCategory;
  DataPlanEntity? _lastSyncedPlan;

  @override
  void initState() {
    super.initState();
    _quotaController = TextEditingController();
    _activeCategory = widget.viewModel.selectedCategory;
    widget.viewModel.init();
    _syncFormWithPlan(widget.viewModel.plan);
    widget.viewModel.addListener(_onViewModelUpdated);
  }

  void _onViewModelUpdated() {
    if (mounted && widget.viewModel.plan != _lastSyncedPlan) {
      setState(() {
        _syncFormWithPlan(widget.viewModel.plan);
      });
    }
  }

  void _syncFormWithPlan(DataPlanEntity plan) {
    _lastSyncedPlan = plan;
    final bytes = plan.quotaBytes;
    final String text;
    if (bytes >= AppConstants.bytesPerGigabyte) {
      _quotaUnit = 'GB';
      text = (bytes / AppConstants.bytesPerGigabyte).toStringAsFixed(1);
    } else {
      _quotaUnit = 'MB';
      text = (bytes / AppConstants.bytesPerMegabyte).toStringAsFixed(0);
    }
    _quotaController.text = text;
    _cycleType = plan.cycleType;
    _resetDay = plan.resetDay;
    _alertThreshold = plan.alertThresholdPercent;
  }

  void _onCategoryChanged(PlanCategory category) {
    if (_activeCategory != category) {
      widget.viewModel.selectCategory(category);
      setState(() {
        _activeCategory = category;
        _syncFormWithPlan(widget.viewModel.plan);
      });
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelUpdated);
    _quotaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final rawValue = double.tryParse(_quotaController.text.trim()) ?? 1.0;
    final int quotaBytes = _quotaUnit == 'GB'
        ? (rawValue * AppConstants.bytesPerGigabyte).round()
        : (rawValue * AppConstants.bytesPerMegabyte).round();

    final int minBytes = AppConstants.bytesPerMegabyte;
    final int maxBytes = 100 * AppConstants.bytesPerGigabyte;
    final currentPlan = widget.viewModel.plan;
    final updated = currentPlan.copyWith(
      quotaBytes: quotaBytes.clamp(minBytes, maxBytes),
      cycleType: _cycleType,
      resetDay: _resetDay,
      alertThresholdPercent: _alertThreshold,
    );

    final success = await widget.viewModel.savePlan(updated);
    if (mounted) {
      if (success) {
        ErrorSnackBar.showInfo(context, 'Data plan updated successfully.');
      } else {
        ErrorSnackBar.show(
          context,
          widget.viewModel.errorMessage ?? 'Failed to update plan.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final isCellular = _activeCategory == PlanCategory.cellular;

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
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Category Switcher (Cellular vs Wi-Fi)
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
                selected: {_activeCategory},
                onSelectionChanged: (val) {
                  if (val.isNotEmpty) {
                    _onCategoryChanged(val.first);
                  }
                },
              ),
              const SizedBox(height: 16),

              // 2. Carrier or Wi-Fi Context Info Card
              if (isCellular)
                CarrierStatusCard(
                  activeSim: vm.activeSim,
                  allSims: vm.allSims,
                )
              else
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
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            AppIcons.wifi,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wi-Fi / Hotspot Allowance',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track home broadband, MiFi, or pocket hotspot monthly Fair Usage Policy limits.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // 3. Quota & Cadence Editing Form Card
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
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(AppIcons.planActive, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            isCellular ? 'CONFIGURE CELLULAR PLAN' : 'CONFIGURE WI-FI PLAN',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quota input with unit dropdown
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _quotaController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Quota Size',
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHigh,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'MB', label: Text('MB')),
                                ButtonSegment(value: 'GB', label: Text('GB')),
                              ],
                              selected: {_quotaUnit},
                              onSelectionChanged: (val) {
                                setState(() => _quotaUnit = val.first);
                              },
                              style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cycle Cadence
                      Text('Cycle Cadence', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      SegmentedButton<DataPlanCycleType>(
                        segments: const [
                          ButtonSegment(
                            value: DataPlanCycleType.monthly,
                            label: Text('Monthly'),
                          ),
                          ButtonSegment(
                            value: DataPlanCycleType.daily,
                            label: Text('Daily'),
                          ),
                          ButtonSegment(
                            value: DataPlanCycleType.prepaid28Days,
                            label: Text('28-Day'),
                          ),
                        ],
                        selected: {_cycleType},
                        onSelectionChanged: (val) {
                          setState(() => _cycleType = val.first);
                        },
                        style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      ),
                      const SizedBox(height: 16),

                      // Reset Day Slider (For Monthly cadence)
                      if (_cycleType == DataPlanCycleType.monthly) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cycle Reset Day', style: theme.textTheme.labelMedium),
                            Text('Day $_resetDay', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _resetDay.toDouble(),
                          min: 1,
                          max: 31,
                          divisions: 30,
                          label: 'Day $_resetDay',
                          onChanged: (val) => setState(() => _resetDay = val.round()),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Warning Alert Threshold Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Warning Notification Threshold', style: theme.textTheme.labelMedium),
                          Text('${_alertThreshold.toInt()}%', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _alertThreshold,
                        min: 50,
                        max: 95,
                        divisions: 9,
                        label: '${_alertThreshold.toInt()}%',
                        onChanged: (val) => setState(() => _alertThreshold = val),
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      FilledButton(
                        onPressed: vm.isLoading ? null : _handleSave,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: vm.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Data Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
