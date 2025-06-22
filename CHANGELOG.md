# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-06-22

### Added
- Initial release of The Overwatch observability package
- **Multi-Backend Support**: Easily integrate with multiple observability backends
- **Grafana Stack Integration**: Built-in support for Loki (logging) and Faro (RUM/metrics/traces)
- **LokiAdapter**: Sends structured logs to Grafana Loki with batching and compression
- **FaroAdapter**: Integrates with Grafana Faro for Real User Monitoring
- **Privacy Controls**: Automatic PII scrubbing with configurable patterns
- **Offline Buffering**: Store events offline and replay when connectivity is restored
- **Type-Safe Data Models**: Strongly typed models for AppEvent, AppError, AppLog, AppMetric
- **Extensible Architecture**: Easy to add custom backend adapters
- **Performance Optimizations**: Batching, compression, and background processing
- **Flutter Integration**: Built-in support for Flutter error handling and navigation tracking
- **Comprehensive Testing**: Test utilities and mocking support
- **Security Features**: PII protection, secure transmission, and data minimization
- **Cross-Platform Support**: Works on Android, iOS, Web, Windows, macOS, and Linux

### Features
- Event tracking with custom properties and context
- Structured logging with multiple levels and labels  
- Error capture with breadcrumbs and stack traces
- Custom metrics recording with tags and units
- User context and session management
- Global context configuration
- Automatic device information collection
- Intelligent retry logic with exponential backoff
- SQLite-based persistent offline storage
- Configurable sampling rates
- Debug logging for troubleshooting

[1.0.0]: https://github.com/yourusername/the_overwatch/releases/tag/v1.0.0
