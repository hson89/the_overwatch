import 'dart:async';
import 'dart:convert';
import '../core/core.dart';
import '../models/models.dart';
import 'loki_config.dart';

/// Loki backend adapter for structured logging
/// This adapter sends logs to a Loki instance for centralized log aggregation
class LokiAdapter extends BackendAdapter {
  LokiAdapter();

  LokiConfig? _config;
  Timer? _flushTimer;
  final List<Map<String, dynamic>> _logBuffer = [];
  bool _isEnabled = false;

  @override
  String get name => 'Loki';

  @override
  bool get isEnabled => _isEnabled;

  @override
  Future<void> initialize(BackendConfig config) async {
    if (config is! LokiConfig) {
      throw ArgumentError('LokiAdapter requires LokiConfig');
    }

    _config = config;
    _isEnabled = config.enabled;

    if (!_isEnabled) return;

    // Start periodic flush timer
    _flushTimer = Timer.periodic(_config!.flushInterval, (_) {
      _flushLogs();
    });

    print('LokiAdapter initialized with host: ${_config!.host}');
  }

  @override
  Future<void> trackEvent(AppEvent event) async {
    // Loki adapter only handles logs, not events
    // Events could be converted to logs if needed
  }

  @override
  Future<void> captureError(AppError error) async {
    // Convert error to log entry
    await log(AppLog(
      level: LogLevel.error,
      message: 'Error: ${error.message ?? error.exception.toString()}',
      timestamp: error.timestamp,
      labels: {
        'level': 'error',
        'severity': error.severity.toString(),
        if (error.type != null) 'error_type': error.type!,
      },
      context: {
        ...error.context,
        'exception': error.exception.toString(),
        if (error.stackTrace != null) 'stackTrace': error.stackTrace.toString(),
        'breadcrumbs': error.breadcrumbs.map((b) => b.toJson()).toList(),
      },
      userId: error.userId,
      sessionId: error.sessionId,
      deviceInfo: error.deviceInfo,
    ));
  }

  @override
  Future<void> log(AppLog log) async {
    if (!_isEnabled || _config == null) return;

    // Prepare log entry in Loki format
    final labels = <String, String>{
      ..._config!.globalLabels,
      ...log.labels,
      'level': log.level.toString(),
      if (log.userId != null) 'user_id': log.userId!,
      if (log.sessionId != null) 'session_id': log.sessionId!,
    };

    final logEntry = {
      'timestamp': (log.timestamp.millisecondsSinceEpoch * 1000000).toString(), // Nanoseconds
      'line': jsonEncode({
        'message': log.message,
        'level': log.level.toString(),
        'timestamp': log.timestamp.toIso8601String(),
        'context': log.context,
        'deviceInfo': log.deviceInfo,
      }),
      'labels': labels,
    };

    _logBuffer.add(logEntry);

    // Flush if buffer is full
    if (_logBuffer.length >= _config!.batchSize) {
      await _flushLogs();
    }
  }

  @override
  Future<void> recordMetric(AppMetric metric) async {
    // Loki adapter only handles logs, not metrics
    // Metrics could be converted to logs if needed
  }

  @override
  Future<void> setUserId(String? userId) async {
    // User ID is handled per-log basis in Loki
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    // User properties are handled per-log basis in Loki
  }

  @override
  Future<void> dispose() async {
    _flushTimer?.cancel();
    await _flushLogs(); // Flush remaining logs
    _isEnabled = false;
  }

  @override
  bool supportsEvent(AppEvent event) => false; // Loki doesn't handle events directly

  @override
  bool supportsError(AppError error) => true; // Errors are converted to logs

  @override
  bool supportsLog(AppLog log) => true; // Primary purpose

  @override
  bool supportsMetric(AppMetric metric) => false; // Loki doesn't handle metrics directly

  /// Flush buffered logs to Loki
  Future<void> _flushLogs() async {
    if (_logBuffer.isEmpty || _config == null) return;

    final logsToSend = List<Map<String, dynamic>>.from(_logBuffer);
    _logBuffer.clear();

    try {
      await _sendLogsToLoki(logsToSend);
    } catch (e) {
      print('Failed to send logs to Loki: $e');
      // Re-add logs to buffer for retry (simple strategy)
      _logBuffer.addAll(logsToSend);
    }
  }

  /// Send logs to Loki HTTP API
  Future<void> _sendLogsToLoki(List<Map<String, dynamic>> logs) async {
    if (logs.isEmpty) return;

    // Group logs by labels for Loki streams format
    final streams = <String, List<Map<String, dynamic>>>{};
    
    for (final log in logs) {
      final labels = log['labels'] as Map<String, String>;
      final labelKey = _encodeLabels(labels);
      
      streams[labelKey] ??= [];
      streams[labelKey]!.add({
        'timestamp': log['timestamp'],
        'line': log['line'],
      });
    }

    // Prepare Loki push request
    final pushData = {
      'streams': streams.entries.map((entry) => {
        'stream': _decodeLabels(entry.key),
        'values': entry.value.map((log) => [log['timestamp'], log['line']]).toList(),
      }).toList(),
    };

    // TODO: Send HTTP request to Loki
    // This would use dio or http package to send POST request to ${_config!.host}/loki/api/v1/push
    // Example:
    // final response = await dio.post(
    //   '${_config!.host}/loki/api/v1/push',
    //   data: pushData,
    //   options: Options(
    //     headers: {'Content-Type': 'application/json'},
    //     sendTimeout: _config!.timeout,
    //     receiveTimeout: _config!.timeout,
    //   ),
    // );
    // 
    // if (response.statusCode != 204) {
    //   throw Exception('Loki returned status code: ${response.statusCode}');
    // }

    print('Would send ${logs.length} logs to Loki: ${_config!.host}');
    print('Payload: ${jsonEncode(pushData)}');
  }

  /// Encode labels map to string key for grouping
  String _encodeLabels(Map<String, String> labels) {
    final sortedEntries = labels.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sortedEntries.map((e) => '${e.key}="${e.value}"').join(',');
  }

  /// Decode labels string back to map
  Map<String, String> _decodeLabels(String labelString) {
    final labels = <String, String>{};
    final pairs = labelString.split(',');
    
    for (final pair in pairs) {
      final equalIndex = pair.indexOf('=');
      if (equalIndex > 0) {
        final key = pair.substring(0, equalIndex);
        final value = pair.substring(equalIndex + 1).replaceAll('"', '');
        labels[key] = value;
      }
    }
    
    return labels;
  }
}
