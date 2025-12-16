import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wishlist_item.dart';
import '../models/product_model.dart';
import '../repositories/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository();
});

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<WishlistItem>>((ref) {
  final repo = ref.read(wishlistRepositoryProvider);
  return WishlistNotifier(repo);
});

/// Provider to get the count of items in wishlist
final wishlistCountProvider = Provider<int>((ref) {
  final items = ref.watch(wishlistProvider);
  return items.length;
});

/// Provider to check if a specific product is in wishlist
final isProductInWishlistProvider = Provider.family<bool, String>((ref, productId) {
  final items = ref.watch(wishlistProvider);
  return items.any((item) => item.product.id == productId);
});

class WishlistNotifier extends StateNotifier<List<WishlistItem>> {
  final WishlistRepository _repo;
  bool _initialized = false;

  WishlistNotifier(this._repo) : super([]) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    await _repo.init();
    state = _repo.getAll();
    _initialized = true;
  }

  Future<void> add(ProductModel product) async {
    if (!_initialized) await _init();
    
    // Check if already in wishlist
    if (_repo.contains(product.id)) return;
    
    final item = WishlistItem(
      id: product.id,
      product: product,
    );
    await _repo.add(item);
    state = _repo.getAll();
  }

  Future<void> remove(String productId) async {
    if (!_initialized) await _init();
    await _repo.remove(productId);
    state = _repo.getAll();
  }

  Future<void> clear() async {
    if (!_initialized) await _init();
    await _repo.clear();
    state = [];
  }

  bool contains(String productId) {
    if (!_initialized) return false;
    return _repo.contains(productId);
  }

  int getCount() => state.length;
}
