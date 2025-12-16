class WishlistItem {
  final String id;
  final String title;
  final String? imageUrl;
  final double price;

  WishlistItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'price': price,
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'] as String,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String?,
      price: (map['price'] is int) ? (map['price'] as int).toDouble() : (map['price'] as double),
    );
  }

  @override
  String toString() => 'WishlistItem(id: $id, title: $title, price: $price)';
}
