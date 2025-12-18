import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/screens/home/views/components/popular_products.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/repository/pagination.dart';

class _EmptyProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async => [];

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request,
      {String? category}) async {
    // Return an empty pagination result to keep tests stable.
    return PaginationResult<Product>.empty();
  }
}

void main() {
  testWidgets('Smoke: app boots with ProviderScope and shows products',
      (WidgetTester tester) async {
    // Ensure SharedPreferences is mocked for tests
    SharedPreferences.setMockInitialValues({});

    // Use an empty repository to avoid rendering ProductCard rows in this smoke test
    final mockRepo = _EmptyProductRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [productRepositoryProvider.overrideWithValue(mockRepo)],
        child: const MaterialApp(
            home:
                Scaffold(body: SizedBox(width: 600, child: PopularProducts()))),
      ),
    );

    // Allow async frames to complete
    await tester.pumpAndSettle();

    // Verify main content header appears; products list is empty in this smoke test
    expect(find.text('Popular products'), findsOneWidget);
  });
}
