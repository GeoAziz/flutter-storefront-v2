import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/screens/admin/admin_products_tab.dart';
import 'package:shop/screens/admin/admin_orders_tab.dart';
import 'package:shop/screens/admin/admin_inventory_tab.dart';
import 'package:shop/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Dashboard')),
            body: const Center(child: Text('Not authorized to view this page')),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Products'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Inventory')
                ],
              ),
            ),
            body: TabBarView(
              children: const [
                AdminProductsTab(),
                AdminOrdersTab(),
                AdminInventoryTab(),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
          body: Center(child: Text('Failed to determine admin status: $e'))),
    );
  }
}
