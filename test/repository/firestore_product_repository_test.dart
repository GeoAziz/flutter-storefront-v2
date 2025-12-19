import 'package:flutter_test/flutter_test.dart';
import 'package:shop/repository/firestore_product_repository.dart';
import 'package:shop/repository/pagination.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

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

    test('fetchProducts reads from injected Firestore instance', () async {
      final fake = FakeFirebaseFirestore();
      // Seed a product document
      await fake.collection('products').doc('f1').set({
        'name': 'Fake Product',
        'price': 11.5,
        'stock': 4,
        'imageUrl': 'https://example.com/fake.png',
        'description': 'Seeded fake product'
      });

      final repo = FirestoreProductRepository(injectedFirestore: fake);
      final result = await repo.fetchProducts();
      // Should read the seeded document from the fake firestore
      expect(result.any((p) => p.id == 'f1' && p.title == 'Fake Product'), isTrue);
    });
  });
}
