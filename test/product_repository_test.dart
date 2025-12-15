import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/repository/product_repository.dart';

void main() {
  test('productRepository provider returns a ProductRepository and can fetch mock products when overridden', () async {
    final container = ProviderContainer(overrides: [
      productRepositoryProvider.overrideWithValue(MockProductRepository()),
    ]);
    addTearDown(container.dispose);

    final repo = container.read(productRepositoryProvider);
    expect(repo, isA<ProductRepository>());

    final products = await repo.fetchProducts();
    expect(products, isNotEmpty);
    expect(products.first.id, equals('p1'));
  });

  test('can override provider with RealProductRepository stub', () async {
    final container = ProviderContainer(overrides: [
      productRepositoryProvider.overrideWithValue(RealProductRepository()),
    ]);
    addTearDown(container.dispose);

    final repo = container.read(productRepositoryProvider);
    expect(repo, isA<ProductRepository>());

    final products = await repo.fetchProducts();
    expect(products, isA<List<Product>>());
  });
}
