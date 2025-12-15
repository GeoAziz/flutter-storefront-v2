import 'package:shop/repository/product_repository.dart';

/// A small stub implementation of [ProductRepository]. This returns a
/// deterministic list of products suitable for local development and tests.
class RealProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    // In a real implementation this would call an API. For now return a
    // deterministic list so screens and tests can rely on it.
    await Future.delayed(const Duration(milliseconds: 50));
    return [
      Product(
        id: 'real1',
        title: 'Real Stub Product 1',
        image: 'assets/images/product_real_1.png',
        price: 39.99,
        priceAfterDiscount: 29.99,
        discountPercent: 25,
      ),
      Product(
        id: 'real2',
        title: 'Real Stub Product 2',
        image: 'assets/images/product_real_2.png',
        price: 59.99,
        priceAfterDiscount: null,
        discountPercent: null,
      ),
    ];
  }
}
