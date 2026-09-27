import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/models/data_plan_entity.dart';

/// Modal bottom sheet for configuring data plan quota, billing cadence, reset day, and alerts.
class EditPlanModalSheet extends StatefulWidget {
  final DataPlanEntity initialPlan;
  final ValueChanged<DataPlanEntity> onSave;

  const EditPlanModalSheet({
    super.key,
    required this.initialPlan,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required DataPlanEntity initialPlan,
    required ValueChanged<DataPlanEntity> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EditPlanModalSheet(
        initialPlan: initialPlan,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditPlanModalSheet> createState() => _EditPlanModalSheetState();
}

class _EditPlanModalSheetState extends State<EditPlanModalSheet> {
  late final TextEditingController _quotaController;
  String _quotaUnit = 'GB';
  late DataPlanCycleType _cycleType;
  late int _resetDay;
  late double _alertThreshold;

  @override
  void initState() {
    super.initState();
    final bytes = widget.initialPlan.quotaBytes;
    if (bytes >= AppConstants.bytesPerGigabyte) {
      _quotaUnit = 'GB';
      _quotaController = TextEditingController(
        text: (bytes / AppConstants.bytesPerGigabyte).toStringAsFixed(1),
      );
    } else {
      _quotaUnit = 'MB';
      _quotaController = TextEditingController(
        text: (bytes / AppConstants.bytesPerMegabyte).toStringAsFixed(0),
      );
    }
    _cycleType = widget.initialPlan.cycleType;
    _resetDay = widget.initialPlan.resetDay;
    _alertThreshold = widget.initialPlan.alertThresholdPercent;
  }

  @override
  void dispose() {
    _quotaController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final rawValue = double.tryParse(_quotaController.text.trim()) ?? 1.0;
    final int quotaBytes = _quotaUnit == 'GB'
        ? (rawValue * AppConstants.bytesPerGigabyte).round()
        : (rawValue * AppConstants.bytesPerMegabyte).round();

    final int minBytes = AppConstants.bytesPerMegabyte;
    final int maxBytes = 100 * AppConstants.bytesPerGigabyte;
    final updated = widget.initialPlan.copyWith(
      quotaBytes: quotaBytes.clamp(minBytes, maxBytes),
      cycleType: _cycleType,
      resetDay: _resetDay,
      alertThresholdPercent: _alertThreshold,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 16.0,
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            24.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Configure Data Plan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 1. Quota input with unit dropdown
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

            // 2. Cycle Cadence
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

            // 3. Reset Day Slider (For Monthly cadence)
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
            ],

            // 4. Warning Alert Threshold Slider
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
            const SizedBox(height: 16),

            // Save Button
            FilledButton(
              onPressed: _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Save Data Plan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
