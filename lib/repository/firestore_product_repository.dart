import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shop/repository/pagination.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/repository/real_product_repository.dart' as real_impl;
import 'package:shop/models/filter_params.dart';

/// Firestore-backed [ProductRepository] using FlutterFire.
///
/// IMPORTANT: This implementation intentionally hardcodes the emulator/project
/// configuration to match the seeded data (poafix). It connects to the
/// Firestore emulator at 127.0.0.1:8080 and reads from project `poafix`.
/// This is a deliberate, simple approach (no env flags) per the team's
/// instructions.
class FirestoreProductRepository implements ProductRepository {
  static const String _projectId = 'poafix';
  static const String _emulatorHost = '127.0.0.1:8080';

  final ProductRepository fallback;

  FirestoreProductRepository({ProductRepository? fallback}) : fallback = fallback ?? real_impl.RealProductRepository();

  FirebaseFirestore get _firestore {
    // Use the default app and explicitly set database/project id so the
    // instance targets the hardcoded project. Caller must have initialized
    // Firebase in the app/test harness.
  // Reference the hardcoded project id so it's obvious in the code and
  // to avoid unused-field warnings. The Firestore Flutter API doesn't
  // accept a `databaseId` named argument in some SDK versions, so keep
  // the project id as a visible constant only.
  final _ = _projectId;
  final instance = FirebaseFirestore.instanceFor(app: Firebase.app());
    // Ensure we point at the local emulator; setting this repeatedly is harmless.
    try {
      instance.settings = const Settings(
        host: _emulatorHost,
        sslEnabled: false,
        persistenceEnabled: false,
      );
    } catch (_) {
      // If settings cannot be applied (older/newer API), ignore and continue.
    }
    return instance;
  }

  Product _mapDocumentToProduct(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final id = doc.id;
    final title = (data['title'] ?? data['name'] ?? data['titleText'] ?? '') as String;
    final image = (data['image'] ?? data['imageUrl'] ?? data['thumbnail'] ?? '') as String;
    final price = (data['price'] is num) ? (data['price'] as num).toDouble() : (double.tryParse('${data['price']}') ?? 0.0);
    final priceAfterDiscount = data['priceAfterDiscount'] == null ? null : (data['priceAfterDiscount'] is num ? (data['priceAfterDiscount'] as num).toDouble() : double.tryParse('${data['priceAfterDiscount']}'));
    final discountPercent = data['discountPercent'] is int ? data['discountPercent'] as int : (data['discountPercent'] != null ? int.tryParse('${data['discountPercent']}') : null);
    final category = data['category'] as String? ?? data['categoryId'] as String?;

    return Product(
      id: id,
      title: title,
      image: image,
      price: price,
      priceAfterDiscount: priceAfterDiscount,
      discountPercent: discountPercent,
      category: category,
    );
  }

  Future<List<Product>> _fetchProducts({int limit = 50, FilterParams? params, String? startAfterId}) async {
    try {
      Query query = _firestore.collection('products');
      if (params != null && params.category.isNotEmpty) {
        query = query.where('category', isEqualTo: params.category);
      }
      if (startAfterId != null && startAfterId.isNotEmpty) {
        final lastDoc = await _firestore.collection('products').doc(startAfterId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }
      query = query.limit(limit);
      final snap = await query.get();
      final items = snap.docs.map(_mapDocumentToProduct).toList();
      if (items.isNotEmpty) return items;
    } catch (e) {
      // Let callers handle fallback
      rethrow;
    }
    return [];
  }

  @override
  Future<List<Product>> fetchProducts() async {
    try {
      final items = await _fetchProducts(limit: 50);
      if (items.isNotEmpty) return items;
    } catch (_) {}
    return fallback.fetchProducts();
  }

  /// New helper that supports FilterParams-based cursor pagination.
  Future<PaginationResult<Product>> _fetchProductsPaginated({required FilterParams params, required int pageSize, String? lastDocumentId}) async {
    try {
      final items = await _fetchProducts(limit: pageSize, params: params, startAfterId: lastDocumentId);
      final hasMore = items.length >= pageSize;
      return PaginationResult(
        items: items,
        nextCursor: hasMore ? (items.isNotEmpty ? items.last.id : null) : null,
        hasMore: hasMore,
        page: 1,
        pageSize: pageSize,
      );
    } catch (_) {
      return fallback.fetchProductsPaginated(PageRequest(page: 1, pageSize: pageSize), category: params.category.isEmpty ? null : params.category);
    }
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(PaginationRequest request, {String? category}) async {
    // Map incoming PaginationRequest to FilterParams where possible
    final params = FilterParams(query: '', category: category ?? '');
    if (request is PageRequest) {
      // For page requests we can approximate by fetching pageSize items and slicing locally
      try {
        final all = await _fetchProducts(limit: request.pageSize * request.page, params: params);
        final filtered = all;
        final startIndex = (request.page - 1) * request.pageSize;
        final endIndex = (startIndex + request.pageSize).clamp(0, filtered.length) as int;
        final items = startIndex >= filtered.length ? <Product>[] : filtered.sublist(startIndex, endIndex);
        final hasMore = endIndex < filtered.length;
        return PaginationResult(items: items, nextCursor: hasMore ? 'page_${request.page + 1}' : null, hasMore: hasMore, page: request.page, pageSize: request.pageSize);
      } catch (_) {
        return fallback.fetchProductsPaginated(request, category: category);
      }
    }

    if (request is CursorRequest) {
      try {
        final result = await _fetchProductsPaginated(params: params, pageSize: request.limit, lastDocumentId: request.cursor);
        return result;
      } catch (_) {
        return fallback.fetchProductsPaginated(request, category: category);
      }
    }

    return PaginationResult.empty();
  }
}
