import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/route/route_names.dart';

/// CartScreen now displays the current cart items from [cartProvider],
/// resolves product details from [productRepositoryProvider] (mock or real),
/// and provides basic actions: increase, decrease, remove, and proceed to
/// checkout (stub).
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Please sign in to view your cart'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final cart = ref.watch(cartProvider);
    final repo = ref.read(productRepositoryProvider);

    // Resolve product data for IDs in cart. For the mock repo we fetch all
    // products and match by id. This is simple and safe for small local dev lists.
    return FutureBuilder<List<Product>>(
      future: repo.fetchProducts(),
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? <Product>[];

        if (cart.isEmpty) {
          return _buildEmptyCart(context);
        }

        // Build list of entries with resolved product info when available
        final entries = cart.entries.map((e) {
          final product = allProducts.firstWhere(
            (p) => p.id == e.key,
            orElse: () => Product(
              id: e.key,
              title: 'Product ${e.key}',
              image: 'assets/images/placeholder.png',
              price: 0.0,
            ),
          );
          return MapEntry(product, e.value);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cart'),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final product = entry.key;
                    final qty = entry.value;

                    return ListTile(
                      leading: SizedBox(
                        width: 64,
                        height: 64,
                        child: Image.asset(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                      title: Text(product.title),
                      subtitle: Text(
                        product.priceAfterDiscount != null
                            ? '\$${product.priceAfterDiscount!.toStringAsFixed(2)}'
                            : '\$${product.price.toStringAsFixed(2)}',
                      ),
                      trailing: SizedBox(
                        width: 130,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .removeItem(product.id, 1);
                              },
                            ),
                            Text(qty.toString()),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addItem(product.id, 1);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remove',
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .removeItem(product.id, qty);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(),
                  itemCount: entries.length,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items: ${cart.values.fold<int>(0, (p, e) => p + e)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: \$${_calculateTotal(entries).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Simple stub: navigate to a checkout flow or show a snackbar
                        Navigator.of(context)
                            .pushNamed(RouteNames.paymentMethod);
                      },
                      child: const Text('Proceed to Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Your cart is empty'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(RouteNames.home);
              },
              child: const Text('Shop now'),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal(List<MapEntry<Product, int>> entries) {
    double sum = 0.0;
    for (final e in entries) {
      final p = e.key;
      final price = p.priceAfterDiscount ?? p.price;
      sum += price * e.value;
    }
    return sum;
  }
}
