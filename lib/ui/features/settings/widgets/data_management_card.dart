import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/export_format.dart';

/// Card offering data export (JSON or CSV) and local database cache purging.
class DataManagementCard extends StatelessWidget {
  final Future<String?> Function(ExportFormat format) onExportData;
  final Future<bool> Function() onClearCache;

  const DataManagementCard({
    super.key,
    required this.onExportData,
    required this.onClearCache,
  });

  Future<void> _handleExport(BuildContext context) async {
    final initialFormat = ExportFormat.json;
    final initialData = await onExportData(initialFormat);
    if (!context.mounted) return;

    if (initialData == null || initialData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        var currentFormat = initialFormat;
        var currentContent = initialData;
        var isLoading = false;

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Export Usage Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SegmentedButton<ExportFormat>(
                    segments: const [
                      ButtonSegment(
                        value: ExportFormat.json,
                        label: Text('JSON'),
                        icon: Icon(Icons.data_object_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: ExportFormat.csv,
                        label: Text('CSV'),
                        icon: Icon(Icons.table_chart_rounded, size: 16),
                      ),
                    ],
                    selected: {currentFormat},
                    onSelectionChanged: (newSelection) async {
                      final newFormat = newSelection.first;
                      if (newFormat == currentFormat) return;
                      setState(() {
                        isLoading = true;
                        currentFormat = newFormat;
                      });
                      final newContent = await onExportData(newFormat);
                      if (ctx.mounted) {
                        setState(() {
                          currentContent = newContent ?? '';
                          isLoading = false;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your historical network and app usage summary has been generated in ${currentFormat.label} format:',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxHeight: 180),
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Text(
                            currentContent,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: currentContent));
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${currentFormat.label} report copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text('Copy ${currentFormat.label}'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleClearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.statusWarning, size: 36),
        title: const Text('Clear Historical Cache?'),
        content: const Text(
          'This will purge all cached hourly and daily snapshots from your local SQLite database.\n\n'
          'Android system netstats logs are not affected, and recent metrics will reload automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await onClearCache();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Historical cache cleared successfully.' : 'Failed to clear cache.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.storage_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DATA MANAGEMENT & BACKUP',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.file_download_outlined, color: colorScheme.primary),
              title: Text(
                'Export Usage Report',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Generate a JSON or CSV report with network totals and app breakdown',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _handleExport(context),
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              title: Text(
                'Clear Cached History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
              subtitle: Text(
                'Reset local SQLite rollups and reclaim disk space',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _handleClearCache(context),
            ),
          ],
        ),
      ),
    );
  }
}
