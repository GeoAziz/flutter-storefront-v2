import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shop/screens/auth/login_screen.dart';
import 'package:shop/route/route_names.dart';
import 'package:shop/providers/auth_provider.dart';

void main() {
  testWidgets('LoginScreen signs in and navigates to entryPoint',
      (tester) async {
    final mockAuth = MockFirebaseAuth();

    // Create a user ahead of time so signIn will succeed
    await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com', password: 'password123');

    await tester.pumpWidget(ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
      ],
      child: MaterialApp(
        routes: {
          RouteNames.entryPoint: (_) =>
              const Scaffold(body: Center(child: Text('ENTRY'))),
        },
        home: const LoginScreen(),
      ),
    ));

    // Ensure widgets are laid out
    await tester.pumpAndSettle();

    // Fill in credentials and tap login
    await tester.enterText(
        find.byKey(const Key('login_user')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('login_pass')), 'password123');
    await tester.tap(find.byKey(const Key('login_btn')));

    // Wait for navigation & async operations
    await tester.pumpAndSettle();

    // Expect navigation to entry point
    expect(find.text('ENTRY'), findsOneWidget);
  });
}
