import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/route/route_names.dart';
import 'package:shop/constants.dart';
import 'package:shop/utils/currency.dart';
import 'package:shop/providers/favorites_provider.dart';
import 'package:shop/screens/product/widgets/reviews_section.dart';

/// ProductDetailScreen is wired to fetch product info by ID from the route arguments.
/// It displays product details (image, price, description) and provides an Add-to-Cart
/// action that updates the [cartProvider].
///
/// Usage: Navigate with Navigator.of(context).pushNamed(RouteNames.productDetails, arguments: productId);
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Extract product ID from route arguments
    final productId = ModalRoute.of(context)?.settings.arguments as String?;

    if (productId == null) {
      // Use first product from mock repo for testing
      final repo = ref.read(productRepositoryProvider);
      return FutureBuilder<List<Product>>(
        future: repo.fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: const Text('Product')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final product =
              snapshot.data?.isNotEmpty ?? false ? snapshot.data!.first : null;

          if (product == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Product')),
              body: const Center(child: Text('No product found')),
            );
          }

          return _buildProductDetail(context, ref, product);
        },
      );
    }

    // Normal flow: fetch by ID
    final repo = ref.read(productRepositoryProvider);
    return FutureBuilder<List<Product>>(
      future: repo.fetchProducts(),
      builder: (context, snapshot) {
        Product? product;
        if (snapshot.data != null) {
          try {
            product = snapshot.data!.firstWhere((p) => p.id == productId);
          } catch (e) {
            product = null;
          }
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: const Center(
              child: Text('Product not found'),
            ),
          );
        }

        return _buildProductDetail(context, ref, product);
      },
    );
  }

  Widget _buildProductDetail(
      BuildContext context, WidgetRef ref, Product product) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          Consumer(builder: (context, ref, _) {
            final favs = ref.watch(favoritesProvider);
            final isFav = favs.contains(product.id);
            return IconButton(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                ref.read(favoritesProvider.notifier).toggle(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(isFav
                          ? 'Removed from favorites'
                          : 'Added to favorites')),
                );
              },
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image (network or asset)
            SizedBox(
              width: double.infinity,
              height: 300,
              child: Builder(builder: (context) {
                final image = product.image;
                if (image.isEmpty) {
                  return const Center(child: Icon(Icons.image_not_supported));
                }
                final isNetwork = image.startsWith('http://') || image.startsWith('https://');
                if (isNetwork) {
                  return Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported),
                    loadingBuilder: (c, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  );
                }
                return Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  // Price and discount
                  Row(
                    children: [
                      if (product.priceAfterDiscount != null) ...[
                        Text(
                          formatPrice(product.priceAfterDiscount!, currency: product.currency),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatPrice(product.price, currency: product.currency),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                        ),
                        if (product.discountPercent != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${product.discountPercent}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ] else
                        Text(
                          formatPrice(product.price, currency: product.currency),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Product description from repository
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description ??
                        'No description available for this product.',
                  ),
                  const SizedBox(height: 24),
                  // Quantity selector and Add-to-Cart button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Add product to cart (qty: 1)
                            ref
                                .read(cartProvider.notifier)
                                .addItem(product.id, 1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.title} added to cart'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            // Optionally navigate to cart or stay on the detail page
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Add to Cart'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Navigate to checkout (stub)
                            Navigator.of(context).pushNamed(RouteNames.cart);
                          },
                          child: const Text('View Cart'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Reviews section
                  ReviewsSection(productId: product.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
