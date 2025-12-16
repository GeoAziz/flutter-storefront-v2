import 'product_model.dart';

class WishlistItem {
  final String id;
  final ProductModel product;
  final DateTime addedAt;

  WishlistItem({
    required this.id,
    required this.product,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'] as String,
      product: ProductModel.fromMap(
          Map<String, dynamic>.from(map['product'] as Map)),
      addedAt: DateTime.parse(map['addedAt'] as String),
    );
  }

  @override
  String toString() => 'WishlistItem(id: $id, product: ${product.title})';
}
