/// Log levels for application logs
enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error,
  fatal;

  @override
  String toString() => name;

  /// Convert to numeric value for comparison
  int get value => index;
}

/// Application log for structured logging
class AppLog {
  const AppLog({
    required this.level,
    required this.message,
    required this.timestamp,
    this.labels = const {},
    this.context = const {},
    this.userId,
    this.sessionId,
    this.deviceInfo,
  });

  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Map<String, String> labels;
  final Map<String, dynamic> context;
  final String? userId;
  final String? sessionId;
  final Map<String, dynamic>? deviceInfo;

  Map<String, dynamic> toJson() => {
        'level': level.toString(),
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'labels': labels,
        'context': context,
        'userId': userId,
        'sessionId': sessionId,
        'deviceInfo': deviceInfo,
      };

  AppLog copyWith({
    LogLevel? level,
    String? message,
    DateTime? timestamp,
    Map<String, String>? labels,
    Map<String, dynamic>? context,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? deviceInfo,
  }) {
    return AppLog(
      level: level ?? this.level,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      labels: labels ?? this.labels,
      context: context ?? this.context,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLog &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          message == other.message &&
          timestamp == other.timestamp &&
          _mapEquals(labels, other.labels) &&
          _mapEquals(context, other.context) &&
          userId == other.userId &&
          sessionId == other.sessionId &&
          _mapEquals(deviceInfo, other.deviceInfo);

  @override
  int get hashCode =>
      level.hashCode ^
      message.hashCode ^
      timestamp.hashCode ^
      labels.hashCode ^
      context.hashCode ^
      userId.hashCode ^
      sessionId.hashCode ^
      deviceInfo.hashCode;

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
