import '../../core/utils/date_utils.dart';

/// Pure Dart date range container with start and end timestamps.
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange(start: $start, end: $end)';
}

/// Standardized time resolutions for dynamic multi-timeframe analytics.
enum TimeRange {
  today,
  week,
  month,
  year;

  /// User-facing display title.
  String get displayName => switch (this) {
        TimeRange.today => 'Today',
        TimeRange.week => 'Weekly',
        TimeRange.month => 'Monthly',
        TimeRange.year => 'Yearly',
      };

  /// Calculates start and end boundaries for this [TimeRange].
  DateRange calculateBounds({int billingCycleResetDay = 1}) {
    final now = DateTime.now();
    return switch (this) {
      TimeRange.today => DateRange(
          start: AppDateUtils.startOfDay(now),
          end: now,
        ),
      TimeRange.week => DateRange(
          start: AppDateUtils.startOfDay(
            DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
          ),
          end: now,
        ),
      TimeRange.month => _calculateBillingCycleRange(now, billingCycleResetDay),
      TimeRange.year => DateRange(
          start: DateTime(now.year - 1, now.month + 1, 1, 0, 0, 0),
          end: now,
        ),
    };
  }

  static DateRange _calculateBillingCycleRange(DateTime now, int resetDay) {
    final (start, end) = AppDateUtils.calculateBillingCycleBounds(now, resetDay);
    return DateRange(start: start, end: end);
  }
}
