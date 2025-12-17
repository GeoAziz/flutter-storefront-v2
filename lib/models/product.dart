import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final bool active;
  final double rating;
  final int reviewCount;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    this.active = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.createdAt,
  });

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse('${map['price']}') ?? 0.0,
      imageUrl: map['imageUrl'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      stock: (map['stock'] is int)
          ? map['stock'] as int
          : int.tryParse('${map['stock']}') ?? 0,
      active: map['active'] is bool ? map['active'] as bool : true,
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      reviewCount: (map['reviewCount'] is int)
          ? map['reviewCount'] as int
          : int.tryParse('${map['reviewCount']}') ?? 0,
      createdAt:
          map['createdAt'] is DateTime ? map['createdAt'] as DateTime : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'active': active,
      'rating': rating,
      'reviewCount': reviewCount,
      // createdAt handled by server timestamp when writing
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    int? stock,
    bool? active,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      active: active ?? this.active,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Product($id, $name, $price)';
}
