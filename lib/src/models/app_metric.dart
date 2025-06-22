/// Application metric for performance monitoring and custom metrics
class AppMetric {
  const AppMetric({
    required this.name,
    required this.value,
    this.unit,
    this.tags = const {},
    required this.timestamp,
    this.userId,
    this.sessionId,
    this.deviceInfo,
    this.traceId,
    this.spanId,
  });

  final String name;
  final double value;
  final String? unit;
  final Map<String, String> tags;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;
  final Map<String, dynamic>? deviceInfo;
  final String? traceId;
  final String? spanId;

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'unit': unit,
        'tags': tags,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'sessionId': sessionId,
        'deviceInfo': deviceInfo,
        'traceId': traceId,
        'spanId': spanId,
      };

  AppMetric copyWith({
    String? name,
    double? value,
    String? unit,
    Map<String, String>? tags,
    DateTime? timestamp,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? deviceInfo,
    String? traceId,
    String? spanId,
  }) {
    return AppMetric(
      name: name ?? this.name,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      traceId: traceId ?? this.traceId,
      spanId: spanId ?? this.spanId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppMetric &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          value == other.value &&
          unit == other.unit &&
          _mapEquals(tags, other.tags) &&
          timestamp == other.timestamp &&
          userId == other.userId &&
          sessionId == other.sessionId &&
          _mapEquals(deviceInfo, other.deviceInfo) &&
          traceId == other.traceId &&
          spanId == other.spanId;

  @override
  int get hashCode =>
      name.hashCode ^
      value.hashCode ^
      unit.hashCode ^
      tags.hashCode ^
      timestamp.hashCode ^
      userId.hashCode ^
      sessionId.hashCode ^
      deviceInfo.hashCode ^
      traceId.hashCode ^
      spanId.hashCode;

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
