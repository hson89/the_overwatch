import 'dart:async';
import 'package:the_overwatch/the_overwatch.dart';

/// Example usage of the Flutter Observability package with Grafana stack
void main() async {
  // Example observability configuration
  final config = ObservabilityConfig(
    backendConfigs: [], // Configs will be passed separately to registerAdapter
    privacy: PrivacyConfig(
      scrubPii: true,
      enableAnalytics: true,
      enableErrorReporting: true,
      enablePerformanceMonitoring: true,
      enableLogging: true,
    ),
    enableOfflineBuffer: true,
    maxBufferSize: 1000,
    flushInterval: Duration(minutes: 1),
    enableDebugLogging: true,
    globalUserId: 'user-123',
    globalContext: {
      'app_type': 'mobile',
      'deployment': 'production',
    },
  );

  // Loki configuration for structured logging
  final lokiConfig = LokiConfig(
    enabled: true,
    host: 'http://localhost:3100',
    globalLabels: {
      'app': 'flutter_app',
      'environment': 'production',
    },
    batchSize: 50,
    flushInterval: Duration(seconds: 30),
  );

  // Faro configuration for RUM, traces, and metrics
  final faroConfig = FaroConfig(
    enabled: true,
    appName: 'Flutter Observability Demo',
    appVersion: '1.0.0',
    collectorUrl: 'https://faro-collector.example.com',
    environment: 'production',
    enableConsoleInstrumentation: true,
    enableWebVitalsInstrumentation: true,
    enableErrorInstrumentation: true,
    enableUserInteractionInstrumentation: true,
    sessionSampleRate: 1.0,
    traceSampleRate: 0.1, // 10% trace sampling
    globalAttributes: {
      'team': 'mobile',
      'feature_flag_group': 'beta',
    },
  );

  // Initialize observability with Grafana stack adapters
  await Observability.setup(
    config,
    adapters: [
      (LokiAdapter(), lokiConfig),
      (FaroAdapter(), faroConfig),
    ],
  );

  // Example usage
  await demonstrateObservability();

  // Clean up
  await Observability.instance.dispose();
}

/// Demonstrate various observability features
Future<void> demonstrateObservability() async {
  final obs = Observability.instance;

  // Set user information
  await obs.setUserId('user-456');
  await obs.setUserProperties({
    'email': 'user@example.com', // Will be scrubbed by PII protection
    'plan': 'premium',
    'signup_date': '2024-01-15',
  });

  // Add global context
  obs.addGlobalContext('screen', 'home');

  // Track custom events
  await obs.trackEvent('button_clicked', properties: {
    'button_id': 'submit_form',
    'form_type': 'contact',
    'timestamp': DateTime.now().toIso8601String(),
  });

  await obs.trackEvent('feature_used', properties: {
    'feature_name': 'advanced_search',
    'usage_count': 5,
  });

  // Log messages with different levels
  await obs.info('Application started successfully');
  await obs.debug('Loading user preferences');
  await obs.warn('API rate limit approaching');

  // Record custom metrics
  await obs.recordMetric('page_load_time', 1.234, unit: 'seconds');
  await obs.recordMetric('memory_usage', 64.5, unit: 'MB');
  await obs.recordMetric('api_response_time', 0.845, 
    unit: 'seconds',
    tags: {'endpoint': '/api/users', 'method': 'GET'},
  );

  // Capture errors with context
  try {
    throw Exception('Something went wrong with user data');
  } catch (e, stack) {
    await obs.captureError(
      e,
      stackTrace: stack,
      message: 'Failed to process user data',
      severity: ErrorSeverity.high,
      context: {
        'user_id': 'user-456',
        'operation': 'data_sync',
        'retry_count': 2,
      },
      breadcrumbs: [
        Breadcrumb(
          message: 'User clicked sync button',
          timestamp: DateTime.now().subtract(Duration(seconds: 5)),
          category: 'user_action',
        ),
        Breadcrumb(
          message: 'Started data synchronization',
          timestamp: DateTime.now().subtract(Duration(seconds: 3)),
          category: 'operation',
        ),
      ],
    );
  }

  // Log with custom labels and context
  await obs.log(
    LogLevel.error,
    'Database connection failed',
    labels: {
      'component': 'database',
      'retry_attempt': '3',
    },
    context: {
      'connection_string': '[REDACTED]', // Sensitive info
      'timeout_ms': 5000,
      'last_successful_connection': '2024-01-20T10:30:00Z',
    },
  );

  // Demonstrate session management
  obs.startNewSession();
  await obs.info('New session started: ${obs.sessionId}');

  // Check buffer status
  final bufferSize = await obs.getBufferSize();
  print('Current buffer size: $bufferSize events');

  // Manual buffer flush
  await obs.flushBuffer();
  print('Buffer flushed manually');
}

