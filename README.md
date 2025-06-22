# The Overwatch

A comprehensive observability package for Flutter applications that enables running with different observability stacks. Currently supports Grafana stack but can be swapped with different stacks as well.

## Features

- **Multi-Backend Support**: Easily integrate with multiple observability backends
- **Grafana Stack Integration**: Built-in support for Loki (logging) and Faro (RUM/metrics/traces)
- **Privacy Controls**: Automatic PII scrubbing with configurable patterns
- **Offline Buffering**: Store events offline and replay when connectivity is restored
- **Type-Safe**: Strongly typed data models for events, errors, logs, and metrics
- **Extensible**: Easy to add custom backend adapters
- **Performance Optimized**: Batching, compression, and background processing

## Architecture

### Core Components

- **Observability**: Main facade providing a simple API
- **ObservabilityDispatcher**: Manages multiple backend adapters and data flow
- **BackendAdapter**: Abstract interface for observability backends
- **Data Models**: Strongly typed models for AppEvent, AppError, AppLog, AppMetric
- **Privacy Utils**: PII scrubbing and data anonymization
- **Offline Buffer**: Persistent storage for offline event replay

### Backend Adapters

#### LokiAdapter
- Sends structured logs to Grafana Loki
- Batches logs by labels for efficient streaming
- Converts errors to structured log entries
- Supports custom labels and global context

#### FaroAdapter
- Integrates with Grafana Faro for Real User Monitoring
- Tracks custom events and user interactions
- Captures errors with breadcrumbs and context
- Records custom metrics and performance data
- Automatically instruments console logs and web vitals

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  the_overwatch:
    path: ../path/to/the_overwatch
```

For actual deployment, this would be published to pub.dev:

```yaml
dependencies:
  the_overwatch: ^1.0.0
```

## Quick Start

### 1. Basic Setup

```dart
import 'package:the_overwatch/the_overwatch.dart';

void main() async {
  // Configure observability
  final config = ObservabilityConfig(
    backendConfigs: [],
    privacy: PrivacyConfig(
      scrubPii: true,
      enableAnalytics: true,
      enableErrorReporting: true,
    ),
    enableOfflineBuffer: true,
    globalContext: {'app_type': 'mobile'},
  );

  // Setup with Grafana stack
  await Observability.setup(config, adapters: [
    (LokiAdapter(), LokiConfig(
      enabled: true,
      host: 'http://localhost:3100',
      globalLabels: {'app': 'my_flutter_app'},
    )),
    (FaroAdapter(), FaroConfig(
      enabled: true,
      appName: 'My Flutter App',
      appVersion: '1.0.0',
      collectorUrl: 'https://faro-collector.example.com',
    )),
  ]);

  // Your app code here
  runApp(MyApp());
}
```

### 2. Track Events

```dart
// Track user interactions
await Observability.instance.trackEvent('button_clicked', properties: {
  'button_id': 'submit_form',
  'form_type': 'contact',
});

// Track feature usage
await Observability.instance.trackEvent('feature_used', properties: {
  'feature_name': 'advanced_search',
  'usage_count': 5,
});
```

### 3. Logging

```dart
// Simple logging
await Observability.instance.info('User logged in successfully');
await Observability.instance.error('Failed to sync data');

// Structured logging with context
await Observability.instance.log(
  LogLevel.warn,
  'API rate limit approaching',
  labels: {'component': 'api_client'},
  context: {'remaining_requests': 10},
);
```

### 4. Error Handling

```dart
try {
  await riskyOperation();
} catch (e, stack) {
  await Observability.instance.captureError(
    e,
    stackTrace: stack,
    severity: ErrorSeverity.high,
    context: {'operation': 'data_sync'},
    breadcrumbs: [
      Breadcrumb(
        message: 'User initiated sync',
        timestamp: DateTime.now().subtract(Duration(seconds: 5)),
        category: 'user_action',
      ),
    ],
  );
}
```

### 5. Metrics

```dart
// Performance metrics
await Observability.instance.recordMetric('page_load_time', 1.234, unit: 'seconds');

// Business metrics
await Observability.instance.recordMetric('api_response_time', 0.845, 
  unit: 'seconds',
  tags: {'endpoint': '/api/users', 'method': 'GET'},
);
```

### 6. User Context

```dart
// Set user information
await Observability.instance.setUserId('user-123');
await Observability.instance.setUserProperties({
  'plan': 'premium',
  'signup_date': '2024-01-15',
  'email': 'user@example.com', // Will be scrubbed if PII protection is enabled
});

