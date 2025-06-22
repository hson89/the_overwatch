import '../models/models.dart';
import 'observability_config.dart';

/// Abstract adapter interface for different observability backends
abstract class BackendAdapter {
  /// Name of the backend adapter
  String get name;

  /// Initialize the adapter with configuration
  Future<void> initialize(BackendConfig config);

  /// Track a custom event
  Future<void> trackEvent(AppEvent event);

  /// Capture an error
  Future<void> captureError(AppError error);

  /// Log a message
  Future<void> log(AppLog log);

  /// Record a metric
  Future<void> recordMetric(AppMetric metric);

  /// Set the current user ID
  Future<void> setUserId(String? userId);

  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties);

  /// Clean up resources
  Future<void> dispose();

  /// Whether this adapter is currently enabled
  bool get isEnabled;

  /// Whether this adapter supports the given data type
  bool supportsEvent(AppEvent event) => true;
  bool supportsError(AppError error) => true;
  bool supportsLog(AppLog log) => true;
  bool supportsMetric(AppMetric metric) => true;
}
