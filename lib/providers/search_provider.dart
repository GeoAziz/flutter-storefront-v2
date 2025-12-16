/// Riverpod providers for Phase 5 search functionality
/// 
/// Manages search state including debounced input, filters, sorting,
/// results pagination, and suggestions overlay.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/repository/search_cache.dart';
import 'package:shop/repository/search_repository.dart';
import 'package:shop/services/cache/hive_cache.dart';
import 'package:shop/services/service_locator.dart' show cacheProvider;

// ============================================================================
// Repositories & Services
// ============================================================================

/// Provides the SearchRepository singleton
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  // Use MockSearchRepository for MVP - will be replaced with API version
  return MockSearchRepository();
});

/// Provides the SearchCache singleton
final searchCacheProvider = Provider<SearchCache>((ref) {
  final cache = cacheProvider as HiveCache;
  return SearchCache(cache);
});

// ============================================================================
// Filter State Providers
// ============================================================================

/// Raw search text input (not debounced)
final searchTextProvider = StateProvider<String>((ref) => '');

/// Selected category filters
final selectedCategoriesProvider =
    StateProvider<Set<String>>((ref) => const {});

/// Selected price range filter
final selectedPriceRangeProvider =
    StateProvider<PriceRange?>((ref) => null);

/// Selected minimum rating filter
final selectedMinRatingProvider = StateProvider<double?>((ref) => null);

/// Selected sort order
final searchSortByProvider = StateProvider<SearchSortBy>((ref) {
  return SearchSortBy.relevance;
});

/// Pagination cursor for infinite scroll
final searchCursorProvider = StateProvider<String?>((ref) => null);

/// Page size for search results
final searchPageSizeProvider = StateProvider<int>((ref) => 20);

// ============================================================================
// Computed State Providers
// ============================================================================

/// Debounced search query (computed from filters and text)
/// 
/// Debounces text input by 300ms to avoid excessive API calls
final searchQueryProvider = FutureProvider<SearchQuery>((ref) async {
  final text = ref.watch(searchTextProvider);
  final categories = ref.watch(selectedCategoriesProvider);
  final priceRange = ref.watch(selectedPriceRangeProvider);
  final minRating = ref.watch(selectedMinRatingProvider);
  final sortBy = ref.watch(searchSortByProvider);
  final pageSize = ref.watch(searchPageSizeProvider);
  final cursor = ref.watch(searchCursorProvider);

  // Wait for debounce (300ms)
  await Future.delayed(const Duration(milliseconds: 300));

  return SearchQuery(
    text: text.isEmpty ? null : text,
    categories: categories.isEmpty ? null : categories,
    priceRange: priceRange,
    minRating: minRating,
    sortBy: sortBy,
    pageSize: pageSize,
    cursor: cursor,
  );
});

// ============================================================================
// Data Providers
// ============================================================================

/// Fetch search results based on current query
final searchResultsProvider =
    FutureProvider.autoDispose<SearchResult>((ref) async {
  final repository = ref.watch(searchRepositoryProvider);
  final cache = ref.watch(searchCacheProvider);
  final query = await ref.watch(searchQueryProvider.future);

  // Check cache first
  final cached = await cache.getSearchResult(query);
  if (cached != null) {
    return cached;
  }

  // Fetch from repository
  final result = await repository.search(query);

  // Cache the result
  await cache.setSearchResult(query, result);

  return result;
});

/// Fetch search suggestions based on text input
final searchSuggestionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final repository = ref.watch(searchRepositoryProvider);
  final cache = ref.watch(searchCacheProvider);
  final text = ref.watch(searchTextProvider);

  if (text.isEmpty) return [];

  // Check cache first
  final cached = await cache.getSuggestions(text);
  if (cached != null) {
    return cached;
  }

  // Fetch from repository
  final suggestions = await repository.getSuggestions(text);

  // Cache the suggestions
  await cache.setSuggestions(text, suggestions);

  return suggestions;
});

/// Fetch available categories for the filter UI
final availableCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryOption>>((ref) async {
  final repository = ref.watch(searchRepositoryProvider);
  return repository.getCategories();
});

