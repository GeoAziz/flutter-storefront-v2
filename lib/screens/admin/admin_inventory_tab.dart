import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/admin_providers.dart';

class AdminInventoryTab extends ConsumerWidget {
  const AdminInventoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invAsync = ref.watch(adminInventoryProvider);

    return invAsync.when(
      data: (items) {
        if (items.isEmpty)
          return const Center(child: Text('No inventory items found'));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final it = items[i];
            return ListTile(
              title: Text(it.productId),
              subtitle: Text('Stock: ${it.stock} • Reserved: ${it.reserved}'),
              trailing: const Icon(Icons.inventory_2),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Failed to load inventory: $e')),
    );
  }
}
