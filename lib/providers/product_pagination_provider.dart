import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/repository/pagination.dart';
import 'package:shop/providers/repository_providers.dart';

class ProductListState {
  final List<Product> items;
  final bool isLoading;
  final int page;
  final bool hasMore;
  final String? error;

  ProductListState({
    required this.items,
    required this.isLoading,
    required this.page,
    required this.hasMore,
    this.error,
  });

  factory ProductListState.initial() => ProductListState(items: [], isLoading: false, page: 1, hasMore: true);

  ProductListState copyWith({List<Product>? items, bool? isLoading, int? page, bool? hasMore, String? error}) {
    return ProductListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class ProductPaginationNotifier extends StateNotifier<ProductListState> {
  final ProductRepository repo;
  final int pageSize;
  String? _nextCursor;

  ProductPaginationNotifier(this.repo, {this.pageSize = 20}) : super(ProductListState.initial());

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, page: 1, error: null);
    try {
      final result = await repo.fetchProductsPaginated(PageRequest(page: 1, pageSize: pageSize));
      _nextCursor = result.nextCursor;
      state = state.copyWith(items: result.items, isLoading: false, page: result.page ?? 1, hasMore: result.hasMore);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      PaginationResult<Product> result;
      if (_nextCursor != null) {
        // Try cursor-based continuation first. If the cursor is invalid or
        // expired the repository will surface a FormatException (per backend
        // contract). In that case we clear the cursor and retry using the
        // page-based fallback so the user can continue browsing.
        try {
          result = await repo.fetchProductsPaginated(CursorRequest(cursor: _nextCursor, limit: pageSize));
        } on FormatException catch (_) {
          // Clear the invalid cursor and retry with page-based continuation.
          _nextCursor = null;
          final nextPage = state.page + 1;
          result = await repo.fetchProductsPaginated(PageRequest(page: nextPage, pageSize: pageSize));
        }
      } else {
        // Fallback to page-based continuation
        final nextPage = state.page + 1;
        result = await repo.fetchProductsPaginated(PageRequest(page: nextPage, pageSize: pageSize));
      }
      final combined = List<Product>.from(state.items)..addAll(result.items);
      _nextCursor = result.nextCursor;
      state = state.copyWith(items: combined, isLoading: false, page: result.page ?? (state.page + 1), hasMore: result.hasMore);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final productPaginationProvider = StateNotifierProvider<ProductPaginationNotifier, ProductListState>((ref) {
  final repo = ref.read(productRepositoryProvider);
  return ProductPaginationNotifier(repo);
});
