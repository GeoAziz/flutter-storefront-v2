import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wishlist_item.dart';
import '../repositories/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final repo = WishlistRepository();
  // Prefer explicit initialization from app startup; call init when used.
  return repo;
});

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<WishlistItem>>((ref) {
  final repo = ref.read(wishlistRepositoryProvider);
  return WishlistNotifier(repo);
});

class WishlistNotifier extends StateNotifier<List<WishlistItem>> {
  final WishlistRepository _repo;

  WishlistNotifier(this._repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    await _repo.init();
    state = _repo.getAll();
  }

  Future<void> add(WishlistItem item) async {
    await _repo.add(item);
    state = _repo.getAll();
  }

  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = _repo.getAll();
  }

  bool contains(String id) => _repo.contains(id);
}
