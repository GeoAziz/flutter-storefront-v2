import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shop/repositories/wishlist_repository.dart';
import 'package:shop/models/wishlist_item.dart';
import 'package:shop/models/product_model.dart';

void main() {
  late Directory tempDir;
  late WishlistRepository repo;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    repo = WishlistRepository();
    await repo.init();
  });

  tearDown(() async {
    try {
      await Hive.deleteBoxFromDisk(WishlistRepository.boxName);
    } catch (_) {}
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('WishlistRepository', () {
    test('initializes successfully', () async {
      expect(repo.isInitialized, true);
    });

    test('add and retrieve wishlist item', () async {
      final product = ProductModel(
        id: 'test_1',
        image: 'https://example.com/image.jpg',
        brandName: 'TestBrand',
        title: 'Test Product',
        price: 99.99,
      );
      final item = WishlistItem(id: product.id, product: product);

      await repo.add(item);

      expect(repo.contains('test_1'), true);
      expect(repo.count(), 1);
    });

    test('remove wishlist item', () async {
      final product = ProductModel(
        id: 'test_2',
        image: 'https://example.com/image.jpg',
        brandName: 'TestBrand',
        title: 'Test Product',
        price: 99.99,
      );
      final item = WishlistItem(id: product.id, product: product);

      await repo.add(item);
      expect(repo.contains('test_2'), true);

      await repo.remove('test_2');
      expect(repo.contains('test_2'), false);
    });

    test('get all wishlist items', () async {
      final product1 = ProductModel(
        id: 'test_3',
        image: 'https://example.com/image1.jpg',
        brandName: 'Brand1',
        title: 'Product 1',
        price: 50.0,
      );
      final product2 = ProductModel(
        id: 'test_4',
        image: 'https://example.com/image2.jpg',
        brandName: 'Brand2',
        title: 'Product 2',
        price: 75.0,
      );

      await repo.add(WishlistItem(id: product1.id, product: product1));
      await repo.add(WishlistItem(id: product2.id, product: product2));

      final items = repo.getAll();

      expect(items.length, 2);
      expect(items[0].product.id, 'test_3');
      expect(items[1].product.id, 'test_4');
    });

    test('clear all wishlist items', () async {
      final product = ProductModel(
        id: 'test_5',
        image: 'https://example.com/image.jpg',
        brandName: 'TestBrand',
        title: 'Test Product',
        price: 99.99,
      );
      await repo.add(WishlistItem(id: product.id, product: product));

      expect(repo.count(), 1);

      await repo.clear();

      expect(repo.count(), 0);
      expect(repo.getAll(), isEmpty);
    });

    test('count returns correct number of items', () async {
      expect(repo.count(), 0);

      for (int i = 0; i < 5; i++) {
        final product = ProductModel(
          id: 'test_$i',
          image: 'https://example.com/image.jpg',
          brandName: 'TestBrand',
          title: 'Test Product $i',
          price: 99.99,
        );
        await repo.add(WishlistItem(id: product.id, product: product));
      }

      expect(repo.count(), 5);
    });

    test('contains returns correct boolean', () async {
      final product = ProductModel(
        id: 'test_contains',
        image: 'https://example.com/image.jpg',
        brandName: 'TestBrand',
        title: 'Test Product',
        price: 99.99,
      );

      expect(repo.contains('test_contains'), false);

      await repo.add(WishlistItem(id: product.id, product: product));

      expect(repo.contains('test_contains'), true);

      await repo.remove('test_contains');

      expect(repo.contains('test_contains'), false);
    });

    test('persists data across repository instances', () async {
      final product = ProductModel(
        id: 'test_persist',
        image: 'https://example.com/image.jpg',
        brandName: 'TestBrand',
        title: 'Test Product',
        price: 99.99,
      );
      await repo.add(WishlistItem(id: product.id, product: product));

      // Create new instance and verify data persists
      final repo2 = WishlistRepository();
      await repo2.init();

      expect(repo2.contains('test_persist'), true);
      expect(repo2.count(), 1);
    });

    test('handles duplicate adds gracefully', () async {
      final product = ProductModel(
        id: 'test_dup',
        image: 'https://example.com/image.jpg',
        brandName: 'TestBrand',
        title: 'Test Product',
        price: 99.99,
      );
      final item = WishlistItem(id: product.id, product: product);

      await repo.add(item);
      await repo.add(item); // Add same item again

      expect(repo.count(), 1); // Should still be 1, not 2
    });
  });
}
