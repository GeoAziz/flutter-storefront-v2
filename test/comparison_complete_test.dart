import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shop/repositories/comparison_repository.dart';
import 'package:shop/models/comparison_item.dart';
import 'package:shop/models/product_model.dart';

void main() {
  late Directory tempDir;
  late ComparisonRepository repo;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_comparison_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    repo = ComparisonRepository();
    await repo.init();
  });

  tearDown(() async {
    try {
      await Hive.deleteBoxFromDisk(ComparisonRepository.boxName);
    } catch (_) {}
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('ComparisonRepository', () {
    test('initializes successfully', () async {
      expect(repo.isInitialized, true);
    });

    test('add item to comparison', () async {
      final product = ProductModel(
        id: 'comp_1',
        image: 'https://example.com/image.jpg',
        brandName: 'TestBrand',
        title: 'Test Product',
        price: 99.99,
      );
      final item = ComparisonItem(id: product.id, product: product);

      final success = await repo.add(item);

      expect(success, true);
      expect(repo.contains('comp_1'), true);
      expect(repo.count(), 1);
    });

    test('respects 4-item maximum limit', () async {
      // Add 4 items (should succeed)
      for (int i = 1; i <= 4; i++) {
        final product = ProductModel(
          id: 'comp_limit_$i',
          image: 'https://example.com/image$i.jpg',
          brandName: 'Brand$i',
          title: 'Product $i',
          price: 50.0 * i,
        );
        final item = ComparisonItem(id: product.id, product: product);
        final success = await repo.add(item);
        expect(success, true);
      }

      expect(repo.count(), 4);
      expect(repo.isFull(), true);

      // Try to add 5th item (should fail)
      final product5 = ProductModel(
        id: 'comp_limit_5',
        image: 'https://example.com/image5.jpg',
        brandName: 'Brand5',
        title: 'Product 5',
        price: 250.0,
      );
      final item5 = ComparisonItem(id: product5.id, product: product5);
      final success5 = await repo.add(item5);

      expect(success5, false);
      expect(repo.count(), 4); // Should still be 4
      expect(repo.contains('comp_limit_5'), false);
    });

    test('allows replacing an item when at capacity', () async {
      // Add 4 items
      for (int i = 1; i <= 4; i++) {
        final product = ProductModel(
          id: 'comp_replace_$i',
          image: 'https://example.com/image$i.jpg',
          brandName: 'Brand$i',
          title: 'Product $i',
          price: 50.0 * i,
        );
        await repo.add(ComparisonItem(id: product.id, product: product));
      }

      // Replace first item
      final product1 = ProductModel(
        id: 'comp_replace_1',
        image: 'https://example.com/image_new.jpg',
        brandName: 'BrandNew',
        title: 'Product New',
        price: 999.99,
      );
      final success = await repo.add(ComparisonItem(id: product1.id, product: product1));

      expect(success, true);
      expect(repo.count(), 4);
    });

    test('remove item from comparison', () async {
      final product = ProductModel(
        id: 'comp_remove',
        image: 'https://example.com/image.jpg',
        brandName: 'TestBrand',
        title: 'Test Product',
        price: 99.99,
      );
      await repo.add(ComparisonItem(id: product.id, product: product));

      expect(repo.contains('comp_remove'), true);

      await repo.remove('comp_remove');

      expect(repo.contains('comp_remove'), false);
    });

    test('get all comparison items', () async {
      final product1 = ProductModel(
        id: 'comp_getall_1',
        image: 'https://example.com/image1.jpg',
        brandName: 'Brand1',
        title: 'Product 1',
        price: 50.0,
      );
      final product2 = ProductModel(
        id: 'comp_getall_2',
        image: 'https://example.com/image2.jpg',
        brandName: 'Brand2',
        title: 'Product 2',
        price: 75.0,
      );

      await repo.add(ComparisonItem(id: product1.id, product: product1));
      await repo.add(ComparisonItem(id: product2.id, product: product2));

      final items = repo.getAll();

      expect(items.length, 2);
      expect(items.any((item) => item.product.id == 'comp_getall_1'), true);
      expect(items.any((item) => item.product.id == 'comp_getall_2'), true);
    });

    test('clear all comparison items', () async {
      for (int i = 1; i <= 3; i++) {
        final product = ProductModel(
          id: 'comp_clear_$i',
          image: 'https://example.com/image$i.jpg',
          brandName: 'Brand$i',
          title: 'Product $i',
          price: 50.0 * i,
        );
        await repo.add(ComparisonItem(id: product.id, product: product));
      }

      expect(repo.count(), 3);

      await repo.clear();

      expect(repo.count(), 0);
      expect(repo.getAll(), isEmpty);
      expect(repo.isFull(), false);
    });

    test('isFull returns correct status', () async {
      expect(repo.isFull(), false);

      for (int i = 1; i <= 3; i++) {
        final product = ProductModel(
          id: 'comp_full_$i',
          image: 'https://example.com/image$i.jpg',
          brandName: 'Brand$i',
          title: 'Product $i',
          price: 50.0 * i,
        );
        await repo.add(ComparisonItem(id: product.id, product: product));
        expect(repo.isFull(), false);
      }

      // Add 4th item
      final product4 = ProductModel(
        id: 'comp_full_4',
        image: 'https://example.com/image4.jpg',
        brandName: 'Brand4',
        title: 'Product 4',
        price: 200.0,
      );
      await repo.add(ComparisonItem(id: product4.id, product: product4));

      expect(repo.isFull(), true);
    });

    test('persists data across repository instances', () async {
      final product = ProductModel(
        id: 'comp_persist',
        image: 'https://example.com/image.jpg',
        brandName: 'TestBrand',
        title: 'Test Product',
        price: 99.99,
      );
      await repo.add(ComparisonItem(id: product.id, product: product));

      // Create new instance and verify data persists
      final repo2 = ComparisonRepository();
      await repo2.init();

      expect(repo2.contains('comp_persist'), true);
      expect(repo2.count(), 1);
    });

    test('maxItems constant equals 4', () {
      expect(ComparisonRepository.maxItems, 4);
    });

    test('count returns correct number', () async {
      expect(repo.count(), 0);

      for (int i = 1; i <= 4; i++) {
        final product = ProductModel(
          id: 'comp_count_$i',
          image: 'https://example.com/image$i.jpg',
          brandName: 'Brand$i',
          title: 'Product $i',
          price: 50.0 * i,
        );
        await repo.add(ComparisonItem(id: product.id, product: product));
        expect(repo.count(), i);
      }
    });
  });
}
