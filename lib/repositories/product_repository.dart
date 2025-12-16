import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

/// Minimal ProductRepository that uses Firestore cursor-based pagination.
/// This is a lightweight skeleton to be extended during Sprint 1.
class ProductRepository {
  final FirebaseFirestore _firestore;
  final String collectionPath;

  ProductRepository({FirebaseFirestore? firestore, this.collectionPath = 'products'})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Page size for pagination
  static const int pageSize = 20;

  /// Fetch a page of products. If [startAfter] is provided, this will fetch
  /// the next page after that document snapshot.
  Future<List<ProductModel>> fetchPage({DocumentSnapshot? startAfter}) async {
    Query query = _firestore.collection(collectionPath).orderBy('createdAt', descending: true).limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    return docs.map((d) => ProductModel.fromMap(d.data() as Map<String, dynamic>)).toList();
  }
}
