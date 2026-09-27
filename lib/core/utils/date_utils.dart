/// High-performance date manipulation and billing cycle calculation utilities.
abstract final class AppDateUtils {
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  /// Returns the start of day (00:00:00.000) for [dateTime].
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 0, 0, 0, 0, 0);
  }

  /// Returns the end of day (23:59:59.999) for [dateTime].
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999, 999);
  }

  /// Returns total days since Unix epoch (1970-01-01 UTC).
  static int epochDay(DateTime dateTime) {
    final utcDate = DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
    return utcDate.difference(DateTime.utc(1970, 1, 1)).inDays;
  }

  /// Reconstructs a [DateTime] at UTC midnight from [epochDay].
  static DateTime dateFromEpochDay(int epochDay) {
    return DateTime.utc(1970, 1, 1).add(Duration(days: epochDay));
  }

  /// Returns `true` if [year] is a leap year.
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Returns the number of days in [month] for [year].
  static int daysInMonth(int year, int month) {
    return switch (month) {
      1 || 3 || 5 || 7 || 8 || 10 || 12 => 31,
      4 || 6 || 9 || 11 => 30,
      2 => isLeapYear(year) ? 29 : 28,
      _ => 30,
    };
  }

  /// Formats date to ISO-8601 date string `'YYYY-MM-DD'`.
  static String formatDateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Formats [hour] (0-23) to two-digit label (e.g. `"14:00"`).
  static String formatHourLabel(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  /// Returns short day name for [date] (e.g. `"Mon"`).
  static String formatDayOfWeek(DateTime date) {
    return _dayNames[date.weekday - 1];
  }

  /// Returns short month name for [month] (1-12) (e.g. `"Aug"`).
  static String formatMonthLabel(int month) {
    if (month < 1 || month > 12) return '';
    return _monthNames[month - 1];
  }

  /// Calculates start and end timestamps for the billing cycle covering [now].
  /// [resetDay] is clamped between 1 and 28/31 depending on month length.
  static (DateTime start, DateTime end) calculateBillingCycleBounds(
    DateTime now,
    int resetDay,
  ) {
    final clampedResetDay = resetDay.clamp(1, 31);
    final DateTime cycleStart;
    final DateTime cycleEnd;

    final currentMonthDays = daysInMonth(now.year, now.month);
    final effectiveResetDay = clampedResetDay.clamp(1, currentMonthDays);

    if (now.day >= effectiveResetDay) {
      cycleStart = DateTime(now.year, now.month, effectiveResetDay, 0, 0, 0);
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final nextMonthDays = daysInMonth(nextYear, nextMonth);
      final nextEffectiveReset = clampedResetDay.clamp(1, nextMonthDays);
      cycleEnd = DateTime(nextYear, nextMonth, nextEffectiveReset, 0, 0, 0)
          .subtract(const Duration(milliseconds: 1));
    } else {
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final prevMonthDays = daysInMonth(prevYear, prevMonth);
      final prevEffectiveReset = clampedResetDay.clamp(1, prevMonthDays);
      cycleStart = DateTime(prevYear, prevMonth, prevEffectiveReset, 0, 0, 0);
      cycleEnd = DateTime(now.year, now.month, effectiveResetDay, 0, 0, 0)
          .subtract(const Duration(milliseconds: 1));
    }

    return (cycleStart, now.isBefore(cycleEnd) ? now : cycleEnd);
  }
}
