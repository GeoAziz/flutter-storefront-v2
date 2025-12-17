/// Emulator configuration for local development and testing.
///
/// Import and call [setupEmulators()] before Firebase.initializeApp() to point
/// the app to local Firebase Emulators (Firestore).
///
/// Usage:
/// ```dart
/// import 'package:shop/config/emulator_config.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Enable emulators for local development (debug only)
///   if (kDebugMode) {
///     await setupEmulators();
///   }
///
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///   runApp(const MyApp());
/// }
/// ```
library;

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Set up local Firebase Emulators for development and testing.
///
/// This function configures the app to use a local Firestore Emulator running on:
/// - Firestore: 127.0.0.1:8080
///
/// For Cloud Functions testing, you can add firebase_functions to pubspec.yaml
/// and uncomment the functions emulator setup below.
///
/// Only call this in debug builds. Make sure the emulators are running before
/// starting the app:
/// ```bash
/// firebase emulators:start --only functions,firestore
/// ```
Future<void> setupEmulators() async {
  try {
    // Determine correct host for emulator depending on platform.
    // Android emulator accesses the host machine via 10.0.2.2. iOS
    // simulator and desktop use localhost/127.0.0.1.
    final host = (Platform.isAndroid) ? '10.0.2.2' : '127.0.0.1';

    // Connect to local Firestore Emulator
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    // Connect to local Firebase Auth Emulator (default 9099)
    try {
      FirebaseAuth.instance.useAuthEmulator(host, 9099);
    } catch (_) {
      // If auth emulator not available in this environment, ignore — tests
      // and local runs should call setupEmulators() in debug mode where
      // the emulator is running.
    }

    // Firestore Functions emulator (requires: flutter pub add firebase_functions)
    // Uncomment when firebase_functions is added:
    // import 'package:firebase_functions/firebase_functions.dart';
    // FirebaseFunctions.instance.useFunctionsEmulator(origin: 'http://127.0.0.1:5001');

    if (kDebugMode) {
      print('✓ Connected to local Firebase Emulators');
      print('  Firestore: http://$host:8080');
      print('  View Emulator UI: http://$host:4000/');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠ Failed to setup emulators: $e');
      print('  Ensure Firebase Emulators are running:');
      print('  firebase emulators:start --only functions,firestore');
    }
  }
}
