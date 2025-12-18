import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../constants.dart';
import 'product_availability_tag.dart';

class ProductInfo extends StatelessWidget {
  const ProductInfo({
    super.key,
    required this.title,
    this.brand,
    this.description,
    this.rating,
    this.numOfReviews,
    required this.isAvailable,
  });

  final String title;
  final String? brand;
  final String? description;
  final double? rating;
  final int? numOfReviews;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final displayBrand = (brand ?? '').toUpperCase();
    final displayRating = rating ?? 0.0;
    final displayReviews = numOfReviews ?? 0;
    final displayDescription = description ?? '';

    return SliverPadding(
      padding: const EdgeInsets.all(defaultPadding),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayBrand.isNotEmpty)
              Text(
                displayBrand,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            if (displayBrand.isNotEmpty) const SizedBox(height: defaultPadding / 2),
            Text(
              title,
              maxLines: 2,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: defaultPadding),
            Row(
              children: [
                ProductAvailabilityTag(isAvailable: isAvailable),
                const Spacer(),
                SvgPicture.asset("assets/icons/Star_filled.svg"),
                const SizedBox(width: defaultPadding / 4),
                Text(
                  "$displayRating ",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text("($displayReviews Reviews)")
              ],
            ),
            const SizedBox(height: defaultPadding),
            Text(
              "Product info",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: defaultPadding / 2),
            if (displayDescription.isNotEmpty)
              Text(
                displayDescription,
                style: const TextStyle(height: 1.4),
              ),
            const SizedBox(height: defaultPadding / 2),
          ],
        ),
      ),
    );
  }
}