// Add global context
Observability.instance.addGlobalContext('screen', 'home');
```

## Configuration

### Privacy Configuration

```dart
PrivacyConfig(
  scrubPii: true,                    // Enable PII scrubbing
  enableAnalytics: true,             // Enable event tracking
  enableErrorReporting: true,        // Enable error capture
  enablePerformanceMonitoring: true, // Enable metrics
  enableLogging: true,               // Enable logging
  piiPatterns: [                     // Custom PII patterns
    r'\\bcustom-secret-\\d+\\b',
  ],
)
```

### Loki Configuration

```dart
LokiConfig(
  enabled: true,
  host: 'http://localhost:3100',
  globalLabels: {
    'app': 'my_app',
    'environment': 'production',
  },
  batchSize: 100,
  flushInterval: Duration(seconds: 30),
  enableCompression: true,
)
```

### Faro Configuration

```dart
FaroConfig(
  enabled: true,
  appName: 'My Flutter App',
  appVersion: '1.0.0',
  collectorUrl: 'https://faro-collector.example.com',
  environment: 'production',
  enableConsoleInstrumentation: true,
  enableWebVitalsInstrumentation: true,
  enableErrorInstrumentation: true,
  enableUserInteractionInstrumentation: true,
  sessionSampleRate: 1.0,
  traceSampleRate: 0.1,
  globalAttributes: {
    'team': 'mobile',
    'feature_flag_group': 'beta',
  },
)
```

## Custom Adapters

Create custom backend adapters by extending `BackendAdapter`:

```dart
class CustomAdapter extends BackendAdapter {
  @override
  String get name => 'CustomBackend';

  @override
  Future<void> initialize(BackendConfig config) async {
    // Initialize your backend
  }

  @override
  Future<void> trackEvent(AppEvent event) async {
    // Handle events
  }

  @override
  Future<void> captureError(AppError error) async {
    // Handle errors
  }

  @override
  Future<void> log(AppLog log) async {
    // Handle logs
  }

  @override
  Future<void> recordMetric(AppMetric metric) async {
    // Handle metrics
  }

  // ... other required methods
}
```

## Data Models

### AppEvent
- `name`: Event name
- `properties`: Event properties
- `timestamp`: When the event occurred
- `userId`: Associated user ID
- `sessionId`: Session identifier
- `deviceInfo`: Device information
- `context`: Additional context

### AppError
- `exception`: The exception object
- `stackTrace`: Stack trace
- `message`: Error message
- `severity`: Error severity level
- `breadcrumbs`: User actions leading to error
- `context`: Additional context

### AppLog
- `level`: Log level (trace, debug, info, warn, error, fatal)
- `message`: Log message
- `labels`: Structured labels
- `context`: Additional context

### AppMetric
- `name`: Metric name
- `value`: Numeric value
- `unit`: Unit of measurement
- `tags`: Metric tags
- `traceId`: Associated trace ID
- `spanId`: Associated span ID

## Offline Support

The package includes robust offline support:

- **Automatic Buffering**: Events are automatically buffered when offline
- **Intelligent Retry**: Exponential backoff with max retry limits
- **Persistent Storage**: Uses SQLite for durable offline storage
- **Manual Control**: Flush buffer manually or check buffer size

```dart
// Check buffer status
final bufferSize = await Observability.instance.getBufferSize();

// Manual flush
await Observability.instance.flushBuffer();
```

## Performance Considerations

- **Batching**: Events are batched for efficient transmission
- **Background Processing**: All operations are non-blocking
- **Memory Management**: Configurable buffer limits
- **Compression**: Optional gzip compression for network efficiency
- **Sampling**: Configurable sampling rates for high-volume applications

## Flutter Integration

### Error Handling

```dart
// Capture Flutter framework errors
FlutterError.onError = (FlutterErrorDetails details) {
  Observability.instance.captureError(
    details.exception,
    stackTrace: details.stack,
    context: {'library': details.library},
  );
};

// Capture platform errors
PlatformDispatcher.instance.onError = (error, stack) {
  Observability.instance.captureError(error, stackTrace: stack);
  return true;
};
```

### Navigation Tracking

```dart
class ObservabilityNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.settings.name != null) {
      Observability.instance.trackEvent('screen_view', properties: {
        'screen_name': route.settings.name!,
        'previous_screen': previousRoute?.settings.name,
      });
    }
  }
}
```

## Security & Privacy

- **PII Protection**: Automatic detection and scrubbing of personally identifiable information
- **Configurable Data Collection**: Granular control over what data is collected
- **Secure Transmission**: HTTPS-only communication with backends
- **Data Minimization**: Only collect what's necessary for observability

## Testing

The package includes comprehensive test utilities:

```dart
// Mock observability for testing
await Observability.instance.initialize(ObservabilityConfig(
  backendConfigs: [],
  enableDebugLogging: true,
));

// Register test adapter
await Observability.instance.registerAdapter(
  TestAdapter(),
  TestConfig(enabled: true),
);
```

## Troubleshooting

### Common Issues

1. **Events not appearing in Loki**: Check Loki URL and label configuration
2. **High memory usage**: Reduce buffer size or increase flush frequency
3. **PII still visible**: Review and update PII patterns
4. **Offline events not replaying**: Check network connectivity and retry configuration

### Debug Mode

Enable debug logging to troubleshoot issues:

```dart
ObservabilityConfig(
  enableDebugLogging: true,
  // ... other config
)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

### 1.0.0
- Initial release
- Loki adapter for structured logging
- Faro adapter for RUM and metrics
- Privacy controls and PII scrubbing
- Offline buffering and retry logic
- Comprehensive documentation and examples
