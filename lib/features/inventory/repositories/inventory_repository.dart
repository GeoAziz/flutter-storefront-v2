import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';

class InventoryRepository {
  final FirebaseFirestore firestore;
  InventoryRepository({required this.firestore});

  CollectionReference get _inventoryCol => firestore.collection('inventory');

  Future<InventoryItem?> getItem(String productId) async {
    final doc = await _inventoryCol.doc(productId).get();
    if (!doc.exists) return null;
    return InventoryItem.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Reserve stock for a product atomically. Returns true if reserved.
  Future<bool> reserveStock(String productId, int qty) async {
    final docRef = _inventoryCol.doc(productId);
    return firestore.runTransaction((tx) async {
      final doc = await tx.get(docRef);
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['stock'] as num).toInt();
      final currentReserved = (data['reserved'] as num?)?.toInt() ?? 0;
      if (currentStock - currentReserved < qty) return false;
      tx.update(docRef, {'reserved': currentReserved + qty});
      return true;
    });
  }

  /// Release reservation (e.g., on payment timeout)
  Future<void> releaseReservation(String productId, int qty) async {
    final docRef = _inventoryCol.doc(productId);
    await firestore.runTransaction((tx) async {
      final doc = await tx.get(docRef);
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final currentReserved = (data['reserved'] as num?)?.toInt() ?? 0;
      final newReserved = (currentReserved - qty).clamp(0, currentReserved);
      tx.update(docRef, {'reserved': newReserved});
    });
  }

  /// Finalize order: decrement stock and clear reservation
  Future<bool> finalizeOrder(String productId, int qty) async {
    final docRef = _inventoryCol.doc(productId);
    return firestore.runTransaction((tx) async {
      final doc = await tx.get(docRef);
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['stock'] as num).toInt();
      final currentReserved = (data['reserved'] as num?)?.toInt() ?? 0;
      if (currentReserved < qty || currentStock < qty) return false;
      tx.update(docRef, {
        'stock': currentStock - qty,
        'reserved': currentReserved - qty,
      });
      return true;
    });
  }
}
