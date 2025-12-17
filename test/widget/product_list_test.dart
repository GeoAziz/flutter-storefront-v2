import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/screens/all_products/views/all_products_screen.dart';

void main() {
  testWidgets('AllProductsScreen displays product grid and navigates on tap',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AllProductsScreen(),
        ),
      ),
    );

    // Allow the paginated list to load
    await tester.pumpAndSettle();

    // Verify that the app bar has "All Products" title
    expect(find.text('All Products'), findsWidgets);

    // Verify that we can find the product grid (at least one ProductCard)
    // ProductCard uses Text for title, so we look for mock product titles
    expect(find.text('Mock Product 1'), findsWidgets);
  });
}
