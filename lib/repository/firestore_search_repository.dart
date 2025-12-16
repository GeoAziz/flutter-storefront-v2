/// Firestore-backed implementation of [SearchRepository].
///
/// Supports basic filter translation (categories, price range, minRating),
/// sorting mapping to common fields, cursor-based pagination using
/// createdAt + documentId, and an optional SearchCache for caching
/// first-page results.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/repository/search_repository.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/repository/search_cache.dart';

class FirestoreSearchRepository implements SearchRepository {
  final FirebaseFirestore _firestore;
  final String collectionPath;
  final SearchCache? _cache;

  FirestoreSearchRepository({
    FirebaseFirestore? firestore,
    this.collectionPath = 'products',
    SearchCache? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache;

  /// Simple retry helper with exponential backoff (maxAttempts including first try).
  Future<T> _retry<T>(Future<T> Function() fn,
      {int maxAttempts = 3,
      Duration baseDelay = const Duration(milliseconds: 300)}) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await fn();
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        final delay = baseDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }
  }

  Query _applyFilters(Query q, SearchQuery query) {
    // Categories: use where('category', whereIn: ...)
    if (query.categories != null && query.categories!.isNotEmpty) {
      // Firestore 'whereIn' supports max 10 items; gracefully trim.
      final values = query.categories!.take(10).toList();
      q = q.where('category', whereIn: values);
    }

    if (query.priceRange != null) {
      q = q.where('price', isGreaterThanOrEqualTo: query.priceRange!.min);
      q = q.where('price', isLessThanOrEqualTo: query.priceRange!.max);
    }

    if (query.minRating != null) {
      q = q.where('rating', isGreaterThanOrEqualTo: query.minRating);
    }

    return q;
  }

  Query _applySort(Query q, SearchSortBy sortBy) {
    switch (sortBy) {
      case SearchSortBy.priceAsc:
        return q.orderBy('price', descending: false);
      case SearchSortBy.priceDesc:
        return q.orderBy('price', descending: true);
      case SearchSortBy.ratingDesc:
        return q.orderBy('rating', descending: true);
      case SearchSortBy.newest:
        return q.orderBy('createdAt', descending: true);
      case SearchSortBy.popularity:
        // Popularity field may not exist; fall back to createdAt desc
        return q.orderBy('popularity', descending: true).orderBy('createdAt', descending: true);
      case SearchSortBy.relevance:
      default:
        // Relevance requires full-text search; fallback to createdAt desc.
        return q.orderBy('createdAt', descending: true);
    }
  }

  Future<Product> _docToProduct(DocumentSnapshot d) async {
    final m = d.data() as Map<String, dynamic>? ?? {};
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
  }

