import 'package:flutter/material.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../domain/models/app_sort_order.dart';
import '../../../../domain/models/app_type_filter.dart';
import '../../../../domain/models/time_range.dart';

/// Compact, pro search and filter bar featuring integrated sort controls, quick-filter pills,
/// and deep filter sheet launching, saving over 60% vertical screen space.
class AppSearchFilterBar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final int selectedNetworkType;
  final ValueChanged<int> onNetworkTypeChanged;
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;
  final AppTypeFilter selectedAppType;
  final ValueChanged<AppTypeFilter> onAppTypeChanged;
  final AppSortOrder selectedSortOrder;
  final ValueChanged<AppSortOrder>? onSortOrderChanged;
  final VoidCallback? onOpenFilterSheet;
  final bool isFiltered;

  const AppSearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedNetworkType,
    required this.onNetworkTypeChanged,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.selectedAppType,
    required this.onAppTypeChanged,
    this.selectedSortOrder = AppSortOrder.totalUsageDesc,
    this.onSortOrderChanged,
    this.onOpenFilterSheet,
    this.isFiltered = false,
  });

  @override
  State<AppSearchFilterBar> createState() => _AppSearchFilterBarState();
}

class _AppSearchFilterBarState extends State<AppSearchFilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant AppSearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _controller.text) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Box with Integrated Sort and Filter Actions
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search app or package...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: const Icon(AppIcons.search, size: 20),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _controller.clear();
                              widget.onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHigh,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Sort Popup Action
              PopupMenuButton<AppSortOrder>(
                icon: Icon(
                  Icons.sort_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                tooltip: 'Sort options',
                onSelected: (order) => widget.onSortOrderChanged?.call(order),
                itemBuilder: (context) => AppSortOrder.values.map((order) {
                  final isSelected = widget.selectedSortOrder == order;
                  return PopupMenuItem<AppSortOrder>(
                    value: order,
                    child: Row(
                      children: [
                        Icon(
                          switch (order) {
                            AppSortOrder.totalUsageDesc => Icons.arrow_downward_rounded,
                            AppSortOrder.backgroundUsageDesc => Icons.sync_problem_rounded,
                            AppSortOrder.foregroundUsageDesc => Icons.touch_app_rounded,
                            AppSortOrder.nameAsc => Icons.sort_by_alpha_rounded,
                          },
                          size: 18,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          order.displayName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // More Filters Sheet Action
              if (widget.onOpenFilterSheet != null)
                IconButton(
                  onPressed: widget.onOpenFilterSheet,
                  tooltip: 'Advanced filters',
                  icon: Badge(
                    isLabelVisible: widget.isFiltered,
                    child: Icon(
                      Icons.tune_rounded,
                      color: widget.isFiltered ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Horizontal Quick-Pill Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Time Range Pill
                _buildTimeRangePill(context, colorScheme),
                const SizedBox(width: 8),

                // Network Interface Pill
                _buildNetworkPill(context, colorScheme),
                const SizedBox(width: 8),

                // App Category Pill
                _buildAppTypePill(context, colorScheme),
                const SizedBox(width: 8),

                // Sort Quick Pill
                _buildSortPill(context, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangePill(BuildContext context, ColorScheme colorScheme) {
    return PopupMenuButton<TimeRange>(
      tooltip: 'Change time range',
      onSelected: widget.onRangeChanged,
      itemBuilder: (context) => TimeRange.values.map((range) {
        final isSelected = widget.selectedRange == range;
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
          color: widget.selectedRange != TimeRange.today
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
              color: widget.selectedRange != TimeRange.today
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              widget.selectedRange.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.selectedRange != TimeRange.today
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: widget.selectedRange != TimeRange.today
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkPill(BuildContext context, ColorScheme colorScheme) {
    final isNonDefault = widget.selectedNetworkType != ChannelConstants.networkTypeAll;
    final (label, icon) = switch (widget.selectedNetworkType) {
      ChannelConstants.networkTypeMobile => ('Mobile', AppIcons.cellular),
      ChannelConstants.networkTypeWifi => ('Wi-Fi', AppIcons.wifi),
      _ => ('All Networks', null),
    };

    return PopupMenuButton<int>(
      tooltip: 'Change network interface',
      onSelected: widget.onNetworkTypeChanged,
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

  Widget _buildAppTypePill(BuildContext context, ColorScheme colorScheme) {
    final isNonDefault = widget.selectedAppType != AppTypeFilter.userInstalled;

    return PopupMenuButton<AppTypeFilter>(
      tooltip: 'Filter app categories',
      onSelected: widget.onAppTypeChanged,
      itemBuilder: (context) => AppTypeFilter.values.map((type) {
        final isSelected = widget.selectedAppType == type;
        return PopupMenuItem<AppTypeFilter>(
          value: type,
          child: Row(
            children: [
              Icon(
                switch (type) {
                  AppTypeFilter.userInstalled => Icons.download_done_rounded,
                  AppTypeFilter.system => Icons.android_rounded,
                  AppTypeFilter.all => Icons.apps_rounded,
                },
                size: 16,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                type.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : null,
                ),
              ),
            ],
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
              switch (widget.selectedAppType) {
                AppTypeFilter.userInstalled => Icons.download_done_rounded,
                AppTypeFilter.system => Icons.android_rounded,
                AppTypeFilter.all => Icons.apps_rounded,
              },
              size: 14,
              color: isNonDefault ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              widget.selectedAppType.displayName,
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

  Widget _buildSortPill(BuildContext context, ColorScheme colorScheme) {
    final isNonDefault = widget.selectedSortOrder != AppSortOrder.totalUsageDesc;

    return PopupMenuButton<AppSortOrder>(
      tooltip: 'Change sort order',
      onSelected: (order) => widget.onSortOrderChanged?.call(order),
      itemBuilder: (context) => AppSortOrder.values.map((order) {
        final isSelected = widget.selectedSortOrder == order;
        return PopupMenuItem<AppSortOrder>(
          value: order,
          child: Row(
            children: [
              Icon(
                switch (order) {
                  AppSortOrder.totalUsageDesc => Icons.arrow_downward_rounded,
                  AppSortOrder.backgroundUsageDesc => Icons.sync_problem_rounded,
                  AppSortOrder.foregroundUsageDesc => Icons.touch_app_rounded,
                  AppSortOrder.nameAsc => Icons.sort_by_alpha_rounded,
                },
                size: 16,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                order.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : null,
                ),
              ),
            ],
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
              switch (widget.selectedSortOrder) {
                AppSortOrder.totalUsageDesc => Icons.arrow_downward_rounded,
                AppSortOrder.backgroundUsageDesc => Icons.sync_problem_rounded,
                AppSortOrder.foregroundUsageDesc => Icons.touch_app_rounded,
                AppSortOrder.nameAsc => Icons.sort_by_alpha_rounded,
              },
              size: 14,
              color: isNonDefault ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              widget.selectedSortOrder.displayName,
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
