import 'observability_config.dart';

/// Utility class for handling data privacy and PII scrubbing
class PrivacyUtils {
  static const List<String> _defaultPiiPatterns = [
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', // Email addresses
    r'\b(?:\+?1[-.\s]?)?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b', // Phone numbers
    r'\b[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b', // Credit card numbers
    r'\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b', // SSN
    r'\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b', // IP addresses
  ];

  static const String _scrubReplacement = '[REDACTED]';

  final PrivacyConfig _config;
  final List<RegExp> _piiRegexes;

  PrivacyUtils(this._config)
      : _piiRegexes = [
          ..._defaultPiiPatterns.map((pattern) => RegExp(pattern)),
          ..._config.piiPatterns.map((pattern) => RegExp(pattern)),
        ];

  /// Scrub PII from a string value
  String scrubString(String input) {
    if (!_config.scrubPii) return input;
    
    String result = input;
    for (final regex in _piiRegexes) {
      result = result.replaceAll(regex, _scrubReplacement);
    }
    return result;
  }

  /// Scrub PII from a map of data
  Map<String, dynamic> scrubMap(Map<String, dynamic> data) {
    if (!_config.scrubPii) return data;
    
    final Map<String, dynamic> scrubbed = {};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String) {
        scrubbed[key] = scrubString(value);
      } else if (value is Map<String, dynamic>) {
        scrubbed[key] = scrubMap(value);
      } else if (value is List) {
        scrubbed[key] = scrubList(value);
      } else {
        scrubbed[key] = value;
      }
    }
    
    return scrubbed;
  }

  /// Scrub PII from a list of data
  List<dynamic> scrubList(List<dynamic> data) {
    if (!_config.scrubPii) return data;
    
    return data.map((item) {
      if (item is String) {
        return scrubString(item);
      } else if (item is Map<String, dynamic>) {
        return scrubMap(item);
      } else if (item is List) {
        return scrubList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Check if analytics tracking is enabled
  bool get analyticsEnabled => _config.enableAnalytics;

  /// Check if error reporting is enabled
  bool get errorReportingEnabled => _config.enableErrorReporting;

  /// Check if performance monitoring is enabled
  bool get performanceMonitoringEnabled => _config.enablePerformanceMonitoring;

  /// Check if logging is enabled
  bool get loggingEnabled => _config.enableLogging;
}
