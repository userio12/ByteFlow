import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';

/// Informational card highlighting ByteFlow's screen-off zero-CPU battery preservation architecture
/// and OEM battery optimization exemption controls.
class BatterySaverCard extends StatelessWidget {
  final bool isBatteryOptimizationsIgnored;
  final VoidCallback? onRequestExemption;

  const BatterySaverCard({
    super.key,
    this.isBatteryOptimizationsIgnored = false,
    this.onRequestExemption,
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
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusNormal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    AppIcons.batterySaver,
                    color: AppColors.statusNormal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ZERO-DRAIN BATTERY SAVER',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusNormal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.statusNormal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Display-Aware Sampling Loop',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ByteFlow dynamically halts Linux socket delta queries the moment your screen turns off (ACTION_SCREEN_OFF). Real-time sampling immediately resumes when you wake the display, ensuring exactly 0.0% background battery consumption in your pocket.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isBatteryOptimizationsIgnored
                            ? AppColors.statusNormal
                            : AppColors.statusWarning)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: isBatteryOptimizationsIgnored
                        ? AppColors.statusNormal
                        : AppColors.statusWarning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'OEM TASK KILLER DEFENSE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isBatteryOptimizationsIgnored
                            ? AppColors.statusNormal
                            : AppColors.statusWarning)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isBatteryOptimizationsIgnored ? 'Whitelisted' : 'Optimized',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isBatteryOptimizationsIgnored
                          ? AppColors.statusNormal
                          : AppColors.statusWarning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isBatteryOptimizationsIgnored
                  ? 'ByteFlow is exempt from Android battery restrictions. Background live speed service and widget updates will not be terminated by aggressive OEM task managers.'
                  : 'Your device may throttle or kill background monitoring. Request unrestricted background activity to ensure continuous speed tracking on Xiaomi, Samsung, and OnePlus devices.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (!isBatteryOptimizationsIgnored && onRequestExemption != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const Key('request_battery_exemption_button'),
                onPressed: onRequestExemption,
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: const Text('Request Unrestricted Activity'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
