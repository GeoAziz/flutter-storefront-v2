import 'package:flutter_test/flutter_test.dart';
import 'package:shop/repository/search_repository.dart';
import 'package:shop/models/search_models.dart';

void main() {
  test('MockSearchRepository seeded returns items for default query', () async {
    final repo = MockSearchRepository.seeded(500);
    final query = SearchQuery(pageSize: 500);
    final result = await repo.search(query);
    expect(result.items.isNotEmpty, isTrue);
    expect(result.totalResults, greaterThan(0));
  });
}
