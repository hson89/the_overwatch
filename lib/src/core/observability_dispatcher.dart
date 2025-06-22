import 'dart:async';
import '../models/models.dart';
import '../core/core.dart';

/// Central dispatcher for managing multiple observability backends
class ObservabilityDispatcher {
  ObservabilityDispatcher._();
  
  static final ObservabilityDispatcher _instance = ObservabilityDispatcher._();
  static ObservabilityDispatcher get instance => _instance;

  final List<BackendAdapter> _adapters = [];
  ObservabilityConfig? _config;
  PrivacyUtils? _privacyUtils;
  OfflineBuffer? _offlineBuffer;
  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentSessionId;
  Map<String, dynamic> _globalContext = {};

  /// Initialize the dispatcher with configuration
  Future<void> initialize(ObservabilityConfig config) async {
    if (_isInitialized) {
      throw StateError('ObservabilityDispatcher is already initialized');
    }

    _config = config;
    _privacyUtils = PrivacyUtils(config.privacy);
    _currentUserId = config.globalUserId;
    _currentSessionId = config.globalSessionId;
    _globalContext = Map.from(config.globalContext);

    // Initialize offline buffer if enabled
    if (config.enableOfflineBuffer) {
      final storage = SqliteBufferStorage();
      _offlineBuffer = OfflineBuffer(
        storage: storage,
        maxBufferSize: config.maxBufferSize,
        flushInterval: config.flushInterval,
        onFlush: _flushBufferedEvent,
      );
      await _offlineBuffer!.initialize();
    }

    // Initialize backend adapters
    await _initializeAdapters(config.backendConfigs);

    _isInitialized = true;
  }

  /// Track a custom event
  Future<void> trackEvent(AppEvent event) async {
    if (!_isInitialized) {
      throw StateError('ObservabilityDispatcher not initialized');
    }

    if (!_privacyUtils!.analyticsEnabled) return;

    final enrichedEvent = await _enrichEvent(event);
    final scrubbedEvent = _scrubEvent(enrichedEvent);

    await _processEvent(scrubbedEvent, (adapter) async {
      if (adapter.supportsEvent(scrubbedEvent)) {
        await adapter.trackEvent(scrubbedEvent);
      }
    });
  }

  /// Capture an error
  Future<void> captureError(AppError error) async {
    if (!_isInitialized) {
      throw StateError('ObservabilityDispatcher not initialized');
    }

    if (!_privacyUtils!.errorReportingEnabled) return;

    final enrichedError = await _enrichError(error);
    final scrubbedError = _scrubError(enrichedError);

    await _processEvent(scrubbedError, (adapter) async {
      if (adapter.supportsError(scrubbedError)) {
        await adapter.captureError(scrubbedError);
      }
    });
  }

  /// Log a message
  Future<void> log(AppLog log) async {
    if (!_isInitialized) {
      throw StateError('ObservabilityDispatcher not initialized');
    }

    if (!_privacyUtils!.loggingEnabled) return;

    final enrichedLog = await _enrichLog(log);
    final scrubbedLog = _scrubLog(enrichedLog);

    await _processEvent(scrubbedLog, (adapter) async {
      if (adapter.supportsLog(scrubbedLog)) {
        await adapter.log(scrubbedLog);
      }
    });
  }

  /// Record a metric
  Future<void> recordMetric(AppMetric metric) async {
    if (!_isInitialized) {
      throw StateError('ObservabilityDispatcher not initialized');
    }

    if (!_privacyUtils!.performanceMonitoringEnabled) return;

    final enrichedMetric = await _enrichMetric(metric);
    final scrubbedMetric = _scrubMetric(enrichedMetric);

    await _processEvent(scrubbedMetric, (adapter) async {
      if (adapter.supportsMetric(scrubbedMetric)) {
        await adapter.recordMetric(scrubbedMetric);
      }
    });
  }

