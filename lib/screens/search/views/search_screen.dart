import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/buy_full_ui_kit.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/route/route_names.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(productRepositoryProvider);
    return FutureBuilder<List<Product>>(
      future: repo.fetchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const BuyFullKit(
            images: [
              "assets/screens/SEARCH_1.png",
              "assets/screens/Search_2.png",
              "assets/screens/Search_3.png",
              "assets/screens/Search_4.png",
              "assets/screens/Search_5.png",
              "assets/screens/Search_6.png",
              "assets/screens/Search_7.png",
              "assets/screens/Search_8.png",
            ],
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Search Results')),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ProductCard(
                  image: p.image,
                  title: p.title,
                  brandName: '',
                  price: p.price,
                  priceAfetDiscount: p.priceAfterDiscount,
                  dicountpercent: p.discountPercent,
                  press: () => Navigator.pushNamed(
                      context, RouteNames.productDetails,
                      arguments: p),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
