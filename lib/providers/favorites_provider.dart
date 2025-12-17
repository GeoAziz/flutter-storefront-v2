import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]);

  void add(String productId) {
    if (!state.contains(productId)) {
      state = [...state, productId];
    }
  }

  void remove(String productId) {
    state = state.where((id) => id != productId).toList();
  }

  void toggle(String productId) {
    if (state.contains(productId)) {
      remove(productId);
    } else {
      add(productId);
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>(
  (ref) => FavoritesNotifier(),
);