/// Example of integrating with Flutter error handling
void setupFlutterErrorHandling() {
  // TODO: Uncomment when Flutter dependencies are available
  
  // FlutterError.onError = (FlutterErrorDetails details) {
  //   Observability.instance.captureError(
  //     details.exception,
  //     stackTrace: details.stack,
  //     context: {
  //       'library': details.library,
  //       'context': details.context?.toString(),
  //     },
  //     severity: ErrorSeverity.high,
  //   );
  // };

  // PlatformDispatcher.instance.onError = (error, stack) {
  //   Observability.instance.captureError(
  //     error,
  //     stackTrace: stack,
  //     context: {'source': 'platform_dispatcher'},
  //     severity: ErrorSeverity.critical,
  //   );
  //   return true;
  // };
}

/// Example of real-time monitoring setup
class AppMonitor {
  static Timer? _metricsTimer;

  static void startRealTimeMonitoring() {
    _metricsTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _recordSystemMetrics();
    });
  }

  static void stopRealTimeMonitoring() {
    _metricsTimer?.cancel();
  }

  static Future<void> _recordSystemMetrics() async {
    final obs = Observability.instance;

    // Example system metrics (would use actual system data in real implementation)
    await obs.recordMetric('cpu_usage', 45.2, unit: 'percent');
    await obs.recordMetric('memory_usage', 128.5, unit: 'MB');
    await obs.recordMetric('network_requests_per_minute', 12);
    await obs.recordMetric('active_users', 1, tags: {'session_id': obs.sessionId ?? 'unknown'});
  }
}

/// Example of custom adapter for additional backends
class CustomLoggingAdapter extends BackendAdapter {
  @override
  String get name => 'CustomLogger';

  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize(BackendConfig config) async {
    print('CustomLoggingAdapter initialized');
  }

  @override
  Future<void> trackEvent(AppEvent event) async {
    print('[CUSTOM] Event: ${event.name} - ${event.properties}');
  }

  @override
  Future<void> captureError(AppError error) async {
    print('[CUSTOM] Error: ${error.exception} - ${error.severity}');
  }

  @override
  Future<void> log(AppLog log) async {
    print('[CUSTOM] Log [${log.level}]: ${log.message}');
  }

  @override
  Future<void> recordMetric(AppMetric metric) async {
    print('[CUSTOM] Metric: ${metric.name} = ${metric.value} ${metric.unit ?? ''}');
  }

  @override
  Future<void> setUserId(String? userId) async {
    print('[CUSTOM] User ID set to: $userId');
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    print('[CUSTOM] User properties: $properties');
  }

  @override
  Future<void> dispose() async {
    print('CustomLoggingAdapter disposed');
  }
}

/// Example custom backend configuration
class CustomLoggingConfig extends BackendConfig {
  const CustomLoggingConfig({required super.enabled, this.logLevel = 'info'});

  final String logLevel;

  @override
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'logLevel': logLevel,
      };
}
