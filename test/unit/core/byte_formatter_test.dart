import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/utils/byte_formatter.dart';

void main() {
  group('ByteFormatter', () {
    group('format', () {
      test('formats zero and negative bytes correctly', () {
        expect(ByteFormatter.format(0), equals('0 B'));
        expect(ByteFormatter.format(-100), equals('0 B'));
      });

      test('formats bytes with unit steps', () {
        expect(ByteFormatter.format(500), equals('500 B'));
        expect(ByteFormatter.format(1024), equals('1.00 KB'));
        expect(ByteFormatter.format(1536), equals('1.50 KB'));
        expect(ByteFormatter.format(1048576), equals('1.00 MB'));
        expect(ByteFormatter.format(10737418240), equals('10.00 GB'));
        expect(ByteFormatter.format(2199023255552), equals('2.00 TB'));
      });

      test('respects custom decimal precision', () {
        expect(ByteFormatter.format(1536, decimals: 0), equals('2 KB'));
        expect(ByteFormatter.format(1536, decimals: 3), equals('1.500 KB'));
      });
    });

    group('formatParts', () {
      test('returns structured record for value and unit separation', () {
        final (zeroVal, zeroUnit) = ByteFormatter.formatParts(0);
        expect(zeroVal, equals('0'));
        expect(zeroUnit, equals('B'));

        final (kbVal, kbUnit) = ByteFormatter.formatParts(1024);
        expect(kbVal, equals('1.00'));
        expect(kbUnit, equals('KB'));

        final (gbVal, gbUnit) = ByteFormatter.formatParts(5368709120);
        expect(gbVal, equals('5.00'));
        expect(gbUnit, equals('GB'));
      });
    });

    group('formatSpeed', () {
      test('formats zero speed', () {
        expect(ByteFormatter.formatSpeed(0), equals('0 B/s'));
        expect(ByteFormatter.formatSpeed(0, useBits: true), equals('0 b/s'));
        expect(ByteFormatter.formatSpeed(-50), equals('0 B/s'));
      });

      test('formats bytes per second', () {
        expect(ByteFormatter.formatSpeed(512), equals('512.0 B/s'));
        expect(ByteFormatter.formatSpeed(1024), equals('1.0 KB/s'));
        expect(ByteFormatter.formatSpeed(2621440), equals('2.5 MB/s'));
      });

      test('formats bits per second', () {
        // 125,000 bytes * 8 = 1,000,000 bits = 1.0 Mb/s (decimal bit units step by 1000)
        expect(ByteFormatter.formatSpeed(125000, useBits: true), equals('1.0 Mb/s'));
        expect(ByteFormatter.formatSpeed(125, useBits: true), equals('1.0 Kb/s'));
      });
    });

    group('parseToBytes', () {
      test('parses units into exact integer bytes', () {
        expect(ByteFormatter.parseToBytes(100, 'B'), equals(100));
        expect(ByteFormatter.parseToBytes(1.5, 'KB'), equals(1536));
        expect(ByteFormatter.parseToBytes(2, 'MB'), equals(2097152));
        expect(ByteFormatter.parseToBytes(5, 'GB'), equals(5368709120));
        expect(ByteFormatter.parseToBytes(1, 'TB'), equals(1099511627776));
      });

      test('handles lowercase or untrimmed units', () {
        expect(ByteFormatter.parseToBytes(2, ' gb '), equals(2147483648));
        expect(ByteFormatter.parseToBytes(50, 'unknown'), equals(50));
      });
    });
  });
}
