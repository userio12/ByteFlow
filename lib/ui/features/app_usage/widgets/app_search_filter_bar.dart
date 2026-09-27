import 'package:flutter/material.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../domain/models/time_range.dart';
import '../../../core/widgets/time_range_segmented_button.dart';

/// Search input bar coupled with network type chips and multi-timeframe segmented switcher.
class AppSearchFilterBar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final int selectedNetworkType;
  final ValueChanged<int> onNetworkTypeChanged;
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;

  const AppSearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedNetworkType,
    required this.onNetworkTypeChanged,
    required this.selectedRange,
    required this.onRangeChanged,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Box
          TextField(
            controller: _controller,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search application or package...',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. TimeRange switcher
          TimeRangeSegmentedButton(
            selectedRange: widget.selectedRange,
            onRangeChanged: widget.onRangeChanged,
          ),
          const SizedBox(height: 10),

          // 3. Network Filter Chips
          Row(
            children: [
              Text(
                'Network: ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              _buildNetworkChip(
                label: 'All',
                type: ChannelConstants.networkTypeAll,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 6),
              _buildNetworkChip(
                label: 'Mobile',
                type: ChannelConstants.networkTypeMobile,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 6),
              _buildNetworkChip(
                label: 'Wi-Fi',
                type: ChannelConstants.networkTypeWifi,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkChip({
    required String label,
    required int type,
    required ColorScheme colorScheme,
  }) {
    final isSelected = widget.selectedNetworkType == type;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => widget.onNetworkTypeChanged(type),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
