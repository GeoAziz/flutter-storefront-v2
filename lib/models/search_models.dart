/// Search domain models and DTOs for Phase 5 enhancement
/// 
/// Provides immutable, well-typed abstractions for search queries,
/// filters, results, and caching strategy.

import 'package:shop/repository/pagination.dart';
import 'package:shop/repository/product_repository.dart';

/// Defines the sorting strategy for search results
enum SearchSortBy {
  relevance,
  popularity,
  priceAsc,
  priceDesc,
  ratingDesc,
  newest,
}

/// Represents a price range with min and max bounds
class PriceRange {
  final double min;
  final double max;

  const PriceRange({required this.min, required this.max});

  /// Create a copy with optional field overrides
  PriceRange copyWith({double? min, double? max}) {
    return PriceRange(
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceRange &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => min.hashCode ^ max.hashCode;

  @override
  String toString() => 'PriceRange(min: $min, max: $max)';
}

/// Represents a search query with optional filters and sorting
class SearchQuery {
  final String? text; // e.g., "blue shirt"
  final Set<String>? categories; // e.g., ['electronics', 'clothing']
  final PriceRange? priceRange;
  final double? minRating; // e.g., 4.0 means >= 4.0 stars
  final SearchSortBy sortBy;
  final int pageSize;
  final String? cursor; // for pagination

  const SearchQuery({
    this.text,
    this.categories,
    this.priceRange,
    this.minRating,
    this.sortBy = SearchSortBy.relevance,
    this.pageSize = 20,
    this.cursor,
  });

  /// True if no filters are active (empty search)
  bool get isEmpty =>
      text == null &&
      categories == null &&
      priceRange == null &&
      minRating == null;

  /// True if any filters are active
  bool get hasFilters => !isEmpty;

  /// Generate a cache key for this query
  String toCacheKey() {
    final parts = [
      text ?? 'all',
      categories?.toList().join(',') ?? '',
      priceRange != null ? '${priceRange!.min}-${priceRange!.max}' : '',
      minRating?.toString() ?? '',
      sortBy.toString(),
    ];
    return parts.join('|');
  }

  /// Create a copy with optional field overrides
  SearchQuery copyWith({
    String? text,
    Set<String>? categories,
    PriceRange? priceRange,
    double? minRating,
    SearchSortBy? sortBy,
    int? pageSize,
    String? cursor,
  }) {
    return SearchQuery(
      text: text ?? this.text,
      categories: categories ?? this.categories,
      priceRange: priceRange ?? this.priceRange,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
      pageSize: pageSize ?? this.pageSize,
      cursor: cursor ?? this.cursor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchQuery &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          categories == other.categories &&
          priceRange == other.priceRange &&
          minRating == other.minRating &&
          sortBy == other.sortBy &&
          pageSize == other.pageSize &&
          cursor == other.cursor;

  @override
  int get hashCode =>
      text.hashCode ^
      categories.hashCode ^
      priceRange.hashCode ^
      minRating.hashCode ^
      sortBy.hashCode ^
      pageSize.hashCode ^
      cursor.hashCode;

  @override
  String toString() =>
      'SearchQuery(text: $text, categories: $categories, priceRange: $priceRange, minRating: $minRating, sortBy: $sortBy)';
}

/// Represents active search filters
class SearchFilter {
  final Set<String> selectedCategories;
  final PriceRange? priceRange;
  final double? minRating;

  const SearchFilter({
    Set<String>? selectedCategories,
    this.priceRange,
    this.minRating,
  }) : selectedCategories = selectedCategories ?? const {};

  /// True if any filters are active
  bool get hasActiveFilters =>
      selectedCategories.isNotEmpty ||
      priceRange != null ||
      minRating != null;

  /// Create a copy with optional field overrides
  SearchFilter copyWith({
    Set<String>? selectedCategories,
    PriceRange? priceRange,
    double? minRating,
  }) {
    return SearchFilter(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      priceRange: priceRange ?? this.priceRange,
      minRating: minRating ?? this.minRating,
    );
  }

  /// Clear all filters
  SearchFilter clearAll() {
    return const SearchFilter();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilter &&
          runtimeType == other.runtimeType &&
          selectedCategories == other.selectedCategories &&
          priceRange == other.priceRange &&
          minRating == other.minRating;

  @override
  int get hashCode =>
      selectedCategories.hashCode ^
      priceRange.hashCode ^
      minRating.hashCode;

  @override
  String toString() =>
      'SearchFilter(categories: $selectedCategories, priceRange: $priceRange, minRating: $minRating)';
}

/// Represents a category option with count
class CategoryOption {
  final String id;
  final String name;
  final int count;

  const CategoryOption({
    required this.id,
    required this.name,
    required this.count,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          count == other.count;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ count.hashCode;

  @override
  String toString() => 'CategoryOption(id: $id, name: $name, count: $count)';
}

/// Available filter options for UI population
class AvailableFilters {
  final List<CategoryOption> categories;
  final PriceRange priceRange;

  const AvailableFilters({
    required this.categories,
    required this.priceRange,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailableFilters &&
          runtimeType == other.runtimeType &&
          categories == other.categories &&
          priceRange == other.priceRange;

  @override
  int get hashCode => categories.hashCode ^ priceRange.hashCode;

  @override
  String toString() =>
      'AvailableFilters(categories: ${categories.length}, priceRange: $priceRange)';
}

/// Extended search results with metadata
class SearchResult extends PaginationResult<Product> {
  final SearchQuery query;
  final int totalResults;
  final List<String> suggestedQueries; // ["blue shirt", "blue dress", ...]
  final Map<String, int> availableCategories; // {"electronics": 45, "clothing": 23}
  final PriceRange availablePriceRange; // actual min/max in filtered results

  SearchResult({
    required List<Product> items,
    required this.query,
    required this.totalResults,
    required this.suggestedQueries,
    required this.availableCategories,
    required this.availablePriceRange,
    String? nextCursor,
    bool hasMore = false,
    int? page,
    int? pageSize,
  }) : super(
    items: items,
    nextCursor: nextCursor,
    hasMore: hasMore,
    page: page,
    pageSize: pageSize,
  );

  /// Create an empty search result
  factory SearchResult.empty({
    required SearchQuery query,
  }) {
    return SearchResult(
      items: [],
      query: query,
      totalResults: 0,
      suggestedQueries: [],
      availableCategories: {},
      availablePriceRange: const PriceRange(min: 0, max: 0),
      hasMore: false,
    );
  }

  /// Create a copy with optional field overrides
  SearchResult copyWith({
    List<Product>? items,
    SearchQuery? query,
    int? totalResults,
    List<String>? suggestedQueries,
    Map<String, int>? availableCategories,
    PriceRange? availablePriceRange,
    String? nextCursor,
    bool? hasMore,
    int? page,
    int? pageSize,
  }) {
    return SearchResult(
      items: items ?? this.items,
      query: query ?? this.query,
      totalResults: totalResults ?? this.totalResults,
      suggestedQueries: suggestedQueries ?? this.suggestedQueries,
      availableCategories: availableCategories ?? this.availableCategories,
      availablePriceRange: availablePriceRange ?? this.availablePriceRange,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  String toString() =>
      'SearchResult(items: ${items.length}, totalResults: $totalResults, query: $query)';
}
