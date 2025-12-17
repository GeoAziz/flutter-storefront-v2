/// Firebase Configuration and Initialization
///
/// This file handles Firebase initialization and provides core configuration
/// for the e-commerce application with support for development, staging, and production.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

/// Firebase Configuration Enum for different environments
enum FirebaseEnvironment { development, staging, production }

/// Main Firebase Configuration Class
class FirebaseConfig {
  static final FirebaseConfig _instance = FirebaseConfig._internal();

  /// Firebase Auth instance
  late FirebaseAuth _auth;

  /// Firestore instance
  late FirebaseFirestore _firestore;

  /// Firebase Storage instance
  late FirebaseStorage _storage;

  /// Firebase Messaging instance
  late FirebaseMessaging _messaging;

  /// Firebase Analytics instance
  late FirebaseAnalytics _analytics;

  /// Current environment
  late FirebaseEnvironment _environment;

  factory FirebaseConfig() {
    return _instance;
  }

  FirebaseConfig._internal();

  /// Initialize Firebase with the specified environment
  Future<void> initialize({
    FirebaseEnvironment environment = FirebaseEnvironment.production,
  }) async {
    _environment = environment;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    _messaging = FirebaseMessaging.instance;
    _analytics = FirebaseAnalytics.instance;

    // Configure based on environment
    _configureForEnvironment(environment);

    // Set up messaging
    await _setupMessaging();

    print('Firebase initialized for ${environment.name} environment');
  }

  /// Configure Firestore, Auth, and Storage based on environment
  void _configureForEnvironment(FirebaseEnvironment environment) {
    switch (environment) {
      case FirebaseEnvironment.development:
        // Enable offline persistence with increased cache size for development
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 104857600, // 100 MB
        );
        _auth.setPersistence(Persistence.LOCAL);
        break;

      case FirebaseEnvironment.staging:
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 52428800, // 50 MB
        );
        _auth.setPersistence(Persistence.LOCAL);
        break;

      case FirebaseEnvironment.production:
        // Minimal cache for production to optimize storage
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 10485760, // 10 MB
        );
        _auth.setPersistence(Persistence.LOCAL);
        break;
    }
  }

  /// Setup Firebase Cloud Messaging
  Future<void> _setupMessaging() async {
    // Request notification permissions (iOS)
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    });
  }

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseMessaging get messaging => _messaging;
  FirebaseAnalytics get analytics => _analytics;
  FirebaseEnvironment get environment => _environment;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
}

/// Global Firebase config instance
final firebaseConfig = FirebaseConfig();
