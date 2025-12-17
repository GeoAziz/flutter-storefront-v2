/// Product and Cart Providers
///
/// Riverpod providers for managing products catalog, cart operations,
/// and shopping state throughout the application.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firestore_models.dart' as models;
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// ============================================================================
// PRODUCT PROVIDERS
// ============================================================================

/// Stream provider for all active products
final allProductsProvider = StreamProvider<List<models.Product>>((ref) {
  return firestoreService.streamProducts();
});

/// Family provider for products by category
final productsByCategoryProvider =
    StreamProvider.family<List<models.Product>, String>((ref, category) async* {
  try {
    final products = await firestoreService.getProductsByCategory(category);
    yield products;
  } catch (e) {
    throw Exception('Failed to fetch products: $e');
  }
});

/// Family provider for single product
final productProvider =
    FutureProvider.family<models.Product?, String>((ref, productId) async {
  return firestoreService.getProduct(productId);
});

/// Search products provider
final searchProductsProvider =
    FutureProvider.family<List<models.Product>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }
  return firestoreService.searchProducts(query);
});

/// Filtered products based on search query and category
final filteredProductsProvider =
    Provider.family<AsyncValue<List<models.Product>>, FilterParams>(
        (ref, params) {
  if (params.query.isEmpty && params.category.isEmpty) {
    return ref.watch(allProductsProvider);
  }

  if (params.query.isNotEmpty) {
    return ref.watch(searchProductsProvider(params.query));
  }

  return ref.watch(productsByCategoryProvider(params.category));
});

// ============================================================================
// CART PROVIDERS
// ============================================================================

/// Stream provider for user cart
final userCartProvider = StreamProvider<models.UserCart?>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value(null);
  }

  return firestoreService.streamUserCart(userId);
});

/// Cart total price provider
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(userCartProvider);
  return cart.maybeWhen(
    data: (userCart) => userCart?.totalPrice ?? 0.0,
    orElse: () => 0.0,
  );
});

/// Cart items count provider
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(userCartProvider);
  return cart.maybeWhen(
    data: (userCart) => userCart?.itemCount ?? 0,
    orElse: () => 0,
  );
});

/// Provider for adding item to cart
final addToCartProvider =
    FutureProvider.family<void, AddToCartParams>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');

  final currentCart = await ref.watch(userCartProvider.future);

  final newItem = models.CartItem(
    productId: params.productId,
    quantity: params.quantity,
    priceAtAdd: params.priceAtAdd,
    selectedOptions: params.selectedOptions,
    addedAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final items = currentCart?.items ?? [];

  // Check if item already exists
  final existingIndex =
      items.indexWhere((item) => item.productId == params.productId);

  if (existingIndex >= 0) {
    // Update quantity if item exists
    items[existingIndex] = items[existingIndex].copyWith(
      quantity: items[existingIndex].quantity + params.quantity,
      updatedAt: DateTime.now(),
    );
  } else {
    items.add(newItem);
  }

  final updatedCart = models.UserCart(
    userId: userId,
    items: items,
    createdAt: currentCart?.createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await firestoreService.updateCart(updatedCart);
});

/// Provider for removing item from cart
final removeFromCartProvider =
    FutureProvider.family<void, String>((ref, productId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');

  final currentCart = await ref.watch(userCartProvider.future);
  if (currentCart == null) return;

  final updatedItems =
      currentCart.items.where((item) => item.productId != productId).toList();

  final updatedCart = models.UserCart(
    userId: userId,
    items: updatedItems,
    createdAt: currentCart.createdAt,
    updatedAt: DateTime.now(),
  );

  await firestoreService.updateCart(updatedCart);
});

/// Provider for updating cart item quantity
final updateCartItemQuantityProvider =
    FutureProvider.family<void, UpdateCartItemParams>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');

  final currentCart = await ref.watch(userCartProvider.future);
  if (currentCart == null) return;

  final updatedItems = currentCart.items.map((item) {
    if (item.productId == params.productId) {
      return item.copyWith(
        quantity: params.quantity,
        updatedAt: DateTime.now(),
      );
    }
    return item;
  }).toList();

  final updatedCart = models.UserCart(
    userId: userId,
    items: updatedItems,
    createdAt: currentCart.createdAt,
    updatedAt: DateTime.now(),
  );

  await firestoreService.updateCart(updatedCart);
});

/// Provider for clearing cart
final clearCartProvider = FutureProvider<void>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');

  await firestoreService.clearCart(userId);
});

// ============================================================================
// ORDERS PROVIDERS
// ============================================================================

/// Stream provider for user orders
final userOrdersProvider = StreamProvider<List<models.Order>>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value([]);
  }

  return firestoreService.streamUserOrders(userId);
});

/// Family provider for single order details
final orderDetailsProvider =
    FutureProvider.family<models.Order?, String>((ref, orderId) async {
  return firestoreService.getOrder(orderId);
});

/// Provider for creating new order
final createOrderProvider =
    FutureProvider.family<models.Order, models.Order>((ref, order) async {
  return firestoreService.createOrder(order);
});

// ============================================================================
// FAVORITES PROVIDERS
// ============================================================================

/// Stream provider for user favorites
final userFavoritesProvider = StreamProvider<models.UserFavorites?>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value(null);
  }

  return firestoreService.streamUserFavorites(userId);
});

/// Provider to check if product is favorited
final isProductFavoritedProvider =
    Provider.family<bool, String>((ref, productId) {
  final favorites = ref.watch(userFavoritesProvider);

  return favorites.maybeWhen(
    data: (userFavorites) {
      if (userFavorites == null) return false;
      return userFavorites.items.any((item) => item.productId == productId);
    },
    orElse: () => false,
  );
});

/// Provider for adding to favorites
final addToFavoritesProvider =
    FutureProvider.family<void, String>((ref, productId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');

  await firestoreService.addToFavorites(userId, productId);
});

/// Provider for removing from favorites
final removeFromFavoritesProvider =
    FutureProvider.family<void, String>((ref, productId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');

  await firestoreService.removeFromFavorites(userId, productId);
});

// ============================================================================
// REVIEWS PROVIDERS
// ============================================================================

/// Stream provider for product reviews
final productReviewsProvider =
    StreamProvider.family<List<models.Review>, String>((ref, productId) {
  return firestoreService.streamProductReviews(productId);
});

/// Provider for adding review
final addReviewProvider =
    FutureProvider.family<models.Review, AddReviewParams>((ref, params) async {
  return firestoreService.addReview(params.productId, params.review);
});

// ============================================================================
// IMPORT REQUIRED PROVIDERS
// ============================================================================

// This import is needed for currentUserIdProvider
// (already imported at the top)

// ============================================================================
// PARAMETER CLASSES
// ============================================================================

/// Parameters for filtering products
class FilterParams {
  final String query;
  final String category;

  FilterParams({
    this.query = '',
    this.category = '',
  });
}

/// Parameters for adding item to cart
class AddToCartParams {
  final String productId;
  final int quantity;
  final double priceAtAdd;
  final Map<String, dynamic> selectedOptions;

  AddToCartParams({
    required this.productId,
    required this.quantity,
    required this.priceAtAdd,
    this.selectedOptions = const {},
  });
}

/// Parameters for updating cart item quantity
class UpdateCartItemParams {
  final String productId;
  final int quantity;

  UpdateCartItemParams({
    required this.productId,
    required this.quantity,
  });
}

/// Parameters for adding review
class AddReviewParams {
  final String productId;
  final models.Review review;

  AddReviewParams({
    required this.productId,
    required this.review,
  });
}
