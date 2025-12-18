import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/product/secondary_product_card.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/repository/product_repository.dart' as repo;

import '../../../../constants.dart';
import '../../../../route/route_names.dart';

class MostPopular extends ConsumerWidget {
  const MostPopular({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoProd = ref.read(productRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Most popular",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // While loading use 👇
        // SeconderyProductsSkelton(),
        SizedBox(
          height: 114,
          child: FutureBuilder<List<repo.Product>>(
            future: repoProd.fetchProducts(),
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: defaultPadding,
                      right:
                          index == products.length - 1 ? defaultPadding : 0,
                    ),
                    child: SecondaryProductCard(
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
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}
