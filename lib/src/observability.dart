import 'dart:async';
import 'models/models.dart';
import 'core/core.dart';

/// Main observability facade - singleton entry point for the Flutter application
class Observability {
  Observability._();
  
  static final Observability _instance = Observability._();
  static Observability get instance => _instance;

  ObservabilityDispatcher get _dispatcher => ObservabilityDispatcher.instance;
  
  bool _isInitialized = false;
  String? _currentSessionId;

  /// Initialize the observability package
  Future<void> initialize(ObservabilityConfig config) async {
    if (_isInitialized) {
      throw StateError('Observability is already initialized');
    }

    // Generate session ID if not provided
    _currentSessionId = config.globalSessionId ?? _generateSessionId();

    // Update config with session ID
    final updatedConfig = config.copyWith(globalSessionId: _currentSessionId);

    await _dispatcher.initialize(updatedConfig);
    _isInitialized = true;
  }

  /// Register a backend adapter
  Future<void> registerAdapter(BackendAdapter adapter, BackendConfig config) async {
    _ensureInitialized();
    await _dispatcher.registerAdapter(adapter, config);
  }

  /// Track a custom event
  Future<void> trackEvent(String name, {
    Map<String, dynamic> properties = const {},
    Map<String, dynamic> context = const {},
  }) async {
    _ensureInitialized();
    
    final event = AppEvent(
      name: name,
      properties: properties,
      timestamp: DateTime.now(),
      context: context,
    );
    
    await _dispatcher.trackEvent(event);
  }

  /// Capture an exception or error
  Future<void> captureError(
    Object exception, {
    StackTrace? stackTrace,
    String? message,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic> context = const {},
    List<Breadcrumb> breadcrumbs = const [],
  }) async {
    _ensureInitialized();
    
    final error = AppError(
      exception: exception,
      stackTrace: stackTrace,
      message: message,
      severity: severity,
      timestamp: DateTime.now(),
      context: context,
      breadcrumbs: breadcrumbs,
    );
    
    await _dispatcher.captureError(error);
  }

  /// Log a message with specified level
  Future<void> log(
    LogLevel level,
    String message, {
    Map<String, String> labels = const {},
    Map<String, dynamic> context = const {},
  }) async {
    _ensureInitialized();
    
    final log = AppLog(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      labels: labels,
      context: context,
    );
    
    await _dispatcher.log(log);
  }

  /// Log trace level message
  Future<void> trace(String message, {Map<String, dynamic> context = const {}}) async {
    await log(LogLevel.trace, message, context: context);
  }

  /// Log debug level message
  Future<void> debug(String message, {Map<String, dynamic> context = const {}}) async {
    await log(LogLevel.debug, message, context: context);
  }

  /// Log info level message
  Future<void> info(String message, {Map<String, dynamic> context = const {}}) async {
    await log(LogLevel.info, message, context: context);
  }

  /// Log warning level message
  Future<void> warn(String message, {Map<String, dynamic> context = const {}}) async {
    await log(LogLevel.warn, message, context: context);
  }

  /// Log error level message
  Future<void> error(String message, {Map<String, dynamic> context = const {}}) async {
    await log(LogLevel.error, message, context: context);
  }

  /// Log fatal level message
  Future<void> fatal(String message, {Map<String, dynamic> context = const {}}) async {
    await log(LogLevel.fatal, message, context: context);
  }

  /// Record a custom metric
  Future<void> recordMetric(
    String name,
    double value, {
    String? unit,
    Map<String, String> tags = const {},
    String? traceId,
    String? spanId,
  }) async {
    _ensureInitialized();
    
    final metric = AppMetric(
      name: name,
      value: value,
      unit: unit,
      tags: tags,
      timestamp: DateTime.now(),
      traceId: traceId,
      spanId: spanId,
    );
    
    await _dispatcher.recordMetric(metric);
  }

  /// Set the current user ID
  Future<void> setUserId(String? userId) async {
    _ensureInitialized();
    await _dispatcher.setUserId(userId);
  }

  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    _ensureInitialized();
    await _dispatcher.setUserProperties(properties);
  }

  /// Set global context that will be added to all events
  void setGlobalContext(Map<String, dynamic> context) {
    _ensureInitialized();
    _dispatcher.setGlobalContext(context);
  }

  /// Add to global context
  void addGlobalContext(String key, dynamic value) {
    _ensureInitialized();
    _dispatcher.addGlobalContext(key, value);
  }

  /// Remove from global context
  void removeGlobalContext(String key) {
    _ensureInitialized();
    _dispatcher.removeGlobalContext(key);
  }

  /// Get current session ID
  String? get sessionId => _currentSessionId;

  /// Start a new session
  void startNewSession() {
    _currentSessionId = _generateSessionId();
    if (_isInitialized) {
      _dispatcher.addGlobalContext('sessionId', _currentSessionId);
    }
  }

  /// Get current buffer size (if offline buffer is enabled)
  Future<int?> getBufferSize() async {
    _ensureInitialized();
    return await _dispatcher.getBufferSize();
  }

  /// Manually flush offline buffer
  Future<void> flushBuffer() async {
    _ensureInitialized();
    await _dispatcher.flushBuffer();
  }

  /// Check if observability is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose of all resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _dispatcher.dispose();
      _isInitialized = false;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Observability not initialized. Call initialize() first.');
    }
  }

  String _generateSessionId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${now.microsecond}';
  }
  // Convenience methods for Flutter integration

  /// Initialize observability with adapters
  static Future<void> setup(
    ObservabilityConfig config, {
    List<(BackendAdapter, BackendConfig)> adapters = const [],
  }) async {
    await Observability.instance.initialize(config);
    
    // Register adapters
    for (final (adapter, adapterConfig) in adapters) {
      await Observability.instance.registerAdapter(adapter, adapterConfig);
    }

    // TODO: Add Flutter error handling integration
    // FlutterError.onError = (FlutterErrorDetails details) {
    //   Observability.instance.captureError(
    //     details.exception,
    //     stackTrace: details.stack,
    //     context: {'library': details.library},
    //   );
    // };

    // TODO: Add PlatformDispatcher error handling
    // PlatformDispatcher.instance.onError = (error, stack) {
    //   Observability.instance.captureError(error, stackTrace: stack);
    //   return true;
    // };

    print('Observability initialized with ${adapters.length} adapters');
  }
}
