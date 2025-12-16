import 'package:hive_flutter/hive_flutter.dart';
import '../models/wishlist_item.dart';

class WishlistRepository {
  static const String boxName = 'wishlist_box';

  Box? _box;

  /// Initialize the repository (opens the Hive box if needed).
  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    _box = Hive.box(boxName);
  }

  Future<void> add(WishlistItem item) async {
    if (_box == null) await init();
    await _box!.put(item.id, item.toMap());
  }

  Future<void> remove(String id) async {
    if (_box == null) await init();
    await _box!.delete(id);
  }

  List<WishlistItem> getAll() {
    if (_box == null) throw StateError('Repository not initialized. Call init() first.');
    return _box!.values
        .map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return WishlistItem.fromMap(map);
        })
        .toList();
  }

  bool contains(String id) {
    if (_box == null) throw StateError('Repository not initialized. Call init() first.');
    return _box!.containsKey(id);
  }

  Future<void> clear() async {
    if (_box == null) await init();
    await _box!.clear();
  }
}
