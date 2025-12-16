import 'package:flutter_test/flutter_test.dart';
import 'package:shop/repository/pagination.dart';
import 'package:shop/repository/product_repository.dart';

class SimpleMockRepository extends ProductRepository {
  final List<Product> _allProducts;

  SimpleMockRepository({List<Product>? products})
      : _allProducts = products ?? _generateMockProducts();

  static List<Product> _generateMockProducts() {
    return List.generate(
      50,
      (i) => Product(
        id: 'p$i',
        title: 'Product $i',
        image: 'assets/images/placeholder.png',
        price: 100.0 + i,
      ),
    );
  }

  @override
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _allProducts;
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 50));

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
        nextCursor: hasMore ? 'page_${page + 1}' : null,
        hasMore: hasMore,
        page: page,
        pageSize: pageSize,
      );
    }

    if (request is CursorRequest) {
      final pageSize = request.limit;
      final page = int.tryParse(request.cursor?.split('_').last ?? '1') ?? 1;
      final startIndex = (page - 1) * pageSize;
      final endIndex =
          ((startIndex + pageSize).clamp(0, _allProducts.length) as int);

      final items = startIndex >= _allProducts.length
          ? <Product>[]
          : _allProducts.sublist(startIndex, endIndex);
      final hasMore = endIndex < _allProducts.length;

      return PaginationResult(
        items: items,
        nextCursor: hasMore ? 'page_${page + 1}' : null,
        hasMore: hasMore,
        page: page,
        pageSize: pageSize,
      );
    }

    return PaginationResult.empty();
  }
}

