import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Minimal Firebase initialization helper.
/// Call FirebaseService.initialize() early in app startup (main.dart)
class FirebaseService {
  static bool _initialized = false;

  /// Initialize Firebase. If [useEmulator] is true, caller should configure
  /// emulator host/ports on the firestore/storage/auth SDK instances after
  /// initialization. This helper only calls Firebase.initializeApp().
  static Future<void> initialize({bool useEmulator = false}) async {
    if (_initialized) return;

    await Firebase.initializeApp();

    // NOTE: emulator wiring (e.g., FirebaseFirestore.instance.useFirestoreEmulator)
    // should be done by higher-level repository code when `useEmulator` is true.

    _initialized = true;
    if (kDebugMode) {
      // Helpful log during development
      // ignore: avoid_print
      print('[FirebaseService] initialized (useEmulator: $useEmulator)');
    }
  }
}
