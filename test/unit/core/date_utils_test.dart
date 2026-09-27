import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('startOfDay and endOfDay clamp correctly', () {
      final dt = DateTime(2024, 3, 15, 14, 30, 45, 123, 456);
      final start = AppDateUtils.startOfDay(dt);
      expect(start.year, equals(2024));
      expect(start.month, equals(3));
      expect(start.day, equals(15));
      expect(start.hour, equals(0));
      expect(start.minute, equals(0));
      expect(start.second, equals(0));
      expect(start.millisecond, equals(0));

      final end = AppDateUtils.endOfDay(dt);
      expect(end.hour, equals(23));
      expect(end.minute, equals(59));
      expect(end.second, equals(59));
      expect(end.millisecond, equals(999));
    });

    test('epochDay and dateFromEpochDay roundtrip', () {
      final date = DateTime.utc(2024, 1, 1);
      final day = AppDateUtils.epochDay(date);
      final reconstructed = AppDateUtils.dateFromEpochDay(day);

      expect(reconstructed.year, equals(2024));
      expect(reconstructed.month, equals(1));
      expect(reconstructed.day, equals(1));
    });

    test('isLeapYear identifies leap years correctly', () {
      expect(AppDateUtils.isLeapYear(2024), isTrue); // divisible by 4
      expect(AppDateUtils.isLeapYear(2000), isTrue); // divisible by 400
      expect(AppDateUtils.isLeapYear(2100), isFalse); // century non-leap
      expect(AppDateUtils.isLeapYear(2023), isFalse); // common year
    });

    test('daysInMonth respects month length and leap year February', () {
      expect(AppDateUtils.daysInMonth(2024, 1), equals(31));
      expect(AppDateUtils.daysInMonth(2024, 2), equals(29)); // leap year Feb
      expect(AppDateUtils.daysInMonth(2023, 2), equals(28)); // non-leap Feb
      expect(AppDateUtils.daysInMonth(2024, 4), equals(30));
      expect(AppDateUtils.daysInMonth(2024, 12), equals(31));
    });

    test('formatDateString produces YYYY-MM-DD format', () {
      expect(AppDateUtils.formatDateString(DateTime(2024, 5, 4)), equals('2024-05-04'));
      expect(AppDateUtils.formatDateString(DateTime(2024, 11, 23)), equals('2024-11-23'));
    });

    test('formatHourLabel pads single digit hours', () {
      expect(AppDateUtils.formatHourLabel(5), equals('05:00'));
      expect(AppDateUtils.formatHourLabel(14), equals('14:00'));
    });

    test('formatDayOfWeek and formatMonthLabel produce short names', () {
      // 2024-03-18 is a Monday
      expect(AppDateUtils.formatDayOfWeek(DateTime(2024, 3, 18)), equals('Mon'));
      expect(AppDateUtils.formatMonthLabel(1), equals('Jan'));
      expect(AppDateUtils.formatMonthLabel(8), equals('Aug'));
      expect(AppDateUtils.formatMonthLabel(12), equals('Dec'));
      expect(AppDateUtils.formatMonthLabel(0), equals(''));
    });

    group('calculateBillingCycleBounds', () {
      test('calculates bounds when now is after reset day in same month', () {
        final now = DateTime(2024, 3, 20, 10, 0, 0);
        final (start, end) = AppDateUtils.calculateBillingCycleBounds(now, 1);

        expect(start, equals(DateTime(2024, 3, 1, 0, 0, 0)));
        expect(end, equals(now));
      });

      test('calculates bounds when now is before reset day', () {
        final now = DateTime(2024, 3, 10, 10, 0, 0);
        final (start, end) = AppDateUtils.calculateBillingCycleBounds(now, 15);

        // Previous cycle started on Feb 15
        expect(start, equals(DateTime(2024, 2, 15, 0, 0, 0)));
        expect(end, equals(now));
      });

      test('handles reset day 31 in months with fewer days', () {
        // April has 30 days; reset day 31 clamps to 30
        final now = DateTime(2024, 4, 15, 10, 0, 0);
        final (start, end) = AppDateUtils.calculateBillingCycleBounds(now, 31);

        expect(start.month, equals(3));
        expect(start.day, equals(31)); // March has 31 days
        expect(end, equals(now));
      });

      test('handles December to January year boundary', () {
        final now = DateTime(2024, 1, 5, 10, 0, 0);
        final (start, end) = AppDateUtils.calculateBillingCycleBounds(now, 15);

        // Cycle started in Dec 2023
        expect(start, equals(DateTime(2023, 12, 15, 0, 0, 0)));
        expect(end, equals(now));
      });
    });
  });
}
