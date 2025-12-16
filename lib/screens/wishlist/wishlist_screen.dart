import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants.dart';
import '../../components/network_image_with_loader.dart';
import '../../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistItems = ref.watch(wishlistProvider);
    final wishlist = ref.read(wishlistProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        elevation: 0,
      ),
      body: wishlistItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: defaultPadding),
                  Text(
                    'No items in wishlist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    'Add your favorite products to your wishlist',
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
          : ListView.separated(
              padding: const EdgeInsets.all(defaultPadding),
              itemCount: wishlistItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = wishlistItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(defaultBorderRadious),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: NetworkImageWithLoader(
                            item.product.image,
                            radius: defaultBorderRadious,
                          ),
                        ),
                      ),
                      const SizedBox(width: defaultPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.brandName.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${item.product.price}',
                                  style: const TextStyle(
                                    color: Color(0xFF31B0D8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.product.priceAfetDiscount != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      '\$${item.product.priceAfetDiscount}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await wishlist.remove(item.product.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.product.title} removed from wishlist'),
                                duration: const Duration(milliseconds: 1500),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
