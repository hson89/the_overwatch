// This is a working demonstration of the Flutter Observability package
// Run with: dart run example/demo.dart

import '../lib/the_overwatch.dart';

Future<void> main() async {
  print('🚀 Flutter Observability Package Demo\n');

  // 1. Initialize observability with configuration
  print('📋 Setting up observability configuration...');
  final config = ObservabilityConfig(
    backendConfigs: [],
    privacy: PrivacyConfig(
      scrubPii: true,
      enableAnalytics: true,
      enableErrorReporting: true,
      enablePerformanceMonitoring: true,
      enableLogging: true,
    ),
    enableOfflineBuffer: true,
    maxBufferSize: 100,
    flushInterval: Duration(seconds: 10),
    enableDebugLogging: true,
    globalUserId: 'demo-user-123',
    globalContext: {
      'app_version': '1.0.0',
      'environment': 'demo',
      'build_type': 'debug',
    },
  );

  // Initialize the observability system
  await Observability.instance.initialize(config);
  print('✅ Observability initialized\n');

  // 2. Set up backend adapters
  print('🔧 Registering backend adapters...');
  
  // Loki adapter for structured logging
  final lokiConfig = LokiConfig(
    enabled: true,
    host: 'http://localhost:3100',
    globalLabels: {
      'app': 'flutter_demo',
      'component': 'mobile_app',
      'environment': 'development',
    },
    batchSize: 10,
    flushInterval: Duration(seconds: 5),
  );
  
  // Faro adapter for RUM and metrics
  final faroConfig = FaroConfig(
    enabled: true,
    appName: 'Flutter Observability Demo',
    appVersion: '1.0.0',
    collectorUrl: 'https://faro-collector.example.com',
    environment: 'development',
    enableConsoleInstrumentation: true,
    enableErrorInstrumentation: true,
    sessionSampleRate: 1.0,
    traceSampleRate: 0.5,
    globalAttributes: {
      'team': 'platform',
      'feature_flag': 'observability_v2',
    },
  );

  await Observability.instance.registerAdapter(LokiAdapter(), lokiConfig);
  await Observability.instance.registerAdapter(FaroAdapter(), faroConfig);
  print('✅ Adapters registered: Loki & Faro\n');

  // 3. Demonstrate event tracking
  print('📊 Tracking events...');
  await Observability.instance.trackEvent('app_started', properties: {
    'launch_time_ms': 1234,
    'cold_start': true,
    'previous_version': '0.9.0',
  });

  await Observability.instance.trackEvent('user_interaction', properties: {
    'action': 'button_tap',
    'element_id': 'demo_button',
    'screen': 'main',
  });
  print('✅ Events tracked\n');

  // 4. Demonstrate logging at different levels
  print('📝 Logging messages...');
  await Observability.instance.trace('Application trace message for debugging');
  await Observability.instance.debug('Debug: Loading configuration from cache');
  await Observability.instance.info('Application started successfully');
  await Observability.instance.warn('API rate limit at 80% capacity');
  
  await Observability.instance.log(
    LogLevel.info,
    'Custom structured log with context',
    labels: {
      'component': 'data_service',
      'operation': 'user_sync',
    },
    context: {
      'user_count': 150,
      'sync_duration_ms': 2340,
      'success_rate': 0.98,
    },
  );
  print('✅ Logs recorded\n');

  // 5. Demonstrate metrics recording
  print('📈 Recording metrics...');
  await Observability.instance.recordMetric('startup_time', 1.23, unit: 'seconds');
  await Observability.instance.recordMetric('memory_usage', 64.5, unit: 'MB');
  await Observability.instance.recordMetric('api_calls_per_minute', 45.0);
  
  await Observability.instance.recordMetric(
    'database_query_time',
    0.085,
    unit: 'seconds',
    tags: {
      'query_type': 'SELECT',
      'table': 'users',
      'cache_hit': 'true',
    },
  );
  print('✅ Metrics recorded\n');

  // 6. Demonstrate error handling
  print('🚨 Handling errors...');
  try {
    // Simulate an error
    throw FormatException('Invalid data format in user preferences');
  } catch (e, stackTrace) {
    await Observability.instance.captureError(
      e,
      stackTrace: stackTrace,
      message: 'Failed to parse user preferences',
      severity: ErrorSeverity.medium,
      context: {
        'user_id': 'demo-user-123',
        'preferences_version': '2.1',
        'corruption_detected': true,
      },
      breadcrumbs: [
        Breadcrumb(
          message: 'User opened settings screen',
          timestamp: DateTime.now().subtract(Duration(seconds: 30)),
          category: 'navigation',
          data: {'screen': 'settings'},
        ),
        Breadcrumb(
          message: 'Attempting to load preferences',
          timestamp: DateTime.now().subtract(Duration(seconds: 5)),
          category: 'data_access',
          data: {'source': 'local_storage'},
        ),
      ],
    );
  }
  print('✅ Error captured with context\n');

  // 7. Demonstrate user context management
  print('👤 Managing user context...');
  await Observability.instance.setUserId('demo-user-456');
  await Observability.instance.setUserProperties({
    'email': 'demo@example.com', // Will be scrubbed by PII protection
    'subscription_tier': 'premium',
    'signup_date': '2024-01-15',
    'feature_flags': ['new_ui', 'beta_features'],
  });

  Observability.instance.addGlobalContext('current_screen', 'demo_screen');
  Observability.instance.addGlobalContext('session_duration', '00:05:32');
  print('✅ User context updated\n');

  // 8. Demonstrate privacy features
  print('🔒 Testing privacy features...');
  final privacyUtils = PrivacyUtils(config.privacy);
  
  final sensitiveData = 'Contact support at support@company.com or call 555-123-4567';
  final scrubbedData = privacyUtils.scrubString(sensitiveData);
  print('Original: $sensitiveData');
  print('Scrubbed: $scrubbedData');
  
  final sensitiveMap = {
    'user_email': 'user@example.com',
    'credit_card': '4532-1234-5678-9012',
    'public_info': 'This is safe to log',
  };
  final scrubbedMap = privacyUtils.scrubMap(sensitiveMap);
  print('Original map: $sensitiveMap');
  print('Scrubbed map: $scrubbedMap');
  print('✅ PII protection working\n');

  // 9. Check buffer status
  print('💾 Checking offline buffer...');
  final bufferSize = await Observability.instance.getBufferSize();
  print('Current buffer size: $bufferSize events');
  
  if (bufferSize != null && bufferSize > 0) {
    print('Manually flushing buffer...');
    await Observability.instance.flushBuffer();
    final newBufferSize = await Observability.instance.getBufferSize();
    print('Buffer size after flush: $newBufferSize events');
  }
  print('✅ Buffer management complete\n');

  // 10. Demonstrate session management
  print('🔄 Managing sessions...');
  print('Current session ID: ${Observability.instance.sessionId}');
  
  Observability.instance.startNewSession();
  print('New session ID: ${Observability.instance.sessionId}');
  
  await Observability.instance.info('New session started');
  print('✅ Session management complete\n');

  // 11. Final logs and cleanup
  print('🏁 Finalizing demo...');
  await Observability.instance.info('Demo completed successfully');
  await Observability.instance.recordMetric('demo_duration', 15.0, unit: 'seconds');

  // Clean up resources
  await Observability.instance.dispose();
  print('✅ Resources cleaned up');
  
  print('\n🎉 Flutter Observability Demo Complete!');
  print('📊 Check your Loki instance at http://localhost:3100 for logs');
  print('📈 Check your Faro collector for RUM data and metrics');
}

