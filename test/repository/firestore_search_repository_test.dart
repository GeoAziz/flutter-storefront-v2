import 'package:flutter_test/flutter_test.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/repository/search_repository.dart';
import 'package:shop/repository/product_repository.dart';

void main() {
  group('MockSearchRepository - Basic Search', () {
    test('search returns empty results for empty repository', () async {
      final repo = MockSearchRepository(products: []);
      final query = const SearchQuery(pageSize: 20);
      final result = await repo.search(query);

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.nextCursor, isNull);
    });

    test('search returns products matching text query', () async {
      final products = [
        Product(
          id: 'p1',
          title: 'Blue Cotton T-Shirt',
          image: 'assets/test.png',
          price: 29.99,
        ),
        Product(
          id: 'p2',
          title: 'Red Cotton Shirt',
          image: 'assets/test.png',
          price: 34.99,
        ),
      ];

      final repo = MockSearchRepository(products: products);
      final query = const SearchQuery(text: 'blue', pageSize: 20);
      final result = await repo.search(query);

      expect(result.items, hasLength(1));
      expect(result.items.first.title, contains('Blue'));
    });

    test('search returns products within price range', () async {
      final products = [
        Product(id: 'p1', title: 'Cheap Item', image: 'assets/test.png', price: 5.0),
        Product(id: 'p2', title: 'Medium Item', image: 'assets/test.png', price: 50.0),
        Product(id: 'p3', title: 'Expensive Item', image: 'assets/test.png', price: 200.0),
      ];

      final repo = MockSearchRepository(products: products);
      final query = SearchQuery(
        pageSize: 20,
        priceRange: const PriceRange(min: 10.0, max: 100.0),
      );
      final result = await repo.search(query);

      expect(result.items, hasLength(1));
      expect(result.items.first.id, equals('p2'));
    });

    test('search respects pagination', () async {
      final products = List.generate(
        50,
        (i) => Product(
          id: 'p$i',
          title: 'Product $i',
          image: 'assets/test.png',
          price: 10.0 + i,
        ),
      );

      final repo = MockSearchRepository(products: products);
      final query = const SearchQuery(pageSize: 20);
      final result = await repo.search(query);

      expect(result.items, hasLength(20));
      expect(result.hasMore, isTrue);
      expect(result.nextCursor, isNotNull);
    });
  });

  group('MockSearchRepository - Sorting', () {
    test('applies price ascending sort', () async {
      final products = [
        Product(id: 'p1', title: 'Expensive', image: 'assets/test.png', price: 100.0),
        Product(id: 'p2', title: 'Cheap', image: 'assets/test.png', price: 10.0),
        Product(id: 'p3', title: 'Medium', image: 'assets/test.png', price: 50.0),
      ];

      final repo = MockSearchRepository(products: products);
      final query = const SearchQuery(pageSize: 20, sortBy: SearchSortBy.priceAsc);
      final result = await repo.search(query);

      expect(result.items[0].price, equals(10.0));
      expect(result.items[1].price, equals(50.0));
      expect(result.items[2].price, equals(100.0));
    });

    test('applies price descending sort', () async {
      final products = [
        Product(id: 'p1', title: 'Cheap', image: 'assets/test.png', price: 10.0),
        Product(id: 'p2', title: 'Medium', image: 'assets/test.png', price: 50.0),
        Product(id: 'p3', title: 'Expensive', image: 'assets/test.png', price: 100.0),
      ];

      final repo = MockSearchRepository(products: products);
      final query = const SearchQuery(pageSize: 20, sortBy: SearchSortBy.priceDesc);
      final result = await repo.search(query);

      expect(result.items[0].price, equals(100.0));
      expect(result.items[1].price, equals(50.0));
      expect(result.items[2].price, equals(10.0));
    });
  });

  group('MockSearchRepository - Suggestions', () {
    test('getSuggestions returns matching titles', () async {
      final products = [
        Product(id: 'p1', title: 'Blue Cotton Shirt', image: 'assets/test.png', price: 29.99),
        Product(id: 'p2', title: 'Blue Denim Jeans', image: 'assets/test.png', price: 49.99),
        Product(id: 'p3', title: 'Red Shirt', image: 'assets/test.png', price: 34.99),
      ];

      final repo = MockSearchRepository(products: products);
      final suggestions = await repo.getSuggestions('blue');

      expect(suggestions, isNotEmpty);
      expect(suggestions.every((s) => s.toLowerCase().contains('blue')), isTrue);
    });

    test('getSuggestions returns empty for no matches', () async {
      final repo = MockSearchRepository(products: []);
      final suggestions = await repo.getSuggestions('nonexistent');

      expect(suggestions, isEmpty);
    });
  });

  group('MockSearchRepository - Categories', () {
    test('getCategories returns predefined categories', () async {
      final repo = MockSearchRepository();
      final categories = await repo.getCategories();

      expect(categories, isNotEmpty);
      expect(categories.map((c) => c.id), contains('clothing'));
      expect(categories.map((c) => c.id), contains('shoes'));
    });
  });

  group('MockSearchRepository - Price Range', () {
    test('getPriceRange returns predefined bounds', () async {
      final repo = MockSearchRepository();
      final priceRange = await repo.getPriceRange();

      expect(priceRange.min, isNonNegative);
      expect(priceRange.max, greaterThan(priceRange.min));
    });
  });

  group('SearchQuery - Properties', () {
    test('isEmpty returns true for default query', () async {
      const query = SearchQuery(pageSize: 20);
      expect(query.isEmpty, isTrue);
    });

    test('hasFilters returns true when text is provided', () async {
      const query = SearchQuery(pageSize: 20, text: 'search term');
      expect(query.hasFilters, isTrue);
    });

    test('hasFilters returns true when categories filter is set', () async {
      final query = SearchQuery(pageSize: 20, categories: {'electronics'});
      expect(query.hasFilters, isTrue);
    });

    test('toCacheKey generates consistent key', () async {
      const query1 = SearchQuery(
        pageSize: 20,
        text: 'test',
        sortBy: SearchSortBy.priceAsc,
      );
      const query2 = SearchQuery(
        pageSize: 20,
        text: 'test',
        sortBy: SearchSortBy.priceAsc,
      );

      expect(query1.toCacheKey(), equals(query2.toCacheKey()));
    });

    test('copyWith creates new instance with overrides', () async {
      const original = SearchQuery(pageSize: 20, text: 'original');
      final updated = original.copyWith(text: 'updated');

      expect(original.text, equals('original'));
      expect(updated.text, equals('updated'));
      expect(updated.pageSize, equals(original.pageSize));
    });
  });

  group('SearchFilter - Operations', () {
    test('clearAll resets all filters', () async {
      final filter = SearchFilter(
        selectedCategories: {'electronics'},
        priceRange: const PriceRange(min: 10, max: 100),
        minRating: 4.0,
      );

      final cleared = filter.clearAll();

      expect(cleared.hasActiveFilters, isFalse);
      expect(cleared.selectedCategories, isEmpty);
      expect(cleared.priceRange, isNull);
      expect(cleared.minRating, isNull);
    });

    test('hasActiveFilters returns true when categories selected', () async {
      final filter = SearchFilter(selectedCategories: {'clothing'});
      expect(filter.hasActiveFilters, isTrue);
    });
  });
}
