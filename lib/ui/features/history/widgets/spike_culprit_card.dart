import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/hourly_spike_entity.dart';

/// Card identifying the primary culprit application and timestamp of peak usage spikes.
class SpikeCulpritCard extends StatelessWidget {
  final HourlySpikeEntity? spike;

  const SpikeCulpritCard({
    super.key,
    required this.spike,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (spike == null) {
      return const SizedBox.shrink();
    }

    final hourLabel = '${spike!.hourOfDay.toString().padLeft(2, '0')}:00 - ${(spike!.hourOfDay + 1).toString().padLeft(2, '0')}:00';
    final hasCulprit = spike!.culpritAppName != null && spike!.culpritAppName!.isNotEmpty;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.statusWarning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    AppIcons.alertWarning,
                    size: 18,
                    color: AppColors.statusWarning,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SPIKE ANALYSIS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cellular.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hourLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.cellular,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Burst Consumption: ${ByteFormatter.format(spike!.totalBytes)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasCulprit
                  ? '• Primary consumer during burst: ${spike!.culpritAppName} (${ByteFormatter.format(spike!.culpritBytes ?? 0)})\n'
                      '• Package: ${spike!.culpritPackageName ?? "unknown"}'
                  : '• Aggregated kernel burst across multiple background system processes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
