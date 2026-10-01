import 'package:flutter/material.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../domain/models/time_range.dart';

/// Modal bottom sheet allowing multi-dimensional filtering of history and trends.
class HistoryFilterModalSheet extends StatefulWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;
  final int selectedNetworkType;
  final ValueChanged<int> onNetworkTypeChanged;
  final VoidCallback onReset;

  const HistoryFilterModalSheet({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.selectedNetworkType,
    required this.onNetworkTypeChanged,
    required this.onReset,
  });

  /// Displays the [HistoryFilterModalSheet] modally.
  static Future<void> show(
    BuildContext context, {
    required TimeRange selectedRange,
    required ValueChanged<TimeRange> onRangeChanged,
    required int selectedNetworkType,
    required ValueChanged<int> onNetworkTypeChanged,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HistoryFilterModalSheet(
        selectedRange: selectedRange,
        onRangeChanged: onRangeChanged,
        selectedNetworkType: selectedNetworkType,
        onNetworkTypeChanged: onNetworkTypeChanged,
        onReset: onReset,
      ),
    );
  }

  @override
  State<HistoryFilterModalSheet> createState() => _HistoryFilterModalSheetState();
}

class _HistoryFilterModalSheetState extends State<HistoryFilterModalSheet> {
  late TimeRange _tempRange;
  late int _tempNetworkType;

  @override
  void initState() {
    super.initState();
    _tempRange = widget.selectedRange;
    _tempNetworkType = widget.selectedNetworkType;
  }

  void _applyChanges() {
    if (_tempRange != widget.selectedRange) {
      widget.onRangeChanged(_tempRange);
    }
    if (_tempNetworkType != widget.selectedNetworkType) {
      widget.onNetworkTypeChanged(_tempNetworkType);
    }
    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    setState(() {
      _tempRange = TimeRange.today;
      _tempNetworkType = ChannelConstants.networkTypeAll;
    });
    widget.onReset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Title + Reset
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter History & Trends',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetToDefaults,
                    child: Text(
                      'Reset All',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Time Range
                    _buildSectionHeader(theme, 'Time Range'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TimeRange.values.map((range) {
                        final isSelected = _tempRange == range;
                        return ChoiceChip(
                          label: Text(range.displayName),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _tempRange = range),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 2. Network Interface
                    _buildSectionHeader(theme, 'Network Interface'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: 'All Networks',
                          icon: null,
                          isSelected: _tempNetworkType == ChannelConstants.networkTypeAll,
                          onSelected: () => setState(() =>
                              _tempNetworkType = ChannelConstants.networkTypeAll),
                        ),
                        _buildChoiceChip(
                          label: 'Mobile Cellular',
                          icon: AppIcons.cellular,
                          isSelected: _tempNetworkType == ChannelConstants.networkTypeMobile,
                          onSelected: () => setState(() =>
                              _tempNetworkType = ChannelConstants.networkTypeMobile),
                        ),
                        _buildChoiceChip(
                          label: 'Wi-Fi',
                          icon: AppIcons.wifi,
                          isSelected: _tempNetworkType == ChannelConstants.networkTypeWifi,
                          onSelected: () => setState(() =>
                              _tempNetworkType = ChannelConstants.networkTypeWifi),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            // Apply Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilledButton(
                onPressed: _applyChanges,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      avatar: icon != null ? Icon(icon, size: 16) : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
