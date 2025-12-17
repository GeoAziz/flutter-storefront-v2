class InventoryItem {
  final String productId;
  final int stock; // available stock
  final int reserved; // reserved but not yet finalized

  InventoryItem(
      {required this.productId, required this.stock, this.reserved = 0});

  InventoryItem copyWith({int? stock, int? reserved}) => InventoryItem(
        productId: productId,
        stock: stock ?? this.stock,
        reserved: reserved ?? this.reserved,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'stock': stock,
        'reserved': reserved,
      };

  factory InventoryItem.fromMap(Map<String, dynamic> m) => InventoryItem(
        productId: m['productId'] as String,
        stock: (m['stock'] as num).toInt(),
        reserved: (m['reserved'] as num?)?.toInt() ?? 0,
      );
}
