import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/product_pagination_provider.dart';
import 'package:shop/models/filter_params.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/repository/pagination.dart';

class ThrowingCursorRepo extends ProductRepository {
  @override
  Future<List<Product>> fetchProducts({int page = 1, int pageSize = 20}) async {
    // simple deterministic items per page
    final start = (page - 1) * pageSize;
    return List.generate(pageSize, (i) {
      final idx = start + i + 1;
      return Product(
          id: 'p$idx', title: 'Product $idx', image: '', price: 1.0 * idx);
    });
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request,
      {String? category}) async {
    if (request is PageRequest) {
      final items =
          await fetchProducts(page: request.page, pageSize: request.pageSize);
      final hasMore = items.length >= request.pageSize;
      // No cursor for page-based responses in this fake
      return PaginationResult(
          items: items,
          nextCursor: null,
          hasMore: hasMore,
          page: request.page,
          pageSize: request.pageSize);
    }
    if (request is CursorRequest) {
      // Simulate an initially-provided valid nextCursor in page 1 response,
      // but when the client later attempts to use it, the server rejects it.
      // To simulate this, if the cursor is null we act as the first-page
      // caller and return a nextCursor; otherwise we throw FormatException to
      // emulate an expired/invalid cursor.
      if (request.cursor == null) {
        final items = await fetchProducts(page: 1, pageSize: request.limit);
        final nextJson = jsonEncode({'offset': items.length});
        final nextCursor = base64.encode(utf8.encode(nextJson));
        return PaginationResult(
            items: items,
            nextCursor: nextCursor,
            hasMore: true,
            page: 1,
            pageSize: request.limit);
      }
      // Simulate invalid/expired cursor on usage
      throw const FormatException('cursor expired');
    }
    return PaginationResult(items: [], nextCursor: null, hasMore: false);
  }
}

void main() {
  group('ProductPaginationProvider invalid cursor handling', () {
    test('clears invalid cursor and retries with page-based fallback',
        () async {
      final repo = ThrowingCursorRepo();
      final container = ProviderContainer(overrides: [
        productRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final notifier = container
          .read(productPaginationProvider(const FilterParams()).notifier);

      // First, refresh to populate items and obtain a nextCursor from the repo
      await notifier.refresh();
      var state =
          container.read(productPaginationProvider(const FilterParams()));
      expect(state.items.isNotEmpty, true);
      final firstCount = state.items.length;
      expect(state.hasMore, true);

      // Next page will attempt to use cursor; our repo will throw FormatException
      // which should be handled by clearing the cursor and retrying a page-based fetch
      await notifier.fetchNextPage();
      state = container.read(productPaginationProvider(const FilterParams()));
      expect(state.items.length, greaterThan(firstCount));
      // No error should be surfaced to the state
      expect(state.error, isNull);
    });
  });
}
