/// Sealed failure hierarchy for strongly-typed domain error handling.
sealed class AppFailure {
  final String message;

  const AppFailure({required this.message});

  @override
  String toString() => '$runtimeType: $message';
}

/// Failure triggered when required Android system permission is not granted.
final class PermissionFailure extends AppFailure {
  final String permission;

  PermissionFailure({
    required this.permission,
    String? message,
  }) : super(
          message: message ?? 'Required permission was not granted: $permission',
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionFailure &&
          runtimeType == other.runtimeType &&
          permission == other.permission &&
          message == other.message;

  @override
  int get hashCode => Object.hash(permission, message);
}

/// Failure triggered when native Android MethodChannel or EventChannel fails.
final class PlatformFailure extends AppFailure {
  final String code;
  final dynamic details;

  const PlatformFailure({
    required this.code,
    required super.message,
    this.details,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformFailure &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);
}

/// Failure triggered during SQLite database query, insertion, or migration.
final class DatabaseFailure extends AppFailure {
  final dynamic cause;

  const DatabaseFailure({
    required super.message,
    this.cause,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Failure triggered when reading or writing local key-value preferences.
final class CacheFailure extends AppFailure {
  const CacheFailure({required super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Failure triggered when user input or plan parameters violate constraints.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({required super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
