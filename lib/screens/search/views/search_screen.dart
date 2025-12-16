import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/pagination/pagination_widgets.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/search/search_input_field.dart';
import 'package:shop/components/search/filter_panel.dart';
import 'package:shop/providers/search_provider.dart';
import 'package:shop/route/route_names.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchInputField(),
          ),
          const FilterPanel(),
          Expanded(
            child: resultsAsync.when(
              data: (result) {
                if (result.items.isEmpty) {
                  return const Center(
                    child: PaginationEmptyWidget(
                      title: 'No search results',
                      subtitle: 'Try different search terms or filters',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: result.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = result.items[index];
                    return ProductCard(
                      image: product.image,
                      brandName: '',
                      title: product.title,
                      price: product.price,
                      priceAfetDiscount: product.priceAfterDiscount,
                      dicountpercent: product.discountPercent,
                      press: () => Navigator.pushNamed(
                        context,
                        RouteNames.productDetails,
                        arguments: product,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: PaginationLoadingIndicator(
                  message: 'Searching...',
                ),
              ),
              error: (err, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error loading search results: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(searchResultsProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
