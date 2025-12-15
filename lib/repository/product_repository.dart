// Minimal ProductRepository abstraction and two simple implementations
class Product {
  final String id;
  final String title;

  Product({required this.id, required this.title});
}

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
}

class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    // return a tiny, deterministic list for tests and local dev
    return [
      Product(id: 'p1', title: 'Mock Product 1'),
      Product(id: 'p2', title: 'Mock Product 2'),
    ];
  }
}

class RealProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    // Placeholder for real network implementation. For now return empty list.
    return [];
  }
}
