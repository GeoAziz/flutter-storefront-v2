import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants.dart';
import '../../components/network_image_with_loader.dart';
import '../../providers/comparison_provider.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonItems = ref.watch(comparisonProvider);
    final comparison = ref.read(comparisonProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Comparison'),
        elevation: 0,
        actions: [
          if (comparisonItems.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Comparison?'),
                    content: const Text(
                      'Are you sure you want to remove all items from comparison?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await comparison.clear();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: comparisonItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.compare_arrows,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: defaultPadding),
                  Text(
                    'No items to compare',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    'Add up to 4 products to start comparing',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product images row
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              'Product',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...comparisonItems.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(right: defaultPadding),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(defaultBorderRadious),
                                    child: SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: NetworkImageWithLoader(
                                        item.product.image,
                                        radius: defaultBorderRadious,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      item.product.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.labelSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  IconButton(
                                    onPressed: () async {
                                      await comparison.remove(item.product.id);
                                    },
                                    icon: const Icon(Icons.close, size: 20),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                      const SizedBox(height: defaultPadding * 2),
                      // Price row
                      _ComparisonRow(
                        label: 'Price',
                        items: comparisonItems
                            .map((item) => '\$${item.product.price}')
                            .toList(),
                      ),
                      // Rating row
                      _ComparisonRow(
                        label: 'Rating',
                        items: comparisonItems
                            .map((item) =>
                                '${item.product.rating ?? 'N/A'} ⭐')
                            .toList(),
                      ),
                      // Review count row
                      _ComparisonRow(
                        label: 'Reviews',
                        items: comparisonItems
                            .map((item) =>
                                '${item.product.reviewCount ?? 0} reviews')
                            .toList(),
                      ),
                      // Brand row
                      _ComparisonRow(
                        label: 'Brand',
                        items: comparisonItems
                            .map((item) => item.product.brandName)
                            .toList(),
                      ),
                      const SizedBox(height: defaultPadding * 2),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comparison shared!'),
                                duration: Duration(milliseconds: 1500),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share Comparison'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final List<String> items;

  const _ComparisonRow({
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(right: defaultPadding),
              child: SizedBox(
                width: 120,
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
