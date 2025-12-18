import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Auth instance provider (can be overridden in tests)
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Firebase Firestore provider (for creating user documents)
final firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Stream provider that emits the currently authenticated [User?]
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  // Use idTokenChanges() which fires on token refreshes and sign-in/restoration
  // This is generally more reliable for lifecycle/resume scenarios than
  // authStateChanges() which can transiently emit null while Firebase restores
  // the user on app resume. We also log emissions for easier diagnosis.
  return auth.idTokenChanges().map((user) {
    // Lightweight instrumentation — keep in debug only if desired.
    try {
      // ignore: avoid_print
      print(
          '[auth] idTokenChanges -> user:${user?.uid} timestamp:${DateTime.now().toIso8601String()}');
    } catch (_) {}
    return user;
  });
});

/// Convenience provider that returns the current user id (or null).
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  return authState.maybeWhen(data: (u) => u?.uid, orElse: () => null);
});

/// Provider that returns whether the current user is an admin.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return false;
  try {
    final firestore = ref.read(firebaseFirestoreProvider);
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    final data = doc.data();
    return (data?['role'] as String?) == 'admin';
  } catch (e) {
    return false;
  }
});

/// Controller that exposes common auth actions (signup, login, logout)
class AuthController {
  final Ref ref;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthController(this.ref)
      : _auth = ref.read(firebaseAuthProvider),
        _firestore = ref.read(firebaseFirestoreProvider);

  /// Sign up using email & password. On success, creates a users/{uid}
  /// document with minimal profile data.
  Future<UserCredential> signUp(
      {required String email, required String password}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = cred.user;

    if (user != null) {
      final docRef = _firestore.collection('users').doc(user.uid);
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user',
      }, SetOptions(merge: true));
    }

    return cred;
  }

  /// Login using email & password
  Future<UserCredential> signIn(
      {required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authControllerProvider =
    Provider<AuthController>((ref) => AuthController(ref));
