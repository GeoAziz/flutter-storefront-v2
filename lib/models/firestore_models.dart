/// Firestore Data Models for E-commerce Application
///
/// This file defines all data models that map to Firestore collections
/// with proper serialization/deserialization methods.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// USER MODELS
// ============================================================================

/// User Profile Model
class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final List<String> addresses;
  final String preferredAddress;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool emailVerified;
  final bool active;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.addresses = const [],
    this.preferredAddress = '',
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
    this.emailVerified = false,
    this.active = true,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'addresses': addresses,
        'preferredAddress': preferredAddress,
        'preferences': preferences,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'emailVerified': emailVerified,
        'active': active,
      };

  /// Create from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] ?? '',
        email: map['email'] ?? '',
        displayName: map['displayName'],
        phoneNumber: map['phoneNumber'],
        avatarUrl: map['avatarUrl'],
        bio: map['bio'],
        addresses: List<String>.from(map['addresses'] ?? []),
        preferredAddress: map['preferredAddress'] ?? '',
        preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        emailVerified: map['emailVerified'] ?? false,
        active: map['active'] ?? true,
      );

  /// Create a copy with modifications
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    List<String>? addresses,
    String? preferredAddress,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? emailVerified,
    bool? active,
  }) =>
      UserProfile(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        addresses: addresses ?? this.addresses,
        preferredAddress: preferredAddress ?? this.preferredAddress,
        preferences: preferences ?? this.preferences,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        emailVerified: emailVerified ?? this.emailVerified,
        active: active ?? this.active,
      );
}

// ============================================================================
// PRODUCT MODELS
// ============================================================================

/// Product Model
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final double rating;
  final int reviewCount;
  final String category;
  final List<String> imageUrls;
  final String? thumbnailUrl;
  final int stock;
  final List<String> tags;
  final Map<String, dynamic> specifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.category,
    this.imageUrls = const [],
    this.thumbnailUrl,
    required this.stock,
    this.tags = const [],
    this.specifications = const {},
    required this.createdAt,
    required this.updatedAt,
    this.active = true,
  });

  /// Calculate discount percentage
  double get discountPercentage {
    if (discountPrice == null) return 0.0;
    return ((price - discountPrice!) / price * 100).roundToDouble();
  }

  /// Get effective price
  double get effectivePrice => discountPrice ?? price;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'discountPrice': discountPrice,
        'rating': rating,
        'reviewCount': reviewCount,
        'category': category,
        'imageUrls': imageUrls,
        'thumbnailUrl': thumbnailUrl,
        'stock': stock,
        'tags': tags,
        'specifications': specifications,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'active': active,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        discountPrice: (map['discountPrice'] as num?)?.toDouble(),
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: map['reviewCount'] ?? 0,
        category: map['category'] ?? '',
        imageUrls: List<String>.from(map['imageUrls'] ?? []),
        thumbnailUrl: map['thumbnailUrl'],
        stock: map['stock'] ?? 0,
        tags: List<String>.from(map['tags'] ?? []),
        specifications: Map<String, dynamic>.from(map['specifications'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        active: map['active'] ?? true,
      );

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    double? rating,
    int? reviewCount,
    String? category,
    List<String>? imageUrls,
    String? thumbnailUrl,
    int? stock,
    List<String>? tags,
    Map<String, dynamic>? specifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        discountPrice: discountPrice ?? this.discountPrice,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        category: category ?? this.category,
        imageUrls: imageUrls ?? this.imageUrls,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        stock: stock ?? this.stock,
        tags: tags ?? this.tags,
        specifications: specifications ?? this.specifications,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        active: active ?? this.active,
      );
}

// ============================================================================
// CART MODELS
// ============================================================================

/// Cart Item Model
class CartItem {
  final String productId;
  final int quantity;
  final double priceAtAdd;
  final Map<String, dynamic> selectedOptions;
  final DateTime addedAt;
  final DateTime updatedAt;

