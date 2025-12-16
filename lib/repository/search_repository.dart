/// Search Repository abstraction for Phase 5
/// 
/// Defines the interface for search operations, including querying,
/// suggestions, and available filter metadata.

import 'package:shop/models/search_models.dart';
import 'package:shop/repository/product_repository.dart';

/// Abstract repository for search operations
/// 
/// Implementations can provide mock (in-memory) or real (API-based) search.
abstract class SearchRepository {
  /// Perform a search with optional filters and sorting
  /// 
  /// Returns a SearchResult with items, metadata, and pagination cursor.
  Future<SearchResult> search(SearchQuery query);

  /// Get search suggestions based on partial text input
  /// 
  /// Used for auto-complete in SearchInputField.
  /// Returns list of suggested queries (e.g., ["blue shirt", "blue jeans", ...])
  Future<List<String>> getSuggestions(String partial);

  /// Get available categories for filter UI
  /// 
  /// Returns list of CategoryOption with counts.
  Future<List<CategoryOption>> getCategories();

  /// Get price range bounds for the current product catalog
  /// 
  /// Used to set min/max limits on PriceRangeSlider.
  Future<PriceRange> getPriceRange();

  /// Get available filters (categories + price range combined)
  /// 
  /// Convenience method to fetch both in one call.
  Future<AvailableFilters> getAvailableFilters() async {
    final categories = await getCategories();
    final priceRange = await getPriceRange();
    return AvailableFilters(
      categories: categories,
      priceRange: priceRange,
    );
  }
}

/// Mock implementation of SearchRepository for MVP and testing
/// 
/// Performs in-memory search/filtering on a deterministic product list.
class MockSearchRepository implements SearchRepository {
  final List<Product> _allProducts;

  MockSearchRepository({List<Product>? products})
      : _allProducts = products ?? _generateMockProducts();

  static List<Product> _generateMockProducts() {
    // Generate a diverse set of mock products with categories and ratings
    return [
      Product(
        id: 'p1',
        title: 'Blue Cotton T-Shirt',
        image: 'assets/images/product1.png',
        price: 29.99,
        priceAfterDiscount: 24.99,
        discountPercent: 17,
      ),
      Product(
        id: 'p2',
        title: 'Black Denim Jeans',
        image: 'assets/images/product2.png',
        price: 79.99,
        priceAfterDiscount: null,
        discountPercent: null,
      ),
      Product(
        id: 'p3',
        title: 'Running Shoes Sneaker',
        image: 'assets/images/product3.png',
        price: 99.99,
        priceAfterDiscount: 79.99,
        discountPercent: 20,
      ),
      Product(
        id: 'p4',
        title: 'Winter Wool Jacket',
        image: 'assets/images/product4.png',
        price: 149.99,
        priceAfterDiscount: 119.99,
        discountPercent: 20,
      ),
      Product(
        id: 'p5',
        title: 'Blue Denim Jacket',
        image: 'assets/images/product5.png',
        price: 89.99,
        priceAfterDiscount: 69.99,
        discountPercent: 22,
      ),
    ];
  }

  @override
  Future<SearchResult> search(SearchQuery query) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    var results = List<Product>.from(_allProducts);

    // Filter by text (simple substring match)
    if (query.text != null && query.text!.isNotEmpty) {
      final lowerText = query.text!.toLowerCase();
      results = results
          .where(
            (p) =>
                p.title.toLowerCase().contains(lowerText) ||
                p.id.toLowerCase().contains(lowerText),
          )
          .toList();
    }

    // Apply price filter
    if (query.priceRange != null) {
      results = results
          .where(
            (p) =>
                p.price >= query.priceRange!.min &&
                p.price <= query.priceRange!.max,
          )
          .toList();
    }

    // Apply sorting
    switch (query.sortBy) {
      case SearchSortBy.relevance:
        // Already in order
        break;
      case SearchSortBy.popularity:
        // Mock: just reverse order
        results.sort((a, b) => b.id.compareTo(a.id));
        break;
      case SearchSortBy.priceAsc:
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SearchSortBy.priceDesc:
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SearchSortBy.ratingDesc:
        // Mock: just keep order (no ratings in test data)
        break;
      case SearchSortBy.newest:
        // Mock: just keep order (no dates in test data)
        break;
    }

    // Pagination
    final pageSize = query.pageSize;
    final start = 0;
    final end = (start + pageSize).clamp(0, results.length);
    final paginatedItems =
        results.sublist(start, end < results.length ? end : results.length);
    final hasMore = end < results.length;

    return SearchResult(
      items: paginatedItems,
      query: query,
      totalResults: results.length,
      suggestedQueries: _generateSuggestions(query.text ?? ''),
      availableCategories: _generateAvailableCategories(results),
      availablePriceRange: _getAvailablePriceRange(results),
      nextCursor: hasMore ? 'cursor_p2' : null,
      hasMore: hasMore,
      page: 1,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<String>> getSuggestions(String partial) async {
    if (partial.isEmpty) return [];

    // Simple mock: return suggestions based on product titles
    await Future.delayed(const Duration(milliseconds: 100));

    final lowerPartial = partial.toLowerCase();
    return _allProducts
        .where((p) => p.title.toLowerCase().contains(lowerPartial))
        .map((p) => p.title)
        .take(5)
        .toList();
  }

  @override
  Future<List<CategoryOption>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Mock categories
    return [
      const CategoryOption(id: 'clothing', name: 'Clothing', count: 45),
      const CategoryOption(id: 'electronics', name: 'Electronics', count: 23),
      const CategoryOption(id: 'shoes', name: 'Shoes', count: 18),
      const CategoryOption(id: 'accessories', name: 'Accessories', count: 12),
    ];
  }

  @override
  Future<PriceRange> getPriceRange() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const PriceRange(min: 9.99, max: 299.99);
  }

  @override
  Future<AvailableFilters> getAvailableFilters() async {
    final categories = await getCategories();
    final priceRange = await getPriceRange();
    return AvailableFilters(
      categories: categories,
      priceRange: priceRange,
    );
  }

  /// Helper: generate suggested queries (mock)
  List<String> _generateSuggestions(String text) {
    if (text.isEmpty) return [];
    return ['$text shirt', '$text jeans', '$text shoes'];
  }

  /// Helper: extract available categories from filtered results
  Map<String, int> _generateAvailableCategories(List<Product> items) {
    // Mock: return category counts
    return {
      'clothing': 15,
      'shoes': 8,
      'accessories': 5,
    };
  }

  /// Helper: calculate price range from filtered results
  PriceRange _getAvailablePriceRange(List<Product> items) {
    if (items.isEmpty) return const PriceRange(min: 0, max: 0);
    final prices = items.map((p) => p.price);
    return PriceRange(
      min: prices.reduce((a, b) => a < b ? a : b),
      max: prices.reduce((a, b) => a > b ? a : b),
    );
  }
}
