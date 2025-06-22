import 'package:test/test.dart';
import 'package:the_overwatch/the_overwatch.dart';

void main() {
  group('Flutter Observability Package', () {
    test('should initialize with basic configuration', () async {
      final config = ObservabilityConfig(
        backendConfigs: [],
        enableDebugLogging: true,
      );

      expect(config.enableDebugLogging, isTrue);
      expect(config.backendConfigs, isEmpty);
      expect(config.privacy.scrubPii, isTrue); // Default value
    });

    test('should create data models correctly', () {
      final event = AppEvent(
        name: 'test_event',
        properties: {'key': 'value'},
        timestamp: DateTime.now(),
      );

      expect(event.name, equals('test_event'));
      expect(event.properties['key'], equals('value'));
      expect(event.toJson(), isA<Map<String, dynamic>>());
    });

    test('should create error with severity', () {
      final error = AppError(
        exception: Exception('Test error'),
        severity: ErrorSeverity.high,
        timestamp: DateTime.now(),
      );

      expect(error.exception.toString(), contains('Test error'));
      expect(error.severity, equals(ErrorSeverity.high));
      expect(error.toJson(), isA<Map<String, dynamic>>());
    });

    test('should create log with level', () {
      final log = AppLog(
        level: LogLevel.info,
        message: 'Test log message',
        timestamp: DateTime.now(),
      );

      expect(log.level, equals(LogLevel.info));
      expect(log.message, equals('Test log message'));
      expect(log.toJson(), isA<Map<String, dynamic>>());
    });

    test('should create metric with value', () {
      final metric = AppMetric(
        name: 'test_metric',
        value: 123.45,
        unit: 'ms',
        timestamp: DateTime.now(),
      );

      expect(metric.name, equals('test_metric'));
      expect(metric.value, equals(123.45));
      expect(metric.unit, equals('ms'));
      expect(metric.toJson(), isA<Map<String, dynamic>>());
    });

    test('should handle privacy configuration', () {
      final privacyConfig = PrivacyConfig(
        scrubPii: false,
        enableAnalytics: false,
        piiPatterns: ['custom-pattern'],
      );

      expect(privacyConfig.scrubPii, isFalse);
      expect(privacyConfig.enableAnalytics, isFalse);
      expect(privacyConfig.piiPatterns, contains('custom-pattern'));
    });

    test('should create Loki configuration', () {
      final lokiConfig = LokiConfig(
        enabled: true,
        host: 'http://localhost:3100',
        globalLabels: {'app': 'test'},
      );

      expect(lokiConfig.enabled, isTrue);
      expect(lokiConfig.host, equals('http://localhost:3100'));
      expect(lokiConfig.globalLabels['app'], equals('test'));
    });

    test('should create Faro configuration', () {
      final faroConfig = FaroConfig(
        enabled: true,
        appName: 'Test App',
        appVersion: '1.0.0',
        collectorUrl: 'https://faro.example.com',
      );

      expect(faroConfig.enabled, isTrue);
      expect(faroConfig.appName, equals('Test App'));
      expect(faroConfig.appVersion, equals('1.0.0'));
      expect(faroConfig.collectorUrl, equals('https://faro.example.com'));
    });

    test('should handle PII scrubbing', () {
      final privacyConfig = PrivacyConfig(scrubPii: true);
      final privacyUtils = PrivacyUtils(privacyConfig);

      final testString = 'Contact me at user@example.com or call 555-123-4567';
      final scrubbedString = privacyUtils.scrubString(testString);

      expect(scrubbedString, isNot(contains('user@example.com')));
      expect(scrubbedString, isNot(contains('555-123-4567')));
      expect(scrubbedString, contains('[REDACTED]'));
    });

    test('should create backend adapters', () {
      final lokiAdapter = LokiAdapter();
      final faroAdapter = FaroAdapter();

      expect(lokiAdapter.name, equals('Loki'));
      expect(faroAdapter.name, equals('Faro'));
      expect(lokiAdapter.isEnabled, isFalse); // Not initialized yet
      expect(faroAdapter.isEnabled, isFalse); // Not initialized yet
    });

    test('should support adapter capabilities', () {
      final lokiAdapter = LokiAdapter();
      final faroAdapter = FaroAdapter();

      final event = AppEvent(name: 'test', timestamp: DateTime.now());
      final error = AppError(exception: 'test', timestamp: DateTime.now());
      final log = AppLog(level: LogLevel.info, message: 'test', timestamp: DateTime.now());
      final metric = AppMetric(name: 'test', value: 1.0, timestamp: DateTime.now());

      // Loki primarily supports logs and errors (converted to logs)
      expect(lokiAdapter.supportsEvent(event), isFalse);
      expect(lokiAdapter.supportsError(error), isTrue);
      expect(lokiAdapter.supportsLog(log), isTrue);
      expect(lokiAdapter.supportsMetric(metric), isFalse);

      // Faro supports all data types
      expect(faroAdapter.supportsEvent(event), isTrue);
      expect(faroAdapter.supportsError(error), isTrue);
      expect(faroAdapter.supportsLog(log), isTrue);
      expect(faroAdapter.supportsMetric(metric), isTrue);
    });
  });

  group('Privacy Utils', () {
    test('should scrub email addresses', () {
      final privacyUtils = PrivacyUtils(PrivacyConfig(scrubPii: true));
      final input = 'Contact support at support@company.com for help';
      final result = privacyUtils.scrubString(input);
      
      expect(result, isNot(contains('support@company.com')));
      expect(result, contains('[REDACTED]'));
    });

    test('should scrub phone numbers', () {
      final privacyUtils = PrivacyUtils(PrivacyConfig(scrubPii: true));
      final input = 'Call us at 555-123-4567 or (555) 987-6543';
      final result = privacyUtils.scrubString(input);
      
      expect(result, isNot(contains('555-123-4567')));
      expect(result, isNot(contains('(555) 987-6543')));
    });

    test('should scrub custom patterns', () {
      final privacyUtils = PrivacyUtils(PrivacyConfig(
        scrubPii: true,
        piiPatterns: [r'SECRET-\d+'],
      ));
      final input = 'The secret code is SECRET-12345';
      final result = privacyUtils.scrubString(input);
      
      expect(result, isNot(contains('SECRET-12345')));
      expect(result, contains('[REDACTED]'));
    });

    test('should handle nested maps', () {
      final privacyUtils = PrivacyUtils(PrivacyConfig(scrubPii: true));
      final input = {
        'user': {
          'email': 'user@example.com',
          'name': 'John Doe',
        },
        'metadata': {
          'phone': '555-123-4567',
        }
      };
      
      final result = privacyUtils.scrubMap(input);
      final userEmail = result['user']?['email'] as String?;
      final phone = result['metadata']?['phone'] as String?;
      
      expect(userEmail, isNot(contains('user@example.com')));
      expect(phone, isNot(contains('555-123-4567')));
      expect(result['user']?['name'], equals('John Doe')); // Non-PII should remain
    });

    test('should respect privacy settings', () {
      final permissiveConfig = PrivacyConfig(
        enableAnalytics: true,
        enableErrorReporting: true,
        enableLogging: true,
      );
      final restrictiveConfig = PrivacyConfig(
        enableAnalytics: false,
        enableErrorReporting: false,
        enableLogging: false,
      );

      final permissiveUtils = PrivacyUtils(permissiveConfig);
      final restrictiveUtils = PrivacyUtils(restrictiveConfig);

      expect(permissiveUtils.analyticsEnabled, isTrue);
      expect(permissiveUtils.errorReportingEnabled, isTrue);
      expect(permissiveUtils.loggingEnabled, isTrue);

      expect(restrictiveUtils.analyticsEnabled, isFalse);
      expect(restrictiveUtils.errorReportingEnabled, isFalse);
      expect(restrictiveUtils.loggingEnabled, isFalse);
    });
  });

  group('Offline Buffer', () {
    test('should create buffered events correctly', () {
      final event = BufferedEvent(
        id: 'test-123',
        type: BufferedEventType.event,
        data: {'test': 'data'},
        timestamp: DateTime.now(),
      );

      expect(event.id, equals('test-123'));
      expect(event.type, equals(BufferedEventType.event));
      expect(event.data['test'], equals('data'));
      expect(event.retryCount, equals(0));
    });

    test('should serialize buffered events', () {
      final event = BufferedEvent(
        id: 'test-456',
        type: BufferedEventType.log,
        data: {'message': 'test log'},
        timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
        retryCount: 2,
      );

      final json = event.toJson();
      expect(json['id'], equals('test-456'));
      expect(json['type'], equals('log'));
      expect(json['retryCount'], equals(2));

      final restored = BufferedEvent.fromJson(json);
      expect(restored.id, equals(event.id));
      expect(restored.type, equals(event.type));
      expect(restored.retryCount, equals(event.retryCount));
    });
  });
}
