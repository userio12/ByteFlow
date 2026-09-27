import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/domain/models/time_range.dart';

void main() {
  group('DateRange', () {
    test('computes duration correctly', () {
      final start = DateTime(2024, 1, 1, 0, 0);
      final end = DateTime(2024, 1, 2, 12, 0);
      final range = DateRange(start: start, end: end);

      expect(range.duration, equals(const Duration(days: 1, hours: 12)));
    });

    test('supports equality and hash code', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 2);
      final r1 = DateRange(start: start, end: end);
      final r2 = DateRange(start: start, end: end);
      final r3 = DateRange(start: start, end: DateTime(2024, 1, 3));

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });

    test('toString formats cleanly', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 2);
      final r = DateRange(start: start, end: end);
      expect(r.toString(), contains('DateRange'));
    });
  });

  group('TimeRange', () {
    test('displayName returns user-facing strings', () {
      expect(TimeRange.today.displayName, equals('Today'));
      expect(TimeRange.week.displayName, equals('Weekly'));
      expect(TimeRange.month.displayName, equals('Monthly'));
      expect(TimeRange.year.displayName, equals('Yearly'));
    });

    test('calculateBounds for TimeRange.today covers current day to now', () {
      final bounds = TimeRange.today.calculateBounds();
      final now = DateTime.now();

      expect(bounds.start.hour, equals(0));
      expect(bounds.start.minute, equals(0));
      expect(bounds.start.second, equals(0));
      expect(bounds.end.day, equals(now.day));
      expect(bounds.start.isBefore(bounds.end) || bounds.start.isAtSameMomentAs(bounds.end), isTrue);
    });

    test('calculateBounds for TimeRange.week spans 7 days', () {
      final bounds = TimeRange.week.calculateBounds();
      // Should start 6 days ago at 00:00:00
      expect(bounds.start.isBefore(bounds.end), isTrue);
      final daysDiff = bounds.end.difference(bounds.start).inDays;
      expect(daysDiff, inInclusiveRange(6, 7));
    });

    test('calculateBounds for TimeRange.month uses billing cycle reset day', () {
      final bounds = TimeRange.month.calculateBounds(billingCycleResetDay: 1);
      expect(bounds.start.day, equals(1));
      expect(bounds.start.hour, equals(0));
      expect(bounds.start.isBefore(bounds.end) || bounds.start.isAtSameMomentAs(bounds.end), isTrue);
    });

    test('calculateBounds for TimeRange.year spans roughly 12 months', () {
      final bounds = TimeRange.year.calculateBounds();
      expect(bounds.start.isBefore(bounds.end), isTrue);
      expect(bounds.start.day, equals(1));
      expect(bounds.start.hour, equals(0));
    });
  });
}
