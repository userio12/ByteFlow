import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/app_usage_entity.dart';
import '../../../../domain/repositories/i_network_repository.dart';
import 'foreground_background_bar.dart';

/// Modal bottom sheet presenting in-depth foreground vs background telemetry for an application.
class AppDetailsBottomSheet extends StatelessWidget {
  final AppUsageEntity app;
  final INetworkRepository? networkRepository;

  const AppDetailsBottomSheet({
    super.key,
    required this.app,
    this.networkRepository,
  });

  static Future<void> show(
    BuildContext context,
    AppUsageEntity app, {
    INetworkRepository? networkRepository,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AppDetailsBottomSheet(
        app: app,
        networkRepository: networkRepository,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgPercent = app.backgroundPercentage;
    final isHighBackground = bgPercent >= 30.0;

    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 16.0,
        bottom: MediaQuery.paddingOf(context).bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 20),

          // App Header
          Row(
            children: [
              _buildAppIcon(colorScheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.packageName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Linux UID: ${app.uid}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Total Consumption Banner
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Traffic',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ByteFormatter.format(app.totalBytes),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Foreground vs Background Distribution
          Text(
            'USAGE SPLIT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ForegroundBackgroundBar(
            foregroundBytes: app.foregroundBytes,
            backgroundBytes: app.backgroundBytes,
            showLabels: true,
            height: 8.0,
          ),
          const SizedBox(height: 20),

          // Granular Socket Metrics
          _buildDetailRow(
            context,
            'Foreground Rx / Tx',
            '↓ ${ByteFormatter.format(app.foregroundRx)}  •  ↑ ${ByteFormatter.format(app.foregroundTx)}',
            AppColors.foregroundUsage,
          ),
          const Divider(height: 16),
          _buildDetailRow(
            context,
            'Background Rx / Tx',
            '↓ ${ByteFormatter.format(app.backgroundRx)}  •  ↑ ${ByteFormatter.format(app.backgroundTx)}',
            AppColors.backgroundUsage,
          ),
          if (isHighBackground) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusWarning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.alertWarning,
                    color: AppColors.statusWarning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unusual background activity: ${bgPercent.toStringAsFixed(1)}% of this app’s data was transferred while closed or sleeping.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Deep Interop Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('app_details_open_app_button'),
                  onPressed: () async {
                    final repo = networkRepository ?? context.read<INetworkRepository>();
                    final result = await repo.launchApp(app.packageName);
                    result.when(
                      success: (launched) {
                        if (!launched && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cannot launch ${app.appName} directly (background system service).'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      failure: (failure) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Launch failed: ${failure.message}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open App'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('app_details_app_info_button'),
                  onPressed: () async {
                    final repo = networkRepository ?? context.read<INetworkRepository>();
                    await repo.openAppDetails(app.packageName);
                  },
                  icon: const Icon(Icons.settings_applications_rounded, size: 18),
                  label: const Text('App Info'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    Color indicatorColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indicatorColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppIcon(ColorScheme colorScheme) {
    if (app.appIconBase64 != null && app.appIconBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(app.appIconBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackIcon(colorScheme),
          ),
        );
      } catch (_) {}
    }
    return _buildFallbackIcon(colorScheme);
  }

  Widget _buildFallbackIcon(ColorScheme colorScheme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        AppIcons.appsActive,
        size: 28,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
