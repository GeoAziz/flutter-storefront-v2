import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wishlist_item.dart';

class WishlistRepository {
  static const String boxName = 'wishlist_box';

  Box? _box;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the repository (opens the Hive box if needed).
  Future<void> init() async {
    if (_isInitialized) return;
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox(boxName);
    } else {
      _box = Hive.box(boxName);
    }
    _isInitialized = true;
  }

  Future<void> add(WishlistItem item) async {
    if (!_isInitialized) await init();
    await _box!.put(item.id, item.toMap());
  }

  Future<void> remove(String id) async {
    if (!_isInitialized) await init();
    await _box!.delete(id);
  }

  List<WishlistItem> getAll() {
    if (!_isInitialized)
      throw StateError('Repository not initialized. Call init() first.');
    return _box!.values.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return WishlistItem.fromMap(map);
    }).toList();
  }

  bool contains(String id) {
    if (!_isInitialized)
      throw StateError('Repository not initialized. Call init() first.');
    return _box!.containsKey(id);
  }

  Future<void> clear() async {
    if (!_isInitialized) await init();
    await _box!.clear();
  }

  int count() {
    if (!_isInitialized)
      throw StateError('Repository not initialized. Call init() first.');
    return _box!.length;
  }

  /// Optional: Sync local wishlist to Firestore for the given user id.
  /// This is best-effort and will not throw on failure in Sprint 1.
  Future<void> syncToFirestore(String uid) async {
    try {
      final items = getAll();
      final batch = FirebaseFirestore.instance.batch();
      final base = FirebaseFirestore.instance
          .collection('wishlists')
          .doc(uid)
          .collection('items');
      for (final item in items) {
        final docRef = base.doc(item.id);
        batch.set(docRef, item.toMap());
      }
      await batch.commit();
    } catch (e) {
      // ignore errors for Sprint 1; log in dev mode
      // ignore: avoid_print
      print('[WishlistRepository] syncToFirestore failed: $e');
    }
  }
}