  CartItem({
    required this.productId,
    required this.quantity,
    required this.priceAtAdd,
    this.selectedOptions = const {},
    required this.addedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'quantity': quantity,
        'priceAtAdd': priceAtAdd,
        'selectedOptions': selectedOptions,
        'addedAt': addedAt,
        'updatedAt': updatedAt,
      };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        productId: map['productId'] ?? '',
        quantity: map['quantity'] ?? 0,
        priceAtAdd: (map['priceAtAdd'] as num?)?.toDouble() ?? 0.0,
        selectedOptions:
            Map<String, dynamic>.from(map['selectedOptions'] ?? {}),
        addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  CartItem copyWith({
    String? productId,
    int? quantity,
    double? priceAtAdd,
    Map<String, dynamic>? selectedOptions,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) =>
      CartItem(
        productId: productId ?? this.productId,
        quantity: quantity ?? this.quantity,
        priceAtAdd: priceAtAdd ?? this.priceAtAdd,
        selectedOptions: selectedOptions ?? this.selectedOptions,
        addedAt: addedAt ?? this.addedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// User Cart Model
class UserCart {
  final String userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserCart({
    required this.userId,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate total price
  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + (item.priceAtAdd * item.quantity));

  /// Count total items
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items.map((item) => item.toMap()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory UserCart.fromMap(Map<String, dynamic> map) => UserCart(
        userId: map['userId'] ?? '',
        items: (map['items'] as List<dynamic>?)
                ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  UserCart copyWith({
    String? userId,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserCart(
        userId: userId ?? this.userId,
        items: items ?? this.items,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ============================================================================
// ORDER MODELS
// ============================================================================

/// Order Status Enum
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

/// Order Item Model
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double pricePerUnit;
  final Map<String, dynamic> selectedOptions;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.pricePerUnit,
    this.selectedOptions = const {},
  });

  double get subtotal => pricePerUnit * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
        'selectedOptions': selectedOptions,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        quantity: map['quantity'] ?? 0,
        pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
        selectedOptions:
            Map<String, dynamic>.from(map['selectedOptions'] ?? {}),
      );
}

/// Order Model
class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double discount;
  final double total;
  final OrderStatus status;
  final String shippingAddress;
  final String paymentMethod;
  final String? trackingNumber;
  final Map<String, dynamic> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.tax,
    required this.discount,
    required this.total,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.trackingNumber,
    this.statusHistory = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'items': items.map((item) => item.toMap()).toList(),
        'subtotal': subtotal,
        'shippingCost': shippingCost,
        'tax': tax,
        'discount': discount,
        'total': total,
        'status': status.name,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'trackingNumber': trackingNumber,
        'statusHistory': statusHistory,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        items: (map['items'] as List<dynamic>?)
                ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
                .toList() ??
            [],
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
        shippingCost: (map['shippingCost'] as num?)?.toDouble() ?? 0.0,
        tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
        status: OrderStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => OrderStatus.pending,
        ),
        shippingAddress: map['shippingAddress'] ?? '',
        paymentMethod: map['paymentMethod'] ?? '',
        trackingNumber: map['trackingNumber'],
        statusHistory: Map<String, dynamic>.from(map['statusHistory'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? subtotal,
    double? shippingCost,
    double? tax,
    double? discount,
    double? total,
    OrderStatus? status,
    String? shippingAddress,
    String? paymentMethod,
    String? trackingNumber,
    Map<String, dynamic>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Order(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        shippingCost: shippingCost ?? this.shippingCost,
        tax: tax ?? this.tax,
        discount: discount ?? this.discount,
        total: total ?? this.total,
        status: status ?? this.status,
        shippingAddress: shippingAddress ?? this.shippingAddress,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        trackingNumber: trackingNumber ?? this.trackingNumber,
        statusHistory: statusHistory ?? this.statusHistory,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ============================================================================
// REVIEW & RATING MODELS
// ============================================================================

/// Review Model
class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String title;
  final String content;
  final List<String> imageUrls;
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.title,
    required this.content,
    this.imageUrls = const [],
    this.helpfulCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'title': title,
        'content': content,
        'imageUrls': imageUrls,
        'helpfulCount': helpfulCount,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Review.fromMap(Map<String, dynamic> map) => Review(
        id: map['id'] ?? '',
        productId: map['productId'] ?? '',
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        title: map['title'] ?? '',
        content: map['content'] ?? '',
        imageUrls: List<String>.from(map['imageUrls'] ?? []),
        helpfulCount: map['helpfulCount'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Review copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    double? rating,
    String? title,
    String? content,
    List<String>? imageUrls,
    int? helpfulCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Review(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        rating: rating ?? this.rating,
        title: title ?? this.title,
        content: content ?? this.content,
        imageUrls: imageUrls ?? this.imageUrls,
        helpfulCount: helpfulCount ?? this.helpfulCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ============================================================================
// FAVORITES/WISHLIST MODELS
// ============================================================================

/// Favorite/Wishlist Item Model
class FavoriteItem {
  final String productId;
  final DateTime addedAt;

  FavoriteItem({
    required this.productId,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'addedAt': addedAt,
      };

  factory FavoriteItem.fromMap(Map<String, dynamic> map) => FavoriteItem(
        productId: map['productId'] ?? '',
        addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

/// User Favorites/Wishlist Model
class UserFavorites {
  final String userId;
  final List<FavoriteItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserFavorites({
    required this.userId,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items.map((item) => item.toMap()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory UserFavorites.fromMap(Map<String, dynamic> map) => UserFavorites(
        userId: map['userId'] ?? '',
        items: (map['items'] as List<dynamic>?)
                ?.map((item) =>
                    FavoriteItem.fromMap(item as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
