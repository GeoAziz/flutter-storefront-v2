import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../providers/comparison_provider.dart';

class ComparisonButton extends ConsumerWidget {
  final ProductModel product;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onLimitReached;

  const ComparisonButton({
    Key? key,
    required this.product,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.onLimitReached,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInComparison = ref.watch(isProductInComparisonProvider(product.id));
    final isFull = ref.watch(isComparisonFullProvider);
    final comparison = ref.read(comparisonProvider.notifier);

    return GestureDetector(
      onTap: () async {
        if (isInComparison) {
          await comparison.remove(product.id);
        } else {
          if (isFull && !isInComparison) {
            // Show snackbar or callback when limit is reached
            onLimitReached?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 4 items can be compared'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          } else {
            final success = await comparison.add(product);
            if (!success && !isInComparison) {
              onLimitReached?.call();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maximum 4 items can be compared'),
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              }
            }
          }
        }
      },
      child: Icon(
        isInComparison ? Icons.check_circle : Icons.radio_button_unchecked,
        size: size,
        color: isInComparison 
            ? (activeColor ?? Colors.green) 
            : (inactiveColor ?? Colors.grey),
      ),
    );
  }
}
