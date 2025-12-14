// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop/main.dart';

void main() {
  testWidgets('App builds and stabilizes', (WidgetTester tester) async {
    // Wrap the app with ProviderScope so providers are available.
  await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Let animations/frames settle.
    await tester.pumpAndSettle();

    // Expect the MaterialApp (root) to be present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
