import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shop/providers/auth_provider.dart';

void main() {
  test('AuthController.signIn signs in existing user', () async {
    final mockAuth = MockFirebaseAuth();

    // Pre-create a user so signInWithEmailAndPassword will succeed
    await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com', password: 'password123');

    final container = ProviderContainer(overrides: [
      firebaseAuthProvider.overrideWithValue(mockAuth),
    ]);
    addTearDown(container.dispose);

    final authController = container.read(authControllerProvider);

    final cred = await authController.signIn(
        email: 'test@example.com', password: 'password123');
    expect(cred.user, isNotNull);
    expect(cred.user!.email, equals('test@example.com'));
  });
}
