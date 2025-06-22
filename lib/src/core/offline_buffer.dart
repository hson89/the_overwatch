import 'dart:async';
import '../models/models.dart';

/// Event type enum for buffer storage
enum BufferedEventType {
  event,
  error,
  log,
  metric,
}

/// Buffered event data structure
class BufferedEvent {
  const BufferedEvent({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  final String id;
  final BufferedEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory BufferedEvent.fromJson(Map<String, dynamic> json) {
    return BufferedEvent(
      id: json['id'] as String,
      type: BufferedEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BufferedEventType.event,
      ),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  BufferedEvent copyWith({
    String? id,
    BufferedEventType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return BufferedEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Abstract interface for offline buffer storage
abstract class BufferStorage {
  Future<void> initialize();
  Future<void> store(BufferedEvent event);
  Future<List<BufferedEvent>> retrieve({int? limit});
  Future<void> remove(String eventId);
  Future<void> clear();
  Future<int> count();
  Future<void> dispose();
}

/// Callback for handling buffered events when connectivity is restored
typedef BufferFlushCallback = Future<bool> Function(BufferedEvent event);

/// Offline buffer manager for storing and replaying events
class OfflineBuffer {
  OfflineBuffer({
    required BufferStorage storage,
    required this.maxBufferSize,
    required this.flushInterval,
    required this.onFlush,
  }) : _storage = storage;

  final BufferStorage _storage;
  final int maxBufferSize;
  final Duration flushInterval;
  final BufferFlushCallback onFlush;

  Timer? _flushTimer;
  bool _isInitialized = false;
  bool _isFlushing = false;

  /// Initialize the buffer
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _storage.initialize();
    _startFlushTimer();
    _isInitialized = true;
  }

  /// Add an event to the buffer
  Future<void> addEvent(AppEvent event) async {
    await _addBufferedEvent(BufferedEvent(
      id: _generateId(),
      type: BufferedEventType.event,
      data: event.toJson(),
      timestamp: DateTime.now(),
    ));
  }

  /// Add an error to the buffer
  Future<void> addError(AppError error) async {
    await _addBufferedEvent(BufferedEvent(
      id: _generateId(),
      type: BufferedEventType.error,
      data: error.toJson(),
      timestamp: DateTime.now(),
    ));
  }

  /// Add a log to the buffer
  Future<void> addLog(AppLog log) async {
    await _addBufferedEvent(BufferedEvent(
      id: _generateId(),
      type: BufferedEventType.log,
      data: log.toJson(),
      timestamp: DateTime.now(),
    ));
  }

  /// Add a metric to the buffer
  Future<void> addMetric(AppMetric metric) async {
    await _addBufferedEvent(BufferedEvent(
      id: _generateId(),
      type: BufferedEventType.metric,
      data: metric.toJson(),
      timestamp: DateTime.now(),
    ));
  }

  /// Manually trigger a flush attempt
  Future<void> flush() async {
    if (_isFlushing) return;
    _isFlushing = true;
    
    try {
      final events = await _storage.retrieve(limit: 50); // Process in batches
      
      for (final event in events) {
        try {
          final success = await onFlush(event);
          if (success) {
            await _storage.remove(event.id);
          } else {
            // Increment retry count and re-store if max retries not reached
            if (event.retryCount < 3) {
              final updatedEvent = event.copyWith(retryCount: event.retryCount + 1);
              await _storage.remove(event.id);
              await _storage.store(updatedEvent);
            } else {
              // Remove after max retries
              await _storage.remove(event.id);
            }
          }
        } catch (e) {
          // Log error but continue processing other events
          print('Error flushing buffered event ${event.id}: $e');
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Get the current buffer size
  Future<int> getBufferSize() async {
    return await _storage.count();
  }

  /// Clear all buffered events
  Future<void> clear() async {
    await _storage.clear();
  }

  /// Dispose of resources
  Future<void> dispose() async {
    _flushTimer?.cancel();
    await _storage.dispose();
  }

  Future<void> _addBufferedEvent(BufferedEvent event) async {
    if (!_isInitialized) {
      throw StateError('Buffer not initialized. Call initialize() first.');
    }

    // Check if buffer is full
    final currentSize = await _storage.count();
    if (currentSize >= maxBufferSize) {
      // Remove oldest events to make space
      final oldEvents = await _storage.retrieve(limit: currentSize - maxBufferSize + 1);
      for (final oldEvent in oldEvents) {
        await _storage.remove(oldEvent.id);
      }
    }

    await _storage.store(event);
  }

  void _startFlushTimer() {
    _flushTimer = Timer.periodic(flushInterval, (_) {
      flush();
    });
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
