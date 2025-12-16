import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shop/repositories/wishlist_repository.dart';
import 'package:shop/models/wishlist_item.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    // Initialize Hive for tests using a temp directory to avoid plugin calls.
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    // Clean up the test box after each test run.
    try {
      await Hive.deleteBoxFromDisk(WishlistRepository.boxName);
    } catch (_) {}
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('add/get/remove wishlist item', () async {
    final repo = WishlistRepository();
    await repo.init();

    final item = WishlistItem(id: 'p1', title: 'Test Product', price: 9.99, imageUrl: null);
    await repo.add(item);

    expect(repo.contains('p1'), isTrue);

    final items = repo.getAll();
    expect(items.length, 1);
    expect(items.first.id, 'p1');

    await repo.remove('p1');
    expect(repo.contains('p1'), isFalse);
  });
}
