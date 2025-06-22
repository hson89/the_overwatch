/// Abstract base class for backend-specific configuration
abstract class BackendConfig {
  const BackendConfig({required this.enabled});

  /// Whether this backend is enabled
  final bool enabled;

  /// Convert configuration to JSON
  Map<String, dynamic> toJson();
}

/// Configuration for data privacy settings
class PrivacyConfig {
  const PrivacyConfig({
    this.scrubPii = true,
    this.enableAnalytics = true,
    this.enableErrorReporting = true,
    this.enablePerformanceMonitoring = true,
    this.enableLogging = true,
    this.piiPatterns = const [],
  });

  /// Whether to automatically scrub PII from data
  final bool scrubPii;
  
  /// Whether to enable analytics tracking
  final bool enableAnalytics;
  
  /// Whether to enable error reporting
  final bool enableErrorReporting;
  
  /// Whether to enable performance monitoring
  final bool enablePerformanceMonitoring;
  
  /// Whether to enable logging
  final bool enableLogging;
  
  /// Custom regex patterns for PII detection
  final List<String> piiPatterns;

  Map<String, dynamic> toJson() => {
        'scrubPii': scrubPii,
        'enableAnalytics': enableAnalytics,
        'enableErrorReporting': enableErrorReporting,
        'enablePerformanceMonitoring': enablePerformanceMonitoring,
        'enableLogging': enableLogging,
        'piiPatterns': piiPatterns,
      };

  PrivacyConfig copyWith({
    bool? scrubPii,
    bool? enableAnalytics,
    bool? enableErrorReporting,
    bool? enablePerformanceMonitoring,
    bool? enableLogging,
    List<String>? piiPatterns,
  }) {
    return PrivacyConfig(
      scrubPii: scrubPii ?? this.scrubPii,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableErrorReporting: enableErrorReporting ?? this.enableErrorReporting,
      enablePerformanceMonitoring: enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      enableLogging: enableLogging ?? this.enableLogging,
      piiPatterns: piiPatterns ?? this.piiPatterns,
    );
  }
}

/// Main configuration for the observability package
class ObservabilityConfig {
  const ObservabilityConfig({
    required this.backendConfigs,
    this.privacy = const PrivacyConfig(),
    this.enableOfflineBuffer = true,
    this.maxBufferSize = 1000,
    this.flushInterval = const Duration(minutes: 1),
    this.enableDebugLogging = false,
    this.globalUserId,
    this.globalSessionId,
    this.globalContext = const {},
  });

  /// List of backend-specific configurations
  final List<BackendConfig> backendConfigs;
  
  /// Privacy and data handling configuration
  final PrivacyConfig privacy;
  
  /// Whether to enable offline buffering
  final bool enableOfflineBuffer;
  
  /// Maximum number of events to buffer offline
  final int maxBufferSize;
  
  /// How often to attempt flushing buffered data
  final Duration flushInterval;
  
  /// Whether to enable debug logging
  final bool enableDebugLogging;
  
  /// Global user ID to attach to all events
  final String? globalUserId;
  
  /// Global session ID to attach to all events
  final String? globalSessionId;
  
  /// Global context to attach to all events
  final Map<String, dynamic> globalContext;

  Map<String, dynamic> toJson() => {
        'backendConfigs': backendConfigs.map((c) => c.toJson()).toList(),
        'privacy': privacy.toJson(),
        'enableOfflineBuffer': enableOfflineBuffer,
        'maxBufferSize': maxBufferSize,
        'flushInterval': flushInterval.inMilliseconds,
        'enableDebugLogging': enableDebugLogging,
        'globalUserId': globalUserId,
        'globalSessionId': globalSessionId,
        'globalContext': globalContext,
      };

  ObservabilityConfig copyWith({
    List<BackendConfig>? backendConfigs,
    PrivacyConfig? privacy,
    bool? enableOfflineBuffer,
    int? maxBufferSize,
    Duration? flushInterval,
    bool? enableDebugLogging,
    String? globalUserId,
    String? globalSessionId,
    Map<String, dynamic>? globalContext,
  }) {
    return ObservabilityConfig(
      backendConfigs: backendConfigs ?? this.backendConfigs,
      privacy: privacy ?? this.privacy,
      enableOfflineBuffer: enableOfflineBuffer ?? this.enableOfflineBuffer,
      maxBufferSize: maxBufferSize ?? this.maxBufferSize,
      flushInterval: flushInterval ?? this.flushInterval,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      globalUserId: globalUserId ?? this.globalUserId,
      globalSessionId: globalSessionId ?? this.globalSessionId,
      globalContext: globalContext ?? this.globalContext,
    );
  }
}
