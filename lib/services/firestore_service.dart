/// Firestore Service
///
/// Handles all Firestore database operations for products, cart, orders,
/// reviews, and other collections with comprehensive error handling.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_models.dart' as models;
import '../config/firebase_config.dart';

class FirestoreException implements Exception {
  final String message;
  final String? code;

  FirestoreException({required this.message, this.code});

  @override
  String toString() => message;
}

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  late FirebaseFirestore _firestore;

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal() {
    _firestore = firebaseConfig.firestore;
  }

  // ========================================================================
  // PRODUCTS OPERATIONS
  // ========================================================================

  /// Get all active products
  Future<List<models.Product>> getAllProducts({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('products')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) =>
              models.Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirestoreException(message: 'Failed to fetch products: $e');
    }
  }

  /// Get products by category
  Future<List<models.Product>> getProductsByCategory(
    String category, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) =>
              models.Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirestoreException(
        message: 'Failed to fetch products in category: $e',
      );
    }
  }

  /// Search products
  Future<List<models.Product>> searchProducts(String query) async {
    try {
      // Simple search by name (for production, consider using Algolia or similar)
      final snapshot = await _firestore
          .collection('products')
          .where('active', isEqualTo: true)
          .get();

      final products = snapshot.docs
          .map((doc) =>
              models.Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by query
      return products
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw FirestoreException(message: 'Search failed: $e');
    }
  }

  /// Get single product
  Future<models.Product?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) return null;

      return models.Product.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirestoreException(message: 'Failed to fetch product: $e');
    }
  }

  /// Stream of products (for real-time updates)
  Stream<List<models.Product>> streamProducts({
    int limit = 20,
  }) {
    try {
      return _firestore
          .collection('products')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) =>
                  models.Product.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw FirestoreException(message: 'Failed to stream products: $e');
    }
  }

  // ========================================================================
  // CART OPERATIONS
  // ========================================================================

  /// Get user cart
  Future<models.UserCart?> getUserCart(String userId) async {
    try {
      final doc = await _firestore.collection('cart').doc(userId).get();

      if (!doc.exists) return null;

      return models.UserCart.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirestoreException(message: 'Failed to fetch cart: $e');
    }
  }

  /// Update cart
  Future<void> updateCart(models.UserCart cart) async {
    try {
      await _firestore
          .collection('cart')
          .doc(cart.userId)
          .set(cart.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw FirestoreException(message: 'Failed to update cart: $e');
    }
  }

  /// Clear cart
  Future<void> clearCart(String userId) async {
    try {
      await _firestore.collection('cart').doc(userId).delete();
    } catch (e) {
      throw FirestoreException(message: 'Failed to clear cart: $e');
    }
  }

  /// Stream user cart (real-time)
  Stream<models.UserCart?> streamUserCart(String userId) {
    try {
      return _firestore.collection('cart').doc(userId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return models.UserCart.fromMap(doc.data() as Map<String, dynamic>);
      });
    } catch (e) {
      throw FirestoreException(message: 'Failed to stream cart: $e');
    }
  }

  // ========================================================================
  // ORDER OPERATIONS
  // ========================================================================

  /// Create new order
  Future<models.Order> createOrder(models.Order order) async {
    try {
      final docRef = _firestore.collection('orders').doc();
      final orderId = docRef.id;

      final newOrder = order.copyWith(id: orderId);

      await docRef.set(newOrder.toMap());

      return newOrder;
    } catch (e) {
      throw FirestoreException(message: 'Failed to create order: $e');
    }
  }

  /// Get user orders
  Future<List<models.Order>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
              (doc) => models.Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirestoreException(message: 'Failed to fetch orders: $e');
    }
  }

  /// Get single order
  Future<models.Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (!doc.exists) return null;

      return models.Order.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirestoreException(message: 'Failed to fetch order: $e');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(
      String orderId, models.OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw FirestoreException(message: 'Failed to update order status: $e');
    }
  }

  /// Stream user orders (real-time)
  Stream<List<models.Order>> streamUserOrders(String userId) {
    try {
      return _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) =>
                  models.Order.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw FirestoreException(message: 'Failed to stream orders: $e');
    }
  }

  // ========================================================================
  // FAVORITES/WISHLIST OPERATIONS
  // ========================================================================

  /// Get user favorites
  Future<models.UserFavorites?> getUserFavorites(String userId) async {
    try {
      final doc = await _firestore.collection('favorites').doc(userId).get();

      if (!doc.exists) return null;

      return models.UserFavorites.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirestoreException(message: 'Failed to fetch favorites: $e');
    }
  }

  /// Add to favorites
  Future<void> addToFavorites(String userId, String productId) async {
    try {
      final docRef = _firestore.collection('favorites').doc(userId);

      await docRef.set({
        'userId': userId,
        'items': FieldValue.arrayUnion([
          {'productId': productId, 'addedAt': DateTime.now()}
        ]),
        'updatedAt': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw FirestoreException(message: 'Failed to add to favorites: $e');
    }
  }

  /// Remove from favorites
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      final docRef = _firestore.collection('favorites').doc(userId);

      await docRef.update({
        'items': FieldValue.arrayRemove([
          {'productId': productId}
        ]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw FirestoreException(message: 'Failed to remove from favorites: $e');
    }
  }

  /// Stream user favorites (real-time)
  Stream<models.UserFavorites?> streamUserFavorites(String userId) {
    try {
      return _firestore
          .collection('favorites')
          .doc(userId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return models.UserFavorites.fromMap(doc.data() as Map<String, dynamic>);
      });
    } catch (e) {
      throw FirestoreException(message: 'Failed to stream favorites: $e');
    }
  }

  // ========================================================================
  // REVIEWS OPERATIONS
  // ========================================================================

  /// Get product reviews
  Future<List<models.Review>> getProductReviews(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              models.Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirestoreException(message: 'Failed to fetch reviews: $e');
    }
  }

  /// Add review to product
  Future<models.Review> addReview(
      String productId, models.Review review) async {
    try {
      final docRef = _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc();

      final reviewId = docRef.id;
      final newReview = review.copyWith(id: reviewId);

      await docRef.set(newReview.toMap());

      // Update product rating
      await _updateProductRating(productId);

      return newReview;
    } catch (e) {
      throw FirestoreException(message: 'Failed to add review: $e');
    }
  }

  /// Update product rating based on reviews
  Future<void> _updateProductRating(String productId) async {
    try {
      final reviews = await getProductReviews(productId);

      if (reviews.isEmpty) return;

      final avgRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

      await _firestore.collection('products').doc(productId).update({
        'rating': avgRating.toStringAsFixed(1),
        'reviewCount': reviews.length,
      });
    } catch (e) {
      // Silently fail - this is a background operation
      print('Failed to update product rating: $e');
    }
  }

  /// Stream product reviews (real-time)
  Stream<List<models.Review>> streamProductReviews(String productId) {
    try {
      return _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) =>
                  models.Review.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw FirestoreException(message: 'Failed to stream reviews: $e');
    }
  }

  // ========================================================================
  // GENERIC OPERATIONS
  // ========================================================================

  /// Batch write operations
  Future<void> batchWrite(
    Future<void> Function(WriteBatch batch) operation,
  ) async {
    try {
      final batch = _firestore.batch();
      await operation(batch);
      await batch.commit();
    } catch (e) {
      throw FirestoreException(message: 'Batch write failed: $e');
    }
  }

  /// Transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction txn) operation,
  ) async {
    try {
      return await _firestore.runTransaction(operation);
    } catch (e) {
      throw FirestoreException(message: 'Transaction failed: $e');
    }
  }
}

/// Global Firestore service instance
final firestoreService = FirestoreService();
