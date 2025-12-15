import 'package:flutter_test/flutter_test.dart';
import 'package:shop/repository/real_product_repository.dart';

void main() {
  test('RealProductRepository returns deterministic products', () async {
    final repo = RealProductRepository();
    final products = await repo.fetchProducts();
    expect(products, isNotEmpty);
    expect(products[0].title, contains('Real Stub Product'));
  });
}
