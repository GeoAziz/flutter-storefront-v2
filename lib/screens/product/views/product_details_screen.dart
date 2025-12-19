// 🔒 FROZEN / DEPRECATED
// This file is kept for backward-compatibility only. The app should not navigate
// to this screen anymore. Use `ProductDetailScreen` (singular) as the canonical
// product detail UI. The router has been updated to redirect legacy
// `RouteNames.productDetails` to `ProductDetailScreen`.

import 'package:flutter/material.dart';
import 'package:shop/route/route_names.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({Key? key, this.productId, this.repoProduct}) : super(key: key);

  final String? productId;
  final Object? repoProduct;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deprecated screen')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DEPRECATED: ProductDetailsScreen (legacy).',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This screen has been frozen and should no longer be used. Navigate to the canonical ProductDetailScreen instead.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(RouteNames.productDetail, arguments: productId),
              child: const Text('Open canonical ProductDetailScreen'),
            ),
          ],
        ),
      ),
    );
  }
}
