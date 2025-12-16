// Minimal ProductRepository abstraction and two simple implementations
import 'package:shop/repository/pagination.dart';
import 'package:shop/services/service_locator.dart';
// telemetry_service type import intentionally omitted; use telemetryService getter.

class Product {
  final String id;
  final String title;
  final String image;
  final double price;
  final double? priceAfterDiscount;
  final int? discountPercent;

  Product({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
    this.priceAfterDiscount,
    this.discountPercent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image': image,
        'price': price,
        'priceAfterDiscount': priceAfterDiscount,
        'discountPercent': discountPercent,
      };

  factory Product.fromJson(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        title: m['title'] as String,
        image: m['image'] as String,
        price: (m['price'] as num).toDouble(),
        priceAfterDiscount: m['priceAfterDiscount'] == null
            ? null
            : (m['priceAfterDiscount'] as num).toDouble(),
        discountPercent: m['discountPercent'] as int?,
      );
}

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();

  /// Fetches products using the specified pagination request (page or cursor based).
  /// Default implementation delegates to fetchProducts() for backward compatibility.
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request) async {
    final telemetry = telemetryService;
    Object? span;
    try {
      span = await telemetry.startSpan('pagination');
      telemetry.logEvent('pagination_start', {
        'requestType': request.runtimeType.toString(),
        if (request is PageRequest) 'page': request.page,
        if (request is PageRequest) 'pageSize': request.pageSize,
        if (request is CursorRequest) 'cursor': request.cursor,
      });

      if (request is PageRequest) {
        final products = await fetchProducts();
        final pageSize = request.pageSize;
        final page = request.page;
        final startIndex = (page - 1) * pageSize;
        final endIndex =
            ((startIndex + pageSize).clamp(0, products.length) as int);

        final items = startIndex >= products.length
            ? <Product>[]
            : products.sublist(startIndex, endIndex);
        final hasMore = endIndex < products.length;

        telemetry.logEvent('pagination_success', {
          'items': items.length,
          'hasMore': hasMore,
          'page': page,
          'pageSize': pageSize,
        });

        return PaginationResult(
          items: items,
          nextCursor: hasMore ? 'page_${page + 1}' : null,
          hasMore: hasMore,
          page: page,
          pageSize: pageSize,
        );
      }

      // Default implementation returns empty for cursor-based requests
      telemetry.logEvent('pagination_success', {'items': 0, 'hasMore': false});
      return PaginationResult.empty();
    } catch (e, st) {
      try {
        telemetry.captureException(e, st,
            context: {'request': request.runtimeType.toString()});
        telemetry.logEvent('pagination_error', {'error': e.toString()});
      } catch (_) {}
      rethrow;
    } finally {
      try {
        await telemetry.finishSpan(span);
      } catch (_) {}
    }
  }
}

class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    // return a tiny, deterministic list for tests and local dev
    return [
      Product(
        id: 'p1',
        title: 'Mock Product 1',
        image: 'assets/images/product1.png',
        price: 99.99,
        priceAfterDiscount: 79.99,
        discountPercent: 20,
      ),
      Product(
        id: 'p2',
        title: 'Mock Product 2',
        image: 'assets/images/product2.png',
        price: 149.99,
        priceAfterDiscount: null,
        discountPercent: null,
      ),
    ];
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request) async {
    final telemetry = telemetryService;
    Object? span;
    try {
      span = await telemetry.startSpan('pagination');
      telemetry.logEvent('pagination_start', {
        'requestType': request.runtimeType.toString(),
        if (request is PageRequest) 'page': request.page
      });

      if (request is PageRequest) {
        final products = await fetchProducts();
        final pageSize = request.pageSize;
        final page = request.page;
        final startIndex = (page - 1) * pageSize;
        final endIndex =
            ((startIndex + pageSize).clamp(0, products.length) as int);

        final items = startIndex >= products.length
            ? <Product>[]
            : products.sublist(startIndex, endIndex);
        final hasMore = endIndex < products.length;

        telemetry.logEvent('pagination_success',
            {'items': items.length, 'hasMore': hasMore, 'page': page});

        return PaginationResult(
          items: items,
          nextCursor: hasMore ? 'page_${page + 1}' : null,
          hasMore: hasMore,
          page: page,
          pageSize: pageSize,
        );
      }

      telemetry.logEvent('pagination_success', {'items': 0, 'hasMore': false});
      return PaginationResult.empty();
    } catch (e, st) {
      try {
        telemetry.captureException(e, st,
            context: {'request': request.runtimeType.toString()});
        telemetry.logEvent('pagination_error', {'error': e.toString()});
      } catch (_) {}
      rethrow;
    } finally {
      try {
        await telemetry.finishSpan(span);
      } catch (_) {}
    }
  }
}

class RealProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    // Placeholder for real network implementation. For now return empty list.
    return [];
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request) async {
    final telemetry = telemetryService;
    Object? span;
    try {
      span = await telemetry.startSpan('pagination');
      telemetry.logEvent('pagination_start', {
        'requestType': request.runtimeType.toString(),
        if (request is PageRequest) 'page': request.page
      });

      if (request is PageRequest) {
        final products = await fetchProducts();
        final pageSize = request.pageSize;
        final page = request.page;
        final startIndex = (page - 1) * pageSize;
        final endIndex =
            ((startIndex + pageSize).clamp(0, products.length) as int);

        final items = startIndex >= products.length
            ? <Product>[]
            : products.sublist(startIndex, endIndex);
        final hasMore = endIndex < products.length;

        telemetry.logEvent('pagination_success',
            {'items': items.length, 'hasMore': hasMore, 'page': page});

        return PaginationResult(
          items: items,
          nextCursor: hasMore ? 'page_${page + 1}' : null,
          hasMore: hasMore,
          page: page,
          pageSize: pageSize,
        );
      }

      telemetry.logEvent('pagination_success', {'items': 0, 'hasMore': false});
      return PaginationResult.empty();
    } catch (e, st) {
      try {
        telemetry.captureException(e, st,
            context: {'request': request.runtimeType.toString()});
        telemetry.logEvent('pagination_error', {'error': e.toString()});
      } catch (_) {}
      rethrow;
    } finally {
      try {
        await telemetry.finishSpan(span);
      } catch (_) {}
    }
  }
}
