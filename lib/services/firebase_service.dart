import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

    // Configure Firestore/Storage to use local emulator when requested.
    if (useEmulator) {
      // Firestore emulator default host/port: localhost:8080
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      // Storage emulator default host/port: localhost:9199
      FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    } else {
      // Enable offline persistence for Firestore in production/dev by default
      try {
        FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      } catch (_) {
        // ignore: avoid_print
        if (bool.fromEnvironment('dart.vm.product') == false) {
          print('[FirebaseService] Firestore settings apply skipped');
        }
      }
    }

    _initialized = true;
    if (kDebugMode) {
      // Helpful log during development
      // ignore: avoid_print
      print('[FirebaseService] initialized (useEmulator: $useEmulator)');
    }
  }
}
