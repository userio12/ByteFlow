import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/models/time_range.dart';

/// A Material 3 SegmentedButton selector for toggling between Today, Weekly, Monthly, and Yearly resolutions.
class TimeRangeSegmentedButton extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;

  const TimeRangeSegmentedButton({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return SegmentedButton<TimeRange>(
          segments: [
            ButtonSegment<TimeRange>(
              value: TimeRange.today,
              label: Text(
                isCompact ? 'Today' : TimeRange.today.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            ButtonSegment<TimeRange>(
              value: TimeRange.week,
              label: Text(
                isCompact ? 'Week' : TimeRange.week.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            ButtonSegment<TimeRange>(
              value: TimeRange.month,
              label: Text(
                isCompact ? 'Month' : TimeRange.month.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            ButtonSegment<TimeRange>(
              value: TimeRange.year,
              label: Text(
                isCompact ? 'Year' : TimeRange.year.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
          selected: {selectedRange},
          onSelectionChanged: (newSelection) {
            if (newSelection.isNotEmpty && newSelection.first != selectedRange) {
              HapticFeedback.selectionClick();
              onRangeChanged(newSelection.first);
            }
          },
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      },
    );
  }
}