  /// Set the current user ID
  Future<void> setUserId(String? userId) async {
    _currentUserId = userId;

    if (_isInitialized) {
      await _processAdapters((adapter) async {
        await adapter.setUserId(userId);
      });
    }
  }

  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_isInitialized) return;

    final scrubbedProperties = _privacyUtils!.scrubMap(properties);

    await _processAdapters((adapter) async {
      await adapter.setUserProperties(scrubbedProperties);
    });
  }

  /// Set global context that will be added to all events
  void setGlobalContext(Map<String, dynamic> context) {
    _globalContext = Map.from(context);
  }

  /// Add to global context
  void addGlobalContext(String key, dynamic value) {
    _globalContext[key] = value;
  }

  /// Remove from global context
  void removeGlobalContext(String key) {
    _globalContext.remove(key);
  }

  /// Get current buffer size (if offline buffer is enabled)
  Future<int?> getBufferSize() async {
    return await _offlineBuffer?.getBufferSize();
  }

  /// Manually flush offline buffer
  Future<void> flushBuffer() async {
    await _offlineBuffer?.flush();
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    await _offlineBuffer?.dispose();
    
    await _processAdapters((adapter) async {
      await adapter.dispose();
    });
    
    _adapters.clear();
    _isInitialized = false;
  }

  /// Register a backend adapter
  Future<void> registerAdapter(BackendAdapter adapter, BackendConfig config) async {
    if (!config.enabled) return;
    
    try {
      await adapter.initialize(config);
      _adapters.add(adapter);
      
      // Set current user info if available
      if (_currentUserId != null) {
        await adapter.setUserId(_currentUserId);
      }
    } catch (e) {
      if (_config?.enableDebugLogging == true) {
        print('Failed to register adapter ${adapter.name}: $e');
      }
      rethrow;
    }
  }

  /// Unregister a backend adapter
  Future<void> unregisterAdapter(BackendAdapter adapter) async {
    try {
      await adapter.dispose();
      _adapters.remove(adapter);
    } catch (e) {
      if (_config?.enableDebugLogging == true) {
        print('Failed to unregister adapter ${adapter.name}: $e');
      }
    }
  }

  // Private helper methods
  Future<void> _initializeAdapters(List<BackendConfig> configs) async {
    // TODO: Create adapters based on config type
    // This would be done through a factory pattern or registration system
    // For now, adapters will be registered separately via registerAdapter method
  }

  Future<AppEvent> _enrichEvent(AppEvent event) async {
    final deviceInfo = await DeviceInfoUtils.getDeviceInfoMap();
    
    return event.copyWith(
      userId: event.userId ?? _currentUserId,
      sessionId: event.sessionId ?? _currentSessionId,
      deviceInfo: {...?event.deviceInfo, ...deviceInfo},
      context: {..._globalContext, ...event.context},
    );
  }

  Future<AppError> _enrichError(AppError error) async {
    final deviceInfo = await DeviceInfoUtils.getDeviceInfoMap();
    
    return error.copyWith(
      userId: error.userId ?? _currentUserId,
      sessionId: error.sessionId ?? _currentSessionId,
      deviceInfo: {...?error.deviceInfo, ...deviceInfo},
      context: {..._globalContext, ...error.context},
    );
  }

  Future<AppLog> _enrichLog(AppLog log) async {
    final deviceInfo = await DeviceInfoUtils.getDeviceInfoMap();
    
    return log.copyWith(
      userId: log.userId ?? _currentUserId,
      sessionId: log.sessionId ?? _currentSessionId,
      deviceInfo: {...?log.deviceInfo, ...deviceInfo},
      context: {..._globalContext, ...log.context},
    );
  }

  Future<AppMetric> _enrichMetric(AppMetric metric) async {
    final deviceInfo = await DeviceInfoUtils.getDeviceInfoMap();
    
    return metric.copyWith(
      userId: metric.userId ?? _currentUserId,
      sessionId: metric.sessionId ?? _currentSessionId,
      deviceInfo: {...?metric.deviceInfo, ...deviceInfo},
    );
  }

  AppEvent _scrubEvent(AppEvent event) {
    return event.copyWith(
      properties: _privacyUtils!.scrubMap(event.properties),
      context: _privacyUtils!.scrubMap(event.context),
      deviceInfo: event.deviceInfo != null 
          ? _privacyUtils!.scrubMap(event.deviceInfo!)
          : null,
    );
  }

  AppError _scrubError(AppError error) {
    return error.copyWith(
      message: error.message != null 
          ? _privacyUtils!.scrubString(error.message!)
          : null,
      context: _privacyUtils!.scrubMap(error.context),
      deviceInfo: error.deviceInfo != null 
          ? _privacyUtils!.scrubMap(error.deviceInfo!)
          : null,
    );
  }

  AppLog _scrubLog(AppLog log) {
    return log.copyWith(
      message: _privacyUtils!.scrubString(log.message),
      context: _privacyUtils!.scrubMap(log.context),
      deviceInfo: log.deviceInfo != null 
          ? _privacyUtils!.scrubMap(log.deviceInfo!)
          : null,
    );
  }

  AppMetric _scrubMetric(AppMetric metric) {
    return metric.copyWith(
      deviceInfo: metric.deviceInfo != null 
          ? _privacyUtils!.scrubMap(metric.deviceInfo!)
          : null,
    );
  }

  Future<void> _processEvent<T>(
    T event,
    Future<void> Function(BackendAdapter adapter) processor,
  ) async {
    // Try to send to adapters immediately
    final futures = _adapters.map((adapter) async {
      try {
        await processor(adapter);
      } catch (e) {
        if (_config!.enableDebugLogging) {
          print('Failed to process event with adapter ${adapter.name}: $e');
        }
        
        // Add to offline buffer if available
        if (_offlineBuffer != null) {
          if (event is AppEvent) {
            await _offlineBuffer!.addEvent(event);
          } else if (event is AppError) {
            await _offlineBuffer!.addError(event);
          } else if (event is AppLog) {
            await _offlineBuffer!.addLog(event);
          } else if (event is AppMetric) {
            await _offlineBuffer!.addMetric(event);
          }
        }
      }
    });

    await Future.wait(futures);
  }

  Future<void> _processAdapters(
    Future<void> Function(BackendAdapter adapter) processor,
  ) async {
    final futures = _adapters.map((adapter) async {
      try {
        await processor(adapter);
      } catch (e) {
        if (_config!.enableDebugLogging) {
          print('Failed to process with adapter ${adapter.name}: $e');
        }
      }
    });

    await Future.wait(futures);
  }

  Future<bool> _flushBufferedEvent(BufferedEvent bufferedEvent) async {
    bool success = false;
    
    for (final adapter in _adapters) {
      try {
        switch (bufferedEvent.type) {
          case BufferedEventType.event:
            final event = AppEvent(
              name: bufferedEvent.data['name'],
              properties: bufferedEvent.data['properties'] ?? {},
              timestamp: DateTime.parse(bufferedEvent.data['timestamp']),
              userId: bufferedEvent.data['userId'],
              sessionId: bufferedEvent.data['sessionId'],
              deviceInfo: bufferedEvent.data['deviceInfo'],
              context: bufferedEvent.data['context'] ?? {},
            );
            if (adapter.supportsEvent(event)) {
              await adapter.trackEvent(event);
              success = true;
            }
            break;
            
          case BufferedEventType.error:
            final error = AppError(
              exception: bufferedEvent.data['exception'] ?? 'Unknown error',
              message: bufferedEvent.data['message'],
              timestamp: DateTime.parse(bufferedEvent.data['timestamp']),
              userId: bufferedEvent.data['userId'],
              sessionId: bufferedEvent.data['sessionId'],
              deviceInfo: bufferedEvent.data['deviceInfo'],
              context: bufferedEvent.data['context'] ?? {},
            );
            if (adapter.supportsError(error)) {
              await adapter.captureError(error);
              success = true;
            }
            break;
            
          case BufferedEventType.log:
            final log = AppLog(
              level: LogLevel.values.firstWhere(
                (l) => l.toString() == bufferedEvent.data['level'],
                orElse: () => LogLevel.info,
              ),
              message: bufferedEvent.data['message'],
              timestamp: DateTime.parse(bufferedEvent.data['timestamp']),
              labels: Map<String, String>.from(bufferedEvent.data['labels'] ?? {}),
              context: bufferedEvent.data['context'] ?? {},
              userId: bufferedEvent.data['userId'],
              sessionId: bufferedEvent.data['sessionId'],
              deviceInfo: bufferedEvent.data['deviceInfo'],
            );
            if (adapter.supportsLog(log)) {
              await adapter.log(log);
              success = true;
            }
            break;
            
          case BufferedEventType.metric:
            final metric = AppMetric(
              name: bufferedEvent.data['name'],
              value: (bufferedEvent.data['value'] as num).toDouble(),
              unit: bufferedEvent.data['unit'],
              tags: Map<String, String>.from(bufferedEvent.data['tags'] ?? {}),
              timestamp: DateTime.parse(bufferedEvent.data['timestamp']),
              userId: bufferedEvent.data['userId'],
              sessionId: bufferedEvent.data['sessionId'],
              deviceInfo: bufferedEvent.data['deviceInfo'],
              traceId: bufferedEvent.data['traceId'],
              spanId: bufferedEvent.data['spanId'],
            );
            if (adapter.supportsMetric(metric)) {
              await adapter.recordMetric(metric);
              success = true;
            }
            break;
        }
      } catch (e) {
        if (_config!.enableDebugLogging) {
          print('Failed to flush buffered event with adapter ${adapter.name}: $e');
        }
      }
    }
    
    return success;
  }
}
