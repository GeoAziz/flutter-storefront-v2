import 'package:flutter_test/flutter_test.dart';
import 'package:shop/repository/firestore_product_repository.dart';

void main() {
  group('FirestoreProductRepository adapter', () {
    final repo = FirestoreProductRepository();

    test('maps full document with imageUrls, discount and stock > 0', () {
      final data = {
        'name': 'Test Phone',
        'imageUrls': ['https://example.com/img1.png', 'https://example.com/img2.png'],
        'price': 100.0,
        'discountPrice': 80.0,
        'stock': 5,
        'description': 'A full-featured test phone',
        'category': 'electronics',
      };

      final p = repo.mapFromFirestoreMap(data, 'test-id-1');

      expect(p.id, 'test-id-1');
      expect(p.title, 'Test Phone');
      expect(p.image, 'https://example.com/img1.png');
      expect(p.price, 100.0);
      expect(p.priceAfterDiscount, 80.0);
      expect(p.discountPercent, 20);
      expect(p.isAvailable, isTrue);
      expect(p.description, 'A full-featured test phone');
      expect(p.category, 'electronics');
    });

    test('handles missing optional fields (no imageUrls, no discount)', () {
      final data = {
        'title': 'Minimal Item',
        'price': 50.0,
        'stock': 3,
        // description intentionally missing
      };

      final p = repo.mapFromFirestoreMap(data, 'test-id-2');

      expect(p.id, 'test-id-2');
      expect(p.title, 'Minimal Item');
      // image should be empty string fallback
      expect(p.image, '');
      expect(p.price, 50.0);
      expect(p.priceAfterDiscount, isNull);
      expect(p.discountPercent, isNull);
      expect(p.isAvailable, isTrue);
      expect(p.description, '');
    });

    test('stock = 0 results in isAvailable = false', () {
      final data = {
        'name': 'Out of Stock Product',
        'imageUrl': 'https://example.com/out.png',
        'price': 20.0,
        'stock': 0,
      };

      final p = repo.mapFromFirestoreMap(data, 'test-id-3');

      expect(p.isAvailable, isFalse);
      expect(p.image, 'https://example.com/out.png');
    });

    test('discountPercent only -> computes priceAfterDiscount and preserves percent', () {
      final data = {
        'name': 'Percent Only Discount',
        'price': 200.0,
        'discountPercent': 25,
        'stock': 10,
      };

      final p = repo.mapFromFirestoreMap(data, 'test-id-4');

      expect(p.discountPercent, 25);
      // 25% off of 200 is 150.0
      expect(p.priceAfterDiscount, equals(150.0));
      expect(p.isAvailable, isTrue);
    });
  });
}
