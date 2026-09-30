import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/data/models/app_usage_dto.dart';

void main() {
  group('AppUsageDto', () {
    final validMap = {
      'uid': 10123,
      'packageName': 'com.android.chrome',
      'appName': 'Chrome',
      'rxBytes': 1048576,
      'txBytes': 524288,
      'foregroundRx': 800000,
      'foregroundTx': 400000,
      'backgroundRx': 248576,
      'backgroundTx': 124288,
      'appIconBase64': 'mock_base64_data',
    };

    test('deserializes from Map correctly', () {
      final dto = AppUsageDto.fromMap(validMap);

      expect(dto.uid, equals(10123));
      expect(dto.packageName, equals('com.android.chrome'));
      expect(dto.appName, equals('Chrome'));
      expect(dto.rxBytes, equals(1048576));
      expect(dto.txBytes, equals(524288));
      expect(dto.foregroundRx, equals(800000));
      expect(dto.backgroundTx, equals(124288));
      expect(dto.appIconBase64, equals('mock_base64_data'));
      expect(dto.isSystemApp, isFalse);
    });

    test('deserializes system UID as system app via fallback', () {
      final systemMap = {
        'uid': 1000,
        'packageName': 'android.uid.system',
        'appName': 'Android System',
      };
      final dto = AppUsageDto.fromMap(systemMap);
      expect(dto.isSystemApp, isTrue);
    });

    test('serializes to Map correctly', () {
      final dto = AppUsageDto.fromMap(validMap);
      final map = dto.toMap();

      expect(map['uid'], equals(10123));
      expect(map['packageName'], equals('com.android.chrome'));
      expect(map['appName'], equals('Chrome'));
      expect(map['totalBytes'], equals(1048576 + 524288));
      expect(map['appIconBase64'], equals('mock_base64_data'));
      expect(map['isSystemApp'], isFalse);
    });

    test('converts to and from domain AppUsageEntity', () {
      final dto = AppUsageDto.fromMap(validMap);
      final entity = dto.toEntity();

      expect(entity.uid, equals(dto.uid));
      expect(entity.packageName, equals(dto.packageName));
      expect(entity.totalBytes, equals(dto.rxBytes + dto.txBytes));
      expect(entity.isSystemApp, equals(dto.isSystemApp));

      final roundtripDto = AppUsageDto.fromEntity(entity);
      expect(roundtripDto.uid, equals(dto.uid));
      expect(roundtripDto.packageName, equals(dto.packageName));
      expect(roundtripDto.rxBytes, equals(dto.rxBytes));
      expect(roundtripDto.isSystemApp, equals(dto.isSystemApp));
    });

    test('throws FormatException on malformed map', () {
      final malformedMap = {
        'invalid_key': 'data',
      };

      expect(
        () => AppUsageDto.fromMap(malformedMap),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
