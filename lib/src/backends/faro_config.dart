import '../core/core.dart';

/// Configuration for Grafana Faro Real User Monitoring
class FaroConfig extends BackendConfig {
  const FaroConfig({
    required super.enabled,
    required this.appName,
    required this.appVersion,
    required this.collectorUrl,
    this.apiKey,
    this.environment,
    this.enableConsoleInstrumentation = true,
    this.enableWebVitalsInstrumentation = true,
    this.enableErrorInstrumentation = true,
    this.enableUserInteractionInstrumentation = true,
    this.sessionSampleRate = 1.0,
    this.traceSampleRate = 1.0,
    this.globalAttributes = const {},
  });

  /// Application name for Faro
  final String appName;
  
  /// Application version for Faro
  final String appVersion;
  
  /// Faro collector URL
  final String collectorUrl;
  
  /// Optional API key for authentication
  final String? apiKey;
  
  /// Environment name (e.g., 'development', 'staging', 'production')
  final String? environment;
  
  /// Whether to enable console log instrumentation
  final bool enableConsoleInstrumentation;
  
  /// Whether to enable web vitals instrumentation
  final bool enableWebVitalsInstrumentation;
  
  /// Whether to enable error instrumentation
  final bool enableErrorInstrumentation;
  
  /// Whether to enable user interaction instrumentation
  final bool enableUserInteractionInstrumentation;
  
  /// Session sampling rate (0.0 to 1.0)
  final double sessionSampleRate;
  
  /// Trace sampling rate (0.0 to 1.0)
  final double traceSampleRate;
  
  /// Global attributes to attach to all telemetry
  final Map<String, String> globalAttributes;

  @override
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'appName': appName,
        'appVersion': appVersion,
        'collectorUrl': collectorUrl,
        'apiKey': apiKey,
        'environment': environment,
        'enableConsoleInstrumentation': enableConsoleInstrumentation,
        'enableWebVitalsInstrumentation': enableWebVitalsInstrumentation,
        'enableErrorInstrumentation': enableErrorInstrumentation,
        'enableUserInteractionInstrumentation': enableUserInteractionInstrumentation,
        'sessionSampleRate': sessionSampleRate,
        'traceSampleRate': traceSampleRate,
        'globalAttributes': globalAttributes,
      };

  FaroConfig copyWith({
    bool? enabled,
    String? appName,
    String? appVersion,
    String? collectorUrl,
    String? apiKey,
    String? environment,
    bool? enableConsoleInstrumentation,
    bool? enableWebVitalsInstrumentation,
    bool? enableErrorInstrumentation,
    bool? enableUserInteractionInstrumentation,
    double? sessionSampleRate,
    double? traceSampleRate,
    Map<String, String>? globalAttributes,
  }) {
    return FaroConfig(
      enabled: enabled ?? this.enabled,
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      collectorUrl: collectorUrl ?? this.collectorUrl,
      apiKey: apiKey ?? this.apiKey,
      environment: environment ?? this.environment,
      enableConsoleInstrumentation: enableConsoleInstrumentation ?? this.enableConsoleInstrumentation,
      enableWebVitalsInstrumentation: enableWebVitalsInstrumentation ?? this.enableWebVitalsInstrumentation,
      enableErrorInstrumentation: enableErrorInstrumentation ?? this.enableErrorInstrumentation,
      enableUserInteractionInstrumentation: enableUserInteractionInstrumentation ?? this.enableUserInteractionInstrumentation,
      sessionSampleRate: sessionSampleRate ?? this.sessionSampleRate,
      traceSampleRate: traceSampleRate ?? this.traceSampleRate,
      globalAttributes: globalAttributes ?? this.globalAttributes,
    );
  }
}
