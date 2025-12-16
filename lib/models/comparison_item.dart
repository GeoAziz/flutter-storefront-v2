import 'product_model.dart';

class ComparisonItem {
  final String id;
  final ProductModel product;
  final DateTime addedAt;

  ComparisonItem({
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

  factory ComparisonItem.fromMap(Map<String, dynamic> map) {
    return ComparisonItem(
      id: map['id'] as String,
      product: ProductModel.fromMap(
          Map<String, dynamic>.from(map['product'] as Map)),
      addedAt: DateTime.parse(map['addedAt'] as String),
    );
  }

  @override
  String toString() => 'ComparisonItem(id: $id, product: ${product.title})';
}
