/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Asset loading exceptions
class AssetException extends AppException {
  const AssetException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Game logic exceptions
class GameException extends AppException {
  const GameException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Serialization exceptions
class SerializationException extends AppException {
  const SerializationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Server exceptions
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(String message, {this.statusCode, String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Platform-specific exceptions
class PlatformException extends AppException {
  const PlatformException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Business logic exceptions
class BusinessLogicException extends AppException {
  const BusinessLogicException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// File system exceptions
class FileSystemException extends AppException {
  const FileSystemException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Configuration exceptions
class ConfigurationException extends AppException {
  const ConfigurationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Initialization exceptions
class InitializationException extends AppException {
  const InitializationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Resource not found exceptions
class NotFoundException extends AppException {
  const NotFoundException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Concurrent access exceptions
class ConcurrencyException extends AppException {
  const ConcurrencyException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Rate limiting exceptions
class RateLimitException extends AppException {
  final Duration? retryAfter;

  const RateLimitException(String message, {this.retryAfter, String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Quota exceeded exceptions
class QuotaExceededException extends AppException {
  const QuotaExceededException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Migration exceptions
class MigrationException extends AppException {
  const MigrationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Dependency injection exceptions
class DependencyException extends AppException {
  const DependencyException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// State management exceptions
class StateException extends AppException {
  const StateException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Feature flag exceptions
class FeatureException extends AppException {
  const FeatureException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Performance-related exceptions
class PerformanceException extends AppException {
  const PerformanceException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Compatibility exceptions
class CompatibilityException extends AppException {
  const CompatibilityException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Maintenance mode exceptions
class MaintenanceException extends AppException {
  final DateTime? estimatedEnd;

  const MaintenanceException(String message, {this.estimatedEnd, String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Device capability exceptions
class DeviceCapabilityException extends AppException {
  const DeviceCapabilityException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Encryption/Decryption exceptions
class CryptographyException extends AppException {
  const CryptographyException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Memory-related exceptions
class MemoryException extends AppException {
  const MemoryException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Thread-related exceptions
class ThreadException extends AppException {
  const ThreadException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Backup/Restore exceptions
class BackupException extends AppException {
  const BackupException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// User input exceptions
class UserInputException extends AppException {
  const UserInputException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Format exceptions
class FormatException extends AppException {
  const FormatException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Version compatibility exceptions
class VersionException extends AppException {
  const VersionException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Security exceptions
class SecurityException extends AppException {
  const SecurityException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Licensing exceptions
class LicenseException extends AppException {
  const LicenseException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Service unavailable exceptions
class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// External service exceptions
class ExternalServiceException extends AppException {
  final String? serviceName;

  const ExternalServiceException(String message, {this.serviceName, String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Exception utility class for common exception handling patterns
class ExceptionUtils {
  /// Extract user-friendly message from exception
  static String getUserMessage(Exception exception) {
    if (exception is AppException) {
      return exception.message;
    }
    
    // Generic message for unknown exceptions
    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if exception is retryable
  static bool isRetryable(Exception exception) {
    if (exception is NetworkException ||
        exception is TimeoutException ||
        exception is ServiceUnavailableException) {
      return true;
    }
    
    return false;
  }

  /// Get exception severity level
  static ExceptionSeverity getSeverity(Exception exception) {
    if (exception is MemoryException ||
        exception is ConcurrencyException ||
        exception is SecurityException) {
      return ExceptionSeverity.critical;
    }
    
    if (exception is NetworkException ||
        exception is StorageException ||
        exception is GameException) {
      return ExceptionSeverity.high;
    }
    
    if (exception is ValidationException ||
        exception is UserInputException ||
        exception is FormatException) {
      return ExceptionSeverity.medium;
    }
    
    return ExceptionSeverity.low;
  }

  /// Convert exception to error report
  static Map<String, dynamic> toErrorReport(Exception exception, {StackTrace? stackTrace}) {
    return {
      'type': exception.runtimeType.toString(),
      'message': exception.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'severity': getSeverity(exception).name,
      'retryable': isRetryable(exception),
      'stackTrace': stackTrace?.toString(),
      if (exception is AppException) ...{
        'code': exception.code,
        'details': exception.details,
      },
    };
  }
}

/// Exception severity levels
enum ExceptionSeverity {
  low,
  medium,
  high,
  critical;
}