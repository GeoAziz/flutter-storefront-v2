import 'package:sentry_flutter/sentry_flutter.dart';

import 'telemetry_service.dart';

class SentryTelemetry implements TelemetryService {
  final String dsn;
  final bool enableTracing;

  SentryTelemetry({required this.dsn, this.enableTracing = false});

  @override
  Future<void> init({Map<String, dynamic>? options}) async {
    await SentryFlutter.init((options) {
      options.dsn = dsn;
      if (enableTracing) {
        options.tracesSampleRate = (options.tracesSampleRate ?? 0.0) > 0
            ? options.tracesSampleRate
            : 0.1;
      }
    });
  }

  @override
  Future<void> logEvent(String name, Map<String, dynamic>? properties) async {
    // Use breadcrumbs for simple events and also a message for searchable logs.
    Sentry.addBreadcrumb(Breadcrumb(message: name, data: properties));
    await Sentry.captureMessage('$name ${properties ?? {}}');
  }

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace,
      {Map<String, dynamic>? context}) async {
    await Sentry.captureException(error,
        stackTrace: stackTrace, hint: context != null ? Hint() : null);
  }

  @override
  Future<Object?> startSpan(String name) async {
    // Start a transaction for broader trace; return transaction as token.
    try {
      final transaction = Sentry.startTransaction(name, 'task');
      return transaction;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> finishSpan(Object? token) async {
    try {
      if (token is ISentrySpan) {
        await token.finish();
      }
    } catch (_) {}
  }

  @override
  Future<void> setUser({String? id, String? email}) async {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: id, email: email));
    });
  }
}
