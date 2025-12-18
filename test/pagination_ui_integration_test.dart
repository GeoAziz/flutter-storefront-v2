import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop/components/pagination/paginated_product_list.dart';
import 'package:shop/components/pagination/pagination_widgets.dart';
import 'package:shop/repository/pagination.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/providers/repository_providers.dart';

class MockPaginationRepository extends ProductRepository {
  final List<Product> _allProducts;

  MockPaginationRepository({List<Product>? products})
      : _allProducts = products ?? _generateMockProducts();

  static List<Product> _generateMockProducts() {
    return List.generate(
      50,
      (i) => Product(
        id: 'p$i',
        title: 'Product $i',
        image: 'assets/images/placeholder.png',
        price: 100.0 + i,
        priceAfterDiscount: 80.0 + i,
        discountPercent: 20,
      ),
    );
  }

  @override
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _allProducts;
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request,
      {String? category}) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (request is PageRequest) {
      final pageSize = request.pageSize;
      final page = request.page;
      final startIndex = (page - 1) * pageSize;
      final endIndex =
          ((startIndex + pageSize).clamp(0, _allProducts.length) as int);

      final items = startIndex >= _allProducts.length
          ? <Product>[]
          : _allProducts.sublist(startIndex, endIndex);
      final hasMore = endIndex < _allProducts.length;

      return PaginationResult(
        items: items,
        nextCursor: hasMore ? 'cursor_p${page + 1}' : null,
        hasMore: hasMore,
        page: page,
        pageSize: pageSize,
      );
    }

    if (request is CursorRequest) {
      // Simple cursor parsing for testing
      final pageSize = request.limit;
      final page = int.tryParse(request.cursor?.split('p').last ?? '1') ?? 1;
      final startIndex = (page - 1) * pageSize;
      final endIndex =
          ((startIndex + pageSize).clamp(0, _allProducts.length) as int);

      final items = startIndex >= _allProducts.length
          ? <Product>[]
          : _allProducts.sublist(startIndex, endIndex);
      final hasMore = endIndex < _allProducts.length;

      return PaginationResult(
        items: items,
        nextCursor: hasMore ? 'cursor_p${page + 1}' : null,
        hasMore: hasMore,
        page: page,
        pageSize: pageSize,
      );
    }

    return PaginationResult.empty();
  }
}

void main() {
  group('PaginatedProductList Widget Tests', () {
    testWidgets('displays loading indicator on initial load',
        (WidgetTester tester) async {
      final mockRepo = MockPaginationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedProductList(
                onProductTap: (_) {},
              ),
            ),
          ),
        ),
      );

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays product list after loading',
        (WidgetTester tester) async {
      final mockRepo = MockPaginationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedProductList(
                onProductTap: (_) {},
              ),
            ),
          ),
        ),
      );

      // Wait for async operations
      await tester.pumpAndSettle();

      // Should display products
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows empty state when no products available',
        (WidgetTester tester) async {
      final mockRepo = MockPaginationRepository(products: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedProductList(
                onProductTap: (_) {},
                customEmptyWidget: const Text('No products'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No products'), findsOneWidget);
    });

    testWidgets('switches to grid layout when useGridLayout is true',
        (WidgetTester tester) async {
      final mockRepo = MockPaginationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedProductList(
                onProductTap: (_) {},
                useGridLayout: true,
                gridColumns: 2,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display grid
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('calls onProductTap when product is tapped',
        (WidgetTester tester) async {
      final mockRepo = MockPaginationRepository();
      Product? tappedProduct;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedProductList(
                onProductTap: (product) {
                  tappedProduct = product;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap first product
      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pumpAndSettle();

      expect(tappedProduct, isNotNull);
    });

    testWidgets('uses custom loading widget when provided',
        (WidgetTester tester) async {
      final mockRepo = MockPaginationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedProductList(
                onProductTap: (_) {},
                customLoadingWidget: const Text('Custom Loading'),
              ),
            ),
          ),
        ),
      );

      // Should show custom loading widget initially
      expect(find.text('Custom Loading'), findsOneWidget);
    });
  });

  group('Pagination Controls Widget Tests', () {
    testWidgets('PaginationLoadingIndicator displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaginationLoadingIndicator(
                message: 'Loading more products...',
                showCancelButton: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading more products...'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('PaginationErrorWidget displays error message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaginationErrorWidget(
                errorMessage: 'Network error occurred',
                onRetry: () async {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Network error occurred'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('PaginationEmptyWidget displays empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaginationEmptyWidget(
                title: 'No items',
                subtitle: 'Try again later',
                onRetry: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Try again later'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('Edge Case Tests', () {
    testWidgets('handles large product lists without freezing UI',
        (WidgetTester tester) async {
      final largeProductList = List.generate(
        500,
        (i) => Product(
          id: 'p$i',
          title: 'Product $i',
          image: 'assets/images/placeholder.png',
          price: 100.0 + i,
        ),
      );

      final mockRepo = MockPaginationRepository(products: largeProductList);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedProductList(
                onProductTap: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle large lists
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Backward Compatibility Tests', () {
    testWidgets('legacy fetchProducts still works for other screens',
        (WidgetTester tester) async {
      final mockRepo = MockPaginationRepository();

      // Test that fetchProducts method still exists and works
      final products = await mockRepo.fetchProducts();

      expect(products, isNotEmpty);
      expect(products.length, greaterThan(0));
    });
  });
}
