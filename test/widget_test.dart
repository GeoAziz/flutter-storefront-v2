// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop/main.dart';

void main() {
  // Initialize Firebase with test options before widget tests run so
  // widgets that reference Firebase can find a default app.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project',
      ),
    );
  });
  testWidgets('App builds and stabilizes', (WidgetTester tester) async {
    // Wrap the app with ProviderScope so providers are available.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Let animations/frames settle.
    await tester.pumpAndSettle();

    // Expect the MaterialApp (root) to be present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
