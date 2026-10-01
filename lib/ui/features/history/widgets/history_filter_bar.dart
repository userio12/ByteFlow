import 'package:flutter/material.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../domain/models/time_range.dart';

/// Compact, pro filter bar featuring quick-filter pills for time range and network interface,
/// plus deep modal filter sheet launching, matching the App Data Usage screen design.
class HistoryFilterBar extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;
  final int selectedNetworkType;
  final ValueChanged<int> onNetworkTypeChanged;
  final VoidCallback? onOpenFilterSheet;
  final bool isFiltered;

  const HistoryFilterBar({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.selectedNetworkType,
    required this.onNetworkTypeChanged,
    this.onOpenFilterSheet,
    this.isFiltered = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 4.0),
      child: Row(
        children: [
          // Horizontal Quick-Pill Row
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Time Range Pill
                  _buildTimeRangePill(context, colorScheme),
                  const SizedBox(width: 8),

                  // Network Interface Pill
                  _buildNetworkPill(context, colorScheme),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Deep Filter Sheet Action
          if (onOpenFilterSheet != null)
            IconButton(
              onPressed: onOpenFilterSheet,
              tooltip: 'Filter options',
              icon: Badge(
                isLabelVisible: isFiltered,
                child: Icon(
                  Icons.tune_rounded,
                  color: isFiltered ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRangePill(BuildContext context, ColorScheme colorScheme) {
    final isNonDefault = selectedRange != TimeRange.today;

    return PopupMenuButton<TimeRange>(
      tooltip: 'Change time range',
      onSelected: onRangeChanged,
      itemBuilder: (context) => TimeRange.values.map((range) {
        final isSelected = selectedRange == range;
        return PopupMenuItem<TimeRange>(
          value: range,
          child: Text(
            range.displayName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : null,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isNonDefault
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isNonDefault
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              selectedRange.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isNonDefault
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isNonDefault
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkPill(BuildContext context, ColorScheme colorScheme) {
    final isNonDefault = selectedNetworkType != ChannelConstants.networkTypeAll;
    final (label, icon) = switch (selectedNetworkType) {
      ChannelConstants.networkTypeMobile => ('Mobile', AppIcons.cellular),
      ChannelConstants.networkTypeWifi => ('Wi-Fi', AppIcons.wifi),
      _ => ('All Networks', null),
    };

    return PopupMenuButton<int>(
      tooltip: 'Change network interface',
      onSelected: onNetworkTypeChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<int>(
          value: ChannelConstants.networkTypeAll,
          child: Text('All Networks'),
        ),
        PopupMenuItem<int>(
          value: ChannelConstants.networkTypeMobile,
          child: Row(
            children: [
              Icon(AppIcons.cellular, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Mobile Cellular'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: ChannelConstants.networkTypeWifi,
          child: Row(
            children: [
              Icon(AppIcons.wifi, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Wi-Fi'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isNonDefault
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isNonDefault ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isNonDefault ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isNonDefault ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
