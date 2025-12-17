import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/order.dart' as model;
import 'package:shop/providers/auth_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  return OrderRepository(firestore);
});

class OrderRepository {
  final FirebaseFirestore _firestore;
  OrderRepository(this._firestore);

  CollectionReference get _col => _firestore.collection('orders');

  Future<String> placeOrder(
      {required String userId,
      required List<model.OrderItem> items,
      required double totalPrice,
      String? paymentMethod}) async {
    final docRef = await _col.add({
      'userId': userId,
      'items': items.map((i) => i.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': 'pending',
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<List<model.Order>> ordersForUser(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                model.Order.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<model.Order?> getOrder(String orderId) async {
    final doc = await _col.doc(orderId).get();
    if (!doc.exists) return null;
    return model.Order.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _col.doc(orderId).update({'status': status});
  }
}
