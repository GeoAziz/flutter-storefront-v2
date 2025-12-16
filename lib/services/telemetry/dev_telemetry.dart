import 'package:flutter/foundation.dart';

import 'telemetry_service.dart';

/// Development telemetry implementation that writes to console via debugPrint.
/// Safe to enable in dev and tests. Minimal, no external dependencies.
class DevTelemetry implements TelemetryService {
  @override
  Future<void> init({Map<String, dynamic>? options}) async {
    debugPrint('[DevTelemetry] initialized with options: $options');
  }

  @override
  Future<void> logEvent(String name, Map<String, dynamic>? properties) async {
    debugPrint('[DevTelemetry] event: $name ${properties ?? {}}');
  }

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace,
      {Map<String, dynamic>? context}) async {
    debugPrint('[DevTelemetry] exception: $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
    if (context != null) debugPrint('context: $context');
  }

  @override
  Future<Object?> startSpan(String name) async {
    final token = DateTime.now().microsecondsSinceEpoch;
    debugPrint('[DevTelemetry] startSpan: $name token=$token');
    return token;
  }

  @override
  Future<void> finishSpan(Object? token) async {
    debugPrint('[DevTelemetry] finishSpan token=$token');
  }

  @override
  Future<void> setUser({String? id, String? email}) async {
    debugPrint('[DevTelemetry] setUser id=$id email=$email');
  }
}
