import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop/providers/repository_providers.dart';

void main() {
  test('productRepositoryProvider returns mock products with extended fields', () async {
    // Create a ProviderContainer with the productRepositoryProvider override
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Read the provider to get the repository
    final repo = container.read(productRepositoryProvider);

    // Fetch products
    final products = await repo.fetchProducts();

    // Verify that products have the extended fields
    expect(products.length, 2);
    
    // Check first product
    expect(products[0].id, 'p1');
    expect(products[0].title, 'Mock Product 1');
    expect(products[0].image, 'assets/images/product1.png');
    expect(products[0].price, 99.99);
    expect(products[0].priceAfterDiscount, 79.99);
    expect(products[0].discountPercent, 20);

    // Check second product
    expect(products[1].id, 'p2');
    expect(products[1].title, 'Mock Product 2');
    expect(products[1].image, 'assets/images/product2.png');
    expect(products[1].price, 149.99);
    expect(products[1].priceAfterDiscount, isNull);
    expect(products[1].discountPercent, isNull);
  });
}
