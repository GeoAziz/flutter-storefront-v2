import 'package:flutter_test/flutter_test.dart';
import 'package:shop/repository/firestore_product_repository.dart';
import 'package:shop/repository/pagination.dart';

void main() {
  setUpAll(() {
    // No Firebase init needed — FirestoreProductRepository will try to connect
    // to the emulator if available; otherwise falls back to the deterministic stub.
    // For unit tests, the fallback is used since there's no platform channel context.
  });

  group('FirestoreProductRepository', () {
    test('fetchProducts returns products from fallback', () async {
      final repo = FirestoreProductRepository();
      final result = await repo.fetchProducts();
      print('Fetched ${result.length} products (will use deterministic fallback in unit tests)');
      expect(result, isNotNull);
      expect(result, isA<List>());
      // The fallback is deterministic and returns non-empty list
      expect(result.length, greaterThan(0));
    });

    test('fetchProductsPaginated with PageRequest works', () async {
      final repo = FirestoreProductRepository();
      final request = PageRequest(page: 1, pageSize: 5);
      final result = await repo.fetchProductsPaginated(request);
      print('Pagination result: ${result.items.length} items, hasMore: ${result.hasMore}');
      expect(result.items, isNotNull);
      expect(result, isA<PaginationResult>());
      // Fallback returns at least some data
      expect(result.items.length, greaterThan(0));
    });

    test('fetchProductsPaginated with CursorRequest works', () async {
      final repo = FirestoreProductRepository();
      final request = CursorRequest(cursor: null, limit: 5);
      final result = await repo.fetchProductsPaginated(request);
      print('Cursor pagination result: ${result.items.length} items, hasMore: ${result.hasMore}');
      expect(result.items, isNotNull);
      expect(result, isA<PaginationResult>());
    });
  });
}
