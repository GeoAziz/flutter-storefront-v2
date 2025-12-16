import 'package:flutter_test/flutter_test.dart';
import 'package:shop/repository/search_repository.dart';
import 'package:shop/models/search_models.dart';

void main() {
  test('Seeded MockSearchRepository returns 500 products', () async {
    final repo = MockSearchRepository.seeded(500);
    final query = SearchQuery(pageSize: 500);
    
    final result = await repo.search(query);
    
    expect(result.totalResults, greaterThanOrEqualTo(500));
    expect(result.items.length, greaterThan(0));
    expect(result.items.first.title, isNotEmpty);
  });

  test('Seeded repo with text filter works', () async {
    final repo = MockSearchRepository.seeded(500);
    final query = SearchQuery(text: 'Blue', pageSize: 500);
    
    final result = await repo.search(query);
    
    expect(result.items.isNotEmpty, isTrue);
    for (var item in result.items) {
      expect(item.title.toLowerCase().contains('blue'), isTrue);
    }
  });

  test('Seeded repo with price filter works', () async {
    final repo = MockSearchRepository.seeded(500);
    final query = SearchQuery(
      priceRange: const PriceRange(min: 50, max: 100),
      pageSize: 500,
    );
    
    final result = await repo.search(query);
    
    expect(result.items.isNotEmpty, isTrue);
    for (var item in result.items) {
      expect(item.price >= 50 && item.price <= 100, isTrue);
    }
  });
}
