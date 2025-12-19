import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/repository/product_repository.dart';

/// Test helper: returns a list of provider overrides that inject the
/// deterministic `MockProductRepository` so widget tests don't need a
/// real Firebase/Firestore instance.
List<Override> defaultTestOverrides() {
  return [
    productRepositoryProvider.overrideWithValue(MockProductRepository()),
  ];
}
