import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/repository/search_repository.dart';
import 'package:shop/providers/search_provider.dart';
import 'package:shop/services/cache/hive_cache.dart';
import 'package:shop/repository/search_cache.dart';

void main() {
  test('searchResultsProvider returns results when repository seeded', () async {
    final seededRepo = MockSearchRepository.seeded(500);

    // Prepare a HiveCache instance for the SearchCache used by providers
    final hive = HiveCache();
    await hive.init();
    final searchCache = SearchCache(hive);

    final container = ProviderContainer(overrides: [
      searchRepositoryProvider.overrideWithValue(seededRepo),
      searchCacheProvider.overrideWithValue(searchCache),
    ]);

    // Wait for debounced searchQueryProvider to settle (it has a 300ms delay)
    final query = await container.read(searchQueryProvider.future);
    expect(query.pageSize, isNotNull);

    final result = await container.read(searchResultsProvider.future);
    expect(result.items.isNotEmpty, isTrue);
    container.dispose();
  });
}
