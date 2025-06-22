import '../core/core.dart';

/// Configuration for Loki logging backend
class LokiConfig extends BackendConfig {
  const LokiConfig({
    required super.enabled,
    required this.host,
    this.globalLabels = const {},
    this.batchSize = 100,
    this.flushInterval = const Duration(seconds: 30),
    this.timeout = const Duration(seconds: 10),
    this.enableCompression = true,
  });

  /// Loki server host URL (e.g., 'http://localhost:3100')
  final String host;
  
  /// Global labels to attach to all log entries
  final Map<String, String> globalLabels;
  
  /// Number of logs to batch before sending
  final int batchSize;
  
  /// How often to flush batched logs
  final Duration flushInterval;
  
  /// HTTP request timeout
  final Duration timeout;
  
  /// Whether to enable gzip compression
  final bool enableCompression;

  @override
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'host': host,
        'globalLabels': globalLabels,
        'batchSize': batchSize,
        'flushInterval': flushInterval.inMilliseconds,
        'timeout': timeout.inMilliseconds,
        'enableCompression': enableCompression,
      };

  LokiConfig copyWith({
    bool? enabled,
    String? host,
    Map<String, String>? globalLabels,
    int? batchSize,
    Duration? flushInterval,
    Duration? timeout,
    bool? enableCompression,
  }) {
    return LokiConfig(
      enabled: enabled ?? this.enabled,
      host: host ?? this.host,
      globalLabels: globalLabels ?? this.globalLabels,
      batchSize: batchSize ?? this.batchSize,
      flushInterval: flushInterval ?? this.flushInterval,
      timeout: timeout ?? this.timeout,
      enableCompression: enableCompression ?? this.enableCompression,
    );
  }
}
