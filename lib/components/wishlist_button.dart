import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../providers/wishlist_provider.dart';

class WishlistButton extends ConsumerWidget {
  final ProductModel product;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const WishlistButton({
    Key? key,
    required this.product,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInWishlist = ref.watch(isProductInWishlistProvider(product.id));
    final wishlist = ref.read(wishlistProvider.notifier);

    return GestureDetector(
      onTap: () async {
        if (isInWishlist) {
          await wishlist.remove(product.id);
        } else {
          await wishlist.add(product);
        }
      },
      child: Icon(
        isInWishlist ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: isInWishlist 
            ? (activeColor ?? Colors.red) 
            : (inactiveColor ?? Colors.grey),
      ),
    );
  }
}
