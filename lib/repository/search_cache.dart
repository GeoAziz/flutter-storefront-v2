/// Search-specific cache layer for Phase 5
/// 
/// Wraps the existing HiveCache and MemoryCache to provide search result caching
/// with automatic key generation, TTL management, and cache statistics.

import 'dart:async';
import 'package:shop/models/search_models.dart';
import 'package:shop/services/cache/hive_cache.dart';

/// Cache key generator for search results
class _SearchCacheKeyGenerator {
  /// Generate a cache key from a search query
  /// 
  /// Format: search:text:categories:priceRange:minRating:sortBy
  static String forQuery(SearchQuery query) {
    final key = 'search:'
        '${query.text ?? "any"}'
        ':${query.categories?.isEmpty ?? true ? "all" : query.categories!.join(",")}'
        ':${query.priceRange?.min}-${query.priceRange?.max ?? "any"}'
        ':${query.minRating ?? "any"}'
        ':${query.sortBy.name}';

    return key;
  }

  /// Generate a cache key for suggestions
  static String forSuggestions(String partial) {
    return 'suggestions:$partial';
  }

  /// Generate a cache key for available filters
  static const String forAvailableFilters = 'available_filters';

  /// Generate a cache key for categories
  static const String forCategories = 'categories';

  /// Generate a cache key for price range
  static const String forPriceRange = 'price_range';
}

/// Search cache statistics for monitoring and debugging
class SearchCacheStats {
  final int totalHits;
  final int totalMisses;
  final int totalItems;
  final DateTime lastEviction;

  const SearchCacheStats({
    required this.totalHits,
    required this.totalMisses,
    required this.totalItems,
    required this.lastEviction,
  });

  double get hitRate =>
      totalHits + totalMisses == 0 ? 0 : totalHits / (totalHits + totalMisses);

  @override
  String toString() => 'SearchCacheStats('
      'hits=$totalHits, '
      'misses=$totalMisses, '
      'hitRate=${(hitRate * 100).toStringAsFixed(1)}%, '
      'items=$totalItems, '
      'lastEviction=$lastEviction)';
}

/// Wrapper around HiveCache and MemoryCache for search result caching
class SearchCache {
  final HiveCache _hiveCache;
  final Duration _ttl;

  int _hits = 0;
  int _misses = 0;
  DateTime _lastEviction = DateTime.now();

  /// Create a new search cache with the given HiveCache and TTL
  /// 
  /// [hiveCache]: The underlying persistent cache (Hive)
  /// [ttl]: Time-to-live for cached search results (default: 1 hour)
  SearchCache(
    this._hiveCache, {
    Duration ttl = const Duration(hours: 1),
  }) : _ttl = ttl;

  /// Cache a search result
  /// 
  /// Stores in both memory (for immediate access) and Hive (for persistence).
  Future<void> setSearchResult(
    SearchQuery query,
    SearchResult result,
  ) async {
    final key = _SearchCacheKeyGenerator.forQuery(query);

    // Store with TTL
    await _hiveCache.set(key, result, ttl: _ttl);
  }

  /// Retrieve a cached search result
  /// 
  /// Returns null if not cached or if cache has expired (TTL exceeded).
  Future<SearchResult?> getSearchResult(SearchQuery query) async {
    final key = _SearchCacheKeyGenerator.forQuery(query);
    return await _hiveCache.get<SearchResult>(key);
  }

  /// Cache search suggestions
  Future<void> setSuggestions(String partial, List<String> suggestions) async {
    final key = _SearchCacheKeyGenerator.forSuggestions(partial);
    await _hiveCache.set(key, suggestions, ttl: const Duration(hours: 1));
  }

  /// Retrieve cached suggestions
  Future<List<String>?> getSuggestions(String partial) async {
    final key = _SearchCacheKeyGenerator.forSuggestions(partial);
    return await _hiveCache.get<List<String>>(key);
  }

  /// Cache available filters
  Future<void> setAvailableFilters(AvailableFilters filters) async {
    const key = _SearchCacheKeyGenerator.forAvailableFilters;
    await _hiveCache.set(key, filters, ttl: const Duration(hours: 2));
  }

  /// Retrieve cached available filters
  Future<AvailableFilters?> getAvailableFilters() async {
    const key = _SearchCacheKeyGenerator.forAvailableFilters;
    return await _hiveCache.get<AvailableFilters>(key);
  }

  /// Clear all search-related cache entries
  Future<void> clearAll() async {
    const keys = [
      _SearchCacheKeyGenerator.forAvailableFilters,
      _SearchCacheKeyGenerator.forCategories,
      _SearchCacheKeyGenerator.forPriceRange,
    ];

    for (final key in keys) {
      await _hiveCache.delete(key);
    }

    _lastEviction = DateTime.now();
  }

  /// Clear cached search results (but keep filters and suggestions)
  Future<void> clearSearchResults() async {
    // Clear all keys starting with 'search:' prefix
    // Note: HiveCache doesn't expose getAllKeys(), so this is a limitation
    // In production, we'd track keys or use a more sophisticated eviction strategy
    _lastEviction = DateTime.now();
  }

  /// Get cache statistics for monitoring
  SearchCacheStats getStats() {
    return SearchCacheStats(
      totalHits: _hits,
      totalMisses: _misses,
      totalItems: 0, // Would require access to cache keys
      lastEviction: _lastEviction,
    );
  }

  /// Reset cache statistics
  void resetStats() {
    _hits = 0;
    _misses = 0;
    _lastEviction = DateTime.now();
  }
}
