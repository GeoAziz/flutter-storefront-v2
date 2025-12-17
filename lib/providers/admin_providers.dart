import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/order.dart' as order_model;
import 'package:shop/features/inventory/models/inventory_item.dart'
    as inv_model;
import 'package:shop/providers/auth_provider.dart';

/// Stream of all orders for admin dashboard (read-only)
final adminOrdersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return firestore
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {
              'id': d.id,
              'userId': data['userId'] ?? '',
              'status': data['status'] ?? '',
              'totalPrice': (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
              'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
            };
          }).toList());
});

/// Stream of inventory items for admin dashboard (read-only)
final adminInventoryProvider =
    StreamProvider<List<inv_model.InventoryItem>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return firestore.collection('inventory').snapshots().map((snap) =>
      snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        // Prefer a productId field if present, otherwise fall back to document id
        final pid = (data['productId'] as String?) ?? d.id;
        final map = {
          'productId': pid,
          'stock': (data['stock'] as num?)?.toInt() ?? 0,
          'reserved': (data['reserved'] as num?)?.toInt() ?? 0,
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
        };
        return inv_model.InventoryItem.fromMap(Map<String, dynamic>.from(map));
      }).toList());
});