  /// Perform searches against Firestore. For the first-page (cursor == null)
  /// we will attempt to return cached results (if provided) and store the
  /// result back into cache when received.
  @override
  Future<SearchResult> search(SearchQuery query) async {
    // Use cache for first-page queries only
    if (query.cursor == null && _cache != null) {
      final cached = await _cache!.getSearchResult(query);
      if (cached != null) return cached;
    }

    return await _retry(() async {
      Query q = _firestore.collection(collectionPath);

      // Apply filters
      q = _applyFilters(q, query);

      // Apply sorting
      q = _applySort(q, query.sortBy);

      // Ensure deterministic ordering for cursor pagination
      q = q.orderBy(FieldPath.documentId, descending: true);

      // Apply cursor if present
      if (query.cursor != null) {
        try {
          final decoded = utf8.decode(base64.decode(query.cursor!));
          final json = jsonDecode(decoded) as Map<String, dynamic>;
          final createdAtMs = json['createdAt'] as int?;
          final lastId = json['id'] as String?;
          if (createdAtMs != null && lastId != null) {
            final ts = Timestamp.fromMillisecondsSinceEpoch(createdAtMs);
            q = q.startAfter([ts, lastId]);
          }
        } catch (e) {
          // Invalid cursor; ignore and fetch from start
        }
      }

      final limit = query.pageSize;
      q = q.limit(limit);

      final snap = await q.get();
      final docs = snap.docs;
      final items = <Product>[];
      for (final d in docs) {
        items.add(await _docToProduct(d));
      }

      // Determine hasMore by whether docs length == limit
      final hasMore = docs.length >= limit;

      String? nextCursor;
      if (hasMore) {
        final lastDoc = docs.last;
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
          createdAtMs = DateTime.now().millisecondsSinceEpoch;
        }

        final nextJson = jsonEncode({'createdAt': createdAtMs, 'id': lastDoc.id});
        nextCursor = base64.encode(utf8.encode(nextJson));
      }

      // For first-page queries, attempt to persist in cache
      final result = SearchResult(
        items: items,
        query: query,
        totalResults: items.length,
        suggestedQueries: const [],
        availableCategories: {},
        availablePriceRange: const PriceRange(min: 0, max: 0),
        nextCursor: nextCursor,
        hasMore: hasMore,
        page: 1,
        pageSize: limit,
      );

      if (query.cursor == null && _cache != null) {
        try {
          await _cache!.setSearchResult(query, result);
        } catch (_) {
          // Ignore cache write failures
        }
      }

      return result;
    });
  }

  @override
  Future<List<String>> getSuggestions(String partial) async {
    if (partial.isEmpty) return [];
    if (_cache != null) {
      final cached = await _cache!.getSuggestions(partial);
      if (cached != null) return cached;
    }

    // Very small, cheap implementation: fetch a few documents and filter client-side
    final q = _firestore.collection(collectionPath).limit(20);
    final snap = await q.get();
    final lower = partial.toLowerCase();
    final suggestions = <String>[];
    for (final d in snap.docs) {
      final m = d.data() as Map<String, dynamic>? ?? {};
      final title = (m['title'] as String?) ?? '';
      if (title.toLowerCase().contains(lower)) {
        suggestions.add(title);
        if (suggestions.length >= 5) break;
      }
    }

    if (_cache != null) {
      try {
        await _cache!.setSuggestions(partial, suggestions);
      } catch (_) {}
    }

    return suggestions;
  }

  @override
  Future<List<CategoryOption>> getCategories() async {
    if (_cache != null) {
      final cached = await _cache!.getAvailableFilters();
      if (cached != null) return cached.categories;
    }

    // Aggregation: Firestore doesn't support simple counts easily; we fetch a small
    // sample and produce placeholder categories. In production we'd use a catalog
    // collection with precomputed counts or Cloud Functions.
    final q = _firestore.collection(collectionPath).limit(100);
    final snap = await q.get();
    final counts = <String, int>{};
    for (final d in snap.docs) {
      final m = d.data() as Map<String, dynamic>? ?? {};
      final cat = (m['category'] as String?) ?? 'uncategorized';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }

    final list = counts.entries
        .map((e) => CategoryOption(id: e.key, name: e.key, count: e.value))
        .toList();

    if (_cache != null) {
      try {
        await _cache!.setAvailableFilters(AvailableFilters(categories: list, priceRange: const PriceRange(min: 0, max: 0)));
      } catch (_) {}
    }

    return list;
  }

  @override
  Future<PriceRange> getPriceRange() async {
    if (_cache != null) {
      final cached = await _cache!.getAvailableFilters();
      if (cached != null) return cached.priceRange;
    }

    // Scan a sample of documents to estimate min/max price
    final q = _firestore.collection(collectionPath).limit(200);
    final snap = await q.get();
    double? min;
    double? max;
    for (final d in snap.docs) {
      final m = d.data() as Map<String, dynamic>? ?? {};
      final p = (m['price'] as num?)?.toDouble();
      if (p == null) continue;
      min = min == null ? p : (p < min ? p : min);
      max = max == null ? p : (p > max ? p : max);
    }

    final pr = PriceRange(min: min ?? 0.0, max: max ?? 0.0);
    if (_cache != null) {
      try {
        await _cache!.setAvailableFilters(AvailableFilters(categories: const [], priceRange: pr));
      } catch (_) {}
    }

    return pr;
  }

  @override
  Future<AvailableFilters> getAvailableFilters() async {
    if (_cache != null) {
      final cached = await _cache!.getAvailableFilters();
      if (cached != null) return cached;
    }

    // Fetch both categories and price range concurrently
    final categoriesFuture = getCategories();
    final priceRangeFuture = getPriceRange();

    final categories = await categoriesFuture;
    final priceRange = await priceRangeFuture;

    final filters = AvailableFilters(categories: categories, priceRange: priceRange);

    if (_cache != null) {
      try {
        await _cache!.setAvailableFilters(filters);
      } catch (_) {}
    }

    return filters;
  }
}
