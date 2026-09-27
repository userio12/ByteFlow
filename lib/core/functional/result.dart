/// Functional Result monad representing either a success ([Success]) or a failure ([Failure]).
sealed class Result<S, F> {
  const Result();

  /// Creates a successful [Result] containing [data].
  const factory Result.success(S data) = Success<S, F>;

  /// Creates a failed [Result] containing [failure].
  const factory Result.failure(F failure) = Failure<S, F>;

  /// Returns `true` if this result is a [Success].
  bool get isSuccess => this is Success<S, F>;

  /// Returns `true` if this result is a [Failure].
  bool get isFailure => this is Failure<S, F>;

  /// Returns the successful data or `null` if this is a [Failure].
  S? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  /// Returns the failure or `null` if this is a [Success].
  F? get failureOrNull => switch (this) {
        Success() => null,
        Failure(:final failure) => failure,
      };

  /// Transforms the result by applying [onSuccess] if this is a [Success],
  /// or [onFailure] if this is a [Failure].
  R fold<R>(
    R Function(S data) onSuccess,
    R Function(F failure) onFailure,
  ) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Failure(:final failure) => onFailure(failure),
    };
  }

  /// Pattern-matches the result executing [success] or [failure] callbacks.
  void when({
    required void Function(S data) success,
    required void Function(F failure) failure,
  }) {
    switch (this) {
      case Success(:final data):
        success(data);
      case Failure(failure: final error):
        failure(error);
    }
  }

  /// Maps the success value to a new value using [transform].
  Result<T, F> map<T>(T Function(S data) transform) {
    return switch (this) {
      Success(:final data) => Result.success(transform(data)),
      Failure(:final failure) => Result.failure(failure),
    };
  }

  /// Flat-maps the success value to a new [Result] using [transform].
  Result<T, F> flatMap<T>(Result<T, F> Function(S data) transform) {
    return switch (this) {
      Success(:final data) => transform(data),
      Failure(:final failure) => Result.failure(failure),
    };
  }

  /// Maps the failure value using [transform].
  Result<S, T> mapError<T>(T Function(F failure) transform) {
    return switch (this) {
      Success(:final data) => Result.success(data),
      Failure(:final failure) => Result.failure(transform(failure)),
    };
  }
}

/// Represents a successful computation returning [data].
final class Success<S, F> extends Result<S, F> {
  final S data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<S, F> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Result.success($data)';
}

/// Represents a failed computation returning [failure].
final class Failure<S, F> extends Result<S, F> {
  final F failure;

  const Failure(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<S, F> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Result.failure($failure)';
}
