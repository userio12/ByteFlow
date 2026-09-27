import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../domain/models/speed_sample_entity.dart';
import '../../../core/animations/count_up_text.dart';
import '../../../core/animations/pulse_indicator.dart';

/// Card displaying real-time download and upload throughput rates with an isolated pulse indicator.
class SpeedPulseCard extends StatelessWidget {
  final SpeedSampleEntity speed;
  final bool useBits;

  const SpeedPulseCard({
    super.key,
    required this.speed,
    this.useBits = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasActiveTraffic = speed.totalBps > 1024; // > 1 KB/s

    return RepaintBoundary(
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and Live Pulse halo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.trafficPulse,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE NETWORK SPEED',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      PulseIndicator(
                        isActive: hasActiveTraffic,
                        color: AppColors.wifi,
                        size: 8.0,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasActiveTraffic ? 'Live Pulse' : 'Idle',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: hasActiveTraffic
                              ? AppColors.wifi
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dual Speed Readings (Download & Upload)
              Row(
                children: [
                  // Download Column
                  Expanded(
                    child: _buildSpeedColumn(
                      context: context,
                      label: 'Download',
                      icon: AppIcons.download,
                      iconColor: AppColors.downloadRate,
                      bytesPerSecond: speed.downloadBps,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  // Upload Column
                  Expanded(
                    child: _buildSpeedColumn(
                      context: context,
                      label: 'Upload',
                      icon: AppIcons.upload,
                      iconColor: AppColors.uploadRate,
                      bytesPerSecond: speed.uploadBps,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedColumn({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required int bytesPerSecond,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CountUpText.speed(
            bytesPerSecond: bytesPerSecond,
            useBits: useBits,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
