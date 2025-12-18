import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/repository/product_repository.dart' as repo;
import 'package:shop/route/route_names.dart';

import '../../../constants.dart';

class BookmarkScreen extends ConsumerWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoProd = ref.read(productRepositoryProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // While loading use 👇
          //  BookMarksSlelton(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<repo.Product>>(
                future: repoProd.fetchProducts(),
                builder: (context, snapshot) {
                  final products = snapshot.data ?? [];
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200.0,
                      mainAxisSpacing: defaultPadding,
                      crossAxisSpacing: defaultPadding,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: products.length,
                    itemBuilder: (BuildContext context, int index) {
                      final p = products[index];
                      return ProductCard(
                        image: p.image,
                        brandName: '',
                        title: p.title,
                        price: p.price,
                        priceAfetDiscount: p.priceAfterDiscount,
                        dicountpercent: p.discountPercent,
                        press: () {
                          Navigator.pushNamed(
                            context,
                            RouteNames.productDetails,
                            arguments: p.id,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
