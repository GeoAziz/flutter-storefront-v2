import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/product_provider.dart';

class AdminProductsTab extends ConsumerWidget {
  const AdminProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final p = products[i];
            return ListTile(
              title: Text(p.name),
              subtitle: Text(p.description),
              trailing: Text('\$${p.price.toStringAsFixed(2)}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Failed to load products: $e')),
    );
  }
}
