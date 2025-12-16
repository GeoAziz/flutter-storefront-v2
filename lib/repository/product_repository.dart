// Minimal ProductRepository abstraction and two simple implementations
import 'package:shop/repository/pagination.dart';
import 'package:shop/services/service_locator.dart';
// telemetry_service type import intentionally omitted; use telemetryService getter.
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String image;
  final double price;
  final double? priceAfterDiscount;
  final int? discountPercent;

  Product({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
    this.priceAfterDiscount,
    this.discountPercent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image': image,
        'price': price,
        'priceAfterDiscount': priceAfterDiscount,
        'discountPercent': discountPercent,
      };

  factory Product.fromJson(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        title: m['title'] as String,
        image: m['image'] as String,
        price: (m['price'] as num).toDouble(),
        priceAfterDiscount: m['priceAfterDiscount'] == null
            ? null
            : (m['priceAfterDiscount'] as num).toDouble(),
        discountPercent: m['discountPercent'] as int?,
      );
}

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();

  /// Fetches products using the specified pagination request (page or cursor based).
  /// Default implementation delegates to fetchProducts() for backward compatibility.
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request) async {
    final telemetry = telemetryService;
    Object? span;
    try {
      span = await telemetry.startSpan('pagination');
      telemetry.logEvent('pagination_start', {
        'requestType': request.runtimeType.toString(),
        if (request is PageRequest) 'page': request.page,
        if (request is PageRequest) 'pageSize': request.pageSize,
        if (request is CursorRequest) 'cursor': request.cursor,
      });

      if (request is PageRequest) {
        final products = await fetchProducts();
        final pageSize = request.pageSize;
        final page = request.page;
        final startIndex = (page - 1) * pageSize;
        final endIndex =
            ((startIndex + pageSize).clamp(0, products.length) as int);

        final items = startIndex >= products.length
            ? <Product>[]
            : products.sublist(startIndex, endIndex);
        final hasMore = endIndex < products.length;

        telemetry.logEvent('pagination_success', {
          'items': items.length,
          'hasMore': hasMore,
          'page': page,
          'pageSize': pageSize,
        });

        return PaginationResult(
          items: items,
          nextCursor: hasMore ? 'page_${page + 1}' : null,
          hasMore: hasMore,
          page: page,
          pageSize: pageSize,
        );
      }

      // Default implementation returns empty for cursor-based requests
      telemetry.logEvent('pagination_success', {'items': 0, 'hasMore': false});
      return PaginationResult.empty();
    } catch (e, st) {
      try {
        telemetry.captureException(e, st,
            context: {'request': request.runtimeType.toString()});
        telemetry.logEvent('pagination_error', {'error': e.toString()});
      } catch (_) {}
      rethrow;
    } finally {
      try {
        await telemetry.finishSpan(span);
      } catch (_) {}
    }
  }
}

class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    // return a tiny, deterministic list for tests and local dev
    return [
      Product(
        id: 'p1',
        title: 'Mock Product 1',
        image: 'assets/images/product1.png',
        price: 99.99,
        priceAfterDiscount: 79.99,
        discountPercent: 20,
      ),
      Product(
        id: 'p2',
        title: 'Mock Product 2',
        image: 'assets/images/product2.png',
        price: 149.99,
        priceAfterDiscount: null,
        discountPercent: null,
      ),
    ];
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request) async {
    final telemetry = telemetryService;
    Object? span;
    try {
      span = await telemetry.startSpan('pagination');
      telemetry.logEvent('pagination_start', {
        'requestType': request.runtimeType.toString(),
        if (request is PageRequest) 'page': request.page
      });

      if (request is PageRequest) {
        final products = await fetchProducts();
        final pageSize = request.pageSize;
        final page = request.page;
        final startIndex = (page - 1) * pageSize;
        final endIndex =
            ((startIndex + pageSize).clamp(0, products.length) as int);

        final items = startIndex >= products.length
            ? <Product>[]
            : products.sublist(startIndex, endIndex);
        final hasMore = endIndex < products.length;

        telemetry.logEvent('pagination_success',
            {'items': items.length, 'hasMore': hasMore, 'page': page});

        return PaginationResult(
          items: items,
          nextCursor: hasMore ? 'page_${page + 1}' : null,
          hasMore: hasMore,
          page: page,
          pageSize: pageSize,
        );
      }

      telemetry.logEvent('pagination_success', {'items': 0, 'hasMore': false});
      return PaginationResult.empty();
    } catch (e, st) {
      try {
        telemetry.captureException(e, st,
            context: {'request': request.runtimeType.toString()});
        telemetry.logEvent('pagination_error', {'error': e.toString()});
      } catch (_) {}
      rethrow;
    } finally {
      try {
        await telemetry.finishSpan(span);
      } catch (_) {}
    }
  }
}

class RealProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    // Placeholder for real network implementation. For now return empty list.
    return [];
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request) async {
    final telemetry = telemetryService;
    Object? span;
    try {
      span = await telemetry.startSpan('pagination');
      telemetry.logEvent('pagination_start', {
        'requestType': request.runtimeType.toString(),
        if (request is PageRequest) 'page': request.page
      });

      if (request is PageRequest) {
        final products = await fetchProducts();
        final pageSize = request.pageSize;
        final page = request.page;
        final startIndex = (page - 1) * pageSize;
        final endIndex =
            ((startIndex + pageSize).clamp(0, products.length) as int);

        final items = startIndex >= products.length
            ? <Product>[]
            : products.sublist(startIndex, endIndex);
        final hasMore = endIndex < products.length;

        telemetry.logEvent('pagination_success',
            {'items': items.length, 'hasMore': hasMore, 'page': page});

        return PaginationResult(
          items: items,
          nextCursor: hasMore ? 'page_${page + 1}' : null,
          hasMore: hasMore,
          page: page,
          pageSize: pageSize,
        );
      }

      telemetry.logEvent('pagination_success', {'items': 0, 'hasMore': false});
      return PaginationResult.empty();
    } catch (e, st) {
      try {
        telemetry.captureException(e, st,
            context: {'request': request.runtimeType.toString()});
        telemetry.logEvent('pagination_error', {'error': e.toString()});
      } catch (_) {}
      rethrow;
    } finally {
      try {
        await telemetry.finishSpan(span);
      } catch (_) {}
    }
  }
}

