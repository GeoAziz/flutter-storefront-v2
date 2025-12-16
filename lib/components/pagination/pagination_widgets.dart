import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/product_pagination_provider.dart';

/// A loading indicator widget specifically designed for pagination use-cases.
/// Shows a centered spinner with optional message and cancel button.
class PaginationLoadingIndicator extends ConsumerWidget {
  /// Optional message to display below the spinner
  final String? message;

  /// Whether to show a cancel button
  final bool showCancelButton;

  /// Callback when cancel button is pressed
  final VoidCallback? onCancel;

  const PaginationLoadingIndicator({
    super.key,
    this.message,
    this.showCancelButton = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: defaultPadding),
            Text(message!),
          ],
          if (showCancelButton) ...[
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ],
      ),
    );
  }
}

/// An error display widget that shows pagination errors with retry capability.
/// Provides clear feedback to the user and recovery options.
class PaginationErrorWidget extends ConsumerWidget {
  /// The error message to display
  final String errorMessage;

  /// Custom error icon (defaults to error icon)
  final IconData errorIcon;

  /// Callback to retry the failed operation
  final Future<void> Function() onRetry;

  /// Optional callback to clear error and start fresh
  final VoidCallback? onReset;

  /// Whether to show detailed error message (full text) or summary
  final bool showDetailedError;

  const PaginationErrorWidget({
    super.key,
    required this.errorMessage,
    this.errorIcon = Icons.error_outline,
    required this.onRetry,
    this.onReset,
    this.showDetailedError = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(errorIcon, size: 64, color: Colors.red),
            const SizedBox(height: defaultPadding),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              showDetailedError ? errorMessage : 'Failed to load products',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: defaultPadding * 1.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                if (onReset != null) ...[
                  const SizedBox(width: defaultPadding),
                  OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.close),
                    label: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// An empty state widget shown when no products are available.
/// Provides visual feedback and optional action button to retry or navigate.
class PaginationEmptyWidget extends ConsumerWidget {
  /// Custom empty state icon
  final IconData emptyIcon;

  /// Title message for empty state
  final String title;

  /// Subtitle/description message
  final String subtitle;

  /// Callback to retry loading products
  final VoidCallback? onRetry;

  /// Optional button text (defaults to 'Retry')
  final String actionButtonText;

  const PaginationEmptyWidget({
    super.key,
    this.emptyIcon = Icons.shopping_bag_outlined,
    this.title = 'No products found',
    this.subtitle = 'Try adjusting your filters or search terms',
    this.onRetry,
    this.actionButtonText = 'Retry',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(emptyIcon, size: 64, color: Colors.grey),
          const SizedBox(height: defaultPadding),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: defaultPadding / 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: defaultPadding * 1.5),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(actionButtonText),
            ),
          ],
        ],
      ),
    );
  }
}

/// A page info widget that displays current pagination state.
/// Shows current page, total items, and pagination controls.
class PaginationInfoWidget extends ConsumerWidget {
  /// Whether to show in compact mode (minimal info)
  final bool compact;

  /// Custom background color
  final Color? backgroundColor;

  const PaginationInfoWidget({
    super.key,
    this.compact = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productPaginationProvider);

    if (compact) {
      return Container(
        color: backgroundColor ?? Colors.grey[100],
        padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: defaultPadding / 2,
        ),
        child: Text(
          'Page ${state.page} • ${state.items.length} items • ${state.hasMore ? "More available" : "All loaded"}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return Container(
      color: backgroundColor ?? Colors.grey[100],
      padding: const EdgeInsets.all(defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Page ${state.page}',
                  style: Theme.of(context).textTheme.bodyLarge),
              Text('${state.items.length} items loaded',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          if (state.hasMore)
            const Text('More products available',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
          else
            const Text('All products loaded',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// A retry button overlay that appears when there's an error during pagination.
/// Provides quick retry and clear actions for users.
class PaginationRetryOverlay extends ConsumerWidget {
  /// Callback when retry is pressed
  final Future<void> Function() onRetry;

  /// Optional callback when clear is pressed
  final VoidCallback? onClear;

  /// Custom button text for retry
  final String retryText;

  /// Custom button text for clear
  final String? clearText;

  const PaginationRetryOverlay({
    super.key,
    required this.onRetry,
    this.onClear,
    this.retryText = 'Try Again',
    this.clearText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productPaginationProvider);

    if (state.error == null) return const SizedBox.shrink();

    return Positioned(
      bottom: defaultPadding,
      left: defaultPadding,
      right: defaultPadding,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error loading more products',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              state.error ?? 'Unknown error',
              style: const TextStyle(fontSize: 12, color: Colors.red),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onClear != null && clearText != null)
                  TextButton(
                    onPressed: onClear,
                    child: Text(clearText!),
                  ),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(retryText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A pagination progress indicator that shows progress through a large dataset.
/// Useful when you know the total count in advance.
class PaginationProgressIndicator extends ConsumerWidget {
  /// Total number of items in the dataset
  final int? totalItems;

  /// Show as linear progress bar instead of circular
  final bool linearMode;

  const PaginationProgressIndicator({
    super.key,
    this.totalItems,
    this.linearMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productPaginationProvider);

    if (totalItems == null || totalItems! <= 0) {
      return const SizedBox.shrink();
    }

    final progress = (state.items.length / totalItems!).clamp(0.0, 1.0);

    if (linearMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% loaded (${state.items.length} of $totalItems)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.items.length}/$totalItems',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
