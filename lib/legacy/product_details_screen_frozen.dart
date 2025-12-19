// 🔒 FROZEN / DEPRECATED
// This screen is no longer used in main flows.
// Only keep for legacy previews or reference.
// Do NOT add new features here.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/repository/product_repository.dart' as repo;
import 'package:shop/providers/product_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/buy_full_ui_kit.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({Key? key, this.productId, this.repoProduct})
      : super(key: key);

  final String? productId;
  final repo.Product? repoProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simple, safe implementation: load product if id provided, otherwise show repo product or demo UI.
    if (productId != null) {
      final productAsync = ref.watch(productProvider(productId!));
      return productAsync.when(
        data: (repo.Product? prod) {
          if (prod == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Product')),
              body: const Center(child: Text('Product not found')),
            );
          }
          return Scaffold(
            appBar: AppBar(title: Text(prod.title)),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(prod.description ?? 'No description'),
            ),
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Loading...')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Error loading product: $e')),
        ),
      );
    }

    if (repoProduct != null) {
      return Scaffold(
        appBar: AppBar(title: Text(repoProduct!.title)),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Price: ${repoProduct!.price}'),
        ),
      );
    }

    // Fallback demo UI
    return Scaffold(
      appBar: AppBar(title: const Text('Product Demo')),
      body: const Center(child: Text('Demo product content')),
    );
  }
}
