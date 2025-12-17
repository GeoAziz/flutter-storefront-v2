/// Firebase Authentication Service
///
/// Handles user authentication including sign up, login, sign out,
/// password reset, and provider authentication (Google, etc.)
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_models.dart';
import '../config/firebase_config.dart';

class AuthenticationException implements Exception {
  final String message;
  final String? code;

  AuthenticationException({required this.message, this.code});

  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();

  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _auth = firebaseConfig.auth;
    _firestore = firebaseConfig.firestore;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========================================================================
  // Sign Up / Registration
  // ========================================================================

  /// Register new user with email and password
  Future<UserProfile> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user account
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credentials.user;
      if (user == null) {
        throw AuthenticationException(
          message: 'Failed to create user account',
        );
      }

      // Update display name
      await user.updateDisplayName(displayName);

      // Create user profile in Firestore
      final userProfile = UserProfile(
        id: user.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(
            userProfile.toMap(),
          );

      return userProfile;
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _handleFirebaseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  // ========================================================================
  // Sign In
  // ========================================================================

  /// Sign in with email and password
  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credentials.user;
      if (user == null) {
        throw AuthenticationException(message: 'Sign in failed');
      }

      // Fetch user profile from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw AuthenticationException(
          message: 'User profile not found',
        );
      }

      return UserProfile.fromMap(userDoc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _handleFirebaseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Sign in anonymously
  Future<UserProfile> signInAnonymously() async {
    try {
      final credentials = await _auth.signInAnonymously();

      final user = credentials.user;
      if (user == null) {
        throw AuthenticationException(message: 'Anonymous sign in failed');
      }

      // Create anonymous user profile
      final userProfile = UserProfile(
        id: user.uid,
        email: 'anonymous@${user.uid}',
        displayName: 'Anonymous User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(
            userProfile.toMap(),
            SetOptions(merge: true),
          );

      return userProfile;
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _handleFirebaseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  // ========================================================================
  // Sign Out
  // ========================================================================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to sign out: $e',
      );
    }
  }

  // ========================================================================
  // Password Management
  // ========================================================================

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _handleFirebaseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to send reset email: $e',
      );
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthenticationException(
            message: 'No user is currently signed in');
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _handleFirebaseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to update password: $e',
      );
    }
  }

  // ========================================================================
  // Email Verification
  // ========================================================================

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthenticationException(
            message: 'No user is currently signed in');
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _handleFirebaseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to send verification email: $e',
      );
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    return user.emailVerified;
  }

  // ========================================================================
  // User Profile Management
  // ========================================================================

  /// Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return null;
      }

      return UserProfile.fromMap(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to fetch user profile: $e',
      );
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthenticationException(
            message: 'No user is currently signed in');
      }

      if (user.uid != profile.id) {
        throw AuthenticationException(
          message: 'Cannot update another user profile',
        );
      }

      await _firestore.collection('users').doc(user.uid).update(
            profile.copyWith(updatedAt: DateTime.now()).toMap(),
          );
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to update user profile: $e',
      );
    }
  }

  // ========================================================================
  // Helper Methods
  // ========================================================================

  /// Handle Firebase Auth errors and return user-friendly messages
  String _handleFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please try a different method.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'requires-recent-login':
        return 'Please sign in again before performing this action.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email.';
      case 'invalid-credential':
        return 'The credential is invalid or expired.';
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }

  /// Delete user account and associated data
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthenticationException(
            message: 'No user is currently signed in');
      }

      final userId = user.uid;

      // Delete user profile from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Delete cart
      await _firestore.collection('cart').doc(userId).delete();

      // Delete favorites
      await _firestore.collection('favorites').doc(userId).delete();

      // Delete user from Firebase Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _handleFirebaseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to delete account: $e',
      );
    }
  }
}

/// Global auth service instance
final authService = AuthService();
