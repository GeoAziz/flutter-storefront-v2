import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/repository/product_repository.dart' as repo;
import 'package:shop/providers/product_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/firestore_models.dart' as models;
import 'package:shop/components/buy_full_ui_kit.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
              ProductListTile(
                svgSrc: "assets/icons/Return.svg",
                title: "Returns",
                isShowBottomBorder: true,
                press: () {
                  customModalBottomSheet(
                    context,
                    height: MediaQuery.of(context).size.height * 0.92,
                    child: const ProductReturnsScreen(),
                  );
                },
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: ReviewCard(
                    rating: 4.3,
                    numOfReviews: 128,
                    numOfFiveStar: 80,
                    numOfFourStar: 30,
                    numOfThreeStar: 5,
                    numOfTwoStar: 4,
                    numOfOneStar: 1,
                  ),
                ),
              ),
              ProductListTile(
                svgSrc: "assets/icons/Chat.svg",
                title: "Reviews",
                isShowBottomBorder: true,
                press: () {
                  Navigator.pushNamed(context, RouteNames.productReviews);
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.all(defaultPadding),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    "You may also like",
                    style: Theme.of(context).textTheme.titleSmall!,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(
                          left: defaultPadding,
                          right: index == 4 ? defaultPadding : 0),
                      child: ProductCard(
                        image: productDemoImg2,
                        title: "Sleeveless Tiered Dobby Swing Dress",
                        brandName: "LIPSY LONDON",
                        price: 24.65,
                        priceAfetDiscount: index.isEven ? 20.99 : null,
                        dicountpercent: index.isEven ? 25 : null,
                        press: () {},
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: defaultPadding),
              )
            ],
          ),
        ),
      );
                description: description,
    // If a product id was passed, load the full product from Firestore provider.
    if (productId != null) {
      final productAsync = ref.watch(productProvider(productId));
      return productAsync.when(
        data: (models.Product? prod) {
          if (prod == null) {
            // fallback to demo UI when product missing
            return buildScaffold(
              images: [productDemoImg1, productDemoImg2, productDemoImg3],
              title: 'Product',
              description: '',
              rating: null,
              numOfReviews: null,
              price: null,
            );
          }

          // Build canonical images list: prefer imageUrls, else thumbnail + first image
          final images = prod.imageUrls.isNotEmpty
              ? prod.imageUrls
              : [if (prod.thumbnailUrl != null) prod.thumbnailUrl!, if (prod.imageUrls.isNotEmpty) prod.imageUrls.first].where((s) => s.isNotEmpty).toList();

          return buildScaffold(
            images: images.isNotEmpty ? images : [productDemoImg1],
            title: prod.name,
            brand: null,
            description: prod.description,
            rating: prod.rating,
            numOfReviews: prod.reviewCount,
            price: prod.discountPrice ?? prod.price,
          );
        },
        loading: () => buildScaffold(
          images: [productDemoImg1, productDemoImg2],
          title: 'Loading...',
          description: '',
          rating: null,
          numOfReviews: null,
          price: null,
        ),
        error: (e, st) => buildScaffold(
          images: [productDemoImg1],
          title: 'Product',
          description: '',
          rating: null,
          numOfReviews: null,
          price: null,
        ),
      );
    }

    // Otherwise if a lightweight repo.Product was passed, map basic fields and render
    if (repoProduct != null) {
      final images = repoProduct.image.isNotEmpty ? [repoProduct.image] : [productDemoImg1];
      return buildScaffold(
        images: images,
        title: repoProduct.title,
        brand: null,
        description: null,
        rating: null,
        numOfReviews: null,
        price: repoProduct.price,
      );
    }

    // Fallback: no args provided, render demo content
    return buildScaffold(
      images: [productDemoImg1, productDemoImg2, productDemoImg3],
      title: 'Sleeveless Ruffle',
      brand: 'LIPSY LONDON',
      description:
          "A cool gray cap in soft corduroy. Watch me.' By buying cotton products from Lindex, you’re supporting more responsibly...",
      rating: 4.4,
      numOfReviews: 126,
      price: 140,
    );
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                        left: defaultPadding,
                        right: index == 4 ? defaultPadding : 0),
                    child: ProductCard(
                      image: productDemoImg2,
                      title: "Sleeveless Tiered Dobby Swing Dress",
                      brandName: "LIPSY LONDON",
                      price: 24.65,
                      priceAfetDiscount: index.isEven ? 20.99 : null,
                      dicountpercent: index.isEven ? 25 : null,
                      press: () {},
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: defaultPadding),
            )
          ],
        ),
      ),
    );
  }
}
