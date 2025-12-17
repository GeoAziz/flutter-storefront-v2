import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/pagination/paginated_product_list.dart';
import 'package:shop/route/route_names.dart';

/// AllProductsScreen displays all products using infinite scroll pagination.
/// It wires the [PaginatedProductList] to [productPaginationProvider] and
/// provides navigation to product details on tap.
class AllProductsScreen extends ConsumerWidget {
  const AllProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
      ),
      body: PaginatedProductList(
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
