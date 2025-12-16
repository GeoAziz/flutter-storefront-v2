/// Riverpod provider for SearchRepository implementations
///
/// Wires mock and Firestore-backed search repositories with toggle support.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/repository/search_repository.dart';
import 'package:shop/repository/firestore_search_repository.dart';
import 'package:shop/repository/search_cache.dart';
import 'package:shop/services/cache/hive_cache.dart';
import 'package:shop/services/service_locator.dart' show cacheProvider;

// Toggle: set at compile time using --dart-define=USE_MOCK_SEARCH=true/false
const bool _useMockSearch = bool.fromEnvironment('USE_MOCK_SEARCH', defaultValue: true);

/// Provides the SearchCache singleton
final searchCacheProvider = Provider<SearchCache>((ref) {
  final cache = cacheProvider as HiveCache;
  return SearchCache(cache);
});

/// Provides the SearchRepository singleton
///
/// Uses MockSearchRepository by default (controlled by USE_MOCK_SEARCH).
/// In production, use FirestoreSearchRepository with caching support.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final cache = ref.watch(searchCacheProvider);

  if (_useMockSearch) {
    return MockSearchRepository.seeded(50);
  }

  // Use Firestore-backed repository with optional caching
  return FirestoreSearchRepository(cache: cache);
});
