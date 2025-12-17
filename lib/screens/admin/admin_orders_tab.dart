import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop/providers/admin_providers.dart';

class AdminOrdersTab extends ConsumerWidget {
  const AdminOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final dateFmt = DateFormat.yMd().add_jm();

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) return const Center(child: Text('No orders found'));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final o = orders[i];
            final createdAt = o['createdAt'] as DateTime?;
            return ListTile(
              title: Text('Order ${o['id']}'),
              subtitle: Text(
                  'User: ${o['userId']} • ${o['status']}\n${createdAt != null ? dateFmt.format(createdAt) : ''}'),
              isThreeLine: true,
              trailing:
                  Text('\$${(o['totalPrice'] as double).toStringAsFixed(2)}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Failed to load orders: $e')),
    );
  }
}
