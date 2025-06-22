/// Generic application event for tracking user interactions and custom events
class AppEvent {
  const AppEvent({
    required this.name,
    this.properties = const {},
    required this.timestamp,
    this.userId,
    this.sessionId,
    this.deviceInfo,
    this.context = const {},
  });

  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;
  final Map<String, dynamic>? deviceInfo;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => {
        'name': name,
        'properties': properties,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'sessionId': sessionId,
        'deviceInfo': deviceInfo,
        'context': context,
      };

  AppEvent copyWith({
    String? name,
    Map<String, dynamic>? properties,
    DateTime? timestamp,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? context,
  }) {
    return AppEvent(
      name: name ?? this.name,
      properties: properties ?? this.properties,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      context: context ?? this.context,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppEvent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _mapEquals(properties, other.properties) &&
          timestamp == other.timestamp &&
          userId == other.userId &&
          sessionId == other.sessionId &&
          _mapEquals(deviceInfo, other.deviceInfo) &&
          _mapEquals(context, other.context);

  @override
  int get hashCode =>
      name.hashCode ^
      properties.hashCode ^
      timestamp.hashCode ^
      userId.hashCode ^
      sessionId.hashCode ^
      deviceInfo.hashCode ^
      context.hashCode;

  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
