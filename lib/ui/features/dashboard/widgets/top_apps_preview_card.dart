import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/app_usage_entity.dart';

/// Card previewing the top 3 data consuming applications for today with a shortcut to the Apps tab.
class TopAppsPreviewCard extends StatelessWidget {
  final List<AppUsageEntity> apps;
  final VoidCallback? onViewAll;

  const TopAppsPreviewCard({
    super.key,
    required this.apps,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topApps = apps.take(3).toList();
    final maxBytes = topApps.isNotEmpty ? topApps.first.totalBytes : 1;

    return Card(
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & View All Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.appsActive, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'TOP CONSUMERS TODAY',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (onViewAll != null)
                  InkWell(
                    onTap: onViewAll,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            AppIcons.chevronRight,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Apps List
            if (topApps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'No application traffic recorded yet today.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: topApps.map((app) {
                  final ratio = maxBytes > 0
                      ? (app.totalBytes / maxBytes).clamp(0.0, 1.0)
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        // App Icon
                        _buildAppIcon(app, colorScheme),
                        const SizedBox(width: 12),
                        // Name and progress bar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      app.appName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    ByteFormatter.format(app.totalBytes),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 5,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon(AppUsageEntity app, ColorScheme colorScheme) {
    if (app.appIconBase64 != null && app.appIconBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(app.appIconBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 36,
            height: 36,
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        AppIcons.appsActive,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
