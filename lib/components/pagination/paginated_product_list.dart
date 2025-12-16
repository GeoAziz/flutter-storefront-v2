import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/product_pagination_provider.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/repository/product_repository.dart';

/// Pagination UI state constants for debouncing and throttling
const _scrollThrottleMs = 300;
const _scrollThresholdPixels = 500;

/// A reusable paginated product list widget that provides infinite scroll capability
/// with smooth UX, error handling, and edge-case protection.
///
/// Supports both ListView and GridView variants and integrates seamlessly with
/// [ProductPaginationNotifier] for cursor-based and page-based pagination.
///
/// Features:
/// - Automatic infinite scroll (fetches next page when scrolled near bottom)
/// - Throttled scroll events to prevent duplicate requests during rapid scrolls
/// - Graceful error handling with retry capability
/// - Loading indicators and empty state handling
/// - Customizable layout (list or grid)
class PaginatedProductList extends ConsumerStatefulWidget {
  /// Callback when a product is tapped
  final Function(Product) onProductTap;

  /// Whether to use grid layout (true) or list layout (false)
  final bool useGridLayout;

  /// Number of columns for grid layout (default 2)
  final int gridColumns;

  /// Custom loading widget (defaults to centered circular progress indicator)
  final Widget? customLoadingWidget;

  /// Custom error widget builder
  final Widget Function(String error, VoidCallback retry)? customErrorWidget;

  /// Custom empty state widget
  final Widget? customEmptyWidget;

  /// Padding around the list
  final EdgeInsets padding;

  /// Spacing between items in grid layout
  final double itemSpacing;

  /// Controller for programmatic scroll control (e.g., scroll to top)
  final ScrollController? externalScrollController;

  const PaginatedProductList({
    super.key,
    required this.onProductTap,
    this.useGridLayout = false,
    this.gridColumns = 2,
    this.customLoadingWidget,
    this.customErrorWidget,
    this.customEmptyWidget,
    this.padding = const EdgeInsets.all(defaultPadding),
    this.itemSpacing = defaultPadding,
    this.externalScrollController,
  });

  @override
  ConsumerState<PaginatedProductList> createState() => _PaginatedProductListState();
}

class _PaginatedProductListState extends ConsumerState<PaginatedProductList> {
  late ScrollController _scrollController;
  DateTime? _lastScrollTime;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.externalScrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);

    // Fetch initial products on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(productPaginationProvider.notifier);
      notifier.refresh();
    });
  }

  @override
  void dispose() {
    if (widget.externalScrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  /// Handles scroll events with throttling to prevent rapid duplicate requests
  /// during aggressive scrolling (e.g., momentum scroll flinging).
  void _onScroll() {
    // Throttle scroll events to avoid fetching multiple pages rapidly
    final now = DateTime.now();
    if (_lastScrollTime != null &&
        now.difference(_lastScrollTime!).inMilliseconds < _scrollThrottleMs) {
      return;
    }
    _lastScrollTime = now;

    // Check if we're near the bottom of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _scrollThresholdPixels) {
      final notifier = ref.read(productPaginationProvider.notifier);
      notifier.fetchNextPage();
    }
  }

  /// Retries fetching the next page after an error
  Future<void> _retryFetchNextPage() async {
    final notifier = ref.read(productPaginationProvider.notifier);
    await notifier.fetchNextPage();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productPaginationProvider);

    // Show loading indicator on first load
    if (state.isLoading && state.items.isEmpty) {
      return Center(
        child: widget.customLoadingWidget ??
            const CircularProgressIndicator(),
      );
    }

    // Show empty state if no products loaded
    if (state.items.isEmpty && !state.isLoading) {
      return Center(
        child: widget.customEmptyWidget ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: defaultPadding),
                const Text('No products found'),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
                  onPressed: () {
                    final notifier = ref.read(productPaginationProvider.notifier);
                    notifier.refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
      );
    }

    // Show error message if one occurred
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: widget.customErrorWidget?.call(state.error!, _retryFetchNextPage) ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: defaultPadding),
                Text(
                  'Error: ${state.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
                  onPressed: _retryFetchNextPage,
                  child: const Text('Retry'),
                ),
              ],
            ),
      );
    }

    // Build the product list or grid
    final itemCount = state.items.length + (state.isLoading ? 1 : 0);

    if (widget.useGridLayout) {
      return GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.gridColumns,
          mainAxisSpacing: widget.itemSpacing,
          crossAxisSpacing: widget.itemSpacing,
          childAspectRatio: 0.65,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Show loading indicator at the end when fetching more
          if (index == state.items.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = state.items[index];
          return ProductCard(
            image: product.image,
            brandName: '',
            title: product.title,
            price: product.price,
            priceAfetDiscount: product.priceAfterDiscount,
            dicountpercent: product.discountPercent,
            press: () => widget.onProductTap(product),
          );
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Show loading indicator at the end when fetching more
          if (index == state.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: defaultPadding),
                  if (state.error != null)
                    Column(
                      children: [
                        Text(
                          'Error: ${state.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        ElevatedButton(
                          onPressed: _retryFetchNextPage,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }

          final product = state.items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: defaultPadding / 2),
            child: ProductCard(
              image: product.image,
              brandName: '',
              title: product.title,
              price: product.price,
              priceAfetDiscount: product.priceAfterDiscount,
              dicountpercent: product.discountPercent,
              press: () => widget.onProductTap(product),
            ),
          );
        },
      );
    }
  }
}
