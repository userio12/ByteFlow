import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';

/// Settings controls for toggling the status bar live speed service, sampling intervals, and unit display.
class StatusBarSettingsTile extends StatelessWidget {
  final bool isLiveSpeedEnabled;
  final ValueChanged<bool> onToggleLiveSpeed;
  final int samplingIntervalMs;
  final ValueChanged<int> onIntervalChanged;
  final bool isSpeedUnitBits;
  final ValueChanged<bool> onUnitChanged;

  const StatusBarSettingsTile({
    super.key,
    required this.isLiveSpeedEnabled,
    required this.onToggleLiveSpeed,
    required this.samplingIntervalMs,
    required this.onIntervalChanged,
    required this.isSpeedUnitBits,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch Row
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(AppIcons.trafficPulse, color: colorScheme.primary),
              ),
              title: Text(
                'Live Speed Indicator',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Shows real-time download and upload rate in status bar shade.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              value: isLiveSpeedEnabled,
              onChanged: onToggleLiveSpeed,
            ),

            if (isLiveSpeedEnabled) ...[
              const Divider(height: 24),
              // Sampling Interval Selector
              Text(
                'Sampling Rate',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1000, label: Text('1.0s')),
                  ButtonSegment(value: 1500, label: Text('1.5s')),
                  ButtonSegment(value: 2000, label: Text('2.0s')),
                  ButtonSegment(value: 3000, label: Text('3.0s')),
                ],
                selected: {samplingIntervalMs},
                onSelectionChanged: (val) => onIntervalChanged(val.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(height: 16),

              // Unit Preference
              Text(
                'Throughput Units',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Bytes (MB/s & KB/s)'),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Bits (Mbps & Kbps)'),
                  ),
                ],
                selected: {isSpeedUnitBits},
                onSelectionChanged: (val) => onUnitChanged(val.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
