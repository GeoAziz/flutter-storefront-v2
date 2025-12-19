import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/pagination/paginated_product_list.dart';
import 'package:shop/components/pagination/pagination_widgets.dart';
import 'package:shop/route/route_names.dart';

class OnSaleScreen extends ConsumerWidget {
  const OnSaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('On Sale'),
        elevation: 0,
      ),
      body: PaginatedProductList(
        onProductTap: (product) {
          Navigator.pushNamed(
            context,
            RouteNames.productDetails,
            arguments: product.id,
          );
        },
        useGridLayout: true,
        gridColumns: 2,
        customLoadingWidget: const PaginationLoadingIndicator(
          message: 'Loading sale items...',
        ),
        customEmptyWidget: const PaginationEmptyWidget(
          title: 'No sale items',
          subtitle: 'Check back later for great deals',
        ),
      ),
    );
  }
}
