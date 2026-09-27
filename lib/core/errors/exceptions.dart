/// Base class for all ByteFlow application exceptions.
abstract class AppException implements Exception {
  final String message;

  const AppException({required this.message});

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a platform channel invocation encounters an error.
class PlatformServiceException extends AppException {
  final String code;
  final dynamic details;

  const PlatformServiceException({
    required this.code,
    required super.message,
    this.details,
  });
}

/// Thrown when a SQLite database operation fails.
class DatabaseStorageException extends AppException {
  final dynamic cause;

  const DatabaseStorageException({
    required super.message,
    this.cause,
  });
}

/// Thrown when a required permission is not granted.
class PermissionNotGrantedException extends AppException {
  final String permission;

  PermissionNotGrantedException({
    required this.permission,
    String? message,
  }) : super(message: message ?? 'Permission not granted: $permission');
}

/// Thrown when requested cached data is not present in storage.
class CacheNotFoundException extends AppException {
  const CacheNotFoundException(String message) : super(message: message);
}
