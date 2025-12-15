// Minimal ProductRepository abstraction and two simple implementations
class Product {
  final String id;
  final String title;
  final String image;
  final double price;
  final double? priceAfterDiscount;
  final int? discountPercent;

  Product({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
    this.priceAfterDiscount,
    this.discountPercent,
  });
}

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
}

class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    // return a tiny, deterministic list for tests and local dev
    return [
      Product(
        id: 'p1',
        title: 'Mock Product 1',
        image: 'assets/images/product1.png',
        price: 99.99,
        priceAfterDiscount: 79.99,
        discountPercent: 20,
      ),
      Product(
        id: 'p2',
        title: 'Mock Product 2',
        image: 'assets/images/product2.png',
        price: 149.99,
        priceAfterDiscount: null,
        discountPercent: null,
      ),
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
