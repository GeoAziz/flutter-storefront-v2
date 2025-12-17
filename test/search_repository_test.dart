/// Unit tests for SearchRepository (Phase 5)

import 'package:flutter_test/flutter_test.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/repository/search_repository.dart';

void main() {
  group('SearchRepository Tests', () {
    late MockSearchRepository repository;

    setUp(() {
      repository = MockSearchRepository();
    });

    group('search()', () {
      test('returns all products when query is empty', () async {
        final query = const SearchQuery();
        final result = await repository.search(query);

        expect(result.items.isNotEmpty, true);
        expect(result.totalResults, greaterThan(0));
      });

      test('filters products by text search', () async {
        final query = const SearchQuery(text: 'blue');
        final result = await repository.search(query);

        expect(result.items.isNotEmpty, true);
        for (final item in result.items) {
          expect(
            item.title.toLowerCase().contains('blue'),
            true,
            reason: 'Product title should contain search text',
          );
        }
      });

      test('filters products by price range', () async {
        final query = SearchQuery(
          priceRange: const PriceRange(min: 50, max: 100),
        );
        final result = await repository.search(query);

        for (final item in result.items) {
          expect(item.price >= 50 && item.price <= 100, true,
              reason: 'Product price should be within range');
        }
      });

      test('sorts products by price ascending', () async {
        final query = const SearchQuery(sortBy: SearchSortBy.priceAsc);
        final result = await repository.search(query);

        expect(result.items.isNotEmpty, true);
        for (int i = 0; i < result.items.length - 1; i++) {
          expect(
            result.items[i].price <= result.items[i + 1].price,
            true,
            reason: 'Products should be sorted by price ascending',
          );
        }
      });

      test('sorts products by price descending', () async {
        final query = const SearchQuery(sortBy: SearchSortBy.priceDesc);
        final result = await repository.search(query);

        expect(result.items.isNotEmpty, true);
        for (int i = 0; i < result.items.length - 1; i++) {
          expect(
            result.items[i].price >= result.items[i + 1].price,
            true,
            reason: 'Products should be sorted by price descending',
          );
        }
      });

      test('respects page size parameter', () async {
        final query = const SearchQuery(pageSize: 2);
        final result = await repository.search(query);

        expect(result.items.length <= 2, true,
            reason: 'Result items should respect page size');
      });

      test('returns correct pagination metadata', () async {
        final query = const SearchQuery(pageSize: 2);
        final result = await repository.search(query);

        expect(result.page, 1);
        expect(result.pageSize, 2);
        expect(result.items.length, isA<int>());
      });

      test('combines text and price filters', () async {
        final query = SearchQuery(
          text: 'shirt',
          priceRange: const PriceRange(min: 20, max: 50),
        );
        final result = await repository.search(query);

        for (final item in result.items) {
          expect(item.title.toLowerCase().contains('shirt'), true);
          expect(item.price >= 20 && item.price <= 50, true);
        }
      });
    });

    group('getSuggestions()', () {
      test('returns empty list for empty text', () async {
        final suggestions = await repository.getSuggestions('');
        expect(suggestions.isEmpty, true);
      });

      test('returns suggestions containing partial text', () async {
        final suggestions = await repository.getSuggestions('blue');

        expect(suggestions.isNotEmpty, true);
        for (final suggestion in suggestions) {
          expect(
            suggestion.toLowerCase().contains('blue'),
            true,
            reason: 'Suggestion should contain search text',
          );
        }
      });

      test('returns limited number of suggestions', () async {
        final suggestions = await repository.getSuggestions('shirt');

        expect(suggestions.length <= 5, true,
            reason: 'Should return at most 5 suggestions');
      });

      test('is case-insensitive', () async {
        final suggestionsLower = await repository.getSuggestions('blue');
        final suggestionsUpper = await repository.getSuggestions('BLUE');

        // Both should find matching products
        expect(suggestionsLower.isNotEmpty, suggestionsUpper.isNotEmpty);
      });
    });

    group('getCategories()', () {
      test('returns non-empty list of categories', () async {
        final categories = await repository.getCategories();

        expect(categories.isNotEmpty, true);
      });

      test('categories have valid ids and names', () async {
        final categories = await repository.getCategories();

        for (final category in categories) {
          expect(category.id.isNotEmpty, true);
          expect(category.name.isNotEmpty, true);
          expect(category.count >= 0, true);
        }
      });

      test('categories are unique by id', () async {
        final categories = await repository.getCategories();
        final ids = categories.map((c) => c.id).toList();

        expect(ids.length, ids.toSet().length,
            reason: 'Category IDs should be unique');
      });
    });

    group('getPriceRange()', () {
      test('returns valid price range', () async {
        final range = await repository.getPriceRange();

        expect(range.min >= 0, true);
        expect(range.max >= range.min, true);
      });

      test('min is less than max', () async {
        final range = await repository.getPriceRange();

        expect(range.min < range.max, true);
      });
    });

    group('getAvailableFilters()', () {
      test('returns both categories and price range', () async {
        final filters = await repository.getAvailableFilters();

        expect(filters.categories.isNotEmpty, true);
        expect(filters.priceRange.min < filters.priceRange.max, true);
      });
    });

    group('Mock data consistency', () {
      test('mock products are consistent across calls', () async {
        final result1 = await repository.search(const SearchQuery());
        final result2 = await repository.search(const SearchQuery());

        expect(result1.items.length, result2.items.length);
        for (int i = 0; i < result1.items.length; i++) {
          expect(result1.items[i].id, result2.items[i].id);
        }
      });

      test('categories remain consistent', () async {
        final cats1 = await repository.getCategories();
        final cats2 = await repository.getCategories();

        expect(cats1.length, cats2.length);
      });
    });
  });
}
