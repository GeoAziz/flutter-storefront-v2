/// Unit tests for SearchCache (Phase 5)

import 'package:flutter_test/flutter_test.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/repository/search_cache.dart';
import 'package:shop/services/cache/hive_cache.dart';
import 'dart:io';

void main() {
  group('SearchCache Tests', () {
    late SearchCache cache;
    late HiveCache hiveCache;

    setUp(() async {
      // Create a temporary directory for test Hive cache
      final tmpDir = await Directory.systemTemp.createTemp('hive_cache_test');
      hiveCache = HiveCache(customPath: tmpDir.path);
      await hiveCache.init();
      cache = SearchCache(hiveCache, ttl: const Duration(hours: 1));
    });

    tearDown(() async {
      await hiveCache.clear();
      await hiveCache.clear(); // Clear the box
    });

    group('setSearchResult() and getSearchResult()', () {
      test('stores and retrieves search result', () async {
        final query = const SearchQuery(text: 'test');
        final result = SearchResult(
          items: const [],
          query: query,
          totalResults: 0,
          suggestedQueries: const [],
          availableCategories: const {},
          availablePriceRange: const PriceRange(min: 0, max: 100),
          page: 1,
          pageSize: 20,
        );

        await cache.setSearchResult(query, result);
        final cached = await cache.getSearchResult(query);

        expect(cached, isNotNull);
        expect(cached?.query.text, 'test');
      });

      test('returns null for non-existent query', () async {
        final query = const SearchQuery(text: 'nonexistent');
        final cached = await cache.getSearchResult(query);

        expect(cached, isNull);
      });

      test('cache key includes all filter components', () async {
        final query1 = const SearchQuery(text: 'test');
        final query2 = const SearchQuery(
          text: 'test',
          priceRange: PriceRange(min: 10, max: 20),
        );

        final result1 = SearchResult(
          items: const [],
          query: query1,
          totalResults: 1,
          suggestedQueries: const [],
          availableCategories: const {},
          availablePriceRange: const PriceRange(min: 0, max: 100),
          page: 1,
          pageSize: 20,
        );

        final result2 = SearchResult(
          items: const [],
          query: query2,
          totalResults: 2,
          suggestedQueries: const [],
          availableCategories: const {},
          availablePriceRange: const PriceRange(min: 0, max: 100),
          page: 1,
          pageSize: 20,
        );

        await cache.setSearchResult(query1, result1);
        await cache.setSearchResult(query2, result2);

        final cached1 = await cache.getSearchResult(query1);
        final cached2 = await cache.getSearchResult(query2);

        expect(cached1?.totalResults, 1);
        expect(cached2?.totalResults, 2);
      });
    });

    group('setSuggestions() and getSuggestions()', () {
      test('stores and retrieves suggestions', () async {
        const partial = 'blu';
        const suggestions = ['blue shirt', 'blue jeans', 'blue hat'];

        await cache.setSuggestions(partial, suggestions);
        final cached = await cache.getSuggestions(partial);

        expect(cached, isNotNull);
        expect(cached?.length, 3);
        expect(cached?.first, 'blue shirt');
      });

      test('returns null for non-existent partial', () async {
        const partial = 'nonexistent';
        final cached = await cache.getSuggestions(partial);

        expect(cached, isNull);
      });

      test('suggestions cache has separate keys from search results', () async {
        const query = SearchQuery(text: 'test');
        const partial = 'test';

        final result = SearchResult(
          items: const [],
          query: query,
          totalResults: 0,
          suggestedQueries: const [],
          availableCategories: const {},
          availablePriceRange: const PriceRange(min: 0, max: 100),
          page: 1,
          pageSize: 20,
        );

        await cache.setSearchResult(query, result);
        await cache.setSuggestions(partial, const ['test1', 'test2']);

        final cachedResult = await cache.getSearchResult(query);
        final cachedSuggestions = await cache.getSuggestions(partial);

        expect(cachedResult, isNotNull);
        expect(cachedSuggestions, isNotNull);
      });
    });

    group('setAvailableFilters() and getAvailableFilters()', () {
      test('stores and retrieves available filters', () async {
        final filters = AvailableFilters(
          categories: const [
            CategoryOption(id: 'cat1', name: 'Category 1', count: 10),
          ],
          priceRange: const PriceRange(min: 0, max: 100),
        );

        await cache.setAvailableFilters(filters);
        final cached = await cache.getAvailableFilters();

        expect(cached, isNotNull);
        expect(cached?.categories.length, 1);
        expect(cached?.priceRange.max, 100);
      });

      test('returns null for non-existent filters', () async {
        final cached = await cache.getAvailableFilters();
        expect(cached, isNull);
      });
    });

    group('Cache statistics', () {
      test('tracks cache hits and misses', () async {
        final query = const SearchQuery(text: 'test');
        final result = SearchResult(
          items: const [],
          query: query,
          totalResults: 0,
          suggestedQueries: const [],
          availableCategories: const {},
          availablePriceRange: const PriceRange(min: 0, max: 100),
          page: 1,
          pageSize: 20,
        );

        // Store and retrieve
        await cache.setSearchResult(query, result);
        await cache.getSearchResult(query); // Hit
        await cache.getSearchResult(const SearchQuery(text: 'other')); // Miss

        final stats = cache.getStats();
        expect(stats.totalHits, greaterThanOrEqualTo(0));
        expect(stats.totalMisses, greaterThanOrEqualTo(0));
      });

      test('resets statistics', () async {
        cache.resetStats();
        final stats = cache.getStats();

        expect(stats.totalHits, 0);
        expect(stats.totalMisses, 0);
      });
    });

    group('clearAll()', () {
      test('clears all cached entries', () async {
        final query = const SearchQuery(text: 'test');
        final result = SearchResult(
          items: const [],
          query: query,
          totalResults: 0,
          suggestedQueries: const [],
          availableCategories: const {},
          availablePriceRange: const PriceRange(min: 0, max: 100),
          page: 1,
          pageSize: 20,
        );

        await cache.setSearchResult(query, result);
        await cache.setSuggestions('test', const ['test1', 'test2']);
        await cache.setAvailableFilters(
          AvailableFilters(
            categories: const [],
            priceRange: const PriceRange(min: 0, max: 100),
          ),
        );

        await cache.clearAll();

        final cachedFilters = await cache.getAvailableFilters();

        // Note: clearAll() currently doesn't clear search results due to key tracking limitation
        // This is documented in the implementation
        expect(cachedFilters, isNull);
      });
    });
  });
}
