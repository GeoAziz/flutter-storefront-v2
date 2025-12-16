/// TelemetryService: abstract interface for error/event/perf telemetry.
/// Implementations: DevTelemetry (console), SentryTelemetry (Sentry), etc.

abstract class TelemetryService {
  /// Initialize telemetry. Providers may accept configuration (dsn, env, sample rate).
  Future<void> init({Map<String, dynamic>? options});

  /// Log a named event with optional properties.
  Future<void> logEvent(String name, Map<String, dynamic>? properties);

  /// Capture a handled/unhandled exception.
  Future<void> captureException(Object error, StackTrace? stackTrace,
      {Map<String, dynamic>? context});

  /// Start a performance/span trace and return a token that can be used to finish it.
  /// The token is implementation-defined (Sentry returns a span object, others may use an id).
  Future<Object?> startSpan(String name);

  /// Finish a span started with startSpan.
  Future<void> finishSpan(Object? token);

  /// Set user context (id, email) for telemetry backends that support user-scoped events.
  Future<void> setUser({String? id, String? email});
}