/// Fetch available price range for the filter UI
final availablePriceRangeProvider =
    FutureProvider.autoDispose<PriceRange>((ref) async {
  final repository = ref.watch(searchRepositoryProvider);
  return repository.getPriceRange();
});

/// Fetch available filters (categories + price range combined)
final availableFiltersProvider =
    FutureProvider.autoDispose<AvailableFilters>((ref) async {
  final repository = ref.watch(searchRepositoryProvider);
  final cache = ref.watch(searchCacheProvider);

  // Check cache first
  final cached = await cache.getAvailableFilters();
  if (cached != null) {
    return cached;
  }

  // Fetch from repository
  final filters = await repository.getAvailableFilters();

  // Cache the result
  await cache.setAvailableFilters(filters);

  return filters;
});

// ============================================================================
// UI State Providers
// ============================================================================

/// Whether the search suggestions overlay is visible
final showSuggestionsProvider = StateProvider<bool>((ref) => false);

/// Whether the filter panel is expanded
final showFilterPanelProvider = StateProvider<bool>((ref) => false);

/// Track if search has been initiated
final hasSearchedProvider = StateProvider<bool>((ref) => false);

// ============================================================================
// Utility Providers
// ============================================================================

/// Check if any filters are active
final hasActiveFiltersProvider = Provider<bool>((ref) {
  final categories = ref.watch(selectedCategoriesProvider);
  final priceRange = ref.watch(selectedPriceRangeProvider);
  final minRating = ref.watch(selectedMinRatingProvider);
  final text = ref.watch(searchTextProvider);

  return text.isNotEmpty ||
      categories.isNotEmpty ||
      priceRange != null ||
      minRating != null;
});

/// Reset all search filters
final resetSearchProvider = Provider<void>((ref) {
  ref.read(searchTextProvider.notifier).state = '';
  ref.read(selectedCategoriesProvider.notifier).state = const {};
  ref.read(selectedPriceRangeProvider.notifier).state = null;
  ref.read(selectedMinRatingProvider.notifier).state = null;
  ref.read(searchSortByProvider.notifier).state = SearchSortBy.relevance;
  ref.read(searchCursorProvider.notifier).state = null;
  ref.read(showSuggestionsProvider.notifier).state = false;
  ref.read(showFilterPanelProvider.notifier).state = false;
  ref.read(hasSearchedProvider.notifier).state = false;
});

/// Toggle a category filter
final toggleCategoryProvider = Provider<void Function(String)>((ref) {
  return (String categoryId) {
    final current = ref.read(selectedCategoriesProvider);
    if (current.contains(categoryId)) {
      ref.read(selectedCategoriesProvider.notifier).state =
          current.where((id) => id != categoryId).toSet();
    } else {
      ref.read(selectedCategoriesProvider.notifier).state = {
        ...current,
        categoryId
      };
    }
  };
});

/// Update the price range filter
final setPriceRangeProvider = Provider<void Function(PriceRange)>((ref) {
  return (PriceRange range) {
    ref.read(selectedPriceRangeProvider.notifier).state = range;
  };
});

/// Update the minimum rating filter
final setMinRatingProvider = Provider<void Function(double?)>((ref) {
  return (double? rating) {
    ref.read(selectedMinRatingProvider.notifier).state = rating;
  };
});

/// Update the sort order
final setSortByProvider = Provider<void Function(SearchSortBy)>((ref) {
  return (SearchSortBy sort) {
    ref.read(searchSortByProvider.notifier).state = sort;
  };
});

/// Update search text with debounce
final setSearchTextProvider = Provider<void Function(String)>((ref) {
  return (String text) {
    ref.read(searchTextProvider.notifier).state = text;
    ref.read(hasSearchedProvider.notifier).state = text.isNotEmpty;
    
    // Show suggestions if text is not empty
    if (text.isNotEmpty) {
      ref.read(showSuggestionsProvider.notifier).state = true;
    } else {
      ref.read(showSuggestionsProvider.notifier).state = false;
    }
  };
});
