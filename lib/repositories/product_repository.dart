import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/product.dart';
import 'package:shop/providers/auth_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  return ProductRepository(firestore);
});

class ProductRepository {
  final FirebaseFirestore _firestore;
  ProductRepository(this._firestore);

  CollectionReference get _col => _firestore.collection('products');

  Future<void> addProduct(Product p) async {
    await _col.add(p.toMap());
  }

  Future<void> setProduct(String id, Product p) async {
    await _col.doc(id).set(p.toMap(), SetOptions(merge: true));
  }

  Stream<List<Product>> streamProducts({String? category}) {
    Query q = _col.where('active', isEqualTo: true);
    if (category != null && category.isNotEmpty)
      q = q.where('category', isEqualTo: category);
    return q.orderBy('createdAt', descending: true).snapshots().map((s) => s
        .docs
        .map((d) => Product.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<Product?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
