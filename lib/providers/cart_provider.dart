import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/repository/cart_storage.dart';

final cartProvider = StateNotifierProvider<CartNotifier, Map<String, int>>(
  (ref) {
    final storage = CartStorage();
    return CartNotifier(storage);
  },
);

class CartNotifier extends StateNotifier<Map<String, int>> {
  final CartStorage _storage;

  CartNotifier(this._storage) : super({}) {
    _init();
  }

  Future<void> _init() async {
    final saved = await _storage.restore();
    if (saved != null) state = saved;
  }

  Future<void> addItem(String productId, [int qty = 1]) async {
    final current = Map<String, int>.from(state);
    current[productId] = (current[productId] ?? 0) + qty;
    state = current;
    await _storage.persist(state);
  }

  Future<void> removeItem(String productId, [int qty = 1]) async {
    final current = Map<String, int>.from(state);
    if (!current.containsKey(productId)) return;
    final newQty = current[productId]! - qty;
    if (newQty > 0) {
      current[productId] = newQty;
    } else {
      current.remove(productId);
    }
    state = current;
    await _storage.persist(state);
  }

  Future<void> clear() async {
    state = {};
    await _storage.persist(state);
  }
}
