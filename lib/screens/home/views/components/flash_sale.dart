import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/route/route_names.dart';
import 'package:shop/providers/repository_providers.dart';
import 'package:shop/repository/product_repository.dart' as repo;

import '/components/Banner/M/banner_m_with_counter.dart';
import '../../../../components/product/product_card.dart';
import '../../../../constants.dart';

class FlashSale extends ConsumerWidget {
  const FlashSale({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoProd = ref.read(productRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // While loading show 👇
        // const BannerMWithCounterSkelton(),
        BannerMWithCounter(
          duration: const Duration(hours: 8),
          text: "Super Flash Sale \n50% Off",
          press: () {},
        ),
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Flash sale",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // While loading show 👇
        // const ProductsSkelton(),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<repo.Product>>(
            future: repoProd.fetchProducts(),
            builder: (context, snapshot) {
              final products = snapshot.data
                      ?.where((p) => (p.discountPercent ?? 0) > 0)
                      .toList() ??
                  [];

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: defaultPadding,
                      right: index == products.length - 1
                          ? defaultPadding
                          : 0,
                    ),
                    child: ProductCard(
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
        ),
      ],
    );
  }
}
