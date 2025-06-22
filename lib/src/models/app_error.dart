/// Severity levels for application errors
enum ErrorSeverity {
  low,
  medium,
  high,
  critical;

  @override
  String toString() => name;
}

/// Breadcrumb for tracking user actions leading to an error
class Breadcrumb {
  const Breadcrumb({
    required this.message,
    required this.timestamp,
    this.category,
    this.level,
    this.data,
  });

  final String message;
  final DateTime timestamp;
  final String? category;
  final String? level;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toJson() => {
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'category': category,
        'level': level,
        'data': data,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Breadcrumb &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          timestamp == other.timestamp &&
          category == other.category &&
          level == other.level &&
          _mapEquals(data, other.data);

  @override
  int get hashCode =>
      message.hashCode ^
      timestamp.hashCode ^
      category.hashCode ^
      level.hashCode ^
      data.hashCode;

  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Application error for exception tracking and error monitoring
class AppError {
  const AppError({
    required this.exception,
    this.stackTrace,
    this.type,
    this.message,
    this.severity = ErrorSeverity.medium,
    required this.timestamp,
    this.userId,
    this.sessionId,
    this.deviceInfo,
    this.breadcrumbs = const [],
    this.context = const {},
  });

  final Object exception;
  final StackTrace? stackTrace;
  final String? type;
  final String? message;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;
  final Map<String, dynamic>? deviceInfo;
  final List<Breadcrumb> breadcrumbs;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => {
        'exception': exception.toString(),
        'stackTrace': stackTrace?.toString(),
        'type': type,
        'message': message,
        'severity': severity.toString(),
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'sessionId': sessionId,
        'deviceInfo': deviceInfo,
        'breadcrumbs': breadcrumbs.map((b) => b.toJson()).toList(),
        'context': context,
      };

  AppError copyWith({
    Object? exception,
    StackTrace? stackTrace,
    String? type,
    String? message,
    ErrorSeverity? severity,
    DateTime? timestamp,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? deviceInfo,
    List<Breadcrumb>? breadcrumbs,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      exception: exception ?? this.exception,
      stackTrace: stackTrace ?? this.stackTrace,
      type: type ?? this.type,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      context: context ?? this.context,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppError &&
          runtimeType == other.runtimeType &&
          exception == other.exception &&
          stackTrace == other.stackTrace &&
          type == other.type &&
          message == other.message &&
          severity == other.severity &&
          timestamp == other.timestamp &&
          userId == other.userId &&
          sessionId == other.sessionId &&
          _mapEquals(deviceInfo, other.deviceInfo) &&
          _listEquals(breadcrumbs, other.breadcrumbs) &&
          _mapEquals(context, other.context);

  @override
  int get hashCode =>
      exception.hashCode ^
      stackTrace.hashCode ^
      type.hashCode ^
      message.hashCode ^
      severity.hashCode ^
      timestamp.hashCode ^
      userId.hashCode ^
      sessionId.hashCode ^
      deviceInfo.hashCode ^
      breadcrumbs.hashCode ^
      context.hashCode;

  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
