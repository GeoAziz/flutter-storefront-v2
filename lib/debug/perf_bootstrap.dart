/// Helpers for performance testing Search UI
///
/// Exposes functions to create a seeded MockSearchRepository and simple helpers
/// for tests to use when overriding providers.

import 'package:shop/repository/search_repository.dart';
/// Create a MockSearchRepository seeded with [count] products.
MockSearchRepository createSeededMockRepo(int count) {
  return MockSearchRepository.seeded(count);
}