/// Utility function to demonstrate adapter capabilities
void demonstrateAdapterCapabilities() {
  print('\n🔍 Backend Adapter Capabilities:');
  
  final lokiAdapter = LokiAdapter();
  final faroAdapter = FaroAdapter();
  
  final testEvent = AppEvent(name: 'test', timestamp: DateTime.now());
  final testError = AppError(exception: 'test', timestamp: DateTime.now());
  final testLog = AppLog(level: LogLevel.info, message: 'test', timestamp: DateTime.now());
  final testMetric = AppMetric(name: 'test', value: 1.0, timestamp: DateTime.now());
  
  print('Loki Adapter (${lokiAdapter.name}):');
  print('  - Events: ${lokiAdapter.supportsEvent(testEvent)}');
  print('  - Errors: ${lokiAdapter.supportsError(testError)}');
  print('  - Logs: ${lokiAdapter.supportsLog(testLog)}');
  print('  - Metrics: ${lokiAdapter.supportsMetric(testMetric)}');
  
  print('Faro Adapter (${faroAdapter.name}):');
  print('  - Events: ${faroAdapter.supportsEvent(testEvent)}');
  print('  - Errors: ${faroAdapter.supportsError(testError)}');
  print('  - Logs: ${faroAdapter.supportsLog(testLog)}');
  print('  - Metrics: ${faroAdapter.supportsMetric(testMetric)}');
}
