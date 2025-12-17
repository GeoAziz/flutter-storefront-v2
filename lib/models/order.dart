class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
      };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] as String,
        productName: m['productName'] as String,
        price: (m['price'] as num).toDouble(),
        quantity: (m['quantity'] as num).toInt(),
      );
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalPrice;
  final String status;
  final String? paymentMethod;
  final String? trackingNumber;
  final DateTime? createdAt;
  final DateTime? completedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    this.status = 'pending',
    this.paymentMethod,
    this.trackingNumber,
    this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items.map((i) => i.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': status,
        'paymentMethod': paymentMethod,
        'trackingNumber': trackingNumber,
        // createdAt handled by server timestamp
      };

  factory Order.fromMap(String id, Map<String, dynamic> m) {
    final items = (m['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    return Order(
      id: id,
      userId: m['userId'] as String,
      items: items,
      totalPrice: (m['totalPrice'] as num).toDouble(),
      status: m['status'] as String? ?? 'pending',
      paymentMethod: m['paymentMethod'] as String?,
    );
  }
}
