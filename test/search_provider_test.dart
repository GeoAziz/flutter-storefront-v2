/// Unit tests for search providers (Phase 5)

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/providers/search_provider.dart';

void main() {
  group('Search Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Filter State Providers', () {
      test('searchTextProvider initializes to empty string', () {
        final text = container.read(searchTextProvider);
        expect(text, '');
      });

      test('selectedCategoriesProvider initializes to empty set', () {
        final categories = container.read(selectedCategoriesProvider);
        expect(categories.isEmpty, true);
      });

      test('searchSortByProvider initializes to relevance', () {
        final sort = container.read(searchSortByProvider);
        expect(sort, SearchSortBy.relevance);
      });

      test('selectedPriceRangeProvider initializes to null', () {
        final range = container.read(selectedPriceRangeProvider);
        expect(range, isNull);
      });

      test('selectedMinRatingProvider initializes to null', () {
        final rating = container.read(selectedMinRatingProvider);
        expect(rating, isNull);
      });
    });

    group('UI State Providers', () {
      test('showSuggestionsProvider initializes to false', () {
        final show = container.read(showSuggestionsProvider);
        expect(show, false);
      });

      test('showFilterPanelProvider initializes to false', () {
        final show = container.read(showFilterPanelProvider);
        expect(show, false);
      });

      test('hasSearchedProvider initializes to false', () {
        final hasSearched = container.read(hasSearchedProvider);
        expect(hasSearched, false);
      });
    });

    group('hasActiveFiltersProvider', () {
      test('returns false when no filters active', () {
        final hasFilters = container.read(hasActiveFiltersProvider);
        expect(hasFilters, false);
      });

      test('returns true when text is entered', () {
        container.read(searchTextProvider.notifier).state = 'test';
        final hasFilters = container.read(hasActiveFiltersProvider);
        expect(hasFilters, true);
      });

      test('returns true when category selected', () {
        container
            .read(selectedCategoriesProvider.notifier)
            .state = {'category1'};
        final hasFilters = container.read(hasActiveFiltersProvider);
        expect(hasFilters, true);
      });

      test('returns true when price range set', () {
        container.read(selectedPriceRangeProvider.notifier).state =
            const PriceRange(min: 10, max: 50);
        final hasFilters = container.read(hasActiveFiltersProvider);
        expect(hasFilters, true);
      });

      test('returns true when min rating set', () {
        container.read(selectedMinRatingProvider.notifier).state = 4.0;
        final hasFilters = container.read(hasActiveFiltersProvider);
        expect(hasFilters, true);
      });
    });

    group('toggleCategoryProvider', () {
      test('adds category to selected when not present', () {
        final toggle = container.read(toggleCategoryProvider);
        expect(
          container.read(selectedCategoriesProvider).contains('cat1'),
          false,
        );

        toggle('cat1');

        expect(
          container.read(selectedCategoriesProvider).contains('cat1'),
          true,
        );
      });

      test('removes category when already selected', () {
        final toggle = container.read(toggleCategoryProvider);
        
        // Add category
        toggle('cat1');
        expect(
          container.read(selectedCategoriesProvider).contains('cat1'),
          true,
        );

        // Remove category
        toggle('cat1');
        expect(
          container.read(selectedCategoriesProvider).contains('cat1'),
          false,
        );
      });

      test('handles multiple categories', () {
        final toggle = container.read(toggleCategoryProvider);

        toggle('cat1');
        toggle('cat2');
        final categories = container.read(selectedCategoriesProvider);

        expect(categories.contains('cat1'), true);
        expect(categories.contains('cat2'), true);
        expect(categories.length, 2);
      });
    });

    group('resetSearchProvider', () {
      test('clears all filter state', () {
        // Set up various filters
        container.read(searchTextProvider.notifier).state = 'test';
        container
            .read(selectedCategoriesProvider.notifier)
            .state = {'cat1', 'cat2'};
        container.read(selectedPriceRangeProvider.notifier).state =
            const PriceRange(min: 10, max: 50);
        container.read(selectedMinRatingProvider.notifier).state = 4.0;
        container.read(searchSortByProvider.notifier).state =
            SearchSortBy.priceAsc;
        container.read(showSuggestionsProvider.notifier).state = true;
        container.read(showFilterPanelProvider.notifier).state = true;
        container.read(hasSearchedProvider.notifier).state = true;

  // Reset all filters
  container.read(resetSearchProvider)();

        // Verify all filters are cleared
        expect(container.read(searchTextProvider), '');
        expect(container.read(selectedCategoriesProvider).isEmpty, true);
        expect(container.read(selectedPriceRangeProvider), isNull);
        expect(container.read(selectedMinRatingProvider), isNull);
        expect(container.read(searchSortByProvider), SearchSortBy.relevance);
        expect(container.read(showSuggestionsProvider), false);
        expect(container.read(showFilterPanelProvider), false);
        expect(container.read(hasSearchedProvider), false);
      });
    });

    group('Helper Providers', () {
      test('setPriceRangeProvider updates price range', () {
        final setPriceRange = container.read(setPriceRangeProvider);
        const newRange = PriceRange(min: 20, max: 80);

        setPriceRange(newRange);

        expect(container.read(selectedPriceRangeProvider), newRange);
      });

      test('setMinRatingProvider updates minimum rating', () {
        final setRating = container.read(setMinRatingProvider);

        setRating(4.5);

        expect(container.read(selectedMinRatingProvider), 4.5);
      });

      test('setSortByProvider updates sort order', () {
        final setSort = container.read(setSortByProvider);

        setSort(SearchSortBy.priceDesc);

        expect(container.read(searchSortByProvider), SearchSortBy.priceDesc);
      });

      test('setSearchTextProvider updates text and UI state', () {
        final setText = container.read(setSearchTextProvider);

        setText('new search');

        expect(container.read(searchTextProvider), 'new search');
        expect(container.read(hasSearchedProvider), true);
        expect(container.read(showSuggestionsProvider), true);
      });

      test('setSearchTextProvider shows/hides suggestions based on text', () {
        final setText = container.read(setSearchTextProvider);

        // Non-empty text should show suggestions
        setText('a');
        expect(container.read(showSuggestionsProvider), true);

        // Empty text should hide suggestions
        setText('');
        expect(container.read(showSuggestionsProvider), false);
      });
    });
  });
}
