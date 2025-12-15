import 'dart:convert';

import 'package:shop/repository/product_repository.dart';
import 'package:shop/repository/pagination.dart';

/// A small stub implementation of [ProductRepository]. This returns a
/// deterministic list of products suitable for local development and tests.
class RealProductRepository extends ProductRepository {
  @override
  Future<List<Product>> fetchProducts({int page = 1, int pageSize = 20}) async {
    // In a real implementation this would call an API. For now return a
    // deterministic list so screens and tests can rely on it. We respect
    // pagination parameters by slicing the deterministic list.
    await Future.delayed(const Duration(milliseconds: 50));
    final all = [
      Product(
        id: 'real1',
        title: 'Real Stub Product 1',
        image: 'assets/images/product_real_1.png',
        price: 39.99,
        priceAfterDiscount: 29.99,
        discountPercent: 25,
      ),
      Product(
        id: 'real2',
        title: 'Real Stub Product 2',
        image: 'assets/images/product_real_2.png',
        price: 59.99,
        priceAfterDiscount: null,
        discountPercent: null,
      ),
    ];

    final start = (page - 1) * pageSize;
    if (start >= all.length) return [];
    final end = (start + pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(PaginationRequest request) async {
    // PageRequest: delegate to existing page-based helper (backwards compatible)
    if (request is PageRequest) return super.fetchProductsPaginated(request);

    // CursorRequest: interim client-side implementation that assumes the
    // backend returns an opaque base64-encoded JSON cursor containing an
    // `offset` integer (e.g. {"offset":20}). This is only an interim
    // assumption; when the backend confirms the cursor format we'll adapt
    // the parser accordingly.
    if (request is CursorRequest) {
      var offset = 0;
      if (request.cursor != null) {
        try {
          final decoded = utf8.decode(base64.decode(request.cursor!));
          final json = jsonDecode(decoded) as Map<String, dynamic>;
          offset = (json['offset'] as int?) ?? 0;
        } catch (_) {
          // Invalid/unknown cursor format: fall back to start (offset 0)
          offset = 0;
        }
      }

      // Map offset + limit into the existing page/size semantics. We compute
      // the page index that contains `offset` under `limit` page size.
      final pageSize = request.limit;
      final page = (offset ~/ pageSize) + 1;
      final items = await fetchProducts(page: page, pageSize: pageSize);
      
      // Determine if there are more items by checking if we got a full page
      // AND if the next page would return any items.
      String? nextCursor;
      bool hasMore = false;
      if (items.length >= pageSize) {
        // We got a full page; check if there's a next page
        final nextPageItems = await fetchProducts(page: page + 1, pageSize: pageSize);
        if (nextPageItems.isNotEmpty) {
          hasMore = true;
          final nextOffset = offset + items.length;
          final nextJson = jsonEncode({'offset': nextOffset});
          nextCursor = base64.encode(utf8.encode(nextJson));
        }
      }

      return PaginationResult(items: items, nextCursor: nextCursor, hasMore: hasMore, page: page, pageSize: pageSize);
    }

    return PaginationResult(items: [], nextCursor: null, hasMore: false);
  }
}
