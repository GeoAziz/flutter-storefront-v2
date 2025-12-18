import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/pagination/paginated_product_list.dart';
import 'package:shop/models/filter_params.dart';
import 'package:shop/route/route_names.dart';

/// AllProductsScreen displays all products using infinite scroll pagination.
/// It wires the [PaginatedProductList] to [productPaginationProvider] and
/// provides navigation to product details on tap.
class AllProductsScreen extends ConsumerWidget {
  const AllProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read optional route arguments to pre-select a category filter or
    // display the selected category in the AppBar.
    final args = ModalRoute.of(context)?.settings.arguments;
    String? categoryName;
    if (args is Map<String, dynamic>) {
      categoryName = args['category'] as String?;
    }
    final filter = FilterParams(category: categoryName ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName ?? 'All Products'),
      ),
      body: PaginatedProductList(
        filter: filter,
        useGridLayout: true,
        gridColumns: 2,
        onProductTap: (product) {
          // Navigate to product details screen with the product ID as argument
          Navigator.of(context).pushNamed(
            RouteNames.productDetails,
            arguments: product.id,
          );
        },
      ),
    );
  }
}
