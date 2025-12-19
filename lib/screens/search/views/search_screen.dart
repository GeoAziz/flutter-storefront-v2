import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/pagination/paginated_product_list.dart';
import 'package:shop/components/pagination/pagination_widgets.dart';
import 'package:shop/route/route_names.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        elevation: 0,
      ),
      body: PaginatedProductList(
        onProductTap: (product) {
          Navigator.pushNamed(
            context,
            RouteNames.productDetails,
            arguments: product,
          );
        },
        useGridLayout: false,
        customLoadingWidget: const PaginationLoadingIndicator(
          message: 'Loading products...',
        ),
        customEmptyWidget: const PaginationEmptyWidget(
          title: 'No search results',
          subtitle: 'Try different search terms or filters',
        ),
      ),
    );
  }
}