void main() {
  group('Pagination DTOs', () {
    test('PageRequest creates correctly', () {
      final req = PageRequest(page: 2, pageSize: 20);
      expect(req.page, equals(2));
      expect(req.pageSize, equals(20));
    });

    test('CursorRequest creates correctly', () {
      final req = CursorRequest(cursor: 'test_cursor', limit: 25);
      expect(req.cursor, equals('test_cursor'));
      expect(req.limit, equals(25));
      expect(req.pageSize, equals(25));
    });

    test('PaginationResult creates correctly', () {
      final products = [
        Product(
          id: 'p1',
          title: 'Test Product',
          image: 'test.png',
          price: 100,
        ),
      ];
      final result = PaginationResult(
        items: products,
        nextCursor: 'next_cursor',
        hasMore: true,
        page: 1,
        pageSize: 20,
      );

      expect(result.items.length, equals(1));
      expect(result.nextCursor, equals('next_cursor'));
      expect(result.hasMore, equals(true));
      expect(result.page, equals(1));
      expect(result.pageSize, equals(20));
    });

    test('PaginationResult.empty() creates empty result', () {
      final result = PaginationResult.empty();
      expect(result.items, isEmpty);
      expect(result.nextCursor, isNull);
      expect(result.hasMore, equals(false));
    });
  });

  group('SimpleMockRepository Pagination', () {
    test('fetchProducts returns all products', () async {
      final repo = SimpleMockRepository();
      final products = await repo.fetchProducts();
      expect(products.length, equals(50));
    });

    test('fetchProductsPaginated with PageRequest returns first page',
        () async {
      final repo = SimpleMockRepository();
      final request = PageRequest(page: 1, pageSize: 20);
      final result = await repo.fetchProductsPaginated(request);

      expect(result.items.length, equals(20));
      expect(result.hasMore, equals(true));
      expect(result.page, equals(1));
    });

    test('fetchProductsPaginated with PageRequest returns last page', () async {
      final repo = SimpleMockRepository();
      final request = PageRequest(page: 3, pageSize: 20);
      final result = await repo.fetchProductsPaginated(request);

      expect(result.items.length, equals(10)); // Only 10 items on last page
      expect(result.hasMore, equals(false));
      expect(result.page, equals(3));
    });

    test('fetchProductsPaginated with CursorRequest works', () async {
      final repo = SimpleMockRepository();
      final request = CursorRequest(cursor: 'page_2', limit: 20);
      final result = await repo.fetchProductsPaginated(request);

      expect(result.items.length, equals(20));
      expect(result.hasMore, equals(true));
    });

    test('fetchProductsPaginated with empty product list', () async {
      final repo = SimpleMockRepository(products: []);
      final request = PageRequest(page: 1, pageSize: 20);
      final result = await repo.fetchProductsPaginated(request);

      expect(result.items, isEmpty);
      expect(result.hasMore, equals(false));
    });

    test('fetchProductsPaginated with page out of bounds', () async {
      final repo = SimpleMockRepository();
      final request = PageRequest(page: 100, pageSize: 20);
      final result = await repo.fetchProductsPaginated(request);

      expect(result.items, isEmpty);
      expect(result.hasMore, equals(false));
    });

    test('fetchProductsPaginated calculates nextCursor correctly', () async {
      final repo = SimpleMockRepository();
      final request = PageRequest(page: 1, pageSize: 20);
      final result = await repo.fetchProductsPaginated(request);

      expect(result.nextCursor, equals('page_2'));
    });

    test('fetchProductsPaginated has no nextCursor on last page', () async {
      final repo = SimpleMockRepository();
      final request = PageRequest(page: 3, pageSize: 20);
      final result = await repo.fetchProductsPaginated(request);

      expect(result.nextCursor, isNull);
    });
  });

  group('Backward Compatibility', () {
    test('legacy fetchProducts method still available and works', () async {
      final repo = SimpleMockRepository();
      final products = await repo.fetchProducts();

      expect(products, isNotEmpty);
      expect(products.length, equals(50));
      expect(products.first.title, equals('Product 0'));
    });

    test('Product model still works as expected', () {
      final product = Product(
        id: 'test',
        title: 'Test Product',
        image: 'test.png',
        price: 99.99,
        priceAfterDiscount: 79.99,
        discountPercent: 20,
      );

      expect(product.id, equals('test'));
      expect(product.title, equals('Test Product'));
      expect(product.price, equals(99.99));
      expect(product.discountPercent, equals(20));
    });

    test('MockProductRepository implements ProductRepository', () {
      final mockRepo = MockProductRepository();
      expect(mockRepo, isA<ProductRepository>());
    });

    test('RealProductRepository implements ProductRepository', () {
      final realRepo = RealProductRepository();
      expect(realRepo, isA<ProductRepository>());
    });
  });

  group('Edge Cases', () {
    test('handles very small pageSize', () async {
      final repo = SimpleMockRepository();
      final request = PageRequest(page: 1, pageSize: 1);
      final result = await repo.fetchProductsPaginated(request);

      expect(result.items.length, equals(1));
      expect(result.hasMore, equals(true));
    });

    test('handles large pageSize', () async {
      final repo = SimpleMockRepository();
      final request = PageRequest(page: 1, pageSize: 1000);
      final result = await repo.fetchProductsPaginated(request);

      expect(result.items.length, equals(50)); // Only 50 products available
      expect(result.hasMore, equals(false));
    });

    test('handles pagination through all pages', () async {
      final repo = SimpleMockRepository();
      int page = 1;
      int totalFetched = 0;
      const pageSize = 10;

      while (true) {
        final request = PageRequest(page: page, pageSize: pageSize);
        final result = await repo.fetchProductsPaginated(request);

        totalFetched += result.items.length;

        if (!result.hasMore) break;
        page++;
      }

      expect(totalFetched, equals(50));
    });

    test('product data integrity through pagination', () async {
      final repo = SimpleMockRepository();

      // Fetch first page
      final result1 = await repo.fetchProductsPaginated(
        PageRequest(page: 1, pageSize: 20),
      );

      // Fetch second page
      final result2 = await repo.fetchProductsPaginated(
        PageRequest(page: 2, pageSize: 20),
      );

      // Verify no overlap
      final ids1 = result1.items.map((p) => p.id).toSet();
      final ids2 = result2.items.map((p) => p.id).toSet();
      expect(ids1.intersection(ids2), isEmpty);

      // Verify order
      expect(result1.items.first.id, equals('p0'));
      expect(result2.items.first.id, equals('p20'));
    });
  });
}
