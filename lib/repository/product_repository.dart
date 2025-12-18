// Minimal ProductRepository abstraction and two simple implementations
import 'package:shop/repository/pagination.dart';

class Product {
  final String id;
  final String title;
  final String image;
  final double price;
  final String? category;
  final double? priceAfterDiscount;
  final int? discountPercent;

  Product({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
    this.priceAfterDiscount,
    this.discountPercent,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image': image,
        'price': price,
        'priceAfterDiscount': priceAfterDiscount,
        'discountPercent': discountPercent,
  'category': category,
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
    category: m['category'] as String?,
      );
}

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();

  /// Fetches products using the specified pagination request (page or cursor based).
  /// Default implementation delegates to fetchProducts() for backward compatibility.
  Future<PaginationResult<Product>> fetchProductsPaginated(
    PaginationRequest request,
    {String? category}) async {
    if (request is PageRequest) {
    final products = await fetchProducts();
    final filtered = category == null
      ? products
      : products.where((p) => p.category == category).toList();
    final pageSize = request.pageSize;
    final page = request.page;
    final startIndex = (page - 1) * pageSize;
    final endIndex = ((startIndex + pageSize).clamp(0, filtered.length) as int);

    final items = startIndex >= filtered.length ? <Product>[] : filtered.sublist(startIndex, endIndex);
    final hasMore = endIndex < filtered.length;

      return PaginationResult(
        items: items,
        nextCursor: hasMore ? 'page_${page + 1}' : null,
        hasMore: hasMore,
        page: page,
        pageSize: pageSize,
      );
    }

    // Default implementation returns empty for cursor-based requests
    return PaginationResult.empty();
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
        category: 'On Sale',
        priceAfterDiscount: 79.99,
        discountPercent: 20,
      ),
      Product(
        id: 'p2',
        title: 'Mock Product 2',
        image: 'assets/images/product2.png',
        price: 149.99,
        category: 'Kids',
        priceAfterDiscount: null,
        discountPercent: null,
      ),
    ];
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request,
      {String? category}) async {
    if (request is PageRequest) {
      final products = await fetchProducts();
      final filtered = category == null
          ? products
          : products.where((p) => p.category == category).toList();
      final pageSize = request.pageSize;
      final page = request.page;
      final startIndex = (page - 1) * pageSize;
      final endIndex =
          ((startIndex + pageSize).clamp(0, filtered.length) as int);

      final items = startIndex >= filtered.length
          ? <Product>[]
          : filtered.sublist(startIndex, endIndex);
      final hasMore = endIndex < filtered.length;

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

class RealProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    // Placeholder for real network implementation. For now return empty list.
    return [];
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
    PaginationRequest request,
    {String? category}) async {
    if (request is PageRequest) {
    final products = await fetchProducts();
    final filtered = category == null
      ? products
      : products.where((p) => p.category == category).toList();
    final pageSize = request.pageSize;
    final page = request.page;
    final startIndex = (page - 1) * pageSize;
    final endIndex = ((startIndex + pageSize).clamp(0, filtered.length) as int);

    final items = startIndex >= filtered.length ? <Product>[] : filtered.sublist(startIndex, endIndex);
    final hasMore = endIndex < filtered.length;

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