/// Firestore-backed implementation of [ProductRepository].
///
/// Note: This implementation uses a simple client-side offset strategy for
/// `PageRequest` and `CursorRequest` by fetching (page * pageSize) documents
/// and slicing the result. This is an interim approach for Sprint 1. It
/// produces correct results but can be inefficient for large collections.
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;
  final String collectionPath;

  FirestoreProductRepository(
      {FirebaseFirestore? firestore, this.collectionPath = 'products'})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Product>> _docsToProducts(
      List<QueryDocumentSnapshot> docs) async {
    return docs.map((d) {
      final m = d.data() as Map<String, dynamic>;
      return Product(
        id: m['id'] as String? ?? d.id,
        title: m['title'] as String? ?? '',
        image: m['image'] as String? ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0.0,
        priceAfterDiscount: m['priceAfterDiscount'] == null
            ? null
            : (m['priceAfterDiscount'] as num).toDouble(),
        discountPercent: m['discountPercent'] as int?,
      );
    }).toList();
  }

  /// Helper to fetch up to [limit] documents ordered by createdAt desc.
  Future<List<QueryDocumentSnapshot>> _fetchUpTo(int limit) async {
    final q = _firestore
        .collection(collectionPath)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    final snap = await q.get();
    return snap.docs;
  }

  @override
  Future<List<Product>> fetchProducts() async {
    final docs = await _fetchUpTo(50); // default small fetch
    return _docsToProducts(docs);
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(
      PaginationRequest request) async {
    if (request is PageRequest) {
      final page = request.page;
      final pageSize = request.pageSize;
      final fetchLimit = page * pageSize;
      final docs = await _fetchUpTo(fetchLimit);
      final startIndex = (page - 1) * pageSize;
      if (startIndex >= docs.length) {
        return PaginationResult.empty();
      }
      final endIndex = (startIndex + pageSize).clamp(0, docs.length) as int;
      final slice = docs.sublist(startIndex, endIndex);
      final items = await _docsToProducts(slice);
      final hasMore = endIndex < docs.length;
      String? nextCursor;
      if (hasMore) {
        final nextOffset = endIndex;
        final nextJson = jsonEncode({'offset': nextOffset});
        nextCursor = base64.encode(utf8.encode(nextJson));
      }
      return PaginationResult(
          items: items,
          nextCursor: nextCursor,
          hasMore: hasMore,
          page: page,
          pageSize: pageSize);
    }

    if (request is CursorRequest) {
      final limit = request.limit;

      // Build base query: order by createdAt desc and documentId desc to
      // produce a deterministic ordering that we can resume using startAfter.
      Query q = _firestore
          .collection(collectionPath)
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limit);

      // If a cursor is provided, decode it to obtain the last-seen
      // createdAt (ms since epoch) and document id, then use startAfter
      // with those field values to continue the query.
      if (request.cursor != null) {
        try {
          final decoded = utf8.decode(base64.decode(request.cursor!));
          final json = jsonDecode(decoded) as Map<String, dynamic>;
          final createdAtMs = json['createdAt'] as int?;
          final lastId = json['id'] as String?;
          if (createdAtMs != null && lastId != null) {
            final ts = Timestamp.fromMillisecondsSinceEpoch(createdAtMs);
            q = q.startAfter([ts, lastId]);
          }
        } catch (e) {
          throw FormatException(
              'Invalid or expired pagination cursor: ${e.toString()}');
        }
      }

      final snap = await q.get();
      final docs = snap.docs;
      if (docs.isEmpty) return PaginationResult.empty();

      final items = await _docsToProducts(docs);

      // Decide whether there are more items by attempting to fetch one more
      // document after the last returned one. If we receive a full page then
      // assume there may be more; otherwise end-of-list.
      final hasMore = docs.length >= limit;

      String? nextCursor;
      if (hasMore) {
        final lastDoc = docs.last;
        // createdAt field may be a Firestore Timestamp or a numeric millis value
        Object? createdAtVal;
        try {
          createdAtVal = lastDoc.get('createdAt');
        } catch (_) {
          createdAtVal = null;
        }
        int createdAtMs;
        if (createdAtVal is Timestamp) {
          createdAtMs = createdAtVal.millisecondsSinceEpoch;
        } else if (createdAtVal is int) {
          createdAtMs = createdAtVal;
        } else if (createdAtVal is double) {
          createdAtMs = (createdAtVal as double).toInt();
        } else {
          // Fallback: use current time if createdAt is not present.
          createdAtMs = DateTime.now().millisecondsSinceEpoch;
        }

        final nextJson =
            jsonEncode({'createdAt': createdAtMs, 'id': lastDoc.id});
        nextCursor = base64.encode(utf8.encode(nextJson));
      }

      return PaginationResult(
          items: items, nextCursor: nextCursor, hasMore: hasMore);
    }

    return PaginationResult.empty();
  }
}
