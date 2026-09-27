import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/core/functional/result.dart';

void main() {
  group('Result Monad', () {
    test('Success stores data and identifies as success', () {
      const result = Result<int, String>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals(42));
      expect(result.failureOrNull, isNull);
    });

    test('Failure stores failure and identifies as failure', () {
      const result = Result<int, String>.failure('something went wrong');

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, equals('something went wrong'));
    });

    test('fold transforms success and failure correctly', () {
      const success = Result<int, String>.success(10);
      final successVal = success.fold(
        (data) => 'Value: $data',
        (fail) => 'Error: $fail',
      );
      expect(successVal, equals('Value: 10'));

      const failure = Result<int, String>.failure('failed');
      final failVal = failure.fold(
        (data) => 'Value: $data',
        (fail) => 'Error: $fail',
      );
      expect(failVal, equals('Error: failed'));
    });

    test('when executes appropriate callbacks', () {
      const success = Result<int, String>.success(99);
      int? capturedSuccess;
      String? capturedFailure;

      success.when(
        success: (data) => capturedSuccess = data,
        failure: (fail) => capturedFailure = fail,
      );
      expect(capturedSuccess, equals(99));
      expect(capturedFailure, isNull);

      capturedSuccess = null;
      const failure = Result<int, String>.failure('err');
      failure.when(
        success: (data) => capturedSuccess = data,
        failure: (fail) => capturedFailure = fail,
      );
      expect(capturedSuccess, isNull);
      expect(capturedFailure, equals('err'));
    });

    test('map transforms success value and preserves failure', () {
      const success = Result<int, String>.success(5);
      final mapped = success.map((x) => x * 2);
      expect(mapped.dataOrNull, equals(10));

      const failure = Result<int, String>.failure('err');
      final mappedFail = failure.map((x) => x * 2);
      expect(mappedFail.failureOrNull, equals('err'));
    });

    test('flatMap chains Results correctly', () {
      const success = Result<int, String>.success(20);
      final flatMapped = success.flatMap(
        (x) => Result<String, String>.success('Result: $x'),
      );
      expect(flatMapped.dataOrNull, equals('Result: 20'));

      final flatMappedFail = success.flatMap(
        (x) => const Result<String, String>.failure('failed in chain'),
      );
      expect(flatMappedFail.failureOrNull, equals('failed in chain'));
    });

    test('mapError transforms failure and preserves success', () {
      const failure = Result<int, String>.failure('404');
      final mapped = failure.mapError((code) => 'Error code: $code');
      expect(mapped.failureOrNull, equals('Error code: 404'));

      const success = Result<int, String>.success(100);
      final mappedSuccess = success.mapError((code) => 'Error code: $code');
      expect(mappedSuccess.dataOrNull, equals(100));
    });

    test('supports equality and hash code', () {
      const s1 = Result<int, AppFailure>.success(1);
      const s2 = Result<int, AppFailure>.success(1);
      const s3 = Result<int, AppFailure>.success(2);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));

      const f1 = Result<int, String>.failure('e');
      const f2 = Result<int, String>.failure('e');
      expect(f1, equals(f2));
    });
  });
}
