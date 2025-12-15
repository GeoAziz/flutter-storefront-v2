import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/route/route_names.dart';
import 'package:shop/providers/repository_providers.dart';

import '../../../../constants.dart';

class PopularProducts extends ConsumerWidget {
  const PopularProducts({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(productRepositoryProvider);
    final future = repo.fetchProducts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Popular products",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(
          height: 220,
          child: FutureBuilder<List>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = snapshot.data ?? [];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    right: index == products.length - 1 ? defaultPadding : 0,
                  ),
                  child: ProductCard(
                    image: '',
                    brandName: '',
                    title: products[index].title,
                    price: 0.0,
                    priceAfetDiscount: null,
                    dicountpercent: null,
                    press: () {
                      Navigator.pushNamed(context, RouteNames.productDetails,
                          arguments: index.isEven);
                    },
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
