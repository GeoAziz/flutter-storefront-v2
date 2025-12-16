import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comparison_item.dart';
import '../models/product_model.dart';
import '../repositories/comparison_repository.dart';

final comparisonRepositoryProvider = Provider<ComparisonRepository>((ref) {
  return ComparisonRepository();
});

final comparisonProvider = StateNotifierProvider<ComparisonNotifier, List<ComparisonItem>>((ref) {
  final repo = ref.read(comparisonRepositoryProvider);
  return ComparisonNotifier(repo);
});

/// Provider to get the count of items in comparison
final comparisonCountProvider = Provider<int>((ref) {
  final items = ref.watch(comparisonProvider);
  return items.length;
});

/// Provider to check if comparison is full (4 items max)
final isComparisonFullProvider = Provider<bool>((ref) {
  final items = ref.watch(comparisonProvider);
  return items.length >= ComparisonRepository.maxItems;
});

/// Provider to check if a specific product is in comparison
final isProductInComparisonProvider = Provider.family<bool, String>((ref, productId) {
  final items = ref.watch(comparisonProvider);
  return items.any((item) => item.product.id == productId);
});

class ComparisonNotifier extends StateNotifier<List<ComparisonItem>> {
  final ComparisonRepository _repo;
  bool _initialized = false;

  ComparisonNotifier(this._repo) : super([]) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    await _repo.init();
    state = _repo.getAll();
    _initialized = true;
  }

  Future<bool> add(ProductModel product) async {
    if (!_initialized) await _init();
    
    // Check if already in comparison
    if (_repo.contains(product.id)) return true;
    
    final item = ComparisonItem(
      id: product.id,
      product: product,
    );
    final success = await _repo.add(item);
    if (success) {
      state = _repo.getAll();
    }
    return success;
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

  bool isFull() {
    if (!_initialized) return false;
    return _repo.isFull();
  }
}
